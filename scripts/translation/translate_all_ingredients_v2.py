#!/usr/bin/env python3
"""
Script amélioré pour traduire TOUS les ingrédients manquants
avec un dictionnaire complet et des règles intelligentes
"""

import json
from pathlib import Path

# Dictionnaire COMPLET de traductions
COMPLETE_TRANSLATIONS = {
    # Fruits
    "almond essence": {"fr": "Arôme d'amande", "es": "Esencia de almendra"},
    "almonds": {"fr": "Amandes", "es": "Almendras"},
    "aubergine": {"fr": "Aubergine", "es": "Berenjena"},
    "banana": {"fr": "Banane", "es": "Plátano"},
    "orange": {"fr": "Orange", "es": "Naranja"},
    "lemon": {"fr": "Citron", "es": "Limón"},
    "lime": {"fr": "Citron vert", "es": "Lima"},
    "strawberries": {"fr": "Fraises", "es": "Fresas"},
    "raspberries": {"fr": "Framboises", "es": "Frambuesas"},
    "prunes": {"fr": "Pruneaux", "es": "Ciruelas pasas"},
    "raisins": {"fr": "Raisins secs", "es": "Pasas"},
    
    # Légumes
    "broccoli": {"fr": "Brocoli", "es": "Brócoli"},
    "spinach": {"fr": "Épinards", "es": "Espinacas"},
    "lettuce": {"fr": "Laitue", "es": "Lechuga"},
    "onions": {"fr": "Oignons", "es": "Cebollas"},
    "tomatoes": {"fr": "Tomates", "es": "Tomates"},
    "potatoes": {"fr": "Pommes de terre", "es": "Patatas"},
    "mushrooms": {"fr": "Champignons", "es": "Champiñones"},
    "peas": {"fr": "Pois", "es": "Guisantes"},
    "sweetcorn": {"fr": "Maïs doux", "es": "Maíz dulce"},
    "beetroot": {"fr": "Betterave", "es": "Remolacha"},
    
    # Viandes
    "bacon": {"fr": "Bacon", "es": "Tocino"},
    "chorizo": {"fr": "Chorizo", "es": "Chorizo"},
    "sausages": {"fr": "Saucisses", "es": "Salchichas"},
    "beef brisket": {"fr": "Poitrine de bœuf", "es": "Pecho de res"},
    "beef cutlet": {"fr": "Côtelette de bœuf", "es": "Chuleta de res"},
    
    # Fromages et produits laitiers
    "gruyère": {"fr": "Gruyère", "es": "Gruyère"},
    "mascarpone": {"fr": "Mascarpone", "es": "Mascarpone"},
    "mayonnaise": {"fr": "Mayonnaise", "es": "Mayonesa"},
    "creme fraiche": {"fr": "Crème fraîche", "es": "Crema fresca"},
    "parmesan": {"fr": "Parmesan", "es": "Parmesano"},
    "parmigiano-reggiano": {"fr": "Parmigiano-Reggiano", "es": "Parmigiano-Reggiano"},
    "pecorino": {"fr": "Pecorino", "es": "Pecorino"},
    "ricotta": {"fr": "Ricotta", "es": "Ricotta"},
    "paneer": {"fr": "Paneer", "es": "Paneer"},
    
    # Épices et herbes
    "cardamom": {"fr": "Cardamome", "es": "Cardamomo"},
    "chives": {"fr": "Ciboulette", "es": "Cebollino"},
    "paprika": {"fr": "Paprika", "es": "Pimentón"},
    "basil leaves": {"fr": "Feuilles de basilic", "es": "Hojas de albahaca"},
    "bay leaf": {"fr": "Feuille de laurier", "es": "Hoja de laurel"},
    "bay leaves": {"fr": "Feuilles de laurier", "es": "Hojas de laurel"},
    "thyme": {"fr": "Thym", "es": "Tomillo"},
    "rosemary": {"fr": "Romarin", "es": "Romero"},
    "sage": {"fr": "Sauge", "es": "Salvia"},
    "mint": {"fr": "Menthe", "es": "Menta"},
    "parsley": {"fr": "Persil", "es": "Perejil"},
    "oregano": {"fr": "Origan", "es": "Orégano"},
    "coriander": {"fr": "Coriandre", "es": "Cilantro"},
    "cumin": {"fr": "Cumin", "es": "Comino"},
    "turmeric": {"fr": "Curcuma", "es": "Cúrcuma"},
    "nutmeg": {"fr": "Muscade", "es": "Nuez moscada"},
    "saffron": {"fr": "Safran", "es": "Azafrán"},
    "cinnamon": {"fr": "Cannelle", "es": "Canela"},
    "ginger": {"fr": "Gingembre", "es": "Jengibre"},
    "clove": {"fr": "Clou de girofle", "es": "Clavo"},
    
    # Céréales et légumineuses
    "brown lentils": {"fr": "Lentilles brunes", "es": "Lentejas marrones"},
    "brown rice noodle": {"fr": "Nouille de riz brun", "es": "Fideo de arroz integral"},
    "bean sprouts": {"fr": "Germes de soja", "es": "Brotes de soja"},
    
    # Boissons
    "brandy": {"fr": "Cognac", "es": "Brandy"},
    "sake": {"fr": "Saké", "es": "Sake"},
    "mirin": {"fr": "Mirin", "es": "Mirin"},
    "stout": {"fr": "Stout", "es": "Stout"},
    
    # Autres
    "baguette": {"fr": "Baguette", "es": "Baguette"},
    "pak choi": {"fr": "Pak choi", "es": "Pak choi"},
    "tofu": {"fr": "Tofu", "es": "Tofu"},
    "hummus": {"fr": "Houmous", "es": "Hummus"},
    "tahini": {"fr": "Tahini", "es": "Tahini"},
}

