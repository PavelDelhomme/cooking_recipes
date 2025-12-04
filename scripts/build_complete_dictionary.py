#!/usr/bin/env python3
"""
Script pour construire un dictionnaire culinaire complet
en téléchargeant toutes les données depuis TheMealDB
"""

import json
import requests
import time
from collections import defaultdict
from pathlib import Path

# Configuration
THEMEALDB_API = "https://www.themealdb.com/api/json/v1/1"
OUTPUT_DIR = Path(__file__).parent.parent / "frontend" / "lib" / "data" / "culinary_dictionaries"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Dictionnaire de traduction manuel pour les termes courants
TRANSLATIONS = {
    'en': {
        'fr': {
            'chicken': 'poulet', 'beef': 'bœuf', 'pork': 'porc', 'lamb': 'agneau',
            'salmon': 'saumon', 'tuna': 'thon', 'cod': 'morue', 'fish': 'poisson',
            'tomato': 'tomate', 'onion': 'oignon', 'garlic': 'ail', 'carrot': 'carotte',
            'potato': 'pomme de terre', 'pepper': 'poivron', 'rice': 'riz', 'pasta': 'pâtes',
            'bread': 'pain', 'cheese': 'fromage', 'milk': 'lait', 'egg': 'œuf',
            'salt': 'sel', 'pepper': 'poivre', 'oil': 'huile', 'butter': 'beurre',
            'soup': 'soupe', 'salad': 'salade', 'curry': 'curry', 'stew': 'ragoût',
            'burger': 'burger', 'pizza': 'pizza', 'cake': 'gâteau', 'pie': 'tarte',
        },
        'es': {
            'chicken': 'pollo', 'beef': 'carne de res', 'pork': 'cerdo', 'lamb': 'cordero',
            'salmon': 'salmón', 'tuna': 'atún', 'cod': 'bacalao', 'fish': 'pescado',
            'tomato': 'tomate', 'onion': 'cebolla', 'garlic': 'ajo', 'carrot': 'zanahoria',
            'potato': 'patata', 'pepper': 'pimiento', 'rice': 'arroz', 'pasta': 'pasta',
            'bread': 'pan', 'cheese': 'queso', 'milk': 'leche', 'egg': 'huevo',
            'salt': 'sal', 'pepper': 'pimienta', 'oil': 'aceite', 'butter': 'mantequilla',
            'soup': 'sopa', 'salad': 'ensalada', 'curry': 'curry', 'stew': 'estofado',
            'burger': 'hamburguesa', 'pizza': 'pizza', 'cake': 'pastel', 'pie': 'tarta',
        }
    }
}

def translate_term(term, target_lang):
    """Traduit un terme en utilisant le dictionnaire de traduction"""
    term_lower = term.lower().strip()
    
    # Chercher dans les traductions manuelles
    if target_lang == 'fr' and term_lower in TRANSLATIONS['en']['fr']:
        return TRANSLATIONS['en']['fr'][term_lower]
    elif target_lang == 'es' and term_lower in TRANSLATIONS['en']['es']:
        return TRANSLATIONS['en']['es'][term_lower]
    
    # Si pas de traduction, retourner le terme original
    return term

def fetch_all_ingredients():
    """Récupère tous les ingrédients depuis TheMealDB"""
    print("📥 Téléchargement de tous les ingrédients depuis TheMealDB...")
    
    ingredients = set()
    
    # Récupérer des recettes aléatoires pour extraire les ingrédients
    print("   Récupération de 100 recettes aléatoires...")
    for i in range(100):
        if (i + 1) % 10 == 0:
            print(f"   Progression: {i + 1}/100...")
        
        try:
            response = requests.get(f"{THEMEALDB_API}/random.php", timeout=5)
            if response.status_code == 200:
                data = response.json()
                if 'meals' in data and data['meals']:
                    meal = data['meals'][0]
                    # Extraire tous les ingrédients
                    for j in range(1, 21):
                        ingredient_key = f'strIngredient{j}'
                        if ingredient_key in meal and meal[ingredient_key]:
                            ingredient = meal[ingredient_key].strip()
                            if ingredient:
                                ingredients.add(ingredient)
            time.sleep(0.2)  # Éviter de surcharger l'API
        except Exception as e:
            print(f"   ⚠️  Erreur lors de la récupération: {e}")
            continue
    
    print(f"✅ {len(ingredients)} ingrédients uniques trouvés")
    return sorted(ingredients)

