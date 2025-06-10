# Documentation du Ciblage Avancé avec Opérateurs ET/OU

## Vue d'ensemble

Le système de ciblage avancé de Listmonk permet maintenant de créer des filtres complexes avec des opérateurs ET/OU pour cibler précisément les mairies par département et nombre d'habitants.

## Fonctionnalités

### ✅ Opérateurs logiques
- **ET (AND)** : Toutes les conditions doivent être vraies
- **OU (OR)** : Au moins une condition doit être vraie

### ✅ Champs de filtrage
- **Département** : Code département (01, 02, 75, etc.)
- **Population** : Nombre d'habitants
- **Région** : Nom de la région
- **Nom de commune** : Nom de la ville/commune
- **Code postal** : Code postal

### ✅ Opérateurs de comparaison
- **Égal** (`eq`) : Valeur exacte
- **Différent** (`ne`) : Valeur différente
- **Supérieur** (`gt`) : Plus grand que
- **Supérieur ou égal** (`gte`) : Plus grand ou égal
- **Inférieur** (`lt`) : Plus petit que
- **Inférieur ou égal** (`lte`) : Plus petit ou égal
- **Dans la liste** (`in`) : Valeur dans une liste
- **Pas dans la liste** (`not_in`) : Valeur pas dans une liste
- **Contient** (`contains`) : Texte contient
- **Ne contient pas** (`not_contains`) : Texte ne contient pas
- **Entre** (`between`) : Valeur dans une plage

## Structure des filtres

### Format JSON

```json
{
  "advanced_filters": {
    "operator": "AND|OR",
    "rules": [
      {
        "field": "department|population|region|commune_name|postal_code",
        "operator": "eq|ne|gt|gte|lt|lte|in|not_in|contains|not_contains|between",
        "value": "valeur ou objet"
      }
    ],
    "groups": [
      {
        "operator": "AND|OR",
        "rules": [...],
        "groups": [...]
      }
    ]
  }
}
```

## Exemples d'utilisation

### 1. Ciblage simple avec ET

**Objectif** : Départements 75 ET population > 10 000

```json
{
  "advanced_filters": {
    "operator": "AND",
    "rules": [
      {
        "field": "department",
        "operator": "eq",
        "value": "75"
      },
      {
        "field": "population",
        "operator": "gt",
        "value": 10000
      }
    ]
  }
}
```

### 2. Ciblage avec OU

**Objectif** : Département 75 OU département 92

```json
{
  "advanced_filters": {
    "operator": "OR",
    "rules": [
      {
        "field": "department",
        "operator": "eq",
        "value": "75"
      },
      {
        "field": "department",
        "operator": "eq",
        "value": "92"
      }
    ]
  }
}
```

### 3. Plage de population

**Objectif** : Population entre 5 000 et 50 000 habitants

```json
{
  "advanced_filters": {
    "operator": "AND",
    "rules": [
      {
        "field": "population",
        "operator": "between",
        "value": {
          "min": 5000,
          "max": 50000
        }
      }
    ]
  }
}
```

### 4. Liste de départements

**Objectif** : Départements d'Île-de-France ET population > 20 000

```json
{
  "advanced_filters": {
    "operator": "AND",
    "rules": [
      {
        "field": "department",
        "operator": "in",
        "value": ["75", "92", "93", "94", "95", "77", "78", "91"]
      },
      {
        "field": "population",
        "operator": "gt",
        "value": 20000
      }
    ]
  }
}
```

### 5. Filtrage par région et exclusion

**Objectif** : Région PACA MAIS PAS les départements 06 et 83

```json
{
  "advanced_filters": {
    "operator": "AND",
    "rules": [
      {
        "field": "region",
        "operator": "eq",
        "value": "Provence-Alpes-Côte d'Azur"
      },
      {
        "field": "department",
        "operator": "not_in",
        "value": ["06", "83"]
      }
    ]
  }
}
```

### 6. Filtrage complexe avec groupes

**Objectif** : (Département 75 OU 92) ET (Population > 10 000 OU Commune contient "Paris")

```json
{
  "advanced_filters": {
    "operator": "AND",
    "rules": [],
    "groups": [
      {
        "operator": "OR",
        "rules": [
          {
            "field": "department",
            "operator": "eq",
            "value": "75"
          },
          {
            "field": "department",
            "operator": "eq",
            "value": "92"
          }
        ]
      },
      {
        "operator": "OR",
        "rules": [
          {
            "field": "population",
            "operator": "gt",
            "value": 10000
          },
          {
            "field": "commune_name",
            "operator": "contains",
            "value": "Paris"
          }
        ]
      }
    ]
  }
}
```

## API Endpoints

### 1. Prévisualisation du ciblage

```http
POST /api/geo/targeting/advanced/preview
Content-Type: application/json

{
  "filter": {
    "advanced_filters": { ... }
  }
}
```

