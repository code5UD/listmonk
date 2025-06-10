# 🎯 Guide du Ciblage Géographique - Listmonk Mairies

## 🚀 Déploiement

```bash
# Déployer les fonctionnalités de ciblage
./deploy-geo-targeting.sh
```

## 📊 Fonctionnalités disponibles

### 1. **Ciblage par Département**
Sélectionnez les mairies d'un ou plusieurs départements français.

### 2. **Ciblage par Population**
Filtrez les communes selon leur nombre d'habitants.

### 3. **Ciblage par Région**
Ciblez toutes les communes d'une région française.

### 4. **Ciblage Combiné**
Combinez département + population pour un ciblage précis.

## 🎯 Utilisation dans Listmonk

### Via l'interface web

1. **Allez dans "Subscribers"**
2. **Cliquez sur "Advanced"** ou "Recherche SQL"
3. **Utilisez les requêtes SQL** ci-dessous

### Exemples de requêtes SQL

#### 🗺️ **Par Département**
```sql
-- Toutes les mairies de Paris (75)
SELECT * FROM subscribers WHERE department_code = '75';

-- Mairies d'Île-de-France
SELECT * FROM subscribers 
WHERE department_code IN ('75', '77', '78', '91', '92', '93', '94', '95');
```

#### 👥 **Par Population**
```sql
-- Petites communes (moins de 1000 habitants)
SELECT * FROM subscribers WHERE population < 1000;

-- Communes moyennes (1000 à 10000 habitants)
SELECT * FROM subscribers WHERE population BETWEEN 1000 AND 10000;

-- Grandes communes (plus de 10000 habitants)
SELECT * FROM subscribers WHERE population > 10000;
```

#### 🌍 **Par Région**
```sql
-- Toutes les mairies d'Auvergne-Rhône-Alpes
SELECT s.* FROM subscribers s
JOIN departments d ON s.department_code = d.code
WHERE d.region = 'Auvergne-Rhône-Alpes';
```

#### 🎯 **Ciblage Combiné**
```sql
-- Grandes communes (> 5000 hab.) en Nouvelle-Aquitaine
SELECT s.*, d.name as department_name FROM subscribers s
JOIN departments d ON s.department_code = d.code
WHERE d.region = 'Nouvelle-Aquitaine' 
AND s.population > 5000
ORDER BY s.population DESC;
```

## 📋 Listes Prédéfinies

Le script crée automatiquement des listes pour :
- ✅ Mairies Paris (75)
- ✅ Mairies Bouches-du-Rhône (13)
- ✅ Mairies Rhône (69)
- ✅ Mairies Nord (59)
- ✅ Mairies Hauts-de-Seine (92)

## 🔧 Requêtes Avancées

### Statistiques par département
```sql
SELECT * FROM subscribers_by_department;
```

### Statistiques par population
```sql
SELECT * FROM subscribers_by_population;
```

### Top 10 des départements avec le plus de mairies
```sql
SELECT department_code, COUNT(*) as nb_mairies
FROM subscribers 
WHERE department_code IS NOT NULL
GROUP BY department_code
ORDER BY nb_mairies DESC
LIMIT 10;
```

## 🎨 Création de Campagnes Ciblées

### 1. **Créer une nouvelle campagne**
- Nom : "Campagne Île-de-France"
- Objet : "Message pour les mairies franciliennes"

### 2. **Sélectionner les destinataires**
- Utilisez une requête SQL pour cibler
- Ou sélectionnez une liste prédéfinie

### 3. **Exemples de ciblage**

#### Campagne "Petites Communes Rurales"
```sql
SELECT * FROM subscribers 
WHERE population < 2000 
AND department_code NOT IN ('75', '92', '93', '94');
```

#### Campagne "Grandes Métropoles"
```sql
SELECT * FROM subscribers 
WHERE population > 50000;
```

#### Campagne "Région PACA"
```sql
SELECT s.* FROM subscribers s
JOIN departments d ON s.department_code = d.code
WHERE d.region = 'Provence-Alpes-Côte d''Azur';
```

## 📊 Données Disponibles

### Champs des abonnés enrichis :
- `department_code` : Code département (ex: "75")
- `commune_code` : Code INSEE de la commune
- `population` : Nombre d'habitants
- `attribs` : Données complètes (nom commune, etc.)

### Tables créées :
- `departments` : Liste des départements français
- `communes` : Données détaillées des communes
- `subscribers_by_department` : Vue statistiques par département
- `subscribers_by_population` : Vue statistiques par population

## 🚀 Cas d'Usage

### 1. **Communication Institutionnelle**
- Cibler les grandes communes pour les annonces importantes
- Informer les petites communes sur les aides spécifiques

### 2. **Événements Régionaux**
- Inviter les mairies d'une région à un événement
- Organiser des réunions départementales

### 3. **Enquêtes et Sondages**
- Sonder les communes selon leur taille
- Études comparatives par région

### 4. **Services Personnalisés**
- Proposer des services adaptés à la taille des communes
- Offres spécifiques par département

## 🔍 Dépannage

### Si les requêtes ne fonctionnent pas :
1. Vérifiez que le script de déploiement a été exécuté
2. Vérifiez la connexion à la base de données
3. Consultez les logs : `docker logs listmonk_mairies_db`

### Pour vérifier les données :
```sql
-- Vérifier les départements
SELECT COUNT(*) FROM departments;

-- Vérifier les abonnés avec données géo
SELECT COUNT(*) FROM subscribers WHERE department_code IS NOT NULL;
```

## 📞 Support

Pour toute question sur le ciblage géographique :
1. Consultez le fichier `geo-targeting-queries.sql`
2. Vérifiez les logs des conteneurs Docker
3. Testez les requêtes dans l'interface SQL de Listmonk