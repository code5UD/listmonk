package geo

import (
	"encoding/csv"
	"fmt"
	"io"
	"strconv"
	"strings"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"
	null "gopkg.in/volatiletech/null.v6"
)

// CSVImporter handles CSV import operations
type CSVImporter struct {
	db      *sqlx.DB
	geoSvc  *Service
	results *ImportResult
}

// NewCSVImporter creates a new CSV importer
func NewCSVImporter(db *sqlx.DB, geoSvc *Service) *CSVImporter {
	return &CSVImporter{
		db:     db,
		geoSvc: geoSvc,
		results: &ImportResult{
			StartTime: time.Now(),
			Errors:    make([]string, 0),
		},
	}
}

// ImportMairiesFromCSV imports mairies data from a CSV reader
func (imp *CSVImporter) ImportMairiesFromCSV(reader io.Reader, createSubscribers bool) (*ImportResult, error) {
	csvReader := csv.NewReader(reader)
	csvReader.Comma = ',' // Use comma delimiter for our CSV format
	csvReader.LazyQuotes = true

	// Read header
	header, err := csvReader.Read()
	if err != nil {
		return nil, fmt.Errorf("error reading CSV header: %w", err)
	}

	// Map header columns
	columnMap := imp.mapColumns(header)
	if err := imp.validateColumns(columnMap); err != nil {
		return nil, fmt.Errorf("invalid CSV format: %w", err)
	}

	// Start transaction
	tx, err := imp.db.Beginx()
	if err != nil {
		return nil, fmt.Errorf("error starting transaction: %w", err)
	}
	defer tx.Rollback()

	// Process records
	lineNumber := 1 // Start at 1 since we already read the header
	for {
		record, err := csvReader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			imp.addError(fmt.Sprintf("Line %d: error reading CSV record: %v", lineNumber, err))
			imp.results.ErrorRecords++
			lineNumber++
			continue
		}

		lineNumber++
		imp.results.TotalRecords++

		// Parse record
		csvRecord, err := imp.parseCSVRecord(record, columnMap)
		if err != nil {
			imp.addError(fmt.Sprintf("Line %d: %v", lineNumber, err))
			imp.results.ErrorRecords++
			continue
		}

		// Validate record
		if err := imp.validateCSVRecord(csvRecord); err != nil {
			imp.addError(fmt.Sprintf("Line %d: %v", lineNumber, err))
			imp.results.ErrorRecords++
			continue
		}

		// Import commune
		commune, err := imp.importCommune(tx, csvRecord)
		if err != nil {
			imp.addError(fmt.Sprintf("Line %d: error importing commune: %v", lineNumber, err))
			imp.results.ErrorRecords++
			continue
		}

		// Import subscriber if requested
		if createSubscribers && csvRecord.Email != "" {
			if err := imp.importSubscriber(tx, csvRecord, commune); err != nil {
				imp.addError(fmt.Sprintf("Line %d: error importing subscriber: %v", lineNumber, err))
				imp.results.ErrorRecords++
				continue
			}
		}

		imp.results.ImportedRecords++
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("error committing transaction: %w", err)
	}

	imp.results.EndTime = time.Now()
	imp.results.Duration = imp.results.EndTime.Sub(imp.results.StartTime).String()
	imp.results.SkippedRecords = imp.results.TotalRecords - imp.results.ImportedRecords - imp.results.ErrorRecords

	return imp.results, nil
}

// mapColumns maps CSV header columns to expected field names
func (imp *CSVImporter) mapColumns(header []string) map[string]int {
	columnMap := make(map[string]int)
	
	for i, col := range header {
		col = strings.ToLower(strings.TrimSpace(col))
		
		// Map various possible column names to standard names
		switch {
		case col == "nom_commune" || (strings.Contains(col, "nom") && strings.Contains(col, "commune")):
			columnMap["nom_commune"] = i
		case col == "code_insee" || (strings.Contains(col, "code") && strings.Contains(col, "insee")):
			columnMap["code_insee"] = i
		case col == "code_departement" || (strings.Contains(col, "code") && strings.Contains(col, "departement")):
			columnMap["code_departement"] = i
		case col == "population" || strings.Contains(col, "population"):
			columnMap["population"] = i
		case col == "email" || strings.Contains(col, "email") || strings.Contains(col, "mail"):
			columnMap["email"] = i
		case col == "nom_contact" || (strings.Contains(col, "nom") && strings.Contains(col, "contact")):
			columnMap["nom_contact"] = i
		case col == "code_postal" || (strings.Contains(col, "code") && strings.Contains(col, "postal")):
			columnMap["code_postal"] = i
		case col == "latitude" || strings.Contains(col, "latitude") || strings.Contains(col, "lat"):
			columnMap["latitude"] = i
		case col == "longitude" || strings.Contains(col, "longitude") || strings.Contains(col, "lng") || strings.Contains(col, "lon"):
			columnMap["longitude"] = i
		}
	}
	
	return columnMap
}

