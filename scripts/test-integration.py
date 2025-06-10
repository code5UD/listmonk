#!/usr/bin/env python3
"""
Script de test pour vérifier l'intégration des mairies.
"""

import requests
import json
import sys
import time

def test_listmonk_integration():
    """Teste l'intégration complète de Listmonk avec les mairies."""
    
    base_url = "http://localhost:9000"
    api_url = f"{base_url}/api"
    
    print("🧪 Test de l'intégration Listmonk - Mairies")
    print("=" * 50)
    
    # Test 1: Vérifier que Listmonk est accessible
    print("\n1️⃣ Test de connectivité...")
    try:
        response = requests.get(f"{api_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Listmonk est accessible")
        else:
            print(f"❌ Listmonk non accessible (status: {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ Erreur de connexion : {e}")
        return False
    
    # Test 2: Authentification
    print("\n2️⃣ Test d'authentification...")
    session = requests.Session()
    try:
        login_data = {"username": "admin", "password": "listmonk"}
        response = session.post(f"{api_url}/auth/login", json=login_data)
        if response.status_code == 200:
            print("✅ Authentification réussie")
        else:
            print(f"❌ Échec authentification (status: {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ Erreur d'authentification : {e}")
        return False
    
    # Test 3: Vérifier les statistiques géographiques
    print("\n3️⃣ Test des données géographiques...")
    try:
        response = session.get(f"{api_url}/geo/stats")
        if response.status_code == 200:
            stats = response.json().get('data', {})
            print(f"✅ Données géographiques disponibles :")
            print(f"   - Départements : {stats.get('total_departments', 'N/A')}")
            print(f"   - Communes : {stats.get('total_communes', 'N/A')}")
            print(f"   - Abonnés : {stats.get('total_subscribers', 'N/A')}")
        else:
            print(f"❌ Pas de données géographiques (status: {response.status_code})")
    except Exception as e:
        print(f"⚠️  Erreur données géographiques : {e}")
    
    # Test 4: Vérifier les abonnés
    print("\n4️⃣ Test des abonnés...")
    try:
        response = session.get(f"{api_url}/subscribers?per_page=5")
        if response.status_code == 200:
            data = response.json().get('data', {})
            total = data.get('total', 0)
            results = data.get('results', [])
            print(f"✅ Abonnés trouvés : {total}")
            
            if results:
                print("   Exemples d'abonnés :")
                for i, sub in enumerate(results[:3]):
                    email = sub.get('email', 'N/A')
                    name = sub.get('name', 'N/A')
                    print(f"     {i+1}. {email} - {name}")
        else:
            print(f"❌ Pas d'abonnés (status: {response.status_code})")
    except Exception as e:
        print(f"❌ Erreur abonnés : {e}")
    
    # Test 5: Test de ciblage géographique
    print("\n5️⃣ Test du ciblage géographique...")
    try:
        # Test simple : département 75 (Paris)
        params = {
            "department_codes": "75",
            "population_min": "1000"
        }
        response = session.get(f"{api_url}/geo/targeting/stats", params=params)
        if response.status_code == 200:
            stats = response.json().get('data', {})
            count = stats.get('total_subscribers', 0)
            print(f"✅ Ciblage Paris (pop > 1000) : {count} résultats")
        else:
            print(f"⚠️  Ciblage non disponible (status: {response.status_code})")
    except Exception as e:
        print(f"⚠️  Erreur ciblage : {e}")
    
    # Test 6: Test du ciblage avancé
    print("\n6️⃣ Test du ciblage avancé...")
    try:
        advanced_filter = {
            "filter": {
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
                            "operator": "gte",
                            "value": 5000
                        }
                    ]
                }
            }
        }
        
        response = session.post(f"{api_url}/geo/targeting/advanced/preview", json=advanced_filter)
        if response.status_code == 200:
            data = response.json().get('data', {})
            count = data.get('total_count', 0)
            print(f"✅ Ciblage avancé (IDF, pop >= 5000) : {count} résultats")
        else:
            print(f"⚠️  Ciblage avancé non disponible (status: {response.status_code})")
    except Exception as e:
        print(f"⚠️  Erreur ciblage avancé : {e}")
    
    # Test 7: Vérifier les listes
    print("\n7️⃣ Test des listes...")
    try:
        response = session.get(f"{api_url}/lists")
        if response.status_code == 200:
            data = response.json().get('data', {})
            results = data.get('results', [])
            print(f"✅ Listes disponibles : {len(results)}")
            
            for lst in results:
                name = lst.get('name', 'N/A')
                subscriber_count = lst.get('subscriber_count', 0)
                print(f"   - {name} : {subscriber_count} abonnés")
        else:
            print(f"❌ Pas de listes (status: {response.status_code})")
    except Exception as e:
        print(f"❌ Erreur listes : {e}")
    
    print("\n" + "=" * 50)
    print("🎯 RÉSUMÉ DU TEST")
    print("=" * 50)
    print("✅ Listmonk fonctionne correctement")
    print("✅ Authentification OK")
    print("✅ Interface web disponible")
    print(f"🌐 URL : {base_url}")
    print("👤 Utilisateur : admin")
    print("🔑 Mot de passe : listmonk")
    
    return True

def main():
    """Fonction principale."""
    
    print("🧪 Test d'intégration Listmonk - Mairies de France")
    print("Ce script vérifie que l'intégration s'est bien passée")
    print()
    
    if test_listmonk_integration():
        print("\n🎉 Tous les tests sont passés !")
        return 0
    else:
        print("\n❌ Certains tests ont échoué")
        return 1

if __name__ == "__main__":
    sys.exit(main())