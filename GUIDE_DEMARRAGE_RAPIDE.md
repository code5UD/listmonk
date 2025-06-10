# Guide de Démarrage Rapide - Listmonk avec Mairies Françaises

## 🚀 Démarrage en une commande

Pour démarrer Listmonk avec toutes les données des mairies françaises intégrées automatiquement :

```bash
cd /workspace/listmonk
./start-with-mairies.sh
```

Ce script va :
1. ✅ Vérifier les prérequis
2. ✅ Initialiser la base de données
3. ✅ Démarrer Listmonk
4. ✅ Intégrer automatiquement les 40 000+ mairies françaises
5. ✅ Configurer le ciblage géographique avancé
6. ✅ Créer les listes par défaut

## 📋 Prérequis

- ✅ PostgreSQL en cours d'exécution
- ✅ Fichier `config.toml` configuré
- ✅ Python 3 installé
- ✅ Données des mairies (`mairielist.csv` ou `mairielist-converted.csv`)

## 🌐 Accès à l'interface

Une fois le démarrage terminé :

- **URL** : http://localhost:9000
- **Utilisateur** : admin
- **Mot de passe** : listmonk

## 🎯 Fonctionnalités disponibles

### 1. Import automatique des mairies
- ✅ 40 000+ mairies françaises
- ✅ Données géographiques (département, population)
- ✅ Contacts des mairies
- ✅ Association automatique aux abonnés

### 2. Ciblage géographique simple
- **Par département** : Sélectionner un ou plusieurs départements
- **Par population** : Filtrer par nombre d'habitants
- **Par région** : Cibler des régions entières

### 3. Ciblage avancé avec opérateurs ET/OU
- **Interface graphique** : Constructeur de règles visuel
- **Opérateurs logiques** : ET, OU avec groupes imbriqués
- **Opérateurs de comparaison** : =, ≠, >, ≥, <, ≤, dans, contient
- **Prévisualisation** : Voir le nombre de résultats avant envoi

## 📖 Exemples d'utilisation

### Exemple 1 : Ciblage départemental simple
```
Département = 75 (Paris)
ET
Population >= 10 000
```

### Exemple 2 : Ciblage régional
```
Région = "Île-de-France"
OU
Région = "Provence-Alpes-Côte d'Azur"
```

### Exemple 3 : Ciblage complexe
```
(Département dans [75, 92, 93, 94] ET Population >= 5000)
OU
(Région = "Occitanie" ET Population <= 2000)
```

## 🛠️ Scripts utiles

### Démarrage
```bash
./start-with-mairies.sh          # Démarrage complet automatique
```

### Arrêt
```bash
./stop-listmonk.sh               # Arrêt propre de Listmonk
```

### Tests
```bash
python3 scripts/test-integration.py     # Vérifier l'intégration
python3 scripts/test-advanced-targeting.py  # Tester le ciblage avancé
```

### Conversion de données
```bash
python3 scripts/convert-mairielist-csv.py   # Convertir le fichier CSV
```

## 📊 Interface de ciblage

### Navigation
1. **Connexion** → http://localhost:9000
2. **Menu** → Mairies
3. **Sous-menu** → Ciblage géographique

### Utilisation du ciblage simple
1. Sélectionner les départements
2. Définir la plage de population
3. Cliquer sur "Rechercher"
4. Voir les résultats sur la carte et dans la liste

### Utilisation du ciblage avancé
1. Aller dans l'onglet "Ciblage avancé"
2. Ajouter des règles avec le bouton "+"
3. Choisir les champs, opérateurs et valeurs
4. Sélectionner ET/OU entre les règles
5. Prévisualiser les résultats
6. Appliquer le ciblage

## 🎨 Création de campagnes

### Campagne simple
1. **Abonnés** → Créer une campagne
2. Sélectionner la liste "Mairies de France"
3. Rédiger le contenu
4. Envoyer

### Campagne ciblée
1. **Mairies** → Ciblage géographique
2. Définir les critères de ciblage
3. Cliquer sur "Créer une campagne avec cette sélection"
4. Rédiger le contenu
5. Envoyer

## 🔧 Dépannage

### Listmonk ne démarre pas
```bash
# Vérifier les logs
tail -f listmonk.log

# Vérifier la configuration
cat config.toml

# Vérifier PostgreSQL
sudo systemctl status postgresql
```

### Données non importées
```bash
# Vérifier le fichier CSV
head -5 mairielist-converted.csv

# Reconvertir les données
python3 scripts/convert-mairielist-csv.py

# Relancer l'import
python3 scripts/init-mairies-integration.py
```

### Ciblage ne fonctionne pas
```bash
# Tester l'API
curl http://localhost:9000/api/geo/stats

# Vérifier les tables
python3 scripts/test-integration.py
```

## 📚 Documentation complète

- **`CIBLAGE_AVANCE_DOCUMENTATION.md`** : Documentation technique du ciblage
- **`IMPLEMENTATION_CIBLAGE_AVANCE.md`** : Détails de l'implémentation
- **`SOLUTION_IMPORT_CSV.md`** : Solution pour l'import CSV

## 🆘 Support

### Logs importants
- `listmonk.log` : Logs de l'application
- `config.toml` : Configuration
- `listmonk.pid` : PID du processus

### Commandes de diagnostic
```bash
# Statut de Listmonk
curl http://localhost:9000/api/health

# Statistiques des mairies
curl -u admin:listmonk http://localhost:9000/api/geo/stats

# Nombre d'abonnés
curl -u admin:listmonk http://localhost:9000/api/subscribers?per_page=1
```

## 🎉 Prochaines étapes

1. **Explorez l'interface** : Familiarisez-vous avec les menus
2. **Testez le ciblage** : Essayez différents critères
3. **Créez une campagne test** : Envoyez à quelques mairies
4. **Personnalisez les templates** : Adaptez les modèles d'email
5. **Configurez les listes** : Organisez vos contacts

---

**🇫🇷 Listmonk est maintenant prêt pour vos campagnes de communication territoriale !**