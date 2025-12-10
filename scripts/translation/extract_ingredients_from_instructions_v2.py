#!/usr/bin/env python3
"""
Script amélioré pour extraire les VRAIS ingrédients des instructions
et les ajouter au dictionnaire
"""

import json
import re
import requests
import time
from pathlib import Path

# Dictionnaire de traductions pour les ingrédients spécifiques trouvés dans les instructions
INGREDIENT_TRANSLATIONS = {
    "panko breadcrumbs": {"fr": "Chapelure panko", "es": "Pan rallado panko"},
    "panko": {"fr": "Panko", "es": "Panko"},
    "cornstarch": {"fr": "Fécule de maïs", "es": "Maicena"},
    "corn starch": {"fr": "Fécule de maïs", "es": "Maicena"},
    "baking powder": {"fr": "Levure chimique", "es": "Polvo de hornear"},
    "baking soda": {"fr": "Bicarbonate de soude", "es": "Bicarbonato de sodio"},
    "cooking spray": {"fr": "Vaporisateur de cuisson", "es": "Spray de cocción"},
    "nonstick spray": {"fr": "Vaporisateur antiadhésif", "es": "Spray antiadherente"},
    "soy sauce": {"fr": "Sauce soja", "es": "Salsa de soja"},
    "oyster sauce": {"fr": "Sauce aux huîtres", "es": "Salsa de ostras"},
    "fish sauce": {"fr": "Sauce de poisson", "es": "Salsa de pescado"},
    "hoisin sauce": {"fr": "Sauce hoisin", "es": "Salsa hoisin"},
    "worcestershire sauce": {"fr": "Sauce Worcestershire", "es": "Salsa Worcestershire"},
    "hot sauce": {"fr": "Sauce piquante", "es": "Salsa picante"},
    "sriracha": {"fr": "Sriracha", "es": "Sriracha"},
    "tahini": {"fr": "Tahini", "es": "Tahini"},
    "mirin": {"fr": "Mirin", "es": "Mirin"},
    "sake": {"fr": "Saké", "es": "Sake"},
    "rice wine": {"fr": "Vin de riz", "es": "Vino de arroz"},
    "rice vinegar": {"fr": "Vinaigre de riz", "es": "Vinagre de arroz"},
    "sesame oil": {"fr": "Huile de sésame", "es": "Aceite de sésamo"},
    "coconut oil": {"fr": "Huile de coco", "es": "Aceite de coco"},
    "canola oil": {"fr": "Huile de colza", "es": "Aceite de canola"},
    "vegetable broth": {"fr": "Bouillon de légumes", "es": "Caldo de verduras"},
    "chicken broth": {"fr": "Bouillon de poulet", "es": "Caldo de pollo"},
    "beef broth": {"fr": "Bouillon de bœuf", "es": "Caldo de res"},
    "vegetable stock": {"fr": "Bouillon de légumes", "es": "Caldo de verduras"},
    "chicken stock": {"fr": "Bouillon de poulet", "es": "Caldo de pollo"},
    "beef stock": {"fr": "Bouillon de bœuf", "es": "Caldo de res"},
}

# Mots-clés qui indiquent un ingrédient
INGREDIENT_KEYWORDS = [
    'breadcrumbs', 'panko', 'cornstarch', 'corn starch', 'baking powder', 'baking soda',
    'sauce', 'paste', 'oil', 'vinegar', 'wine', 'broth', 'stock', 'cream', 'butter',
    'cheese', 'flour', 'sugar', 'salt', 'pepper', 'spice', 'herb', 'extract', 'spray',
    'powder', 'soda', 'juice', 'milk', 'yogurt', 'tofu', 'tempeh', 'seitan'
]

