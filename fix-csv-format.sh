#!/bin/bash

# Script pour corriger le format CSV des mairies

echo "🔧 Correction du format CSV des mairies"
echo "======================================="

# Vérifier que le fichier source existe
if [ ! -f "mairielist-converted.csv" ]; then
    echo "❌ Fichier mairielist-converted.csv non trouvé"
    exit 1
fi

echo "📋 Format actuel du fichier :"
head -3 mairielist-converted.csv

echo ""
echo "🔄 Conversion des points-virgules en virgules..."

# Créer une sauvegarde
cp mairielist-converted.csv mairielist-converted.csv.backup

# Convertir les points-virgules en virgules
sed 's/;/,/g' mairielist-converted.csv.backup > mairielist-converted.csv

echo "✅ Conversion terminée"

echo ""
echo "📋 Nouveau format :"
head -3 mairielist-converted.csv

echo ""
echo "📊 Statistiques :"
echo "Nombre de lignes : $(wc -l < mairielist-converted.csv)"
echo "Première ligne (en-tête) : $(head -1 mairielist-converted.csv)"

echo ""
echo "🧪 Test de validation :"
# Vérifier que la colonne email existe
if head -1 mairielist-converted.csv | grep -q "email"; then
    echo "✅ Colonne 'email' trouvée"
else
    echo "❌ Colonne 'email' non trouvée"
fi

# Vérifier le délimiteur
if head -1 mairielist-converted.csv | grep -q ","; then
    echo "✅ Délimiteur virgule détecté"
else
    echo "❌ Délimiteur virgule non détecté"
fi

echo ""
echo "💾 Fichier de sauvegarde créé : mairielist-converted.csv.backup"