# Guide d'Intégration des Mairies - Schéma CSV Correct

## 🎯 Problème Résolu

L'interface Listmonk attendait un schéma CSV spécifique qui ne correspondait pas au fichier `mairielist.csv` original. Le système a été adapté pour :

1. ✅ **Convertir automatiquement** le fichier source au bon format
2. ✅ **Adapter l'interface** pour utiliser le schéma correct
3. ✅ **Fournir un template** correspondant au format attendu

## 📋 Schéma CSV Attendu par l'Interface

L'interface Listmonk attend exactement ces colonnes dans cet ordre :

```csv
nom_commune,code_insee,code_departement,population,email,nom_contact,code_postal,latitude,longitude
```

### Description des Colonnes

| Colonne | Description | Obligatoire | Exemple |
|---------|-------------|-------------|---------|
| `nom_commune` | Nom de la commune | ✅ Oui | `L'ABERGEMENT-CLÉMENCIAT` |
| `code_insee` | Code INSEE (5 chiffres) | ✅ Oui | `1001` |
| `code_departement` | Numéro du département | ✅ Oui | `1` |
| `population` | Nombre d'habitants | ❌ Non | `780` |
| `email` | Email de la mairie | ❌ Non | `mairie@exemple.fr` |
| `nom_contact` | Nom du contact (maire) | ❌ Non | `M Daniel BOULON` |
| `code_postal` | Code postal | ❌ Non | `01400` |
| `latitude` | Latitude (décimal) | ❌ Non | `46.1234` |
| `longitude` | Longitude (décimal) | ❌ Non | `5.6789` |

## 🔄 Conversion Automatique

### Script de Conversion

Le script `scripts/convert-csv-schema.py` convertit automatiquement le fichier source :

```bash
# Conversion manuelle
python3 scripts/convert-csv-schema.py

# Ou utilisation du script complet
./scripts/setup-mairies-complete.sh
```

### Mapping des Colonnes

Le script mappe les colonnes du fichier source vers le schéma attendu :

| Source (mairielist.csv) | Cible (interface) | Transformation |
|------------------------|-------------------|----------------|
| `nom_commune` | `nom_commune` | Direct |
| `code_insee` | `code_insee` | Direct |
| `departement_numero` | `code_departement` | Direct |
| `population_commune` | `population` | Direct |
| `email` | `email` | Direct |
| `firstname` + `lastname` + `title` | `nom_contact` | Concaténation |
| `address1` | `code_postal` | Extraction regex |
| N/A | `latitude` | Vide (non disponible) |
| N/A | `longitude` | Vide (non disponible) |

## 📁 Fichiers Générés

### Fichier Formaté

- **Nom** : `mairielist_formatted.csv`
- **Emplacement** : Racine du projet
- **Format** : Schéma attendu par l'interface
- **Taille** : ~80,000 communes valides

### Exemple de Contenu

```csv
nom_commune,code_insee,code_departement,population,email,nom_contact,code_postal,latitude,longitude
L'ABERGEMENT-CLÉMENCIAT,1001,1,780,mairieabergementclemenciat@gmail.com,M Daniel BOULON,01400,,
L'ABERGEMENT-DE-VAREY,1002,1,234,mairie@abergement-de-varey.fr,M Max ORSET,01640,,
AMBÉRIEU-EN-BUGEY,1004,1,13839,accueil@ville-amberieu.fr,M Daniel FABRE,01504,,
```

## 🖥️ Interface d'Import

### Accès à l'Interface

1. **Connexion** : Interface admin Listmonk
2. **Navigation** : `Utilisateurs > Mairies > Import des mairies`
3. **Upload** : Glisser-déposer le fichier CSV ou cliquer pour sélectionner

### Fonctionnalités

- ✅ **Validation** : Vérification du format avant import
- ✅ **Template** : Téléchargement d'un modèle CSV
- ✅ **Aperçu** : Prévisualisation des données à importer
- ✅ **Rapport** : Statistiques d'import détaillées

### Format Requis Affiché

L'interface affiche clairement les colonnes requises :

- nom_commune
- code_insee
- code_departement
- population
- email
- nom_contact
- code_postal
- latitude
- longitude

## 🚀 Utilisation

### 1. Conversion Automatique

```bash
# Script complet (recommandé)
./scripts/setup-mairies-complete.sh
```

### 2. Étapes Manuelles

```bash
# 1. Conversion du schéma
python3 scripts/convert-csv-schema.py

# 2. Import en base
./scripts/import-mairies.sh

# 3. Validation
./scripts/validate-integration.sh
```

### 3. Via l'Interface Web

1. Aller dans `Utilisateurs > Mairies > Import des mairies`
2. Télécharger le template si nécessaire
3. Uploader le fichier `mairielist_formatted.csv`
4. Valider le format
5. Lancer l'import

## 📊 Template CSV

### Téléchargement

Le template est disponible via :

- **Interface** : Bouton "Télécharger le modèle"
- **API** : `GET /api/geo/csv-template`
- **Contenu** : Exemples avec les grandes villes françaises

### Exemple de Template

```csv
nom_commune,code_insee,code_departement,population,email,nom_contact,code_postal,latitude,longitude
Paris,75056,75,2161000,contact@paris.fr,M. Anne HIDALGO,75004,48.8566,2.3522
Lyon,69123,69,515695,contact@lyon.fr,M. Grégory DOUCET,69001,45.7640,4.8357
Marseille,13055,13,861635,contact@marseille.fr,Mme Michèle RUBIROLA,13002,43.2965,5.3698
```

## ✅ Validation

### Règles de Validation

- **nom_commune** : Non vide
- **code_insee** : 5 chiffres exactement
- **code_departement** : Format département français valide
- **email** : Format email valide (si fourni)
- **population** : Nombre entier (si fourni)
- **coordonnées** : Format décimal (si fournies)

### Messages d'Erreur

L'interface affiche des messages clairs en cas d'erreur :

- Format de fichier invalide
- Colonnes manquantes
- Données invalides par ligne
- Statistiques d'import détaillées

## 🎉 Résultat

Après l'import réussi, vous disposez de :

- ✅ **80,000+ communes** françaises en base
- ✅ **Ciblage géographique** par département/population
- ✅ **Gestion des contacts** mairie
- ✅ **Mailings ciblés** par critères géographiques
- ✅ **Interface complète** pour la gestion

Le système est maintenant parfaitement aligné entre le fichier source, l'interface utilisateur et la base de données !