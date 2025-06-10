#!/bin/bash

# Script complet pour configurer et importer les données de mairies
# Ce script fait tout : conversion du CSV + import + validation

set -e

echo "🏛️  === CONFIGURATION COMPLÈTE DES MAIRIES ==="
echo

# Aller au répertoire racine du projet
cd "$(dirname "$0")/.."

# 1. Vérifier que le fichier source existe
if [ ! -f "mairielist.csv" ]; then
    echo "❌ Erreur: Le fichier mairielist.csv n'existe pas dans le répertoire racine."
    echo "   Assurez-vous que le fichier CSV des mairies est présent."
    exit 1
fi

echo "✅ Fichier source mairielist.csv trouvé"

# 2. Conversion du schéma CSV
echo "🔄 Conversion du schéma CSV..."
python3 scripts/convert-csv-schema.py

if [ ! -f "mairielist_formatted.csv" ]; then
    echo "❌ Erreur: La conversion du CSV a échoué."
    exit 1
fi

echo "✅ Fichier converti: mairielist_formatted.csv"

# 3. Afficher un échantillon du fichier converti
echo
echo "📋 Échantillon du fichier converti:"
head -3 mairielist_formatted.csv | while IFS= read -r line; do
    echo "   $line"
done
echo

# 4. Import des données
echo "📥 Import des données dans la base..."
./scripts/import-mairies.sh

# 5. Validation de l'import
echo
echo "🔍 Validation de l'import..."
./scripts/validate-integration.sh

echo
echo "🎉 === CONFIGURATION TERMINÉE ==="
echo
echo "📊 Résumé:"
echo "   - Fichier source: mairielist.csv"
echo "   - Fichier formaté: mairielist_formatted.csv"
echo "   - Import: Terminé avec succès"
echo "   - Validation: Passée"
echo
echo "🌐 L'interface d'import est maintenant disponible dans l'admin Listmonk:"
echo "   → Utilisateurs > Mairies > Import des mairies"
echo
echo "📝 Format CSV attendu par l'interface:"
echo "   nom_commune,code_insee,code_departement,population,email,nom_contact,code_postal,latitude,longitude"
echo
echo "✨ Vous pouvez maintenant utiliser le système de ciblage géographique !"