def extract_real_ingredients(text):
    """Extrait les VRAIS ingrédients du texte (pas des phrases)"""
    found = set()
    text_lower = text.lower()
    
    # Pattern 1: Mots composés connus (2-3 mots max)
    known_patterns = [
        r'\b(panko(?:\s+breadcrumbs?)?)\b',
        r'\b(corn\s*starch)\b',
        r'\b(baking\s+(?:powder|soda))\b',
        r'\b(cooking\s+spray)\b',
        r'\b(nonstick\s+spray)\b',
        r'\b(soy\s+sauce)\b',
        r'\b(oyster\s+sauce)\b',
        r'\b(fish\s+sauce)\b',
        r'\b(hoisin\s+sauce)\b',
        r'\b(worcestershire\s+sauce)\b',
        r'\b(hot\s+sauce)\b',
        r'\b(sriracha)\b',
        r'\b(tahini)\b',
        r'\b(mirin)\b',
        r'\b(sake)\b',
        r'\b(rice\s+(?:wine|vinegar))\b',
        r'\b(sesame\s+oil)\b',
        r'\b(coconut\s+oil)\b',
        r'\b(canola\s+oil)\b',
        r'\b(vegetable\s+(?:broth|stock))\b',
        r'\b(chicken\s+(?:broth|stock))\b',
        r'\b(beef\s+(?:broth|stock))\b',
    ]
    
    for pattern in known_patterns:
        matches = re.finditer(pattern, text_lower, re.IGNORECASE)
        for match in matches:
            ingredient = match.group(1).strip()
            if len(ingredient.split()) <= 3:  # Max 3 mots
                found.add(ingredient)
    
    # Pattern 2: Mot + keyword (ex: "panko breadcrumbs", "olive oil")
    for keyword in INGREDIENT_KEYWORDS:
        # Avant le keyword
        pattern_before = rf'\b([a-z]+(?:\s+[a-z]+)?)\s+{keyword}\b'
        matches = re.finditer(pattern_before, text_lower)
        for match in matches:
            prefix = match.group(1).strip()
            if len(prefix.split()) <= 2:  # Max 2 mots avant
                ingredient = f"{prefix} {keyword}"
                found.add(ingredient)
        
        # Après le keyword (ex: "breadcrumbs panko" - moins commun)
        pattern_after = rf'\b{keyword}\s+([a-z]+(?:\s+[a-z]+)?)\b'
        matches = re.finditer(pattern_after, text_lower)
        for match in matches:
            suffix = match.group(1).strip()
            if len(suffix.split()) <= 2:
                ingredient = f"{keyword} {suffix}"
                found.add(ingredient)
    
    return found

def fetch_recipes_from_themealdb():
    """Récupère des recettes variées depuis TheMealDB"""
    base_url = "https://www.themealdb.com/api/json/v1/1"
    recipes = []
    
    # Termes de recherche variés
    search_terms = [
        "chicken", "beef", "pork", "fish", "pasta", "rice", "bread",
        "cake", "soup", "salad", "curry", "stir", "fried", "baked"
    ]
    
    print(f"📥 Récupération de recettes depuis TheMealDB...")
    
    for term in search_terms:
        try:
            url = f"{base_url}/search.php?s={term}"
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get('meals'):
                    recipes.extend(data['meals'][:3])  # Limiter à 3 par terme
            time.sleep(0.2)
        except:
            continue
    
    # Dédupliquer
    seen_ids = set()
    unique_recipes = []
    for recipe in recipes:
        recipe_id = recipe.get('idMeal')
        if recipe_id and recipe_id not in seen_ids:
            seen_ids.add(recipe_id)
            unique_recipes.append(recipe)
    
    print(f"✅ {len(unique_recipes)} recettes récupérées")
    return unique_recipes

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_file = project_root / "frontend" / "lib" / "data" / "culinary_dictionaries" / "ingredients_fr_en_es.json"
    
    if not json_file.exists():
        print(f"❌ Fichier non trouvé: {json_file}")
        return
    
    # Lire le dictionnaire
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    existing_ingredients = {k.lower() for k in data.get("ingredients", {}).keys()}
    print(f"📚 {len(existing_ingredients)} ingrédients déjà dans le dictionnaire")
    
    # Récupérer des recettes
    recipes = fetch_recipes_from_themealdb()
    
    # Extraire les ingrédients
    found_ingredients = set()
    for recipe in recipes:
        instructions = recipe.get('strInstructions', '')
        if instructions:
            ingredients = extract_real_ingredients(instructions)
            found_ingredients.update(ingredients)
    
    print(f"🔍 {len(found_ingredients)} ingrédients trouvés dans les instructions")
    
    # Filtrer ceux qui ne sont pas déjà dans le dictionnaire
    new_ingredients = {}
    for ingredient in found_ingredients:
        ingredient_lower = ingredient.lower().strip()
        
        # Vérifier si déjà présent
        is_present = any(
            ingredient_lower == existing.lower() or 
            ingredient_lower in existing.lower() or 
            existing.lower() in ingredient_lower
            for existing in existing_ingredients
        )
        
        if not is_present and len(ingredient.split()) <= 3:  # Max 3 mots
            # Chercher dans les traductions
            if ingredient_lower in INGREDIENT_TRANSLATIONS:
                translations = INGREDIENT_TRANSLATIONS[ingredient_lower]
                new_ingredients[ingredient_lower] = {
                    "en": ingredient.title(),
                    "fr": translations["fr"],
                    "es": translations["es"]
                }
            else:
                # Traduction basique (à améliorer)
                new_ingredients[ingredient_lower] = {
                    "en": ingredient.title(),
                    "fr": ingredient.title(),
                    "es": ingredient.title()
                }
    
    if new_ingredients:
        # Ajouter au dictionnaire
        data["ingredients"].update(new_ingredients)
        data["metadata"]["total_terms"] = len(data["ingredients"])
        
        # Sauvegarder
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"\n✅ {len(new_ingredients)} nouveaux ingrédients ajoutés:")
        for ing, trans in sorted(new_ingredients.items()):
            print(f"   - {ing}: FR={trans['fr']}, ES={trans['es']}")
    else:
        print("\n✅ Aucun nouvel ingrédient trouvé")

if __name__ == "__main__":
    main()

