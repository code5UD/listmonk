# Commandes Finales pour Récupérer et Tester le Projet

## 🚀 Commandes pour Récupérer la Dernière Version

### 1. Récupération du Code depuis GitHub

```bash
# Cloner le repository (si pas encore fait)
git clone https://github.com/code5UD/listmonk.git
cd listmonk

# Ou mettre à jour un repository existant
git fetch origin
git checkout main  # ou la branche souhaitée
git pull origin main
```

### 2. Récupération du Fichier CSV des Mairies

```bash
# Le fichier est déjà dans le repository, mais vous pouvez le re-télécharger si nécessaire
curl -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3.raw" \
     -o mairielist.csv \
     https://api.github.com/repos/code5UD/listmonk/contents/mairielist.csv?ref=feature/french-municipalities-targeting
```

## 🔧 Commandes de Déploiement et Test

### 3. Déploiement Automatique Complet

```bash
# Déploiement en développement (recommandé pour les tests)
./scripts/deploy-mairies.sh development

# Ou déploiement en production
./scripts/deploy-mairies.sh production
```

### 4. Mise à Jour et Test (Script Tout-en-Un)

```bash
# Récupère la dernière version, reconstruit et teste
./scripts/update-and-test.sh main

# Avec une branche spécifique
./scripts/update-and-test.sh feature/nouvelle-fonctionnalite
```

### 5. Validation de l'Intégration

```bash
# Vérifie que tout est correctement installé et configuré
./scripts/validate-integration.sh
```

## 📊 Commandes de Test Manuel

### 6. Tests des API Endpoints

```bash
# Test de santé de l'API
curl http://localhost:9000/api/health

# Liste des départements
curl http://localhost:9000/api/geo/departments

# Communes avec filtres
curl "http://localhost:9000/api/geo/communes?department_codes=75,92&population_min=1000"

# Statistiques générales
curl http://localhost:9000/api/geo/stats

# Prévisualisation de ciblage
curl -X POST http://localhost:9000/api/geo/targeting/preview \
     -H "Content-Type: application/json" \
     -d '{
       "department_codes": ["75", "92"],
       "population_min": 1000,
       "population_max": 50000
     }'

# Comptage de destinataires
curl -X POST http://localhost:9000/api/geo/targeting/count \
     -H "Content-Type: application/json" \
     -d '{
       "department_codes": ["75"],
       "population_min": 5000
     }'
```

### 7. Import Manuel des Données

```bash
# Conversion du CSV (si nécessaire)
python3 scripts/convert-mairielist-csv.py mairielist.csv mairielist-converted.csv

# Import en base de données
./scripts/import-mairies.sh mairielist-converted.csv

# Ou avec une chaîne de connexion personnalisée
go run scripts/import-mairies.go mairielist-converted.csv "postgres://user:pass@localhost:5432/dbname?sslmode=disable"
```

## 🐳 Commandes Docker

### 8. Gestion des Conteneurs

```bash
# Démarrer tous les services
docker-compose -f docker-compose.mairies.yml up -d

# Voir l'état des services
docker-compose -f docker-compose.mairies.yml ps

# Voir les logs
docker-compose -f docker-compose.mairies.yml logs -f

# Redémarrer un service spécifique
docker-compose -f docker-compose.mairies.yml restart app

# Arrêter tous les services
docker-compose -f docker-compose.mairies.yml down

# Reconstruction complète (en cas de problème)
docker-compose -f docker-compose.mairies.yml down --rmi local
docker-compose -f docker-compose.mairies.yml build --no-cache
docker-compose -f docker-compose.mairies.yml up -d
```

### 9. Accès aux Services

```bash
# Application principale
open http://localhost:9000

# Adminer (interface base de données)
open http://localhost:8080

# Redis Commander (interface Redis)
open http://localhost:8081
```

## 🔍 Commandes de Diagnostic

