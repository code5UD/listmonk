# 🎯 Ciblage Géographique pour Listmonk - Mairies Françaises

## 🚀 Déploiement Automatique

### Installation complète en une commande :

```bash
# Récupérer les dernières mises à jour
git pull origin feature/french-municipalities-targeting

# Déploiement automatique complet
./deploy-complete-geo-targeting.sh
```

### Vérification rapide :

```bash
# Vérifier que tout fonctionne
./verify-geo-targeting.sh
```

## 🎯 Utilisation

### 1. Interface Graphique (Recommandée)

1. **Ouvrez Listmonk** : http://localhost:9000
2. **Allez dans "Abonnés"** (Subscribers)
3. **Cliquez sur le bouton flottant** "🎯 Ciblage Géo" en bas à droite
4. **Configurez vos filtres** :
   - 📍 Sélectionnez les départements (Ctrl+clic pour plusieurs)
   - 👥 Activez le filtre population si besoin
   - ⚡ Ou utilisez les filtres rapides
5. **Cliquez "🎯 Appliquer"** pour filtrer automatiquement

### 2. Filtres Rapides Disponibles

- 🏘️ **Petites communes** : < 2000 habitants
- 🏙️ **Communes moyennes** : 2000-10000 habitants  
- 🏢 **Grandes communes** : > 10000 habitants
- 🏙️ **Métropoles** : > 50000 habitants
- 🏛️ **Île-de-France** : Tous les départements IDF
- 🌊 **PACA** : Tous les départements PACA
- 🏔️ **Auvergne-Rhône-Alpes** : Tous les départements AURA

### 3. Requêtes SQL Manuelles

Si vous préférez utiliser SQL directement :

```sql
-- Mairies de Paris
SELECT * FROM subscribers WHERE department_code = '75';

-- Petites communes rurales
SELECT * FROM subscribers 
WHERE population < 2000 AND population > 0;

-- Île-de-France complète
SELECT * FROM subscribers 
WHERE department_code IN ('75','77','78','91','92','93','94','95');

-- Grandes communes en PACA
SELECT * FROM subscribers 
WHERE department_code IN ('04','05','06','13','83','84') 
AND population > 10000;

-- Statistiques par département
SELECT * FROM subscribers_by_department 
WHERE subscriber_count > 0 
ORDER BY subscriber_count DESC;
```

## 📊 Données Disponibles

### Départements par Région

#### 🏛️ Île-de-France
- 75 - Paris
- 77 - Seine-et-Marne  
- 78 - Yvelines
- 91 - Essonne
- 92 - Hauts-de-Seine
- 93 - Seine-Saint-Denis
- 94 - Val-de-Marne
- 95 - Val-d'Oise

#### 🌊 Provence-Alpes-Côte d'Azur
- 04 - Alpes-de-Haute-Provence
- 05 - Hautes-Alpes
- 06 - Alpes-Maritimes
- 13 - Bouches-du-Rhône
- 83 - Var
- 84 - Vaucluse

#### 🏔️ Auvergne-Rhône-Alpes
- 01 - Ain, 03 - Allier, 07 - Ardèche
- 15 - Cantal, 26 - Drôme, 38 - Isère
- 42 - Loire, 43 - Haute-Loire, 63 - Puy-de-Dôme
- 69 - Rhône, 73 - Savoie, 74 - Haute-Savoie

#### 🌿 Nouvelle-Aquitaine
- 16 - Charente, 17 - Charente-Maritime, 19 - Corrèze
- 23 - Creuse, 24 - Dordogne, 33 - Gironde
- 40 - Landes, 47 - Lot-et-Garonne, 64 - Pyrénées-Atlantiques
- 79 - Deux-Sèvres, 86 - Vienne, 87 - Haute-Vienne

#### 🌞 Occitanie
- 09 - Ariège, 11 - Aude, 12 - Aveyron
- 30 - Gard, 31 - Haute-Garonne, 32 - Gers
- 34 - Hérault, 46 - Lot, 48 - Lozère
- 65 - Hautes-Pyrénées, 66 - Pyrénées-Orientales
- 81 - Tarn, 82 - Tarn-et-Garonne

### Tranches de Population

- **Très petites communes** : < 500 habitants
- **Petites communes** : 500-2000 habitants
- **Communes moyennes** : 2000-10000 habitants
- **Grandes communes** : 10000-50000 habitants
- **Très grandes communes** : > 50000 habitants