def translate_ingredient(key, english_name):
    """Traduit un ingrédient avec règles intelligentes"""
    key_lower = key.lower().strip()
    en_lower = english_name.lower().strip()
    
    # Vérifier le dictionnaire complet
    if key_lower in COMPLETE_TRANSLATIONS:
        return COMPLETE_TRANSLATIONS[key_lower]
    
    # Règles de traduction par patterns
    if 'essence' in en_lower:
        base = en_lower.replace(' essence', '').replace('essence', '')
        return {
            "fr": f"Arôme de {translate_word(base, 'fr')}",
            "es": f"Esencia de {translate_word(base, 'es')}"
        }
    
    if 'leaves' in en_lower or 'leaf' in en_lower:
        base = en_lower.replace(' leaves', '').replace(' leaf', '').replace('leaves', '').replace('leaf', '')
        return {
            "fr": f"Feuilles de {translate_word(base, 'fr')}",
            "es": f"Hojas de {translate_word(base, 'es')}"
        }
    
    # Traduction simple par mot
    words = en_lower.split()
    if len(words) == 1:
        return {
            "fr": translate_word(words[0], 'fr').title(),
            "es": translate_word(words[0], 'es').title()
        }
    
    # Mots composés - traduire le dernier mot principal
    main_word = words[-1]
    fr_main = translate_word(main_word, 'fr')
    es_main = translate_word(main_word, 'es')
    
    prefix = ' '.join(words[:-1])
    return {
        "fr": f"{prefix.title()} {fr_main}" if prefix else fr_main.title(),
        "es": f"{prefix.title()} {es_main}" if prefix else es_main.title()
    }

