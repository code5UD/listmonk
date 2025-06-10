#!/bin/bash

# Script d'import des données de mairies
# Usage: ./import-mairies.sh [csv_file] [db_connection_string]

set -e

# Configuration par défaut
CSV_FILE="${1:-../mairielist_formatted.csv}"
DB_CONN="${2:-postgres://listmonk_mairies:secure_password@localhost:5432/listmonk_mairies?sslmode=disable}"

echo "=== Import des données de mairies ==="
echo "Fichier CSV: $CSV_FILE"
echo "Base de données: $DB_CONN"
echo

# Vérification que le fichier CSV existe
if [ ! -f "$CSV_FILE" ]; then
    echo "Erreur: Le fichier CSV '$CSV_FILE' n'existe pas."
    echo "Assurez-vous d'avoir converti le fichier avec convert-csv-schema.py"
    echo "Exécutez: python3 scripts/convert-csv-schema.py"
    exit 1
fi

# Compilation et exécution du script d'import
echo "Compilation du script d'import..."
cd "$(dirname "$0")"
go mod tidy 2>/dev/null || true
go run import-mairies.go "$CSV_FILE" "$DB_CONN"

echo
echo "=== Import terminé ==="