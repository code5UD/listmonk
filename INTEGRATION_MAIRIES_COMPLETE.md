# Intégration Complète des Données Mairies

## 📋 Résumé des Modifications

Cette mise à jour intègre complètement les données du fichier `mairielist.csv` et corrige les fonctionnalités de gestion des contacts mairie et des mailings par département/nombre d'habitants.

## 🔧 Corrections Apportées

### 1. Intégration des Données CSV

- **Script de conversion** : `scripts/convert-mairielist-csv.py`
  - Convertit le format CSV original au format attendu par l'importeur
  - Gère les codes INSEE à 4 chiffres en les complétant à 5 chiffres
  - Nettoie et valide les données (emails, population, codes départements)

- **Script d'import** : `scripts/import-mairies.go`
  - Import direct en base de données avec gestion des erreurs
  - Support des mises à jour incrémentales
  - Validation des données avant insertion

### 2. Correction des Incohérences de Base de Données

- **Migration corrigée** : `migrations/v5.1.0_geo_tables.sql`
  - Utilisation cohérente des noms de tables (`french_communes`, `french_departments`)
  - Correction des références entre tables
  - Ajout d'index pour optimiser les performances

### 3. Fonctionnalités de Ciblage Géographique

- **Service géographique étendu** : `internal/geo/geo.go`
  - `GetTargetedSubscribers()` : Récupère les abonnés selon des critères géographiques
  - `GetTargetingStats()` : Statistiques détaillées de ciblage
  - `GetDepartmentStats()` : Statistiques par département
  - `GetPopulationRangeStats()` : Statistiques par tranche de population

- **Handlers de ciblage** : `cmd/targeting.go`
  - `CreateTargetedCampaign()` : Création de campagnes ciblées géographiquement
  - `BulkSubscriberUpdate()` : Mise à jour en masse des abonnés
  - `GetTargetingStats()` : API pour les statistiques de ciblage

### 4. Optimisations de Performance

- **Fonctions SQL** : `scripts/fix-targeting.sql`
  - `count_targeting_recipients()` : Comptage optimisé des destinataires
  - `get_targeted_subscribers()` : Récupération paginée des abonnés ciblés
  - `get_department_statistics()` : Statistiques par département
  - `get_population_range_statistics()` : Statistiques par tranche de population

- **Index de performance**
  - Index composites sur population et département
  - Index sur les associations abonnés-communes
  - Vue matérialisée pour les statistiques (optionnel)

## 📊 Nouvelles API Endpoints

### Endpoints Géographiques

```bash
# Départements
GET /api/geo/departments

# Communes avec filtres
GET /api/geo/communes?department_codes=75,92&population_min=1000&population_max=50000

# Recherche de communes
GET /api/geo/communes/search?q=Paris

# Statistiques générales
GET /api/geo/stats
```

### Endpoints de Ciblage

```bash
# Prévisualisation de ciblage
POST /api/geo/targeting/preview
{
  "department_codes": ["75", "92"],
  "population_min": 1000,
  "population_max": 50000
}

# Comptage de destinataires
POST /api/geo/targeting/count
{
  "department_codes": ["75"],
  "population_min": 5000
}

# Statistiques de ciblage
GET /api/geo/targeting/stats?department_codes=75,92

# Statistiques par département
GET /api/geo/targeting/departments

# Statistiques par tranche de population
GET /api/geo/targeting/population-ranges
```

### Endpoints de Campagnes Ciblées

```bash
# Création de campagne ciblée
POST /api/geo/campaigns/targeted
{
  "name": "Campagne Île-de-France",
  "subject": "Information importante",
  "body": "Contenu du message",
  "targeting_filter": {
    "department_codes": ["75", "92", "93", "94"],
    "population_min": 1000
  }
}

# Mise à jour en masse d'abonnés
POST /api/geo/subscribers/bulk-update
{
  "filter": {
    "department_codes": ["75"]
  },
  "action": "add_to_list",
  "list_id": 123
}
```

## 🚀 Scripts de Déploiement

### 1. Déploiement Complet

```bash
# Déploiement en développement
./scripts/deploy-mairies.sh development

# Déploiement en production
./scripts/deploy-mairies.sh production
```

### 2. Mise à Jour et Tests

```bash
# Récupération de la dernière version et mise à jour des conteneurs
./scripts/update-and-test.sh main

# Avec une branche spécifique
./scripts/update-and-test.sh feature/nouvelle-fonctionnalite
```

### 3. Import Manuel des Données

```bash
# Conversion du CSV
python3 scripts/convert-mairielist-csv.py mairielist.csv mairielist-converted.csv

# Import en base
./scripts/import-mairies.sh mairielist-converted.csv
```

## 📈 Fonctionnalités de Ciblage

### Filtres Disponibles

- **Par département** : Codes 01-95, 2A, 2B, 971-978
- **Par région** : Toutes les régions françaises
- **Par population** : Tranches min/max configurables
- **Par nom de commune** : Recherche textuelle
- **Par code postal** : Filtrage par codes postaux

### Statistiques Générées

- Nombre total de communes et d'abonnés
- Répartition par département et région
- Tranches de population avec comptages
- Taux de couverture par zone géographique
- Estimation de la portée des campagnes

## 🔍 Tests et Validation

### Tests Automatiques

Les scripts incluent des vérifications automatiques :
- Connectivité de l'API
- Disponibilité des endpoints
- Intégrité des données importées

### Tests Manuels Recommandés

1. **Interface Web** : http://localhost:9000
   - Connexion et navigation
   - Import CSV via l'interface
   - Création de campagnes ciblées

2. **API REST**
   - Test des endpoints géographiques
   - Validation des filtres de ciblage
   - Vérification des statistiques

3. **Fonctionnalités de Ciblage**
   - Prévisualisation avec différents filtres
   - Création de campagnes ciblées
   - Mise à jour en masse d'abonnés

## 📝 Données Intégrées

Le fichier `mairielist.csv` contient **40 583 mairies** avec :
- Informations de contact (email, téléphone)
- Données géographiques (département, code INSEE, population)
- Coordonnées des responsables
- Adresses postales

## 🛠️ Maintenance

### Rafraîchissement des Statistiques

```sql
-- Manuel
SELECT refresh_targeting_stats();

-- Automatique (optionnel, via trigger)
-- Activé automatiquement lors des modifications d'abonnés
```

### Monitoring

- Logs applicatifs : `docker-compose logs -f app`
- Logs base de données : `docker-compose logs -f db`
- Métriques Redis : Interface Redis Commander

## 🔒 Sécurité et Performance

### Optimisations

- Index composites pour les requêtes de ciblage
- Vue matérialisée pour les statistiques fréquentes
- Pagination des résultats volumineux
- Cache Redis pour les données fréquemment consultées

### Sécurité

- Validation stricte des codes INSEE et départements
- Sanitisation des données CSV importées
- Contrôle d'accès par permissions utilisateur
- Limitation des requêtes API

## 📞 Support

Pour toute question ou problème :
1. Vérifier les logs : `docker-compose logs -f`
2. Consulter la documentation API
3. Tester les endpoints avec curl ou Postman
4. Vérifier l'état des services : `docker-compose ps`

---

**Note** : Cette intégration est maintenant complète et fonctionnelle. Toutes les fonctionnalités de ciblage géographique et de gestion des contacts mairie sont opérationnelles.