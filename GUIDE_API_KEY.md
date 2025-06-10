# 🔑 Guide d'utilisation avec clé API

## Vos identifiants

- **Login** : api
- **Clé API** : `RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o`

## 🚀 Intégration rapide

```bash
# 1. Tester la clé API
./test-api-key.sh

# 2. Intégrer les mairies avec la clé API
./docker-integration-mairies-api-key.sh
```

## 🔧 Utilisation manuelle de l'API

### Lister les abonnés
```bash
curl -H "Authorization: Bearer RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o" \
     http://localhost:9000/api/subscribers?per_page=10
```

### Importer un CSV
```bash
curl -H "Authorization: Bearer RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o" \
     -X POST \
     -F "file=@mairielist-converted.csv" \
     -F "mode=subscribe" \
     -F "delim=," \
     http://localhost:9000/api/import/subscribers
```

### Vérifier le statut d'import
```bash
curl -H "Authorization: Bearer RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o" \
     http://localhost:9000/api/import/subscribers
```

## 📋 Scripts disponibles

| Script | Description |
|--------|-------------|
| `test-api-key.sh` | Test de la clé API |
| `docker-integration-mairies-api-key.sh` | Intégration complète |
| `debug-listmonk-api.sh` | Debug général |

## 🎯 Ordre d'exécution recommandé

```bash
# 1. Récupérer les dernières modifications
git pull origin feature/french-municipalities-targeting

# 2. Tester la clé API
./test-api-key.sh

# 3. Si le test réussit, lancer l'intégration
./docker-integration-mairies-api-key.sh
```

## 🔍 Dépannage

### Si la clé API ne fonctionne pas
1. Vérifiez que Listmonk est accessible : `curl http://localhost:9000/api/health`
2. Vérifiez les logs du conteneur : `docker logs listmonk_mairies_app`
3. Vérifiez la configuration : `docker exec listmonk_mairies_app cat /listmonk/config.toml`

### Si l'import échoue
1. Vérifiez le format du CSV : `head -5 mairielist-converted.csv`
2. Reconvertissez le CSV : `python3 scripts/fix-and-convert-csv.py`
3. Vérifiez l'espace disque : `df -h`

## ✅ Résultat attendu

Après l'exécution réussie :
- 40 000+ mairies françaises importées
- Interface accessible sur http://localhost:9000
- Données prêtes pour les campagnes