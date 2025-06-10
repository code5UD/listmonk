#!/usr/bin/env python3
"""
Script pour nettoyer et convertir le fichier CSV des mairies.
"""

import csv
import sys
import os
from pathlib import Path

def clean_git_conflicts(input_file, output_file):
    """Nettoie les marqueurs de conflit Git du fichier."""
    
    print("🔄 Nettoyage des marqueurs Git...")
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8') as outfile:
        
        skip_until_end = False
        lines_written = 0
        
        for line_num, line in enumerate(infile, 1):
            # Détecter les marqueurs de conflit Git
            if line.startswith('<<<<<<< HEAD'):
                skip_until_end = False
                continue
            elif line.startswith('======='):
                skip_until_end = True
                continue
            elif line.startswith('>>>>>>> '):
                skip_until_end = False
                continue
            
            # Écrire la ligne si on n'est pas dans une section à ignorer
            if not skip_until_end:
                outfile.write(line)
                lines_written += 1
    
    print(f"✅ Marqueurs Git nettoyés - {lines_written} lignes conservées")
    return lines_written > 0

def convert_to_mairies_format(input_file, output_file):
    """Convertit le fichier CSV au format attendu par l'importeur de mairies."""
    
    print("🔄 Conversion au format mairies...")
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        writer = csv.writer(outfile, delimiter=';')
        
        # Écrire l'en-tête au format attendu
        writer.writerow([
            'nom_commune', 'code_insee', 'code_departement', 'population',
            'email', 'nom_contact', 'code_postal', 'latitude', 'longitude'
        ])
        
        processed = 0
        errors = 0
        
        for row_num, row in enumerate(reader, start=2):
            try:
                # Extraire et nettoyer les données
                email = row.get('email', '').strip()
                firstname = row.get('firstname', '').strip()
                lastname = row.get('lastname', '').strip()
                nom_commune = row.get('nom_commune', '').strip()
                code_insee = row.get('code_insee', '').strip()
                departement_numero = row.get('departement_numero', '').strip()
                population_commune = row.get('population_commune', '').strip()
                zipcode = row.get('zipcode', '').strip()
                
                # Valider les données essentielles
                if not email or '@' not in email:
                    continue
                
                if not nom_commune:
                    continue
                
                # Construire le nom de contact
                nom_contact = f"{firstname} {lastname}".strip()
                if not nom_contact:
                    nom_contact = f"Mairie de {nom_commune}"
                
                # Nettoyer le code INSEE
                if code_insee and code_insee.isdigit():
                    code_insee = code_insee.zfill(5)  # Assurer 5 chiffres
                else:
                    code_insee = ""
                
                # Nettoyer le code département
                if departement_numero and departement_numero.isdigit():
                    departement_numero = departement_numero.zfill(2)  # Assurer 2 chiffres
                else:
                    departement_numero = ""
                
                # Nettoyer la population
                if population_commune and population_commune.isdigit():
                    population = int(population_commune)
                else:
                    population = 0
                
                # Nettoyer le code postal
                if zipcode and zipcode.isdigit():
                    code_postal = zipcode.zfill(5)  # Assurer 5 chiffres
                else:
                    code_postal = ""
                
                # Écrire la ligne convertie
                writer.writerow([
                    nom_commune,           # nom_commune
                    code_insee,            # code_insee
                    departement_numero,    # code_departement
                    population,            # population
                    email,                 # email
                    nom_contact,           # nom_contact
                    code_postal,           # code_postal
                    "",                    # latitude (vide pour l'instant)
                    ""                     # longitude (vide pour l'instant)
                ])
                
                processed += 1
                
                if processed % 1000 == 0:
                    print(f"   Traité {processed} lignes...")
                    
            except Exception as e:
                errors += 1
                if errors < 10:  # Afficher seulement les 10 premières erreurs
                    print(f"   ⚠️  Erreur ligne {row_num}: {e}")
                continue
        
        print(f"✅ Conversion terminée :")
        print(f"   - Lignes traitées : {processed}")
        print(f"   - Erreurs : {errors}")
        
        return processed > 0

def main():
    """Fonction principale."""
    
    print("🇫🇷 Nettoyage et conversion du fichier des mairies")
    print("=" * 50)
    
    base_path = Path("/workspace/listmonk")
    input_file = base_path / "mairielist.csv"
    clean_file = base_path / "mairielist-clean.csv"
    output_file = base_path / "mairielist-converted.csv"
    
    if not input_file.exists():
        print("❌ Fichier d'entrée non trouvé")
        return 1
    
    # Étape 1: Nettoyer les marqueurs Git
    if not clean_git_conflicts(input_file, clean_file):
        print("❌ Échec du nettoyage")
        return 1
    
    # Étape 2: Convertir au format mairies
    if not convert_to_mairies_format(clean_file, output_file):
        print("❌ Échec de la conversion")
        return 1
    
    # Nettoyer le fichier temporaire
    if clean_file.exists():
        clean_file.unlink()
    
    print(f"\n🎉 Fichier prêt pour l'import : {output_file}")
    
    # Afficher quelques lignes d'exemple
    print("\n📋 Aperçu du fichier converti :")
    with open(output_file, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if i < 5:  # Afficher les 5 premières lignes
                print(f"   {line.strip()}")
            else:
                break
    
    return 0

if __name__ == "__main__":
    sys.exit(main())