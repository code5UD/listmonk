#!/usr/bin/env python3
"""
Script pour convertir le fichier CSV des mairies au format attendu par Listmonk.
Listmonk n'accepte que 3 colonnes : email, name, attributes
"""

import csv
import json
import sys
import os

def convert_csv_to_listmonk_format(input_file, output_file):
    """
    Convertit le fichier CSV des mairies au format Listmonk.
    
    Format d'entrée : nom_commune;code_insee;code_departement;population;email;nom_contact;code_postal;latitude;longitude
    Format de sortie : email,name,attributes
    """
    
    if not os.path.exists(input_file):
        print(f"Erreur : Le fichier {input_file} n'existe pas.")
        return False
    
    try:
        with open(input_file, 'r', encoding='utf-8') as infile, \
             open(output_file, 'w', encoding='utf-8', newline='') as outfile:
            
            # Détection du délimiteur
            sample = infile.read(1024)
            infile.seek(0)
            delimiter = ';' if ';' in sample else ','
            
            reader = csv.DictReader(infile, delimiter=delimiter)
            writer = csv.writer(outfile)
            
            # Écriture de l'en-tête Listmonk
            writer.writerow(['email', 'name', 'attributes'])
            
            processed = 0
            skipped = 0
            
            for row in reader:
                try:
                    # Extraction des données principales
                    email = row.get('email', '').strip()
                    nom_contact = row.get('nom_contact', '').strip()
                    nom_commune = row.get('nom_commune', '').strip()
                    
                    # Validation de l'email
                    if not email or '@' not in email:
                        print(f"Ligne ignorée - email invalide : {email}")
                        skipped += 1
                        continue
                    
                    # Construction du nom (contact ou commune)
                    name = nom_contact if nom_contact else nom_commune
                    if not name:
                        name = email.split('@')[0]  # Utiliser la partie locale de l'email
                    
                    # Construction des attributs JSON avec toutes les autres données
                    attributes = {}
                    for key, value in row.items():
                        if key not in ['email', 'nom_contact'] and value and value.strip():
                            # Nettoyage des valeurs
                            clean_value = value.strip()
                            if clean_value and clean_value != 'nan':
                                # Conversion des nombres
                                if key in ['code_insee', 'code_departement', 'population', 'code_postal']:
                                    try:
                                        attributes[key] = int(clean_value)
                                    except ValueError:
                                        attributes[key] = clean_value
                                elif key in ['latitude', 'longitude']:
                                    try:
                                        attributes[key] = float(clean_value) if clean_value else None
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
    input_file = "/workspace/listmonk/mairielist-converted.csv"
    output_file = "/workspace/listmonk/mairielist-listmonk.csv"
    
    # Permettre de spécifier des fichiers en arguments
    if len(sys.argv) >= 2:
        input_file = sys.argv[1]
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    
    print(f"Conversion de {input_file} vers {output_file}")
    
    if convert_csv_to_listmonk_format(input_file, output_file):
        print("Conversion réussie !")
        return 0
    else:
        print("Échec de la conversion.")
        return 1

if __name__ == "__main__":
    sys.exit(main())