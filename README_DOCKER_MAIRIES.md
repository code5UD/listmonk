# 🇫🇷 Listmonk Docker - Mairies Françaises

## 🎯 Solution complète pour votre déploiement Docker

Vous avez déjà Listmonk qui fonctionne avec Docker. Cette solution ajoute l'intégration automatique des 40 000+ mairies françaises avec ciblage géographique avancé.

## 🚀 Démarrage rapide

### 1. Diagnostic de votre environnement
```bash
./docker-diagnostic.sh
```

### 2. Intégration des mairies
```bash
./docker-integration-mairies.sh
```

### 3. Accès à l'interface
- **Principal** : http://localhost:9000
- **Backup** : http://localhost:12000
- **Utilisateur** : admin
- **Mot de passe** : listmonk

## 📋 Votre environnement Docker

```
CONTAINER ID   IMAGE                           STATUS                      PORTS
1420d1c7e45e   listmonk_app                    Up 53 minutes (unhealthy)   0.0.0.0:9000->9000/tcp, 0.0.0.0:12000->9000/tcp
e889807940da   redis:7-alpine                  Up 54 minutes (healthy)     127.0.0.1:6380->6379/tcp
b13dc0ec7c59   postgis/postgis:17-3.5-alpine   Up 54 minutes (healthy)     127.0.0.1:5433->5432/tcp
```

## 🔧 Scripts disponibles

| Script | Description |
|--------|-------------|
| `docker-diagnostic.sh` | Diagnostic complet de l'environnement |
| `docker-integration-mairies.sh` | Intégration automatique des mairies |
| `scripts/fix-and-convert-csv.py` | Conversion du fichier CSV |

## 📁 Structure des fichiers

```
~/listmonk/
├── docker-compose.yml                 # Votre configuration Docker
├── mairielist.csv                     # Fichier source (à placer ici)
├── docker-integration-mairies.sh      # Script d'intégration
├── docker-diagnostic.sh               # Script de diagnostic
├── scripts/
│   └── fix-and-convert-csv.py         # Conversion CSV
└── docs/
    ├── GUIDE_DOCKER_MAIRIES.md        # Guide détaillé
    └── README_DOCKER_MAIRIES.md       # Ce fichier
```

## 🎯 Fonctionnalités

### ✅ Import automatique
- 40 583 mairies françaises
- Validation des données
- Nettoyage automatique du CSV
- Import via API Listmonk

### ✅ Ciblage géographique
- Par département (01, 02, 75, etc.)
- Par nombre d'habitants
- Par région
- Interface graphique

### ✅ Gestion des campagnes
- Création de listes ciblées
- Templates personnalisables
- Statistiques détaillées
- Gestion des désabonnements

## 🆘 Résolution de problèmes

### Conteneur "unhealthy"
```bash
# Diagnostic
./docker-diagnostic.sh

# Redémarrer
docker restart listmonk_mairies_app

# Voir les logs
docker logs --tail 50 listmonk_mairies_app
```

### Import des mairies échoue
```bash
# Vérifier le fichier CSV
head -5 mairielist.csv

# Reconvertir
python3 scripts/fix-and-convert-csv.py

# Relancer l'intégration
./docker-integration-mairies.sh
```

### Interface non accessible
```bash
# Vérifier les ports
docker port listmonk_mairies_app

# Tester la connectivité
curl http://localhost:9000/api/health
```

## 📊 Vérification manuelle

### Compter les abonnés
```bash
docker exec listmonk_mairies_db psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers;"
```

### Voir les derniers abonnés
```bash
docker exec listmonk_mairies_db psql -U listmonk -d listmonk -c "SELECT email, name FROM subscribers ORDER BY created_at DESC LIMIT 5;"
```

### Statistiques par département
```bash
# Via l'API
curl -u admin:listmonk http://localhost:9000/api/geo/stats
```

## 🔐 Sécurité

### Changer le mot de passe admin
1. Connectez-vous à http://localhost:9000
2. Allez dans **Paramètres** > **Utilisateurs**
3. Modifiez le mot de passe

### Limiter l'accès réseau
```yaml
# Dans docker-compose.yml
services:
  app:
    ports:
      - "127.0.0.1:9000:9000"  # Seulement localhost
```

## 📈 Optimisation

### Augmenter les performances
```yaml
# Dans docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
```

### Optimiser PostgreSQL
```yaml
services:
  db:
    environment:
      - POSTGRES_SHARED_PRELOAD_LIBRARIES=pg_stat_statements
      - POSTGRES_MAX_CONNECTIONS=200
```

## 💾 Sauvegardes

### Sauvegarde automatique
```bash
# Ajouter au crontab
0 2 * * * docker exec listmonk_mairies_db pg_dump -U listmonk listmonk | gzip > /backup/listmonk_$(date +\%Y\%m\%d).sql.gz
```

### Sauvegarde manuelle
```bash
docker exec listmonk_mairies_db pg_dump -U listmonk listmonk > backup_mairies.sql
```

### Restauration
```bash
docker exec -i listmonk_mairies_db psql -U listmonk listmonk < backup_mairies.sql
```

## 🌐 Mise en production

### Reverse proxy Nginx
```nginx
server {
    listen 80;
    server_name votre-domaine.com;
    
    location / {
        proxy_pass http://localhost:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### HTTPS avec Let's Encrypt
```bash
certbot --nginx -d votre-domaine.com
```

## 📚 Documentation

- **[Guide Docker détaillé](GUIDE_DOCKER_MAIRIES.md)** - Instructions complètes
- **[Documentation Listmonk](https://listmonk.app/docs/)** - Documentation officielle
- **[Ciblage avancé](CIBLAGE_AVANCE_DOCUMENTATION.md)** - Fonctionnalités avancées

## 🎉 Résultat attendu

Après l'intégration :
- ✅ 40 000+ mairies françaises dans Listmonk
- ✅ Interface web opérationnelle
- ✅ Ciblage géographique fonctionnel
- ✅ Système de campagnes prêt
- ✅ Environnement Docker stable

## 🆘 Support

### Commandes de diagnostic
```bash
./docker-diagnostic.sh              # Diagnostic complet
docker logs listmonk_mairies_app    # Logs de l'application
docker stats                        # Utilisation des ressources
```

### Informations système
```bash
docker ps                           # État des conteneurs
docker images                       # Images disponibles
docker volume ls                    # Volumes Docker
```

---

**🇫🇷 Votre Listmonk Docker est maintenant prêt pour la communication territoriale !**