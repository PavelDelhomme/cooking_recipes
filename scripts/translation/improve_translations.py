#!/usr/bin/env python3
"""
Outil interactif pour améliorer les traductions des recettes
Permet d'ajouter, modifier et tester les traductions d'instructions
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, List

# Couleurs pour le terminal
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
RED = '\033[0;31m'
NC = '\033[0m'  # No Color

PROJECT_ROOT = Path(__file__).parent.parent
DICTIONARIES_DIR = PROJECT_ROOT / 'frontend' / 'lib' / 'data' / 'culinary_dictionaries'
INSTRUCTIONS_FILE = DICTIONARIES_DIR / 'instructions_fr_en_es.json'
INGREDIENTS_FILE = DICTIONARIES_DIR / 'ingredients_fr_en_es.json'
RECIPE_NAMES_FILE = DICTIONARIES_DIR / 'recipe_names_fr_en_es.json'


def load_json_file(file_path: Path) -> Dict:
    """Charge un fichier JSON"""
    if not file_path.exists():
        return {}
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"{RED}❌ Erreur lors du chargement de {file_path}: {e}{NC}")
        return {}


def save_json_file(file_path: Path, data: Dict):
    """Sauvegarde un fichier JSON avec formatage"""
    file_path.parent.mkdir(parents=True, exist_ok=True)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def init_instructions_file():
    """Initialise le fichier d'instructions s'il n'existe pas"""
    if not INSTRUCTIONS_FILE.exists():
        data = {
            "metadata": {
                "version": "1.0.0",
                "source": "Manual improvements",
                "languages": ["en", "fr", "es"],
                "total_terms": 0,
                "last_updated": datetime.now().strftime("%Y-%m-%d")
            },
            "instructions": {}
        }
        save_json_file(INSTRUCTIONS_FILE, data)
        print(f"{GREEN}✅ Fichier d'instructions créé{NC}")
    return load_json_file(INSTRUCTIONS_FILE)


def normalize_text(text: str) -> str:
    """Normalise un texte pour la recherche (minuscules, sans accents)"""
    import unicodedata
    # Enlever les accents
    text = unicodedata.normalize('NFD', text.lower().strip())
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    return text


def find_similar_instructions(instructions_data: Dict, search_text: str, limit: int = 5) -> List[tuple]:
    """Trouve des instructions similaires"""
    search_normalized = normalize_text(search_text)
    similar = []
    
    for key, translations in instructions_data.get('instructions', {}).items():
        key_normalized = normalize_text(key)
        # Calculer une similarité simple (nombre de mots communs)
        search_words = set(search_normalized.split())
        key_words = set(key_normalized.split())
        common_words = search_words & key_words
        if common_words:
            similarity = len(common_words) / max(len(search_words), len(key_words))
            if similarity > 0.3:  # Au moins 30% de similarité
                similar.append((similarity, key, translations))
    
    # Trier par similarité décroissante
    similar.sort(reverse=True, key=lambda x: x[0])
    return similar[:limit]


def add_instruction_translation():
    """Ajoute ou modifie une traduction d'instruction"""
    instructions_data = init_instructions_file()
    
    print(f"\n{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{BLUE}➕ Ajouter/Modifier une traduction d'instruction{NC}")
    print(f"{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")
    
    # Demander l'instruction originale (en anglais)
    original = input(f"{YELLOW}📝 Instruction originale (en anglais): {NC}").strip()
    if not original:
        print(f"{RED}❌ L'instruction ne peut pas être vide{NC}")
        return
    
    # Vérifier si elle existe déjà
    existing = instructions_data.get('instructions', {}).get(original.lower())
    if existing:
        print(f"\n{GREEN}✓ Instruction existante trouvée:{NC}")
        print(f"  EN: {existing.get('en', original)}")
        print(f"  FR: {existing.get('fr', '')}")
        print(f"  ES: {existing.get('es', '')}")
        response = input(f"\n{YELLOW}Modifier cette traduction? (o/n): {NC}").strip().lower()
        if response != 'o':
            return
        current_fr = existing.get('fr', '')
        current_es = existing.get('es', '')
    else:
        current_fr = ''
        current_es = ''
    
    # Demander les traductions
    print(f"\n{YELLOW}Traductions (laisser vide pour garder l'original):{NC}")
    fr_translation = input(f"  🇫🇷 Français: {current_fr} → ").strip() or current_fr
    es_translation = input(f"  🇪🇸 Espagnol: {current_es} → ").strip() or current_es
    
    # Sauvegarder
    if 'instructions' not in instructions_data:
        instructions_data['instructions'] = {}
    
    instructions_data['instructions'][original.lower()] = {
        'en': original,
        'fr': fr_translation,
        'es': es_translation
    }
    
    # Mettre à jour les métadonnées
    instructions_data['metadata']['total_terms'] = len(instructions_data['instructions'])
    instructions_data['metadata']['last_updated'] = datetime.now().strftime("%Y-%m-%d")
    
    save_json_file(INSTRUCTIONS_FILE, instructions_data)
    print(f"\n{GREEN}✅ Traduction sauvegardée!{NC}")


