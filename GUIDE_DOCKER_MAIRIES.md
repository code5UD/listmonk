# Guide Docker - Intégration des Mairies Françaises

## 🐳 Pour votre déploiement Docker existant

Vous avez déjà Listmonk qui fonctionne avec Docker. Voici comment intégrer les mairies françaises.

## 🚀 Intégration en une commande

```bash
./docker-integration-mairies.sh
```

## 📋 Prérequis

Votre environnement Docker actuel :
- ✅ `listmonk_mairies_app` - Conteneur Listmonk principal
- ✅ `listmonk_mairies_db` - Base de données PostgreSQL
- ✅ `listmonk_mairies_redis` - Cache Redis
- ✅ Ports : 9000 (interface) et 12000 (backup)

## 🔧 Ce que fait le script

1. **Vérifie l'environnement Docker** - S'assure que vos conteneurs fonctionnent
2. **Prépare le CSV** - Nettoie et convertit le fichier des mairies
3. **Copie dans le conteneur** - Transfère le fichier dans Listmonk
4. **Importe via l'API** - Utilise l'API Listmonk pour l'import
5. **Vérifie l'intégration** - Confirme que tout fonctionne

## 📁 Structure de votre projet

```
~/listmonk/
├── docker-compose.yml          # Votre configuration Docker
├── mairielist.csv              # Fichier source des mairies
├── docker-integration-mairies.sh  # Script d'intégration
├── scripts/
│   └── fix-and-convert-csv.py  # Conversion CSV
└── mairielist-converted.csv    # Fichier converti (généré)
```

## 🌐 Accès après intégration

- **Interface web** : http://localhost:9000
- **Interface backup** : http://localhost:12000
- **Utilisateur** : admin
- **Mot de passe** : listmonk

## 📊 Vérification manuelle

### 1. Vérifier les conteneurs
```bash
docker ps
```

### 2. Voir les logs Listmonk
```bash
docker logs listmonk_mairies_app
```

### 3. Accéder au conteneur
```bash
docker exec -it listmonk_mairies_app /bin/sh
```

### 4. Vérifier la base de données
```bash
docker exec -it listmonk_mairies_db psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers;"
```

## 🔄 Gestion des données

### Réimporter les mairies
```bash
# Si vous voulez réimporter
./docker-integration-mairies.sh
```

### Sauvegarder la base de données
```bash
docker exec listmonk_mairies_db pg_dump -U listmonk listmonk > backup_mairies.sql
```

### Restaurer la base de données
```bash
docker exec -i listmonk_mairies_db psql -U listmonk listmonk < backup_mairies.sql
```

## 🎯 Utilisation du ciblage

### Interface web
1. Connectez-vous sur http://localhost:9000
2. Allez dans **Abonnés** pour voir les mairies
3. Créez des **Listes** pour organiser
4. Lancez des **Campagnes** ciblées

### API pour ciblage avancé
```bash
# Tester l'API de ciblage
curl -u admin:listmonk http://localhost:9000/api/subscribers?per_page=5
```

## 🆘 Dépannage

### Problème : Conteneur unhealthy
```bash
# Redémarrer le conteneur
docker restart listmonk_mairies_app

# Vérifier les logs
docker logs --tail 50 listmonk_mairies_app
```

### Problème : Import échoue
```bash
# Vérifier le fichier CSV
head -5 mairielist-converted.csv

# Reconvertir le CSV
python3 scripts/fix-and-convert-csv.py
```

### Problème : Accès refusé
```bash
# Vérifier les ports
docker port listmonk_mairies_app

# Vérifier la configuration
docker exec listmonk_mairies_app cat /listmonk/config.toml
```

## 📈 Optimisation Docker

### Augmenter la mémoire (si nécessaire)
```yaml
# Dans docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### Optimiser PostgreSQL
```yaml
# Dans docker-compose.yml
services:
  db:
    environment:
      - POSTGRES_SHARED_PRELOAD_LIBRARIES=pg_stat_statements
      - POSTGRES_MAX_CONNECTIONS=200
```

## 🔐 Sécurité

### Changer les mots de passe par défaut
```bash
# Accéder au conteneur
docker exec -it listmonk_mairies_app /bin/sh

# Modifier la configuration
vi /listmonk/config.toml
```

### Limiter l'accès réseau
```yaml
# Dans docker-compose.yml
services:
  app:
    ports:
      - "127.0.0.1:9000:9000"  # Seulement localhost
```

## 🚀 Mise en production

### 1. Utiliser un reverse proxy
```nginx
# Configuration Nginx
server {
    listen 80;
    server_name votre-domaine.com;
    
    location / {
        proxy_pass http://localhost:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 2. Configurer HTTPS
```bash
# Avec Let's Encrypt
certbot --nginx -d votre-domaine.com
```

### 3. Sauvegardes automatiques
```bash
# Crontab pour sauvegardes quotidiennes
0 2 * * * docker exec listmonk_mairies_db pg_dump -U listmonk listmonk | gzip > /backup/listmonk_$(date +\%Y\%m\%d).sql.gz
```

## 📚 Ressources

- **Documentation Listmonk** : https://listmonk.app/docs/
- **Docker Compose** : https://docs.docker.com/compose/
- **PostgreSQL Docker** : https://hub.docker.com/_/postgres

## 🎉 Résultat attendu

Après l'exécution du script :
- ✅ 40 000+ mairies françaises importées
- ✅ Interface web accessible
- ✅ Système de campagnes opérationnel
- ✅ Ciblage géographique disponible
- ✅ Environnement Docker stable

**Votre Listmonk Docker est maintenant prêt pour les campagnes de communication territoriale !** 🇫🇷