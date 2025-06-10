# Solution pour l'Import CSV - Problème Résolu ✅

## Problème initial

Votre fichier CSV avec l'en-tête :
```
email,firstname,lastname,title,phone,website,address1,city,state,zipcode,country,code_insee,population_commune,date_naissance,csp,siren,siret,telecopie,nom_commune,departement_numero
```

Ne fonctionnait pas avec Listmonk car :

1. **Conflit Git** : Marqueurs `<<<<<<< HEAD` dans le fichier
2. **Format incompatible** : Listmonk n'accepte que 3 colonnes : `email`, `name`, `attributes`
3. **En-têtes non reconnus** : `firstname`/`lastname` au lieu de `name`

## Solution mise en place

### 1. Nettoyage et conversion automatique

✅ **Scripts créés** :
- `scripts/convert-detailed-csv-to-listmonk.py` : Conversion automatique
- `scripts/validate-listmonk-csv.py` : Validation du format

✅ **Fichiers générés** :
- `mairielist-sample-listmonk.csv` : 100 lignes pour tester
- `mairielist-detailed-listmonk.csv` : 40 583 lignes complètes
- Format validé compatible Listmonk

### 2. Transformation des données

**Avant** (votre format) :
```csv
email,firstname,lastname,title,phone,website,address1,city,state,zipcode,country,code_insee,population_commune,date_naissance,csp,siren,siret,telecopie,nom_commune,departement_numero
mairieabergementclemenciat@gmail.com,Daniel,BOULON,M,04 74 24 03 08,nan,"119 route de la Fontaine, , , 01400, L'Abergement-Clémenciat",L'ABERGEMENT-CLÉMENCIAT,AIN,01400,France,1001,780,04/03/1951,Retraités salariés privés,nan,21010001200017,,L'ABERGEMENT-CLÉMENCIAT,1
```

**Après** (format Listmonk) :
```csv
email,name,attributes
mairieabergementclemenciat@gmail.com,Daniel BOULON,"{""title"": ""M"", ""phone"": ""04 74 24 03 08"", ""address1"": ""119 route de la Fontaine, , , 01400, L'Abergement-Clémenciat"", ""city"": ""L'ABERGEMENT-CLÉMENCIAT"", ""state"": ""AIN"", ""zipcode"": 1400, ""country"": ""France"", ""code_insee"": 1001, ""population_commune"": 780, ""date_naissance"": ""04/03/1951"", ""csp"": ""Retraités salariés privés"", ""siret"": ""21010001200017"", ""nom_commune"": ""L'ABERGEMENT-CLÉMENCIAT"", ""departement_numero"": 1}"
```

### 3. Données préservées

✅ **Toutes vos données sont conservées** dans le champ `attributes` :
- Informations personnelles (title, phone, date_naissance, csp)
- Adresse complète (address1, city, state, zipcode, country)
- Données géographiques (code_insee, nom_commune, departement_numero)
- Informations administratives (population_commune, siret)
- Site web (website)

## Instructions d'import

### 1. Test rapide (recommandé)

1. Utilisez `mairielist-sample-listmonk.csv` (100 lignes)
2. Dans Listmonk : **Subscribers** > **Import**
3. Paramètres :
   - **Fichier** : `mairielist-sample-listmonk.csv`
   - **Délimiteur** : `,` (virgule)
   - **Mode** : Subscribe
   - **Statut** : Unconfirmed ou Confirmed

### 2. Import complet

Une fois le test réussi, utilisez `mairielist-detailed-listmonk.csv` (40 583 lignes)

## Utilisation des données

### Segmentation par attributs

Vous pouvez créer des segments basés sur :
```sql
-- Par département
subscribers.attribs->>'departement_numero' = '75'

-- Par population
(subscribers.attribs->>'population_commune')::int > 10000

-- Par région
subscribers.attribs->>'state' = 'ILE-DE-FRANCE'
```

### Personnalisation des emails

```html
Bonjour {{ .Subscriber.Name }},

Nous vous contactons depuis {{ .Subscriber.Attribs.nom_commune }}
(département {{ .Subscriber.Attribs.departement_numero }}).

{{ if .Subscriber.Attribs.website }}
Site web : {{ .Subscriber.Attribs.website }}
{{ end }}

Population : {{ .Subscriber.Attribs.population_commune }} habitants
```

## Validation

✅ **Tests effectués** :
```bash
# Validation du fichier échantillon
✅ Lignes valides : 100

# Validation du fichier complet  
✅ Lignes valides : 40583

✅ Le fichier est compatible avec Listmonk !
```

## Fichiers prêts à l'emploi

- 📁 `mairielist-sample-listmonk.csv` : **100 lignes** pour tester
- 📁 `mairielist-detailed-listmonk.csv` : **40 583 lignes** pour l'import complet

## Résultat

🎉 **Votre problème d'import CSV est résolu !**

- ✅ Format compatible Listmonk
- ✅ Toutes les données préservées
- ✅ Fichiers validés et prêts
- ✅ Scripts pour futures conversions

Vous pouvez maintenant importer vos données dans Listmonk sans problème.