def search_instructions():
    """Recherche des instructions"""
    instructions_data = init_instructions_file()
    
    print(f"\n{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{BLUE}🔍 Rechercher des instructions{NC}")
    print(f"{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")
    
    search = input(f"{YELLOW}Rechercher: {NC}").strip()
    if not search:
        return
    
    # Recherche exacte
    found = instructions_data.get('instructions', {}).get(search.lower())
    if found:
        print(f"\n{GREEN}✓ Trouvé (correspondance exacte):{NC}")
        print(f"  EN: {found.get('en', search)}")
        print(f"  FR: {found.get('fr', '')}")
        print(f"  ES: {found.get('es', '')}")
        return
    
    # Recherche partielle
    matches = []
    search_lower = search.lower()
    for key, translations in instructions_data.get('instructions', {}).items():
        if search_lower in key or search_lower in translations.get('en', '').lower():
            matches.append((key, translations))
    
    if matches:
        print(f"\n{GREEN}✓ {len(matches)} résultat(s) trouvé(s):{NC}")
        for i, (key, trans) in enumerate(matches[:10], 1):
            print(f"\n  {i}. EN: {trans.get('en', key)}")
            print(f"     FR: {trans.get('fr', '')}")
            print(f"     ES: {trans.get('es', '')}")
    else:
        # Recherche similaire
        similar = find_similar_instructions(instructions_data, search)
        if similar:
            print(f"\n{YELLOW}⚠ Aucune correspondance exacte, mais voici des instructions similaires:{NC}")
            for similarity, key, trans in similar:
                print(f"\n  • ({similarity:.0%}) EN: {trans.get('en', key)}")
                print(f"      FR: {trans.get('fr', '')}")
                print(f"      ES: {trans.get('es', '')}")
        else:
            print(f"\n{RED}❌ Aucune instruction trouvée{NC}")


def list_all_instructions():
    """Liste toutes les instructions"""
    instructions_data = init_instructions_file()
    
    instructions = instructions_data.get('instructions', {})
    if not instructions:
        print(f"\n{YELLOW}⚠ Aucune instruction enregistrée{NC}")
        return
    
    print(f"\n{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{BLUE}📋 Liste de toutes les instructions ({len(instructions)} au total){NC}")
    print(f"{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")
    
    for i, (key, trans) in enumerate(sorted(instructions.items()), 1):
        print(f"{i}. {GREEN}EN:{NC} {trans.get('en', key)}")
        print(f"   {YELLOW}FR:{NC} {trans.get('fr', '')}")
        print(f"   {BLUE}ES:{NC} {trans.get('es', '')}")
        print()


