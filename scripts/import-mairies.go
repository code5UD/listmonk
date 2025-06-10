package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"
	_ "github.com/lib/pq"
)

type MairieRecord struct {
	NomCommune     string
	CodeInsee      string
	CodeDept       string
	Population     int
	Email          string
	NomContact     string
	CodePostal     string
	Latitude       *float64
	Longitude      *float64
}

func main() {
	if len(os.Args) != 3 {
		log.Fatal("Usage: go run import-mairies.go <csv_file> <db_connection_string>")
	}

	csvFile := os.Args[1]
	dbConnStr := os.Args[2]

	// Connexion à la base de données
	db, err := sqlx.Connect("postgres", dbConnStr)
	if err != nil {
		log.Fatalf("Erreur de connexion à la base de données: %v", err)
	}
	defer db.Close()

	// Ouverture du fichier CSV
	file, err := os.Open(csvFile)
	if err != nil {
		log.Fatalf("Erreur d'ouverture du fichier CSV: %v", err)
	}
	defer file.Close()

	reader := csv.NewReader(file)
	reader.Comma = ';'
	reader.LazyQuotes = true

	// Lecture de l'en-tête
	header, err := reader.Read()
	if err != nil {
		log.Fatalf("Erreur de lecture de l'en-tête: %v", err)
	}

	fmt.Printf("En-tête: %v\n", header)

	// Début de la transaction
	tx, err := db.Beginx()
	if err != nil {
		log.Fatalf("Erreur de début de transaction: %v", err)
	}
	defer tx.Rollback()

	imported := 0
	errors := 0
	lineNumber := 1

	for {
		record, err := reader.Read()
		if err != nil {
			if err.Error() == "EOF" {
				break
			}
			log.Printf("Erreur ligne %d: %v", lineNumber, err)
			errors++
			lineNumber++
			continue
		}

		lineNumber++

		if len(record) < 7 {
			log.Printf("Ligne %d: nombre de colonnes insuffisant", lineNumber)
			errors++
			continue
		}

		// Parsing des données
		mairie := MairieRecord{
			NomCommune: strings.TrimSpace(record[0]),
			CodeInsee:  strings.TrimSpace(record[1]),
			CodeDept:   strings.TrimSpace(record[2]),
			Email:      strings.TrimSpace(record[4]),
			NomContact: strings.TrimSpace(record[5]),
			CodePostal: strings.TrimSpace(record[6]),
		}

		// Population
		if popStr := strings.TrimSpace(record[3]); popStr != "" {
			if pop, err := strconv.Atoi(popStr); err == nil {
				mairie.Population = pop
			}
		}

		// Coordonnées (si disponibles)
		if len(record) > 7 && strings.TrimSpace(record[7]) != "" {
			if lat, err := strconv.ParseFloat(strings.TrimSpace(record[7]), 64); err == nil {
				mairie.Latitude = &lat
			}
		}

		if len(record) > 8 && strings.TrimSpace(record[8]) != "" {
			if lng, err := strconv.ParseFloat(strings.TrimSpace(record[8]), 64); err == nil {
				mairie.Longitude = &lng
			}
		}

		// Validation
		if mairie.NomCommune == "" || mairie.CodeInsee == "" || mairie.CodeDept == "" {
			log.Printf("Ligne %d: données obligatoires manquantes", lineNumber)
			errors++
			continue
		}

		// Insertion ou mise à jour
		err = insertOrUpdateCommune(tx, &mairie)
		if err != nil {
			log.Printf("Ligne %d: erreur d'insertion: %v", lineNumber, err)
			errors++
			continue
		}

		imported++

		if imported%1000 == 0 {
			fmt.Printf("Importé %d communes...\n", imported)
		}
	}

	// Commit de la transaction
	if err := tx.Commit(); err != nil {
		log.Fatalf("Erreur de commit: %v", err)
	}

	fmt.Printf("\nImport terminé:\n")
	fmt.Printf("- Communes importées: %d\n", imported)
	fmt.Printf("- Erreurs: %d\n", errors)
}

func insertOrUpdateCommune(tx *sqlx.Tx, mairie *MairieRecord) error {
	// Vérifier si la commune existe déjà
	var existingID int
	checkQuery := `SELECT id FROM french_communes WHERE insee_code = $1`
	err := tx.Get(&existingID, checkQuery, mairie.CodeInsee)

	var postalCodes []string
	if mairie.CodePostal != "" {
		postalCodes = []string{mairie.CodePostal}
	}

	if err == nil {
		// Mise à jour
		updateQuery := `
			UPDATE french_communes 
			SET name = $2, department_code = $3, population = $4, postal_codes = $5, 
			    latitude = $6, longitude = $7, email = $8, updated_at = NOW()
			WHERE id = $1
		`
		_, err = tx.Exec(updateQuery, existingID, mairie.NomCommune, mairie.CodeDept,
			mairie.Population, pq.Array(postalCodes), mairie.Latitude, mairie.Longitude, mairie.Email)
		return err
	} else {
		// Insertion
		insertQuery := `
			INSERT INTO french_communes (insee_code, name, department_code, population, postal_codes, latitude, longitude, email)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		`
		_, err = tx.Exec(insertQuery, mairie.CodeInsee, mairie.NomCommune, mairie.CodeDept,
			mairie.Population, pq.Array(postalCodes), mairie.Latitude, mairie.Longitude, mairie.Email)
		return err
	}
}