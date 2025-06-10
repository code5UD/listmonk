#!/usr/bin/env python3
"""
Script pour convertir le fichier mairielist.csv au format attendu par l'importeur listmonk.
"""

import csv
import sys
import re
from typing import Dict, Any

def extract_postal_code(address: str) -> str:
    """Extrait le code postal de l'adresse."""
    # Recherche d'un code postal français (5 chiffres)
    match = re.search(r'\b(\d{5})\b', address)
    return match.group(1) if match else ""

def extract_department_from_insee(insee_code: str) -> str:
    """Extrait le code département du code INSEE."""
    if len(insee_code) >= 2:
        dept = insee_code[:2]
        # Gestion des cas spéciaux de la Corse
        if dept == "20":
            # Pour la Corse, on utilise le 3ème chiffre pour déterminer 2A ou 2B
            if len(insee_code) >= 3:
                third_digit = insee_code[2]
                return "2A" if third_digit in "01" else "2B"
        return dept
    return ""

def clean_email(email: str) -> str:
    """Nettoie l'adresse email."""
    email = email.strip().lower()
    # Supprime les valeurs invalides
    if email in ["nan", "null", "", "none"]:
        return ""
    # Validation basique d'email
    if "@" not in email or "." not in email:
        return ""
    return email

def clean_population(pop_str: str) -> str:
    """Nettoie la valeur de population."""
    if not pop_str or pop_str.lower() in ["nan", "null", ""]:
        return "0"
    # Supprime les espaces et caractères non numériques
    pop_clean = re.sub(r'[^\d]', '', str(pop_str))
    return pop_clean if pop_clean else "0"

def format_insee_code(insee_code: str, dept_code: str) -> str:
    """Formate le code INSEE au format standard 5 chiffres."""
    if not insee_code:
        return ""
    
    # Nettoie le code INSEE
    insee_clean = re.sub(r'[^\d]', '', insee_code)
    
    # Si le code fait déjà 5 chiffres, on le retourne tel quel
    if len(insee_clean) == 5:
        return insee_clean
    
    # Pour les codes à 4 chiffres, on ajoute un zéro au début
    if len(insee_clean) == 4:
        return "0" + insee_clean
    
    # Si le code fait moins de 4 chiffres, on le complète avec le département
    if len(insee_clean) < 4:
        # Utilise le code département pour compléter
        dept_clean = re.sub(r'[^\d]', '', dept_code)
        if len(dept_clean) == 1:
            dept_clean = "0" + dept_clean
        
        # Complète le code INSEE
        if len(insee_clean) <= 3:
            # Ajoute des zéros au début si nécessaire
            commune_part = insee_clean.zfill(3)
            return dept_clean + commune_part
    
    return insee_clean

def convert_csv(input_file: str, output_file: str):
    """Convertit le CSV d'entrée au format attendu."""
    
    # Mapping des colonnes
    output_headers = [
        "nom_commune",
        "code_insee", 
        "code_departement",
        "population",
        "email",
        "nom_contact",
        "code_postal",
        "latitude",
        "longitude"
    ]
    
    converted_count = 0
    error_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        writer = csv.writer(outfile, delimiter=';')
        
        # Écrire l'en-tête
        writer.writerow(output_headers)
        
        for row_num, row in enumerate(reader, 1):
            try:
                # Extraction et nettoyage des données
                nom_commune = row.get('nom_commune', row.get('city', '')).strip().upper()
                code_insee_raw = row.get('code_insee', '').strip()
                
                # Extraction du département
                code_departement = row.get('departement_numero', '')
                if not code_departement:
                    code_departement = extract_department_from_insee(code_insee_raw)
                
                # Formatage du code INSEE
                code_insee = format_insee_code(code_insee_raw, code_departement)
                
                # Population
                population = clean_population(row.get('population_commune', '0'))
                
                # Email et contact
                email = clean_email(row.get('email', ''))
                nom_contact = f"{row.get('firstname', '').strip()} {row.get('lastname', '').strip()}".strip()
                
                # Code postal
                code_postal = row.get('zipcode', '')
                if not code_postal:
                    code_postal = extract_postal_code(row.get('address1', ''))
                
                # Coordonnées (pas disponibles dans ce CSV)
                latitude = ""
                longitude = ""
                
                # Validation des données obligatoires
                if not nom_commune or not code_insee or not code_departement:
                    print(f"Ligne {row_num}: Données obligatoires manquantes - ignorée")
                    error_count += 1
                    continue
                
                # Validation du code INSEE (5 chiffres)
                if not re.match(r'^\d{5}$', code_insee):
                    print(f"Ligne {row_num}: Code INSEE invalide '{code_insee}' - ignorée")
                    error_count += 1
                    continue
                
                # Écrire la ligne convertie
                writer.writerow([
                    nom_commune,
                    code_insee,
                    code_departement,
                    population,
                    email,
                    nom_contact,
                    code_postal,
                    latitude,
                    longitude
                ])
                
                converted_count += 1
                
                if converted_count % 1000 == 0:
                    print(f"Converti {converted_count} lignes...")
                    
            except Exception as e:
                print(f"Erreur ligne {row_num}: {e}")
                error_count += 1
                continue
    
    print(f"\nConversion terminée:")
    print(f"- Lignes converties: {converted_count}")
    print(f"- Erreurs: {error_count}")
    print(f"- Fichier de sortie: {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 convert-mairielist-csv.py <input.csv> <output.csv>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        convert_csv(input_file, output_file)
    except Exception as e:
        print(f"Erreur: {e}")
        sys.exit(1)