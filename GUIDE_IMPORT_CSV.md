# Guide d'Import CSV pour Listmonk

## Problème résolu

Votre fichier CSV original avait plusieurs problèmes qui empêchaient l'import dans Listmonk :

1. **Conflit Git** : Le fichier contenait des marqueurs de conflit Git (`<<<<<<< HEAD`)
2. **Format incompatible** : Listmonk n'accepte que 3 colonnes : `email`, `name`, `attributes`
3. **Structure des données** : Votre fichier avait `firstname` et `lastname` séparés

## Solution mise en place

### 1. Scripts de conversion créés

- `scripts/convert-to-listmonk-format.py` : Pour le format simplifié (nom_commune;code_insee;...)
- `scripts/convert-detailed-csv-to-listmonk.py` : Pour le format détaillé (email,firstname,lastname,...)

### 2. Fichiers générés

- `mairielist-clean.csv` : Fichier original nettoyé (sans marqueurs Git)
- `mairielist-detailed-listmonk.csv` : Fichier converti au format Listmonk (40 583 lignes)
- `mairielist-sample-listmonk.csv` : Échantillon de 100 lignes pour tester

## Format Listmonk

Listmonk accepte uniquement ce format CSV :

```csv
email,name,attributes
user@example.com,John Doe,"{""city"": ""Paris"", ""phone"": ""0123456789""}"
```

### Colonnes requises :

1. **email** : Adresse email (obligatoire)
2. **name** : Nom complet de la personne/organisation
3. **attributes** : Données supplémentaires au format JSON

## Comment utiliser les fichiers convertis

### 1. Test avec l'échantillon

Utilisez d'abord `mairielist-sample-listmonk.csv` (100 lignes) pour tester l'import :

1. Connectez-vous à Listmonk
2. Allez dans **Subscribers** > **Import**
3. Sélectionnez le fichier `mairielist-sample-listmonk.csv`
4. Paramètres d'import :
   - **Mode** : Subscribe
   - **Délimiteur** : `,` (virgule)
   - **Statut** : Unconfirmed ou Confirmed selon vos besoins
   - **Listes** : Sélectionnez la liste de destination

### 2. Import complet

Une fois le test réussi, utilisez `mairielist-detailed-listmonk.csv` pour l'import complet.

## Données conservées

Toutes vos données originales sont conservées dans le champ `attributes` :

- `title` : Civilité (M, Mme, etc.)
- `phone` : Numéro de téléphone
- `website` : Site web
- `address1` : Adresse complète
- `city` : Ville
- `state` : Département (nom)
- `zipcode` : Code postal
- `country` : Pays
- `code_insee` : Code INSEE
- `population_commune` : Population
- `date_naissance` : Date de naissance
- `csp` : Catégorie socio-professionnelle
- `siret` : Numéro SIRET
- `nom_commune` : Nom de la commune
- `departement_numero` : Numéro du département

## Utilisation des attributs

Vous pouvez utiliser ces attributs pour :

1. **Segmentation** : Créer des segments basés sur les départements, population, etc.
2. **Personnalisation** : Utiliser les données dans vos templates d'email
3. **Ciblage géographique** : Filtrer par région, département, code postal

### Exemple de template utilisant les attributs :

```html
Bonjour {{ .Subscriber.Name }},

Nous vous contactons depuis {{ .Subscriber.Attribs.nom_commune }} 
({{ .Subscriber.Attribs.departement_numero }}).

{{ if .Subscriber.Attribs.website }}
Votre site web : {{ .Subscriber.Attribs.website }}
{{ end }}

Cordialement,
L'équipe
```

## Dépannage

### Si l'import échoue :

1. Vérifiez que le délimiteur est bien `,` (virgule)
2. Assurez-vous que le fichier est en UTF-8
3. Vérifiez les logs d'import dans Listmonk
4. Testez d'abord avec l'échantillon de 100 lignes

### Pour reconvertir vos données :

```bash
# Pour le format détaillé
python3 scripts/convert-detailed-csv-to-listmonk.py votre-fichier.csv sortie.csv

# Pour le format simplifié
python3 scripts/convert-to-listmonk-format.py votre-fichier.csv sortie.csv
```

## Fichiers disponibles

- ✅ `mairielist-sample-listmonk.csv` : Échantillon de test (100 lignes)
- ✅ `mairielist-detailed-listmonk.csv` : Import complet (40 583 lignes)
- ✅ `mairielist-listmonk.csv` : Version simplifiée (40 583 lignes)

Votre problème d'import CSV est maintenant résolu ! 🎉