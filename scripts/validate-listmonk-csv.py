#!/usr/bin/env python3
"""
Script pour valider qu'un fichier CSV est compatible avec Listmonk.
"""

import csv
import json
import sys
import re

def validate_email(email):
    """Valide une adresse email."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def validate_listmonk_csv(file_path):
    """
    Valide qu'un fichier CSV est compatible avec Listmonk.
    
    Vérifie :
    - Les en-têtes requis (email, name, attributes)
    - La validité des emails
    - La validité du JSON dans attributes
    """
    
    errors = []
    warnings = []
    valid_rows = 0
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            # Vérification des en-têtes
            required_headers = {'email', 'name', 'attributes'}
            actual_headers = set(reader.fieldnames)
            
            if not required_headers.issubset(actual_headers):
                missing = required_headers - actual_headers
                errors.append(f"En-têtes manquants : {', '.join(missing)}")
                return errors, warnings, 0
            
            extra_headers = actual_headers - required_headers
            if extra_headers:
                warnings.append(f"En-têtes supplémentaires (seront ignorés) : {', '.join(extra_headers)}")
            
            # Vérification des lignes
            for row_num, row in enumerate(reader, start=2):  # Start=2 car ligne 1 = en-têtes
                row_errors = []
                
                # Vérification email
                email = row.get('email', '').strip()
                if not email:
                    row_errors.append("Email vide")
                elif not validate_email(email):
                    row_errors.append(f"Email invalide : {email}")
                
                # Vérification name
                name = row.get('name', '').strip()
                if not name:
                    warnings.append(f"Ligne {row_num} : Nom vide")
                
                # Vérification attributes
                attributes = row.get('attributes', '').strip()
                if attributes:
                    try:
                        json.loads(attributes)
                    except json.JSONDecodeError as e:
                        row_errors.append(f"JSON invalide dans attributes : {e}")
                
                if row_errors:
                    errors.append(f"Ligne {row_num} : {'; '.join(row_errors)}")
                else:
                    valid_rows += 1
                
                # Limite pour éviter trop de messages
                if len(errors) > 50:
                    errors.append("... (plus de 50 erreurs, arrêt de la validation)")
                    break
    
    except Exception as e:
        errors.append(f"Erreur lors de la lecture du fichier : {e}")
    
    return errors, warnings, valid_rows

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 validate-listmonk-csv.py <fichier.csv>")
        return 1
    
    file_path = sys.argv[1]
    
    print(f"Validation du fichier : {file_path}")
    print("=" * 50)
    
    errors, warnings, valid_rows = validate_listmonk_csv(file_path)
    
    # Affichage des résultats
    if errors:
        print("❌ ERREURS :")
        for error in errors:
            print(f"  - {error}")
        print()
    
    if warnings:
        print("⚠️  AVERTISSEMENTS :")
        for warning in warnings:
            print(f"  - {warning}")
        print()
    
    print(f"✅ Lignes valides : {valid_rows}")
    
    if errors:
        print("\n❌ Le fichier n'est PAS compatible avec Listmonk.")
        return 1
    else:
        print("\n✅ Le fichier est compatible avec Listmonk !")
        return 0

if __name__ == "__main__":
    sys.exit(main())