def improve_ingredient_translation():
    """Améliore une traduction d'ingrédient"""
    ingredients_data = load_json_file(INGREDIENTS_FILE)
    
    print(f"\n{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{BLUE}🍅 Améliorer une traduction d'ingrédient{NC}")
    print(f"{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")
    
    ingredient = input(f"{YELLOW}Ingrédient (en anglais): {NC}").strip().lower()
    if not ingredient:
        return
    
    if 'ingredients' not in ingredients_data:
        ingredients_data['ingredients'] = {}
    
    existing = ingredients_data['ingredients'].get(ingredient)
    if existing:
        print(f"\n{GREEN}✓ Ingrédient existant:{NC}")
        print(f"  EN: {existing.get('en', ingredient)}")
        print(f"  FR: {existing.get('fr', '')}")
        print(f"  ES: {existing.get('es', '')}")
        response = input(f"\n{YELLOW}Modifier? (o/n): {NC}").strip().lower()
        if response != 'o':
            return
        current_fr = existing.get('fr', '')
        current_es = existing.get('es', '')
    else:
        current_fr = ''
        current_es = ''
    
    print(f"\n{YELLOW}Nouvelles traductions:{NC}")
    fr_translation = input(f"  🇫🇷 Français: {current_fr} → ").strip() or current_fr
    es_translation = input(f"  🇪🇸 Espagnol: {current_es} → ").strip() or current_es
    
    ingredients_data['ingredients'][ingredient] = {
        'en': ingredient.capitalize(),
        'fr': fr_translation,
        'es': es_translation
    }
    
    ingredients_data['metadata']['total_terms'] = len(ingredients_data['ingredients'])
    ingredients_data['metadata']['last_updated'] = datetime.now().strftime("%Y-%m-%d")
    
    save_json_file(INGREDIENTS_FILE, ingredients_data)
    print(f"\n{GREEN}✅ Traduction sauvegardée!{NC}")


def show_statistics():
    """Affiche les statistiques des dictionnaires"""
    instructions_data = init_instructions_file()
    ingredients_data = load_json_file(INGREDIENTS_FILE)
    recipe_names_data = load_json_file(RECIPE_NAMES_FILE)
    
    print(f"\n{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{BLUE}📊 Statistiques des dictionnaires{NC}")
    print(f"{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")
    
    instructions_count = len(instructions_data.get('instructions', {}))
    ingredients_count = len(ingredients_data.get('ingredients', {}))
    recipe_names_count = len(recipe_names_data.get('recipe_names', {}))
    
    print(f"  📝 Instructions: {GREEN}{instructions_count}{NC}")
    print(f"  🍅 Ingrédients: {GREEN}{ingredients_count}{NC}")
    print(f"  🍳 Noms de recettes: {GREEN}{recipe_names_count}{NC}")
    print(f"\n  📅 Dernière mise à jour:")
    if instructions_data.get('metadata', {}).get('last_updated'):
        print(f"     Instructions: {instructions_data['metadata']['last_updated']}")
    if ingredients_data.get('metadata', {}).get('last_updated'):
        print(f"     Ingrédients: {ingredients_data['metadata']['last_updated']}")
    if recipe_names_data.get('metadata', {}).get('last_updated'):
        print(f"     Noms de recettes: {recipe_names_data['metadata']['last_updated']}")


def main():
    """Menu principal"""
    while True:
        print(f"\n{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
        print(f"{GREEN}🌍 Amélioration des Traductions de Recettes{NC}")
        print(f"{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")
        print(f"  1. {YELLOW}➕ Ajouter/Modifier une traduction d'instruction{NC}")
        print(f"  2. {YELLOW}🔍 Rechercher des instructions{NC}")
        print(f"  3. {YELLOW}📋 Lister toutes les instructions{NC}")
        print(f"  4. {YELLOW}🍅 Améliorer une traduction d'ingrédient{NC}")
        print(f"  5. {YELLOW}📊 Statistiques{NC}")
        print(f"  6. {RED}❌ Quitter{NC}\n")
        
        choice = input(f"{BLUE}Votre choix: {NC}").strip()
        
        if choice == '1':
            add_instruction_translation()
        elif choice == '2':
            search_instructions()
        elif choice == '3':
            list_all_instructions()
        elif choice == '4':
            improve_ingredient_translation()
        elif choice == '5':
            show_statistics()
        elif choice == '6':
            print(f"\n{GREEN}👋 Au revoir!{NC}\n")
            break
        else:
            print(f"{RED}❌ Choix invalide{NC}")


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{GREEN}👋 Au revoir!{NC}\n")
        sys.exit(0)

