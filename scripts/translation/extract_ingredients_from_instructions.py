#!/usr/bin/env python3
"""
Script pour extraire les ingrédients mentionnés dans les instructions des recettes
et les ajouter au dictionnaire s'ils n'y sont pas déjà
"""

import json
import re
import requests
import time
from pathlib import Path

# Dictionnaire de traductions pour les ingrédients courants trouvés dans les instructions
INGREDIENT_TRANSLATIONS = {
    "panko breadcrumbs": {"fr": "Chapelure panko", "es": "Pan rallado panko"},
    "breadcrumbs": {"fr": "Chapelure", "es": "Pan rallado"},
    "panko": {"fr": "Panko", "es": "Panko"},
    "cornstarch": {"fr": "Fécule de maïs", "es": "Maicena"},
    "corn starch": {"fr": "Fécule de maïs", "es": "Maicena"},
    "baking powder": {"fr": "Levure chimique", "es": "Polvo de hornear"},
    "baking soda": {"fr": "Bicarbonate de soude", "es": "Bicarbonato de sodio"},
    "vanilla extract": {"fr": "Extrait de vanille", "es": "Extracto de vainilla"},
    "olive oil": {"fr": "Huile d'olive", "es": "Aceite de oliva"},
    "vegetable oil": {"fr": "Huile végétale", "es": "Aceite vegetal"},
    "cooking spray": {"fr": "Vaporisateur de cuisson", "es": "Spray de cocción"},
    "nonstick spray": {"fr": "Vaporisateur antiadhésif", "es": "Spray antiadherente"},
}

def extract_ingredient_like_words(text):
    """Extrait les mots qui ressemblent à des ingrédients du texte"""
    # Mots à ignorer (verbes, prépositions, etc.)
    stop_words = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
        'by', 'from', 'up', 'about', 'into', 'through', 'during', 'including', 'until',
        'against', 'among', 'throughout', 'despite', 'towards', 'upon', 'concerning',
        'add', 'mix', 'stir', 'cook', 'bake', 'fry', 'boil', 'heat', 'pour', 'cut',
        'chop', 'slice', 'dice', 'mince', 'grate', 'peel', 'remove', 'place', 'put',
        'set', 'let', 'allow', 'cover', 'uncover', 'turn', 'flip', 'serve', 'garnish',
        'season', 'taste', 'adjust', 'continue', 'until', 'when', 'while', 'if', 'then',
        'step', 'minutes', 'hours', 'degrees', 'fahrenheit', 'celsius', 'preheat', 'oven',
        'pan', 'pot', 'bowl', 'plate', 'serving', 'garnish', 'optional', 'taste', 'salt',
        'pepper', 'season', 'adjust', 'taste', 'serve', 'hot', 'cold', 'warm', 'room',
        'temperature', 'medium', 'high', 'low', 'heat', 'flame', 'simmer', 'boil',
    }
    
    # Pattern pour trouver des groupes de mots qui ressemblent à des ingrédients
    # Format: "mot1 mot2" ou "mot1-mot2" (2-4 mots max)
    patterns = [
        r'\b([a-z]+(?:\s+[a-z]+){0,2})\s+(?:breadcrumbs?|crumbs?|powder|soda|extract|oil|spray|sauce|paste|juice|cream|butter|cheese|flour|sugar|salt|pepper|vinegar|wine|stock|broth)\b',
        r'\b(panko|breadcrumbs?|cornstarch|baking\s+powder|baking\s+soda|vanilla\s+extract|olive\s+oil|vegetable\s+oil|cooking\s+spray)\b',
        r'\b([a-z]+(?:\s+[a-z]+)?)\s+(?:flour|sugar|salt|pepper|vinegar|wine|stock|broth|cream|butter|cheese|oil)\b',
    ]
    
    found_ingredients = set()
    text_lower = text.lower()
    
    for pattern in patterns:
        matches = re.finditer(pattern, text_lower, re.IGNORECASE)
        for match in matches:
            ingredient = match.group(1) if match.lastindex else match.group(0)
            ingredient = ingredient.strip()
            
            # Nettoyer et valider
            if len(ingredient) > 2 and len(ingredient.split()) <= 4:
                # Ignorer les stop words
                words = ingredient.split()
                if not all(word in stop_words for word in words):
                    found_ingredients.add(ingredient)
    
    return found_ingredients