### 10. Vérification de l'État du Système

```bash
# Vérifier que les ports sont ouverts
netstat -tlnp | grep -E ':(9000|8080|8081|5432|6379)'

# Tester la connectivité de la base de données
docker-compose -f docker-compose.mairies.yml exec db psql -U listmonk_mairies -d listmonk_mairies -c "SELECT COUNT(*) FROM french_communes;"

# Vérifier les données importées
docker-compose -f docker-compose.mairies.yml exec db psql -U listmonk_mairies -d listmonk_mairies -c "SELECT department_code, COUNT(*) FROM french_communes GROUP BY department_code ORDER BY department_code LIMIT 10;"

# Tester Redis
docker-compose -f docker-compose.mairies.yml exec redis redis-cli ping
```

### 11. Logs et Debugging

```bash
# Logs détaillés de l'application
docker-compose -f docker-compose.mairies.yml logs -f app

# Logs de la base de données
docker-compose -f docker-compose.mairies.yml logs -f db

# Logs de Redis
docker-compose -f docker-compose.mairies.yml logs -f redis

# Entrer dans le conteneur de l'application
docker-compose -f docker-compose.mairies.yml exec app /bin/sh

# Entrer dans la base de données
docker-compose -f docker-compose.mairies.yml exec db psql -U listmonk_mairies -d listmonk_mairies
```

## 📈 Tests de Performance

### 12. Tests de Charge (Optionnel)

```bash
# Test de charge simple avec curl
for i in {1..100}; do
  curl -s http://localhost:9000/api/geo/departments > /dev/null &
done
wait

# Test avec Apache Bench (si installé)
ab -n 1000 -c 10 http://localhost:9000/api/geo/departments

# Test avec wrk (si installé)
wrk -t12 -c400 -d30s http://localhost:9000/api/geo/departments
```

## 🔄 Commandes de Maintenance

### 13. Sauvegarde et Restauration

```bash
# Sauvegarde de la base de données
docker-compose -f docker-compose.mairies.yml exec db pg_dump -U listmonk_mairies listmonk_mairies > backup_$(date +%Y%m%d_%H%M%S).sql

# Restauration de la base de données
docker-compose -f docker-compose.mairies.yml exec -T db psql -U listmonk_mairies -d listmonk_mairies < backup_file.sql

# Rafraîchissement des statistiques
docker-compose -f docker-compose.mairies.yml exec db psql -U listmonk_mairies -d listmonk_mairies -c "SELECT refresh_targeting_stats();"
```

## 🎯 Séquence Recommandée pour les Tests

### 14. Procédure de Test Complète

```bash
# 1. Récupération et déploiement
git pull origin main
./scripts/update-and-test.sh main

# 2. Validation
./scripts/validate-integration.sh

# 3. Tests API
curl http://localhost:9000/api/health
curl http://localhost:9000/api/geo/departments

# 4. Test de l'interface web
open http://localhost:9000

# 5. Vérification des données
docker-compose -f docker-compose.mairies.yml exec db psql -U listmonk_mairies -d listmonk_mairies -c "SELECT COUNT(*) FROM french_communes;"

# 6. Test de ciblage
curl -X POST http://localhost:9000/api/geo/targeting/preview \
     -H "Content-Type: application/json" \
     -d '{"department_codes": ["75"], "population_min": 1000}'
```

---

## 📞 En Cas de Problème

Si vous rencontrez des problèmes :

1. **Vérifiez les logs** : `docker-compose -f docker-compose.mairies.yml logs -f`
2. **Redémarrez les services** : `docker-compose -f docker-compose.mairies.yml restart`
3. **Validez l'intégration** : `./scripts/validate-integration.sh`
4. **Reconstruction complète** : Voir section 8 ci-dessus

L'intégration est maintenant complète et toutes les fonctionnalités de gestion des contacts mairie et de ciblage géographique sont opérationnelles ! 🎉