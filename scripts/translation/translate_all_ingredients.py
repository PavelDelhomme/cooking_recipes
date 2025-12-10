#!/usr/bin/env python3
"""
Script pour traduire TOUS les ingrédients manquants dans ingredients_fr_en_es.json
Utilise un dictionnaire complet de traductions culinaires
"""

import json
import re
from pathlib import Path

# Dictionnaire complet de traductions FR/ES pour les ingrédients
TRANSLATIONS = {
    # Farines et céréales
    "all purpose flour": {"fr": "Farine tout usage", "es": "Harina para todo uso"},
    "plain flour": {"fr": "Farine ordinaire", "es": "Harina común"},
    "self-raising flour": {"fr": "Farine à lever", "es": "Harina con levadura"},
    "strong white bread flour": {"fr": "Farine de blé forte", "es": "Harina de trigo fuerte"},
    "cornstarch": {"fr": "Fécule de maïs", "es": "Maicena"},
    "corn starch": {"fr": "Fécule de maïs", "es": "Maicena"},
    
    # Sucres
    "icing sugar": {"fr": "Sucre glace", "es": "Azúcar glas"},
    "light brown soft sugar": {"fr": "Sucre roux clair", "es": "Azúcar moreno claro"},
    "dark brown soft sugar": {"fr": "Sucre brun foncé", "es": "Azúcar moreno oscuro"},
    "dark soft brown sugar": {"fr": "Sucre roux foncé", "es": "Azúcar moreno oscuro"},
    "muscovado sugar": {"fr": "Sucre muscovado", "es": "Azúcar muscovado"},
    "palm sugar": {"fr": "Sucre de palme", "es": "Azúcar de palma"},
    
    # Huiles
    "extra virgin olive oil": {"fr": "Huile d'olive extra vierge", "es": "Aceite de oliva extra virgen"},
    "sesame seed oil": {"fr": "Huile de sésame", "es": "Aceite de sésamo"},
    "sunflower oil": {"fr": "Huile de tournesol", "es": "Aceite de girasol"},
    "coconut oil": {"fr": "Huile de coco", "es": "Aceite de coco"},
    "canola oil": {"fr": "Huile de colza", "es": "Aceite de canola"},
    
    # Pains et produits de boulangerie
    "sesame seed burger buns": {"fr": "Pains à hamburger aux graines de sésame", "es": "Bollos de hamburguesa con semillas de sésamo"},
    "naan bread": {"fr": "Pain naan", "es": "Pan naan"},
    "pita bread": {"fr": "Pain pita", "es": "Pan pita"},
    "white bread": {"fr": "Pain blanc", "es": "Pan blanco"},
    "wholegrain bread": {"fr": "Pain complet", "es": "Pan integral"},
    "toast": {"fr": "Pain grillé", "es": "Tostada"},
    "corn tortillas": {"fr": "Tortillas de maïs", "es": "Tortillas de maíz"},
    
    # Fromages
    "shredded monterey jack cheese": {"fr": "Fromage Monterey Jack râpé", "es": "Queso Monterey Jack rallado"},
    "cheddar cheese": {"fr": "Fromage cheddar", "es": "Queso cheddar"},
    "parmesan cheese": {"fr": "Fromage parmesan", "es": "Queso parmesano"},
    "mozzarella balls": {"fr": "Boules de mozzarella", "es": "Bolas de mozzarella"},
    
    # Viandes
    "minced beef": {"fr": "Bœuf haché", "es": "Carne de res picada"},
    "minced pork": {"fr": "Porc haché", "es": "Cerdo picado"},
    "lamb mince": {"fr": "Viande d'agneau hachée", "es": "Carne de cordero picada"},
    "ground pork": {"fr": "Porc haché", "es": "Cerdo picado"},
    "pork shoulder": {"fr": "Épaule de porc", "es": "Paleta de cerdo"},
    "pork shoulder steaks": {"fr": "Steaks d'épaule de porc", "es": "Filetes de paleta de cerdo"},
    "lamb leg": {"fr": "Gigot d'agneau", "es": "Pierna de cordero"},
    "lamb loin chops": {"fr": "Côtelettes d'agneau", "es": "Chuletas de cordero"},
    "lamb kidney": {"fr": "Rognon d'agneau", "es": "Riñón de cordero"},
    "sirloin steak": {"fr": "Entrecôte", "es": "Entrecot"},
    "skirty steak": {"fr": "Steak de bavette", "es": "Filete de falda"},
    
    # Poissons et fruits de mer
    "smoked haddock": {"fr": "Églefin fumé", "es": "Eglefino ahumado"},
    "raw king prawns": {"fr": "Gambas royales crues", "es": "Gambas reales crudas"},
    "tiger prawns": {"fr": "Crevettes tigrées", "es": "Gambas tigre"},
    
    # Légumes
    "new potatoes": {"fr": "Pommes de terre nouvelles", "es": "Patatas nuevas"},
    "small potatoes": {"fr": "Petites pommes de terre", "es": "Patatas pequeñas"},
    "russet potato": {"fr": "Pomme de terre rousse", "es": "Patata roja"},
    "sweet potatoes": {"fr": "Patates douces", "es": "Batatas"},
    "plum tomatoes": {"fr": "Tomates prune", "es": "Tomates ciruela"},
    "tinned tomatos": {"fr": "Tomates en conserve", "es": "Tomates enlatados"},
    "red onions": {"fr": "Oignons rouges", "es": "Cebollas rojas"},
    "spring onions": {"fr": "Oignons nouveaux", "es": "Cebolletas"},
    "purple sprouting broccoli": {"fr": "Brocoli violet", "es": "Brócoli morado"},
    "white cabbage": {"fr": "Chou blanc", "es": "Repollo blanco"},
    "iceberg lettuce": {"fr": "Laitue iceberg", "es": "Lechuga iceberg"},
    "pak choi": {"fr": "Pak choi", "es": "Pak choi"},
    "fennel bulb": {"fr": "Bulbe de fenouil", "es": "Bulbo de hinojo"},
    "swede": {"fr": "Rutabaga", "es": "Nabo sueco"},
    
    # Fruits
    "stoned dates": {"fr": "Dattes dénoyautées", "es": "Dátiles sin hueso"},
    "orange blossom water": {"fr": "Eau de fleur d'oranger", "es": "Agua de azahar"},
    
    # Pâtes et riz
    "lasagne sheets": {"fr": "Feuilles de lasagnes", "es": "Láminas de lasaña"},
    "linguine pasta": {"fr": "Pâtes linguine", "es": "Pasta linguine"},
    "penne rigate": {"fr": "Pennes rigate", "es": "Penne rigate"},
    "rice noodles": {"fr": "Nouilles de riz", "es": "Fideos de arroz"},
    "vermicelli rice noodles": {"fr": "Nouilles vermicelles de riz", "es": "Fideos vermicelli de arroz"},
    "rice paper sheets": {"fr": "Feuilles de papier de riz", "es": "Hojas de papel de arroz"},
    "basmati rice": {"fr": "Riz basmati", "es": "Arroz basmati"},
    "sushi rice": {"fr": "Riz à sushi", "es": "Arroz para sushi"},
    "porridge oats": {"fr": "Flocons d'avoine", "es": "Copos de avena"},
    "rolled oats": {"fr": "Flocons d'avoine", "es": "Copos de avena"},
    "mixed grain": {"fr": "Céréales mélangées", "es": "Cereales mixtas"},
    
    # Épices et herbes
    "dried leaves of summer savoury": {"fr": "Feuilles séchées de sarriette", "es": "Hojas secas de ajedrea"},
    "lime leaves": {"fr": "Feuilles de citron vert", "es": "Hojas de lima"},
    "vine leaves": {"fr": "Feuilles de vigne", "es": "Hojas de parra"},
    "thai red curry paste": {"fr": "Pâte de curry rouge thaï", "es": "Pasta de curry rojo tailandés"},
    "fajita seasoning": {"fr": "Assaisonnement pour fajitas", "es": "Condimento para fajitas"},
    "italian seasoning": {"fr": "Assaisonnement italien", "es": "Condimento italiano"},
    "red chilli flakes": {"fr": "Flocons de piment rouge", "es": "Copos de chile rojo"},
    "chilli powder": {"fr": "Piment en poudre", "es": "Chile en polvo"},
    
    # Produits laitiers
    "melted butter": {"fr": "Beurre fondu", "es": "Mantequilla derretida"},
    "salted butter": {"fr": "Beurre salé", "es": "Mantequilla salada"},
    "heavy cream": {"fr": "Crème épaisse", "es": "Crema espesa"},
    "whipping cream": {"fr": "Crème à fouetter", "es": "Crema para batir"},
    "sour cream": {"fr": "Crème fraîche", "es": "Crema agria"},
    
    # Sauces et condiments
    "oyster sauce": {"fr": "Sauce aux huîtres", "es": "Salsa de ostras"},
    "fish sauce": {"fr": "Sauce de poisson", "es": "Salsa de pescado"},
    "red wine vinegar": {"fr": "Vinaigre de vin rouge", "es": "Vinagre de vino tinto"},
    "white wine vinegar": {"fr": "Vinaigre de vin blanc", "es": "Vinagre de vino blanco"},
    "rice vinegar": {"fr": "Vinaigre de riz", "es": "Vinagre de arroz"},
    "red wine jelly": {"fr": "Gelée de vin rouge", "es": "Mermelada de vino tinto"},
    
    # Bouillons
    "chicken stock": {"fr": "Bouillon de poulet", "es": "Caldo de pollo"},
    "beef stock": {"fr": "Bouillon de bœuf", "es": "Caldo de res"},
    "vegetable stock": {"fr": "Bouillon de légumes", "es": "Caldo de verduras"},
    
    # Autres
    "cooking spray": {"fr": "Vaporisateur de cuisson", "es": "Spray de cocción"},
    "nonstick spray": {"fr": "Vaporisateur antiadhésif", "es": "Spray antiadherente"},
    "baking powder": {"fr": "Levure chimique", "es": "Polvo de hornear"},
    "baking soda": {"fr": "Bicarbonate de soude", "es": "Bicarbonato de sodio"},
    "ginger cordial": {"fr": "Sirop de gingembre", "es": "Jarabe de jengibre"},
    "meringue nests": {"fr": "Nids de meringue", "es": "Nidos de merengue"},
    "sweet peppadew peppers": {"fr": "Poivrons Peppadew doux", "es": "Pimientos Peppadew dulces"},
}