## 🔧 Maintenance

### Mise à jour des données géographiques

```bash
./fix-geo-data-extraction.sh
```

### Redéploiement complet

```bash
./deploy-complete-geo-targeting.sh
```

### Vérification du système

```bash
./verify-geo-targeting.sh
```

## 🎯 Cas d'Usage

### 1. Communication Institutionnelle
```sql
-- Grandes métropoles pour annonces importantes
SELECT * FROM subscribers WHERE population > 50000;

-- Petites communes pour aides spécifiques
SELECT * FROM subscribers WHERE population < 2000;
```

### 2. Événements Régionaux
```sql
-- Invitation événement en Île-de-France
SELECT * FROM subscribers 
WHERE department_code IN ('75','77','78','91','92','93','94','95');

-- Réunion départementale
SELECT * FROM subscribers WHERE department_code = '13';
```

### 3. Enquêtes et Sondages
```sql
-- Échantillon représentatif par taille
SELECT * FROM subscribers WHERE population BETWEEN 5000 AND 15000;

-- Comparaison urbain/rural
SELECT * FROM subscribers WHERE population > 20000; -- Urbain
SELECT * FROM subscribers WHERE population < 2000;  -- Rural
```

### 4. Services Personnalisés
```sql
-- Communes touristiques (départements côtiers)
SELECT * FROM subscribers 
WHERE department_code IN ('06','13','83','11','34','66','64','40','33','17','85','44','29','22','35','50','14','76','80','62','59');

-- Communes de montagne
SELECT * FROM subscribers 
WHERE department_code IN ('04','05','06','38','73','74','09','31','65','66','64');
```

## 📞 Support et Dépannage

### Problèmes Courants

#### L'interface n'apparaît pas
1. Vérifiez que vous êtes sur la page "Abonnés"
2. Actualisez la page (F5)
3. Ouvrez la console navigateur (F12) pour voir les erreurs
4. Relancez le déploiement : `./deploy-complete-geo-targeting.sh`

#### Pas de résultats dans les requêtes
1. Vérifiez les données : `./verify-geo-targeting.sh`
2. Corrigez l'extraction : `./fix-geo-data-extraction.sh`
3. Vérifiez la syntaxe SQL

#### Erreurs de base de données
```bash
# Vérifier la connexion
docker exec listmonk_mairies_db psql -U listmonk_mairies -d listmonk_mairies

# Voir les logs
docker logs listmonk_mairies_db
docker logs listmonk_mairies_app
```

### Commandes Utiles

```bash
# Statistiques rapides
docker exec listmonk_mairies_db psql -U listmonk_mairies -d listmonk_mairies -c "
SELECT 
    COUNT(*) as total_subscribers,
    COUNT(department_code) as with_department,
    COUNT(CASE WHEN population > 0 THEN 1 END) as with_population
FROM subscribers;"

# Top 10 départements
docker exec listmonk_mairies_db psql -U listmonk_mairies -d listmonk_mairies -c "
SELECT department_code, COUNT(*) as nb_mairies
FROM subscribers 
WHERE department_code IS NOT NULL
GROUP BY department_code
ORDER BY nb_mairies DESC
LIMIT 10;"

# Redémarrer Listmonk
docker restart listmonk_mairies_app
```

## 🎉 Fonctionnalités

✅ **30 000+ mairies françaises** importées  
✅ **95 départements** avec codes et régions  
✅ **Interface graphique** intuitive  
✅ **Filtres rapides** prédéfinis  
✅ **Ciblage par population** avec min/max  
✅ **Sélection multiple** de départements  
✅ **Génération automatique** de requêtes SQL  
✅ **Application directe** dans Listmonk  
✅ **Statistiques** et vues de données  
✅ **Scripts de maintenance** automatisés  

## 📚 Documentation

- **Guide complet** : `UTILISATION_CIBLAGE_GEO.md`
- **Requêtes d'exemple** : `geo-targeting-queries.sql`
- **Rapport de déploiement** : `RAPPORT_DEPLOIEMENT.md` (généré après déploiement)

---

🇫🇷 **Système de ciblage géographique pour les mairies françaises**  
🎯 **Ciblage précis par département et population**  
🚀 **Interface intuitive et déploiement automatique**