def fetch_recipes_from_themealdb(num_recipes=50):
    """Récupère des recettes depuis TheMealDB"""
    base_url = "https://www.themealdb.com/api/json/v1/1"
    recipes = []
    
    print(f"📥 Récupération de {num_recipes} recettes depuis TheMealDB...")
    
    # Récupérer des recettes aléatoires
    for i in range(0, num_recipes, 10):
        try:
            url = f"{base_url}/random.php"
            # Récupérer 10 recettes aléatoires (on fait plusieurs appels)
            for _ in range(min(10, num_recipes - i)):
                response = requests.get(url, timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    if data.get('meals'):
                        recipes.extend(data['meals'])
                time.sleep(0.5)  # Éviter de surcharger l'API
        except Exception as e:
            print(f"⚠️  Erreur lors de la récupération: {e}")
            continue
    
    print(f"✅ {len(recipes)} recettes récupérées")
    return recipes

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_file = project_root / "frontend" / "lib" / "data" / "culinary_dictionaries" / "ingredients_fr_en_es.json"
    
    if not json_file.exists():
        print(f"❌ Fichier non trouvé: {json_file}")
        return
    
    # Lire le dictionnaire existant
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    existing_ingredients = set(data.get("ingredients", {}).keys())
    print(f"📚 {len(existing_ingredients)} ingrédients déjà dans le dictionnaire")
    
    # Récupérer des recettes
    recipes = fetch_recipes_from_ingredients_api()
    
    # Extraire les ingrédients des instructions
    found_ingredients = set()
    for recipe in recipes:
        instructions = recipe.get('strInstructions', '')
        if instructions:
            ingredients = extract_ingredient_like_words(instructions)
            found_ingredients.update(ingredients)
    
    print(f"🔍 {len(found_ingredients)} ingrédients potentiels trouvés dans les instructions")
    
    # Filtrer ceux qui ne sont pas déjà dans le dictionnaire
    new_ingredients = {}
    for ingredient in found_ingredients:
        ingredient_lower = ingredient.lower().strip()
        
        # Vérifier si déjà présent (avec variations)
        is_present = False
        for existing in existing_ingredients:
            if ingredient_lower in existing.lower() or existing.lower() in ingredient_lower:
                is_present = True
                break
        
        if not is_present:
            # Chercher dans les traductions prédéfinies
            if ingredient_lower in INGREDIENT_TRANSLATIONS:
                translations = INGREDIENT_TRANSLATIONS[ingredient_lower]
                new_ingredients[ingredient_lower] = {
                    "en": ingredient,
                    "fr": translations["fr"],
                    "es": translations["es"]
                }
            else:
                # Traduction basique (capitaliser)
                new_ingredients[ingredient_lower] = {
                    "en": ingredient.title(),
                    "fr": ingredient.title(),  # À améliorer manuellement
                    "es": ingredient.title()   # À améliorer manuellement
                }
    
    if new_ingredients:
        # Ajouter au dictionnaire
        data["ingredients"].update(new_ingredients)
        data["metadata"]["total_terms"] = len(data["ingredients"])
        
        # Sauvegarder
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"\n✅ {len(new_ingredients)} nouveaux ingrédients ajoutés:")
        for ing, trans in new_ingredients.items():
            print(f"   - {ing}: FR={trans['fr']}, ES={trans['es']}")
    else:
        print("\n✅ Aucun nouvel ingrédient trouvé")

def fetch_recipes_from_ingredients_api():
    """Récupère des recettes en utilisant différents ingrédients comme recherche"""
    base_url = "https://www.themealdb.com/api/json/v1/1"
    recipes = []
    
    # Ingrédients variés pour obtenir des recettes diverses
    search_terms = [
        "chicken", "beef", "pork", "fish", "pasta", "rice", "vegetable",
        "bread", "cake", "soup", "salad", "dessert", "pizza", "curry"
    ]
    
    print(f"📥 Récupération de recettes depuis TheMealDB...")
    
    for term in search_terms:
        try:
            url = f"{base_url}/search.php?s={term}"
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get('meals'):
                    recipes.extend(data['meals'][:5])  # Limiter à 5 par terme
            time.sleep(0.3)
        except Exception as e:
            continue
    
    # Dédupliquer par ID
    seen_ids = set()
    unique_recipes = []
    for recipe in recipes:
        recipe_id = recipe.get('idMeal')
        if recipe_id and recipe_id not in seen_ids:
            seen_ids.add(recipe_id)
            unique_recipes.append(recipe)
    
    print(f"✅ {len(unique_recipes)} recettes uniques récupérées")
    return unique_recipes

if __name__ == "__main__":
    main()