**Réponse** :
```json
{
  "data": {
    "count": 150,
    "total_count": 150,
    "population_total": 2500000,
    "sample_communes": [...],
    "statistics": {
      "total_communes": 150,
      "total_subscribers": 150,
      "by_department": {...},
      "by_region": {...}
    }
  }
}
```

### 2. Application du ciblage

```http
POST /api/geo/targeting/advanced
Content-Type: application/json

{
  "filter": {
    "advanced_filters": { ... }
  },
  "limit": 1000,
  "offset": 0
}
```

**Réponse** :
```json
{
  "data": {
    "subscribers": [...],
    "statistics": {...},
    "total_count": 150,
    "filter": {...}
  }
}
```

## Interface utilisateur

### Composant Vue.js

Le composant `AdvancedTargeting.vue` fournit une interface graphique pour :

1. **Constructeur de règles** : Ajouter/supprimer des règles de filtrage
2. **Sélection d'opérateurs** : Choisir ET/OU pour chaque groupe
3. **Prévisualisation** : Voir le nombre de résultats avant application
4. **Export** : Télécharger les résultats en CSV

### Utilisation dans une vue

```vue
<template>
  <div>
    <AdvancedTargeting 
      @preview="onPreview"
      @apply="onApply"
      :show-sql-preview="true"
    />
  </div>
</template>

<script>
import AdvancedTargeting from '@/components/AdvancedTargeting.vue';

export default {
  components: {
    AdvancedTargeting,
  },
  
  methods: {
    onPreview(results) {
      console.log('Prévisualisation:', results);
    },
    
    onApply(results) {
      console.log('Ciblage appliqué:', results);
      // Créer une campagne avec ces résultats
    },
  },
};
</script>
```

## Compatibilité

### Ancien système

Le nouveau système est **100% compatible** avec l'ancien format :

```json
{
  "department_codes": ["75", "92"],
  "population_min": 10000,
  "population_max": 100000,
  "regions": ["Île-de-France"]
}
```

### Migration automatique

Les anciens filtres sont automatiquement convertis en filtres avancés avec l'opérateur ET.

## Performance

### Optimisations

1. **Index de base de données** sur les champs de filtrage
2. **Query builder optimisé** pour générer des requêtes SQL efficaces
3. **Mise en cache** des résultats de prévisualisation
4. **Pagination** pour les gros volumes de données

### Limites recommandées

- **Prévisualisation** : Maximum 10 000 résultats
- **Export** : Maximum 50 000 résultats
- **Règles par filtre** : Maximum 20 règles
- **Groupes imbriqués** : Maximum 5 niveaux

## Tests

### Script de test

```bash
# Tester le système de ciblage avancé
python3 scripts/test-advanced-targeting.py
```

### Tests unitaires

```bash
# Tests Go
go test ./internal/geo/...

# Tests frontend
npm test -- --grep "AdvancedTargeting"
```

## Exemples pratiques

### Cas d'usage 1 : Campagne régionale

**Objectif** : Toutes les mairies d'Île-de-France avec plus de 5 000 habitants

```json
{
  "advanced_filters": {
    "operator": "AND",
    "rules": [
      {
        "field": "region",
        "operator": "eq",
        "value": "Île-de-France"
      },
      {
        "field": "population",
        "operator": "gte",
        "value": 5000
      }
    ]
  }
}
```

### Cas d'usage 2 : Campagne ciblée

**Objectif** : Grandes villes OU petites communes rurales

```json
{
  "advanced_filters": {
    "operator": "OR",
    "rules": [
      {
        "field": "population",
        "operator": "gte",
        "value": 50000
      },
      {
        "field": "population",
        "operator": "lte",
        "value": 1000
      }
    ]
  }
}
```

### Cas d'usage 3 : Exclusion géographique

**Objectif** : Toute la France SAUF l'Île-de-France

```json
{
  "advanced_filters": {
    "operator": "AND",
    "rules": [
      {
        "field": "region",
        "operator": "ne",
        "value": "Île-de-France"
      }
    ]
  }
}
```

## Dépannage

### Erreurs courantes

1. **Aucun résultat** : Vérifiez que les critères ne sont pas trop restrictifs
2. **Erreur de syntaxe** : Validez le format JSON des filtres
3. **Performance lente** : Réduisez le nombre de règles ou utilisez des index

### Logs de débogage

```bash
# Activer les logs SQL
export LISTMONK_LOG_LEVEL=debug

# Voir les requêtes générées
tail -f /var/log/listmonk/app.log | grep "SELECT"
```

## Conclusion

Le système de ciblage avancé permet maintenant de créer des campagnes très précises avec des critères complexes combinant département, population et autres attributs géographiques avec des opérateurs ET/OU natifs.

Cette fonctionnalité transforme Listmonk en un outil puissant pour le marketing territorial et la communication institutionnelle ciblée.