def translate_word(word, lang='fr'):
    """Traduit un mot simple"""
    word_lower = word.lower().strip()
    
    # Traductions simples
    simple_translations = {
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
        }
    }
    
    return simple_translations.get(lang, {}).get(word_lower, word)

def translate_ingredient(ingredient_key, english_name):
    """Traduit un ingrédient"""
    key_lower = ingredient_key.lower().strip()
    
    # Vérifier d'abord le dictionnaire complet
    if key_lower in TRANSLATIONS:
        return TRANSLATIONS[key_lower]
    
    # Traductions par mots-clés
    en_lower = english_name.lower()
    
    # Patterns de traduction
    if 'breadcrumbs' in en_lower or 'panko' in en_lower:
        if 'panko' in en_lower:
            return {"fr": "Chapelure panko", "es": "Pan rallado panko"}
        return {"fr": "Chapelure", "es": "Pan rallado"}
    
    if 'flour' in en_lower:
        if 'all purpose' in en_lower or 'plain' in en_lower:
            return {"fr": "Farine ordinaire", "es": "Harina común"}
        if 'self-raising' in en_lower or 'self raising' in en_lower:
            return {"fr": "Farine à lever", "es": "Harina con levadura"}
        return {"fr": "Farine", "es": "Harina"}
    
    if 'sugar' in en_lower:
        if 'icing' in en_lower:
            return {"fr": "Sucre glace", "es": "Azúcar glas"}
        if 'brown' in en_lower:
            if 'light' in en_lower or 'soft' in en_lower:
                return {"fr": "Sucre roux", "es": "Azúcar moreno claro"}
            return {"fr": "Sucre brun", "es": "Azúcar moreno"}
        return {"fr": "Sucre", "es": "Azúcar"}
    
    if 'oil' in en_lower:
        if 'olive' in en_lower:
            if 'extra virgin' in en_lower:
                return {"fr": "Huile d'olive extra vierge", "es": "Aceite de oliva extra virgen"}
            return {"fr": "Huile d'olive", "es": "Aceite de oliva"}
        if 'sesame' in en_lower:
            return {"fr": "Huile de sésame", "es": "Aceite de sésamo"}
        if 'vegetable' in en_lower:
            return {"fr": "Huile végétale", "es": "Aceite vegetal"}
        if 'sunflower' in en_lower:
            return {"fr": "Huile de tournesol", "es": "Aceite de girasol"}
        if 'coconut' in en_lower:
            return {"fr": "Huile de coco", "es": "Aceite de coco"}
        return {"fr": "Huile", "es": "Aceite"}
    
    if 'sauce' in en_lower:
        if 'soy' in en_lower:
            return {"fr": "Sauce soja", "es": "Salsa de soja"}
        if 'oyster' in en_lower:
            return {"fr": "Sauce aux huîtres", "es": "Salsa de ostras"}
        if 'fish' in en_lower:
            return {"fr": "Sauce de poisson", "es": "Salsa de pescado"}
        if 'hoisin' in en_lower:
            return {"fr": "Sauce hoisin", "es": "Salsa hoisin"}
        if 'worcestershire' in en_lower:
            return {"fr": "Sauce Worcestershire", "es": "Salsa Worcestershire"}
        if 'hot' in en_lower or 'hotsauce' in en_lower:
            return {"fr": "Sauce piquante", "es": "Salsa picante"}
        return {"fr": "Sauce", "es": "Salsa"}
    
    if 'vinegar' in en_lower:
        if 'rice' in en_lower:
            return {"fr": "Vinaigre de riz", "es": "Vinagre de arroz"}
        if 'red wine' in en_lower:
            return {"fr": "Vinaigre de vin rouge", "es": "Vinagre de vino tinto"}
        if 'white wine' in en_lower:
            return {"fr": "Vinaigre de vin blanc", "es": "Vinagre de vino blanco"}
        return {"fr": "Vinaigre", "es": "Vinagre"}
    
    if 'stock' in en_lower or 'broth' in en_lower:
        if 'chicken' in en_lower:
            return {"fr": "Bouillon de poulet", "es": "Caldo de pollo"}
        if 'beef' in en_lower:
            return {"fr": "Bouillon de bœuf", "es": "Caldo de res"}
        if 'vegetable' in en_lower:
            return {"fr": "Bouillon de légumes", "es": "Caldo de verduras"}
        return {"fr": "Bouillon", "es": "Caldo"}
    
    # Traduction par mots simples
    words = en_lower.split()
    if len(words) == 1:
        fr_word = translate_word(words[0], 'fr')
        es_word = translate_word(words[0], 'es')
        return {"fr": fr_word.title(), "es": es_word.title()}
    
    # Pour les mots composés, traduire le dernier mot principal
    main_word = words[-1]
    fr_main = translate_word(main_word, 'fr')
    es_main = translate_word(main_word, 'es')
    
    # Garder les préfixes en anglais si ce sont des noms propres ou techniques
    if len(words) <= 2:
        return {"fr": f"{' '.join(words[:-1]).title()} {fr_main}", "es": f"{' '.join(words[:-1]).title()} {es_main}"}
    
    return {"fr": english_name.title(), "es": english_name.title()}

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_file = project_root / "frontend" / "lib" / "data" / "culinary_dictionaries" / "ingredients_fr_en_es.json"
    
    if not json_file.exists():
        print(f"❌ Fichier non trouvé: {json_file}")
        return
    
    # Lire le fichier
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    ingredients = data.get("ingredients", {})
    updated_fr = 0
    updated_es = 0
    
    print(f"📚 {len(ingredients)} ingrédients à vérifier...")
    print("")
    
    for key, value in ingredients.items():
        en_name = value.get("en", key).strip()
        fr_name = value.get("fr", "").strip()
        es_name = value.get("es", "").strip()
        
        # Vérifier si FR est traduit
        if not fr_name or fr_name == en_name or fr_name.lower() == en_name.lower():
            translations = translate_ingredient(key, en_name)
            value["fr"] = translations["fr"]
            updated_fr += 1
            if updated_fr <= 20:  # Afficher les 20 premiers
                print(f"✓ FR: {key} → {translations['fr']}")
        
        # Vérifier si ES est traduit
        if not es_name or es_name == en_name or es_name.lower() == en_name.lower():
            translations = translate_ingredient(key, en_name)
            value["es"] = translations["es"]
            updated_es += 1
            if updated_es <= 20 and updated_es > updated_fr:  # Afficher si différent
                print(f"✓ ES: {key} → {translations['es']}")
    
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

