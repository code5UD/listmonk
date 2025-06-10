#!/usr/bin/env python3
"""
Script pour tester le système de ciblage avancé avec opérateurs ET/OU.
"""

import json
import requests
import sys

# Configuration
BASE_URL = "http://localhost:9000"
API_BASE = f"{BASE_URL}/api/geo"

def test_advanced_targeting():
    """Test le système de ciblage avancé."""
    
    print("🧪 Test du système de ciblage avancé")
    print("=" * 50)
    
    # Test 1: Ciblage simple avec ET
    print("\n1️⃣ Test: Départements 75 ET population > 10000")
    filter_and = {
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
    
    test_filter(filter_and, "Ciblage ET")
    
    # Test 2: Ciblage avec OU
    print("\n2️⃣ Test: Département 75 OU département 92")
    filter_or = {
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
    
    test_filter(filter_or, "Ciblage OU")
    
    # Test 3: Ciblage complexe avec plage de population
    print("\n3️⃣ Test: Population entre 5000 et 50000 ET région Île-de-France")
    filter_complex = {
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
                },
                {
                    "field": "region",
                    "operator": "contains",
                    "value": "Île-de-France"
                }
            ]
        }
    }
    
    test_filter(filter_complex, "Ciblage complexe")
    
    # Test 4: Ciblage avec liste de départements
    print("\n4️⃣ Test: Départements dans [75, 92, 93, 94] ET population > 20000")
    filter_list = {
        "advanced_filters": {
            "operator": "AND",
            "rules": [
                {
                    "field": "department",
                    "operator": "in",
                    "value": ["75", "92", "93", "94"]
                },
                {
                    "field": "population",
                    "operator": "gt",
                    "value": 20000
                }
            ]
        }
    }
    
    test_filter(filter_list, "Ciblage avec liste")
    
    # Test 5: Ciblage par nom de commune
    print("\n5️⃣ Test: Communes contenant 'Paris' OU 'Lyon'")
    filter_commune = {
        "advanced_filters": {
            "operator": "OR",
            "rules": [
                {
                    "field": "commune_name",
                    "operator": "contains",
                    "value": "Paris"
                },
                {
                    "field": "commune_name",
                    "operator": "contains",
                    "value": "Lyon"
                }
            ]
        }
    }
    
    test_filter(filter_commune, "Ciblage par commune")

def test_filter(filter_data, test_name):
    """Teste un filtre spécifique."""
    
    try:
        # Test de prévisualisation
        print(f"\n📋 {test_name}")
        print(f"Filtre: {json.dumps(filter_data, indent=2)}")
        
        response = requests.post(
            f"{API_BASE}/targeting/advanced/preview",
            json={"filter": filter_data},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json().get('data', {})
            print(f"✅ Résultats:")
            print(f"   - Nombre total: {data.get('total_count', 0)}")
            print(f"   - Communes: {data.get('statistics', {}).get('total_communes', 0)}")
            print(f"   - Population totale: {data.get('population_total', 0):,}")
            
            # Afficher quelques exemples
            subscribers = data.get('subscribers', [])
            if subscribers:
                print(f"   - Exemples:")
                for i, sub in enumerate(subscribers[:3]):
                    print(f"     {i+1}. {sub.get('subscriber_email', 'N/A')} - {sub.get('name', 'N/A')} ({sub.get('department_code', 'N/A')})")
        else:
            print(f"❌ Erreur HTTP {response.status_code}: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erreur de connexion: {e}")
    except Exception as e:
        print(f"❌ Erreur: {e}")

def test_legacy_compatibility():
    """Teste la compatibilité avec l'ancien système."""
    
    print("\n🔄 Test de compatibilité avec l'ancien système")
    print("=" * 50)
    
    # Test avec l'ancien format
    legacy_filter = {
        "department_codes": ["75", "92"],
        "population_min": 10000,
        "population_max": 100000
    }
    
    try:
        response = requests.post(
            f"{API_BASE}/targeting/advanced",
            json={"filter": legacy_filter},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json().get('data', {})
            print(f"✅ Ancien format fonctionne:")
            print(f"   - Nombre total: {data.get('total_count', 0)}")
        else:
            print(f"❌ Erreur avec ancien format: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erreur: {e}")

def main():
    """Fonction principale."""
    
    print("🎯 Test du système de ciblage avancé Listmonk")
    print("Assurez-vous que Listmonk est démarré sur http://localhost:9000")
    
    # Vérifier que le serveur est accessible
    try:
        response = requests.get(f"{BASE_URL}/api/health", timeout=5)
        if response.status_code != 200:
            print("❌ Serveur Listmonk non accessible")
            return 1
    except:
        print("❌ Impossible de se connecter à Listmonk")
        print("   Démarrez Listmonk avec: ./listmonk --config config.toml")
        return 1
    
    print("✅ Serveur Listmonk accessible")
    
    # Exécuter les tests
    test_advanced_targeting()
    test_legacy_compatibility()
    
    print("\n🎉 Tests terminés!")
    return 0

if __name__ == "__main__":
    sys.exit(main())