// validateColumns checks if required columns are present
func (imp *CSVImporter) validateColumns(columnMap map[string]int) error {
	required := []string{"nom_commune", "code_insee", "code_departement"}
	
	for _, col := range required {
		if _, exists := columnMap[col]; !exists {
			return fmt.Errorf("required column '%s' not found in CSV", col)
		}
	}
	
	return nil
}

// parseCSVRecord parses a CSV record into a MairieCSVRecord
func (imp *CSVImporter) parseCSVRecord(record []string, columnMap map[string]int) (*MairieCSVRecord, error) {
	csvRecord := &MairieCSVRecord{}
	
	// Parse required fields
	if idx, exists := columnMap["nom_commune"]; exists && idx < len(record) {
		csvRecord.CommuneName = strings.TrimSpace(record[idx])
	}
	
	if idx, exists := columnMap["code_insee"]; exists && idx < len(record) {
		csvRecord.InseeCode = strings.TrimSpace(record[idx])
	}
	
	if idx, exists := columnMap["code_departement"]; exists && idx < len(record) {
		csvRecord.DepartmentCode = strings.TrimSpace(record[idx])
	}
	
	// Parse optional fields
	if idx, exists := columnMap["population"]; exists && idx < len(record) {
		if popStr := strings.TrimSpace(record[idx]); popStr != "" {
			// Remove any non-numeric characters except digits
			popStr = strings.ReplaceAll(popStr, " ", "")
			popStr = strings.ReplaceAll(popStr, ",", "")
			if pop, err := strconv.Atoi(popStr); err == nil {
				csvRecord.Population = pop
			}
		}
	}
	
	if idx, exists := columnMap["email"]; exists && idx < len(record) {
		csvRecord.Email = strings.TrimSpace(record[idx])
	}
	
	if idx, exists := columnMap["nom_contact"]; exists && idx < len(record) {
		csvRecord.ContactName = strings.TrimSpace(record[idx])
	}
	
	if idx, exists := columnMap["code_postal"]; exists && idx < len(record) {
		csvRecord.PostalCode = strings.TrimSpace(record[idx])
	}
	
	if idx, exists := columnMap["latitude"]; exists && idx < len(record) {
		csvRecord.Latitude = strings.TrimSpace(record[idx])
	}
	
	if idx, exists := columnMap["longitude"]; exists && idx < len(record) {
		csvRecord.Longitude = strings.TrimSpace(record[idx])
	}
	
	return csvRecord, nil
}

// validateCSVRecord validates a CSV record
func (imp *CSVImporter) validateCSVRecord(record *MairieCSVRecord) error {
	if record.CommuneName == "" {
		return fmt.Errorf("commune name is required")
	}
	
	if record.InseeCode == "" {
		return fmt.Errorf("INSEE code is required")
	}
	
	if len(record.InseeCode) != 5 {
		return fmt.Errorf("INSEE code must be 5 characters long, got: %s", record.InseeCode)
	}
	
	if record.DepartmentCode == "" {
		return fmt.Errorf("department code is required")
	}
	
	// Validate department code format
	if !isValidDepartmentCode(record.DepartmentCode) {
		return fmt.Errorf("invalid department code: %s", record.DepartmentCode)
	}
	
	// Validate email if provided
	if record.Email != "" && !isValidEmail(record.Email) {
		return fmt.Errorf("invalid email format: %s", record.Email)
	}
	
	return nil
}

