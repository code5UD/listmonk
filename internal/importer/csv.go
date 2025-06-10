package importer

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"io"
	"strconv"
	"strings"

	"github.com/knadh/listmonk/internal/geo"
)

// CSVImporter handles CSV import operations for municipalities
type CSVImporter struct {
	db     *sql.DB
	geoSvc *geo.Service
	logger func(string, ...interface{})
}

// ImportResult represents the result of a CSV import operation
type ImportResult struct {
	TotalRows    int           `json:"total_rows"`
	ImportedRows int           `json:"imported_rows"`
	ErrorRows    int           `json:"error_rows"`
	Errors       []ImportError `json:"errors,omitempty"`
}

// ImportError represents an error that occurred during import
type ImportError struct {
	Row     int    `json:"row"`
	Message string `json:"message"`
}

// NewCSVImporter creates a new CSV importer
func NewCSVImporter(db *sql.DB, geoSvc *geo.Service, logger func(string, ...interface{})) *CSVImporter {
	return &CSVImporter{
		db:     db,
		geoSvc: geoSvc,
		logger: logger,
	}
}

// GetImportTemplate returns a CSV template with headers and example data
func (c *CSVImporter) GetImportTemplate() string {
	template := `nom_commune,code_insee,code_departement,population,email,nom_contact,code_postal,latitude,longitude
Paris,75056,75,2161000,contact@paris.fr,M. Anne HIDALGO,75004,48.8566,2.3522
Lyon,69123,69,515695,contact@lyon.fr,M. Grégory DOUCET,69001,45.7640,4.8357
Marseille,13055,13,861635,contact@marseille.fr,Mme Michèle RUBIROLA,13002,43.2965,5.3698
Toulouse,31555,31,471941,contact@toulouse.fr,M. Jean-Luc MOUDENC,31000,43.6047,1.4442
Nice,06088,06,342637,contact@nice.fr,M. Christian ESTROSI,06000,43.7102,7.2620`

	return template
}

// ValidateCSV validates a CSV file and returns validation results
func (c *CSVImporter) ValidateCSV(reader io.Reader) (*ImportResult, error) {
	csvReader := csv.NewReader(reader)
	csvReader.Comma = ','
	csvReader.TrimLeadingSpace = true

	result := &ImportResult{
		Errors: make([]ImportError, 0),
	}

	// Read header
	headers, err := csvReader.Read()
	if err != nil {
		return nil, fmt.Errorf("error reading CSV headers: %v", err)
	}

	headerMap := make(map[string]int)
	for i, header := range headers {
		headerMap[strings.TrimSpace(header)] = i
	}

	// Check for required headers
	requiredHeaders := []string{"nom_commune", "code_insee", "code_departement"}
	for _, required := range requiredHeaders {
		if _, exists := headerMap[required]; !exists {
			return nil, fmt.Errorf("missing required header: %s", required)
		}
	}

	// Read and validate data rows
	rowNum := 1 // Start at 1 since we already read headers
	for {
		record, err := csvReader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			result.Errors = append(result.Errors, ImportError{
				Row:     rowNum + 1,
				Message: fmt.Sprintf("Error reading row: %v", err),
			})
			result.ErrorRows++
			rowNum++
			continue
		}

		result.TotalRows++
		rowNum++

		// Validate row data
		if err := c.validateRow(record, headerMap, rowNum); err != nil {
			result.Errors = append(result.Errors, ImportError{
				Row:     rowNum,
				Message: err.Error(),
			})
			result.ErrorRows++
		} else {
			result.ImportedRows++
		}
	}

	return result, nil
}

// validateRow validates a single CSV row
func (c *CSVImporter) validateRow(record []string, headerMap map[string]int, rowNum int) error {
	// Check required fields
	if idx, exists := headerMap["nom_commune"]; !exists || idx >= len(record) || strings.TrimSpace(record[idx]) == "" {
		return fmt.Errorf("nom_commune is required")
	}

	if idx, exists := headerMap["code_insee"]; !exists || idx >= len(record) || strings.TrimSpace(record[idx]) == "" {
		return fmt.Errorf("code_insee is required")
	}

	if idx, exists := headerMap["code_departement"]; !exists || idx >= len(record) || strings.TrimSpace(record[idx]) == "" {
		return fmt.Errorf("code_departement is required")
	}

	// Validate population if provided
	if idx, exists := headerMap["population"]; exists && idx < len(record) {
		if popStr := strings.TrimSpace(record[idx]); popStr != "" {
			if _, err := strconv.Atoi(popStr); err != nil {
				return fmt.Errorf("invalid population value: %s", popStr)
			}
		}
	}

	// Validate coordinates if provided
	if idx, exists := headerMap["latitude"]; exists && idx < len(record) {
		if latStr := strings.TrimSpace(record[idx]); latStr != "" {
			if _, err := strconv.ParseFloat(latStr, 64); err != nil {
				return fmt.Errorf("invalid latitude value: %s", latStr)
			}
		}
	}

	if idx, exists := headerMap["longitude"]; exists && idx < len(record) {
		if lngStr := strings.TrimSpace(record[idx]); lngStr != "" {
			if _, err := strconv.ParseFloat(lngStr, 64); err != nil {
				return fmt.Errorf("invalid longitude value: %s", lngStr)
			}
		}
	}

	return nil
}

// nullString returns a sql.NullString for empty strings
func nullString(s string) sql.NullString {
	return sql.NullString{
		String: s,
		Valid:  s != "",
	}
}