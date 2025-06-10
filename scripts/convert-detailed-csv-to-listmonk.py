#!/usr/bin/env python3
"""
Script pour convertir le fichier CSV détaillé des mairies au format attendu par Listmonk.
Ce script traite le format avec firstname, lastname et tous les autres champs.
"""

import csv
import json
import sys
import os

def convert_detailed_csv_to_listmonk_format(input_file, output_file):
    """
    Convertit le fichier CSV détaillé des mairies au format Listmonk.
    
    Format d'entrée : email,firstname,lastname,title,phone,website,address1,city,state,zipcode,country,code_insee,population_commune,date_naissance,csp,siren,siret,telecopie,nom_commune,departement_numero
    Format de sortie : email,name,attributes
    """
    
    if not os.path.exists(input_file):
        print(f"Erreur : Le fichier {input_file} n'existe pas.")
        return False
    
    try:
        with open(input_file, 'r', encoding='utf-8') as infile, \
             open(output_file, 'w', encoding='utf-8', newline='') as outfile:
            
            reader = csv.DictReader(infile)
            writer = csv.writer(outfile)
            
            # Écriture de l'en-tête Listmonk
            writer.writerow(['email', 'name', 'attributes'])
            
            processed = 0
            skipped = 0
            
            for row in reader:
                try:
                    # Extraction des données principales
                    email = row.get('email', '').strip()
                    firstname = row.get('firstname', '').strip()
                    lastname = row.get('lastname', '').strip()
                    
                    # Validation de l'email
                    if not email or '@' not in email:
                        print(f"Ligne ignorée - email invalide : {email}")
                        skipped += 1
                        continue
                    
                    # Construction du nom complet
                    name_parts = []
                    if firstname:
                        name_parts.append(firstname)
                    if lastname:
                        name_parts.append(lastname)
                    
                    name = ' '.join(name_parts) if name_parts else email.split('@')[0]
                    
                    # Construction des attributs JSON avec toutes les autres données
                    attributes = {}
                    for key, value in row.items():
                        if key not in ['email', 'firstname', 'lastname'] and value and value.strip():
                            # Nettoyage des valeurs
                            clean_value = value.strip()
                            if clean_value and clean_value.lower() not in ['nan', 'null', '']:
                                # Conversion des nombres
                                if key in ['code_insee', 'population_commune', 'zipcode', 'departement_numero']:
                                    try:
                                        attributes[key] = int(clean_value)
                                    except ValueError:
                                        attributes[key] = clean_value
                                else:
                                    attributes[key] = clean_value
                    
                    # Écriture de la ligne
                    writer.writerow([
                        email,
                        name,
                        json.dumps(attributes, ensure_ascii=False)
                    ])
                    processed += 1
                    
                    if processed % 1000 == 0:
                        print(f"Traité {processed} lignes...")
                        
                except Exception as e:
                    print(f"Erreur lors du traitement de la ligne : {e}")
                    skipped += 1
                    continue
            
            print(f"\nConversion terminée :")
            print(f"- Lignes traitées : {processed}")
            print(f"- Lignes ignorées : {skipped}")
            print(f"- Fichier de sortie : {output_file}")
            
            return True
            
    except Exception as e:
        print(f"Erreur lors de la conversion : {e}")
        return False

def main():
    # Fichiers par défaut
    input_file = "/workspace/listmonk/mairielist-clean.csv"
    output_file = "/workspace/listmonk/mairielist-detailed-listmonk.csv"
    
    # Permettre de spécifier des fichiers en arguments
    if len(sys.argv) >= 2:
        input_file = sys.argv[1]
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    
    print(f"Conversion de {input_file} vers {output_file}")
    
    if convert_detailed_csv_to_listmonk_format(input_file, output_file):
        print("Conversion réussie !")
        return 0
    else:
        print("Échec de la conversion.")
        return 1

if __name__ == "__main__":
    sys.exit(main())