// importCommune imports or updates a commune
func (imp *CSVImporter) importCommune(tx *sqlx.Tx, record *MairieCSVRecord) (*Commune, error) {
	commune := &Commune{
		InseeCode:      record.InseeCode,
		Name:           record.CommuneName,
		DepartmentCode: record.DepartmentCode,
		Population:     record.Population,
	}
	
	// Parse postal codes
	if record.PostalCode != "" {
		postalCodes := strings.Split(record.PostalCode, ",")
		for i, code := range postalCodes {
			postalCodes[i] = strings.TrimSpace(code)
		}
		commune.PostalCodes = postalCodes
	}
	
	// Parse coordinates
	if record.Latitude != "" {
		if lat, err := strconv.ParseFloat(strings.Replace(record.Latitude, ",", ".", 1), 64); err == nil {
			commune.Latitude = null.Float64From(lat)
		}
	}
	
	if record.Longitude != "" {
		if lng, err := strconv.ParseFloat(strings.Replace(record.Longitude, ",", ".", 1), 64); err == nil {
			commune.Longitude = null.Float64From(lng)
		}
	}
	
	// Check if commune already exists
	var existingID int
	checkQuery := `SELECT id FROM french_communes WHERE insee_code = $1`
	err := tx.Get(&existingID, checkQuery, commune.InseeCode)
	
	if err == nil {
		// Update existing commune
		commune.ID = existingID
		updateQuery := `
			UPDATE french_communes 
			SET name = $2, department_code = $3, population = $4, postal_codes = $5, 
			    latitude = $6, longitude = $7, updated_at = NOW()
			WHERE id = $1
		`
		_, err = tx.Exec(updateQuery, commune.ID, commune.Name, commune.DepartmentCode,
			commune.Population, pq.Array(commune.PostalCodes), commune.Latitude, commune.Longitude)
		if err != nil {
			return nil, fmt.Errorf("error updating commune: %w", err)
		}
	} else {
		// Create new commune
		insertQuery := `
			INSERT INTO french_communes (insee_code, name, department_code, population, postal_codes, latitude, longitude)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			RETURNING id, created_at, updated_at
		`
		err = tx.QueryRow(insertQuery, commune.InseeCode, commune.Name, commune.DepartmentCode,
			commune.Population, pq.Array(commune.PostalCodes), commune.Latitude, commune.Longitude).
			Scan(&commune.ID, &commune.CreatedAt, &commune.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("error creating commune: %w", err)
		}
	}
	
	return commune, nil
}

// importSubscriber imports or updates a subscriber
func (imp *CSVImporter) importSubscriber(tx *sqlx.Tx, record *MairieCSVRecord, commune *Commune) error {
	if record.Email == "" {
		return nil // Skip if no email
	}
	
	// Check if subscriber already exists
	var subscriberID int
	checkQuery := `SELECT id FROM subscribers WHERE LOWER(email) = LOWER($1)`
	err := tx.Get(&subscriberID, checkQuery, record.Email)
	
	if err == nil {
		// Subscriber exists, associate with commune
		associateQuery := `
			INSERT INTO subscriber_communes (subscriber_id, commune_id)
			VALUES ($1, $2)
			ON CONFLICT (subscriber_id, commune_id) DO NOTHING
		`
		_, err = tx.Exec(associateQuery, subscriberID, commune.ID)
		if err != nil {
			return fmt.Errorf("error associating existing subscriber to commune: %w", err)
		}
	} else {
		// Create new subscriber
		subscriberName := record.ContactName
		if subscriberName == "" {
			subscriberName = fmt.Sprintf("Mairie de %s", record.CommuneName)
		}
		
		// Create subscriber attributes
		attribs := map[string]interface{}{
			"commune": map[string]interface{}{
				"insee_code":      record.InseeCode,
				"name":            record.CommuneName,
				"department_code": record.DepartmentCode,
				"population":      record.Population,
			},
			"contact_type": "mairie",
		}
		
		if record.PostalCode != "" {
			attribs["commune"].(map[string]interface{})["postal_codes"] = strings.Split(record.PostalCode, ",")
		}
		
		// Insert subscriber
		insertQuery := `
			INSERT INTO subscribers (uuid, email, name, attribs, status)
			VALUES (gen_random_uuid(), $1, $2, $3, 'enabled')
			RETURNING id
		`
		err = tx.QueryRow(insertQuery, record.Email, subscriberName, attribs).Scan(&subscriberID)
		if err != nil {
			return fmt.Errorf("error creating subscriber: %w", err)
		}
		
		// Associate with commune
		associateQuery := `
			INSERT INTO subscriber_communes (subscriber_id, commune_id)
			VALUES ($1, $2)
		`
		_, err = tx.Exec(associateQuery, subscriberID, commune.ID)
		if err != nil {
			return fmt.Errorf("error associating new subscriber to commune: %w", err)
		}
	}
	
	return nil
}

// addError adds an error to the import results
func (imp *CSVImporter) addError(errMsg string) {
	imp.results.Errors = append(imp.results.Errors, errMsg)
	
	// Limit the number of errors stored to prevent memory issues
	if len(imp.results.Errors) > 1000 {
		imp.results.Errors = imp.results.Errors[len(imp.results.Errors)-1000:]
	}
}

// isValidDepartmentCode validates a French department code
func isValidDepartmentCode(code string) bool {
	// Standard metropolitan departments (01-95)
	if len(code) == 2 {
		if num, err := strconv.Atoi(code); err == nil {
			return num >= 1 && num <= 95
		}
	}
	
	// Corsica (2A, 2B)
	if code == "2A" || code == "2B" {
		return true
	}
	
	// Overseas departments (971-978)
	if len(code) == 3 {
		if num, err := strconv.Atoi(code); err == nil {
			return num >= 971 && num <= 978
		}
	}
	
	return false
}

// isValidEmail performs basic email validation
func isValidEmail(email string) bool {
	return strings.Contains(email, "@") && strings.Contains(email, ".")
}