#!/usr/bin/env python3
"""
Script pour convertir le fichier mairielist.csv au schéma attendu par l'interface Listmonk.

Schéma source:
email,firstname,lastname,title,phone,website,address1,city,state,zipcode,country,code_insee,population_commune,date_naissance,csp,siren,siret,telecopie,nom_commune,departement_numero

Schéma cible:
nom_commune,code_insee,code_departement,population,email,nom_contact,code_postal,latitude,longitude
"""

import csv
import sys
import re
from pathlib import Path

def extract_postal_code(address):
    """Extrait le code postal de l'adresse."""
    if not address or address == 'nan':
        return ''
    
    # Recherche d'un code postal français (5 chiffres)
    match = re.search(r'\b(\d{5})\b', address)
    return match.group(1) if match else ''

def format_contact_name(firstname, lastname, title):
    """Formate le nom du contact."""
    parts = []
    if title and title != 'nan':
        parts.append(title)
    if firstname and firstname != 'nan':
        parts.append(firstname)
    if lastname and lastname != 'nan':
        parts.append(lastname)
    return ' '.join(parts)

def convert_csv_schema(input_file, output_file):
    """Convertit le CSV du schéma source vers le schéma cible."""
    
    print(f"Conversion de {input_file} vers {output_file}")
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        
        # Définir les colonnes de sortie
        fieldnames = [
            'nom_commune',
            'code_insee', 
            'code_departement',
            'population',
            'email',
            'nom_contact',
            'code_postal',
            'latitude',
            'longitude'
        ]
        
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        
        converted_count = 0
        skipped_count = 0
        
        for row in reader:
            try:
                # Mapper les colonnes
                converted_row = {
                    'nom_commune': row.get('nom_commune', '').strip(),
                    'code_insee': row.get('code_insee', '').strip(),
                    'code_departement': row.get('departement_numero', '').strip(),
                    'population': row.get('population_commune', '0').strip(),
                    'email': row.get('email', '').strip(),
                    'nom_contact': format_contact_name(
                        row.get('firstname', ''),
                        row.get('lastname', ''),
                        row.get('title', '')
                    ),
                    'code_postal': extract_postal_code(row.get('address1', '')),
                    'latitude': '',  # Pas disponible dans le fichier source
                    'longitude': ''  # Pas disponible dans le fichier source
                }
                
                # Validation basique
                if not converted_row['nom_commune'] or not converted_row['code_insee']:
                    skipped_count += 1
                    continue
                
                # Nettoyer les valeurs 'nan'
                for key, value in converted_row.items():
                    if value == 'nan' or value == 'None':
                        converted_row[key] = ''
                
                # Valider le code INSEE (doit être numérique)
                try:
                    int(converted_row['code_insee'])
                except ValueError:
                    skipped_count += 1
                    continue
                
                # Valider la population
                try:
                    pop = int(converted_row['population']) if converted_row['population'] else 0
                    converted_row['population'] = str(pop)
                except ValueError:
                    converted_row['population'] = '0'
                
                writer.writerow(converted_row)
                converted_count += 1
                
            except Exception as e:
                print(f"Erreur lors de la conversion de la ligne: {e}")
                skipped_count += 1
                continue
    
    print(f"Conversion terminée:")
    print(f"  - Lignes converties: {converted_count}")
    print(f"  - Lignes ignorées: {skipped_count}")
    print(f"  - Fichier de sortie: {output_file}")

def main():
    input_file = Path(__file__).parent.parent / 'mairielist.csv'
    output_file = Path(__file__).parent.parent / 'mairielist_formatted.csv'
    
    if not input_file.exists():
        print(f"Erreur: Le fichier {input_file} n'existe pas")
        sys.exit(1)
    
    convert_csv_schema(input_file, output_file)
    
    # Afficher un échantillon du résultat
    print("\nÉchantillon du fichier converti:")
    with open(output_file, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if i < 3:  # Afficher les 3 premières lignes
                print(f"  {line.strip()}")
            else:
                break

if __name__ == '__main__':
    main()