def translate_word(word, lang='fr'):
    """Traduit un mot simple"""
    word_lower = word.lower().strip()
    
    translations = {
        'fr': {
            'cheese': 'fromage', 'cream': 'crème', 'butter': 'beurre', 'sugar': 'sucre',
            'salt': 'sel', 'pepper': 'poivre', 'oil': 'huile', 'flour': 'farine',
            'rice': 'riz', 'pasta': 'pâtes', 'bread': 'pain', 'sauce': 'sauce',
            'vinegar': 'vinaigre', 'wine': 'vin', 'stock': 'bouillon', 'broth': 'bouillon',
            'milk': 'lait', 'water': 'eau', 'juice': 'jus', 'lemon': 'citron',
            'lime': 'citron vert', 'orange': 'orange', 'apple': 'pomme', 'banana': 'banane',
            'tomato': 'tomate', 'onion': 'oignon', 'garlic': 'ail', 'carrot': 'carotte',
            'potato': 'pomme de terre', 'chicken': 'poulet', 'beef': 'bœuf', 'pork': 'porc',
            'fish': 'poisson', 'egg': 'œuf', 'mushroom': 'champignon', 'spinach': 'épinards',
            'almond': 'amande', 'almonds': 'amandes', 'broccoli': 'brocoli', 'lettuce': 'laitue',
            'onion': 'oignon', 'onions': 'oignons', 'tomato': 'tomate', 'tomatoes': 'tomates',
            'potato': 'pomme de terre', 'potatoes': 'pommes de terre', 'pea': 'pois', 'peas': 'pois',
            'mushroom': 'champignon', 'mushrooms': 'champignons', 'beetroot': 'betterave',
            'bacon': 'bacon', 'chorizo': 'chorizo', 'sausage': 'saucisse', 'sausages': 'saucisses',
            'brisket': 'poitrine', 'cutlet': 'côtelette', 'cardamom': 'cardamome',
            'chive': 'ciboulette', 'chives': 'ciboulette', 'paprika': 'paprika',
            'basil': 'basilic', 'bay': 'laurier', 'thyme': 'thym', 'rosemary': 'romarin',
            'sage': 'sauge', 'mint': 'menthe', 'parsley': 'persil', 'oregano': 'origan',
            'coriander': 'coriandre', 'cumin': 'cumin', 'turmeric': 'curcuma', 'nutmeg': 'muscade',
            'saffron': 'safran', 'cinnamon': 'cannelle', 'ginger': 'gingembre', 'clove': 'clou de girofle',
            'lentil': 'lentille', 'lentils': 'lentilles', 'sprout': 'germe', 'sprouts': 'germes',
            'noodle': 'nouille', 'noodles': 'nouilles', 'brandy': 'cognac', 'sake': 'saké',
            'mirin': 'mirin', 'stout': 'stout', 'baguette': 'baguette', 'tofu': 'tofu',
            'hummus': 'houmous', 'tahini': 'tahini',
        },
        'es': {
            'cheese': 'queso', 'cream': 'crema', 'butter': 'mantequilla', 'sugar': 'azúcar',
            'salt': 'sal', 'pepper': 'pimienta', 'oil': 'aceite', 'flour': 'harina',
            'rice': 'arroz', 'pasta': 'pasta', 'bread': 'pan', 'sauce': 'salsa',
            'vinegar': 'vinagre', 'wine': 'vino', 'stock': 'caldo', 'broth': 'caldo',
            'milk': 'leche', 'water': 'agua', 'juice': 'zumo', 'lemon': 'limón',
            'lime': 'lima', 'orange': 'naranja', 'apple': 'manzana', 'banana': 'plátano',
            'tomato': 'tomate', 'onion': 'cebolla', 'garlic': 'ajo', 'carrot': 'zanahoria',
            'potato': 'patata', 'chicken': 'pollo', 'beef': 'carne de res', 'pork': 'cerdo',
            'fish': 'pescado', 'egg': 'huevo', 'mushroom': 'champiñón', 'spinach': 'espinacas',
            'almond': 'almendra', 'almonds': 'almendras', 'broccoli': 'brócoli', 'lettuce': 'lechuga',
            'onion': 'cebolla', 'onions': 'cebollas', 'tomato': 'tomate', 'tomatoes': 'tomates',
            'potato': 'patata', 'potatoes': 'patatas', 'pea': 'guisante', 'peas': 'guisantes',
            'mushroom': 'champiñón', 'mushrooms': 'champiñones', 'beetroot': 'remolacha',
            'bacon': 'tocino', 'chorizo': 'chorizo', 'sausage': 'salchicha', 'sausages': 'salchichas',
            'brisket': 'pecho', 'cutlet': 'chuleta', 'cardamom': 'cardamomo',
            'chive': 'cebollino', 'chives': 'cebollino', 'paprika': 'pimentón',
            'basil': 'albahaca', 'bay': 'laurel', 'thyme': 'tomillo', 'rosemary': 'romero',
            'sage': 'salvia', 'mint': 'menta', 'parsley': 'perejil', 'oregano': 'orégano',
            'coriander': 'cilantro', 'cumin': 'comino', 'turmeric': 'cúrcuma', 'nutmeg': 'nuez moscada',
            'saffron': 'azafrán', 'cinnamon': 'canela', 'ginger': 'jengibre', 'clove': 'clavo',
            'lentil': 'lenteja', 'lentils': 'lentejas', 'sprout': 'brote', 'sprouts': 'brotes',
            'noodle': 'fideo', 'noodles': 'fideos', 'brandy': 'brandy', 'sake': 'sake',
            'mirin': 'mirin', 'stout': 'stout', 'baguette': 'baguette', 'tofu': 'tofu',
            'hummus': 'hummus', 'tahini': 'tahini',
        }
    }
    
    return translations.get(lang, {}).get(word_lower, word)

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_file = project_root / "frontend" / "lib" / "data" / "culinary_dictionaries" / "ingredients_fr_en_es.json"
    
    if not json_file.exists():
        print(f"❌ Fichier non trouvé: {json_file}")
        return
    
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    ingredients = data.get("ingredients", {})
    updated_fr = 0
    updated_es = 0
    
    print(f"📚 Traduction de {len(ingredients)} ingrédients...")
    print("")
    
    for key, value in ingredients.items():
        en_name = value.get("en", key).strip()
        fr_name = value.get("fr", "").strip()
        es_name = value.get("es", "").strip()
        
        changed = False
        
        # Vérifier FR
        if not fr_name or fr_name == en_name or fr_name.lower() == en_name.lower():
            translations = translate_ingredient(key, en_name)
            if translations["fr"] != fr_name:
                value["fr"] = translations["fr"]
                updated_fr += 1
                changed = True
        
        # Vérifier ES
        if not es_name or es_name == en_name or es_name.lower() == en_name.lower():
            translations = translate_ingredient(key, en_name)
            if translations["es"] != es_name:
                value["es"] = translations["es"]
                updated_es += 1
                changed = True
        
        if changed and (updated_fr + updated_es) <= 30:
            print(f"✓ {key}: FR={value['fr']}, ES={value['es']}")
    
    # Sauvegarder
    data["metadata"]["total_terms"] = len(ingredients)
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("")
    print(f"✅ {updated_fr} traductions FR ajoutées/corrigées")
    print(f"✅ {updated_es} traductions ES ajoutées/corrigées")
    print(f"📁 Fichier sauvegardé: {json_file}")

if __name__ == "__main__":
    main()