def fetch_all_recipe_names():
    """Récupère tous les noms de recettes depuis TheMealDB"""
    print("📥 Téléchargement de tous les noms de recettes depuis TheMealDB...")
    
    recipe_names = set()
    
    # Récupérer par catégorie
    categories = ['Beef', 'Chicken', 'Dessert', 'Lamb', 'Miscellaneous', 'Pasta', 'Pork', 'Seafood', 'Side', 'Starter', 'Vegan', 'Vegetarian', 'Breakfast', 'Goat']
    
    for category in categories:
        print(f"   Récupération des recettes de la catégorie: {category}...")
        try:
            response = requests.get(f"{THEMEALDB_API}/filter.php?c={category}", timeout=5)
            if response.status_code == 200:
                data = response.json()
                if 'meals' in data:
                    for meal in data['meals']:
                        if 'strMeal' in meal:
                            recipe_names.add(meal['strMeal'])
            time.sleep(0.2)
        except Exception as e:
            print(f"   ⚠️  Erreur pour {category}: {e}")
            continue
    
    print(f"✅ {len(recipe_names)} noms de recettes trouvés")
    return sorted(recipe_names)

def build_ingredients_dictionary(ingredients):
    """Construit le dictionnaire d'ingrédients"""
    print("📚 Construction du dictionnaire d'ingrédients...")
    
    dictionary = {
        "metadata": {
            "version": "2.0.0",
            "source": "TheMealDB",
            "languages": ["en", "fr", "es"],
            "total_terms": len(ingredients),
            "last_updated": "2025-12-04"
        },
        "ingredients": {}
    }
    
    for ingredient in ingredients:
        dictionary["ingredients"][ingredient.lower()] = {
            "en": ingredient,
            "fr": translate_term(ingredient, 'fr'),
            "es": translate_term(ingredient, 'es')
        }
    
    return dictionary

def build_recipe_names_dictionary(recipe_names):
    """Construit le dictionnaire de noms de recettes"""
    print("📚 Construction du dictionnaire de noms de recettes...")
    
    dictionary = {
        "metadata": {
            "version": "2.0.0",
            "source": "TheMealDB",
            "languages": ["en", "fr", "es"],
            "total_terms": len(recipe_names),
            "last_updated": "2025-12-04"
        },
        "recipe_names": {}
    }
    
    for recipe_name in recipe_names:
        dictionary["recipe_names"][recipe_name.lower()] = {
            "en": recipe_name,
            "fr": translate_term(recipe_name, 'fr'),
            "es": translate_term(recipe_name, 'es')
        }
    
    return dictionary

def main():
    print("🚀 Construction du dictionnaire culinaire complet...")
    print("")
    
    # Récupérer les données
    ingredients = fetch_all_ingredients()
    recipe_names = fetch_all_recipe_names()
    
    print("")
    
    # Construire les dictionnaires
    ingredients_dict = build_ingredients_dictionary(ingredients)
    recipe_names_dict = build_recipe_names_dictionary(recipe_names)
    
    # Sauvegarder
    ingredients_file = OUTPUT_DIR / "ingredients_fr_en_es.json"
    recipe_names_file = OUTPUT_DIR / "recipe_names_fr_en_es.json"
    
    with open(ingredients_file, 'w', encoding='utf-8') as f:
        json.dump(ingredients_dict, f, ensure_ascii=False, indent=2)
    
    with open(recipe_names_file, 'w', encoding='utf-8') as f:
        json.dump(recipe_names_dict, f, ensure_ascii=False, indent=2)
    
    print("")
    print("✅ Dictionnaires créés avec succès !")
    print(f"   📁 {ingredients_file}")
    print(f"      - {len(ingredients)} ingrédients")
    print(f"   📁 {recipe_names_file}")
    print(f"      - {len(recipe_names)} noms de recettes")
    print("")
    print("💡 Note: Les traductions automatiques sont basiques.")
    print("   Vous pouvez améliorer les traductions en éditant les fichiers JSON.")

if __name__ == '__main__':
    main()

