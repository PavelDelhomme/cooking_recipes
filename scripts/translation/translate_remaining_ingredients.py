#!/usr/bin/env python3
"""
Script pour traduire automatiquement les ingrédients restants
dans ingredients_fr_en_es.json à partir de la ligne 689
"""

import json
import re
import sys
from pathlib import Path

# Dictionnaire de traductions de base
TRANSLATIONS = {
    # Fromages
    "gruyère": {"fr": "Gruyère", "es": "Gruyère"},
    "mascarpone": {"fr": "Mascarpone", "es": "Mascarpone"},
    "mayonnaise": {"fr": "Mayonnaise", "es": "Mayonesa"},
    "parmesan": {"fr": "Parmesan", "es": "Parmesano"},
    "parmesan cheese": {"fr": "Fromage parmesan", "es": "Queso parmesano"},
    "parmigiano-reggiano": {"fr": "Parmigiano-Reggiano", "es": "Parmigiano-Reggiano"},
    "pecorino": {"fr": "Pecorino", "es": "Pecorino"},
    "ricotta": {"fr": "Ricotta", "es": "Ricotta"},
    "cheddar cheese": {"fr": "Fromage cheddar", "es": "Queso cheddar"},
    "shredded monterey jack cheese": {"fr": "Fromage Monterey Jack râpé", "es": "Queso Monterey Jack rallado"},
    "mozzarella balls": {"fr": "Boules de mozzarella", "es": "Bolas de mozzarella"},
    
    # Poissons et fruits de mer
    "haddock": {"fr": "Églefin", "es": "Eglefino"},
    "hake": {"fr": "Merlu", "es": "Merluza"},
    "king prawns": {"fr": "Gambas royales", "es": "Gambas reales"},
    "raw king prawns": {"fr": "Gambas royales crues", "es": "Gambas reales crudas"},
    "prawns": {"fr": "Crevettes", "es": "Gambas"},
    "tiger prawns": {"fr": "Crevettes tigrées", "es": "Gambas tigre"},
    "mussels": {"fr": "Moules", "es": "Mejillones"},
    "oysters": {"fr": "Huîtres", "es": "Ostras"},
    "sardines": {"fr": "Sardines", "es": "Sardinas"},
    "squid": {"fr": "Calmar", "es": "Calamar"},
    "smoked haddock": {"fr": "Églefin fumé", "es": "Eglefino ahumado"},
    "white fish": {"fr": "Poisson blanc", "es": "Pescado blanco"},
    
    # Légumineuses
    "haricot beans": {"fr": "Haricots blancs", "es": "Judías blancas"},
    "kidney beans": {"fr": "Haricots rouges", "es": "Frijoles rojos"},
    "soya bean": {"fr": "Soja", "es": "Soja"},
    "toor dal": {"fr": "Toor dal", "es": "Toor dal"},
    
    # Épices et assaisonnements
    "harissa spice": {"fr": "Épice harissa", "es": "Especia harissa"},
    "hoisin sauce": {"fr": "Sauce hoisin", "es": "Salsa hoisin"},
    "hotsauce": {"fr": "Sauce piquante", "es": "Salsa picante"},
    "kosher salt": {"fr": "Sel casher", "es": "Sal kosher"},
    "onion salt": {"fr": "Sel à l'oignon", "es": "Sal de cebolla"},
    "sea salt": {"fr": "Sel de mer", "es": "Sal marina"},
    "red chilli": {"fr": "Piment rouge", "es": "Chile rojo"},
    "red chilli flakes": {"fr": "Flocons de piment rouge", "es": "Copos de chile rojo"},
    "chilli powder": {"fr": "Piment en poudre", "es": "Chile en polvo"},
    "mustard seeds": {"fr": "Graines de moutarde", "es": "Semillas de mostaza"},
    "poppy seeds": {"fr": "Graines de pavot", "es": "Semillas de amapola"},
    "sesame seed": {"fr": "Graine de sésame", "es": "Semilla de sésamo"},
    "fajita seasoning": {"fr": "Assaisonnement pour fajitas", "es": "Condimento para fajitas"},
    "italian seasoning": {"fr": "Assaisonnement italien", "es": "Condimento italiano"},
    "thai red curry paste": {"fr": "Pâte de curry rouge thaï", "es": "Pasta de curry rojo tailandés"},
    
    # Produits laitiers
    "heavy cream": {"fr": "Crème épaisse", "es": "Crema espesa"},
    "whipping cream": {"fr": "Crème à fouetter", "es": "Crema para batir"},
    "sour cream": {"fr": "Crème fraîche", "es": "Crema agria"},
    "melted butter": {"fr": "Beurre fondu", "es": "Mantequilla derretida"},
    "salted butter": {"fr": "Beurre salé", "es": "Mantequilla salada"},
    
    # Fruits
    "honey": {"fr": "Miel", "es": "Miel"},
    "jam": {"fr": "Confiture", "es": "Mermelada"},
    "raspberry jam": {"fr": "Confiture de framboises", "es": "Mermelada de frambuesas"},
    "prunes": {"fr": "Pruneaux", "es": "Ciruelas pasas"},
    "raisins": {"fr": "Raisins secs", "es": "Pasas"},
    "stoned dates": {"fr": "Dattes dénoyautées", "es": "Dátiles sin hueso"},
    "raspberries": {"fr": "Framboises", "es": "Frambuesas"},
    "strawberries": {"fr": "Fraises", "es": "Fresas"},
    "lemons": {"fr": "Citrons", "es": "Limones"},
    "lemon juice": {"fr": "Jus de citron", "es": "Zumo de limón"},
    "orange blossom water": {"fr": "Eau de fleur d'oranger", "es": "Agua de azahar"},
    
    # Légumes
    "iceberg lettuce": {"fr": "Laitue iceberg", "es": "Lechuga iceberg"},
    "lettuce": {"fr": "Laitue", "es": "Lechuga"},
    "kale": {"fr": "Chou frisé", "es": "Col rizada"},
    "pak choi": {"fr": "Pak choi", "es": "Pak choi"},
    "purple sprouting broccoli": {"fr": "Brocoli violet", "es": "Brócoli morado"},
    "mushrooms": {"fr": "Champignons", "es": "Champiñones"},
    "shiitake mushrooms": {"fr": "Champignons shiitake", "es": "Champiñones shiitake"},
    "chestnut mushroom": {"fr": "Champignon cèpe", "es": "Champiñón castaño"},
    "wood ear mushrooms": {"fr": "Champignons oreille de bois", "es": "Champiñones oreja de madera"},
    "onions": {"fr": "Oignons", "es": "Cebollas"},
    "red onions": {"fr": "Oignons rouges", "es": "Cebollas rojas"},
    "shallots": {"fr": "Échalotes", "es": "Chalotas"},
    "spring onions": {"fr": "Oignons nouveaux", "es": "Cebolletas"},
    "red pepper": {"fr": "Poivron rouge", "es": "Pimiento rojo"},
    "plum tomatoes": {"fr": "Tomates prune", "es": "Tomates ciruela"},
    "tomatoes": {"fr": "Tomates", "es": "Tomates"},
    "tinned tomatos": {"fr": "Tomates en conserve", "es": "Tomates enlatados"},
    "new potatoes": {"fr": "Pommes de terre nouvelles", "es": "Patatas nuevas"},
    "small potatoes": {"fr": "Petites pommes de terre", "es": "Patatas pequeñas"},
    "potatoes": {"fr": "Pommes de terre", "es": "Patatas"},
    "sweet potatoes": {"fr": "Patates douces", "es": "Batatas"},
    "russet potato": {"fr": "Pomme de terre rousse", "es": "Patata roja"},
    "peas": {"fr": "Pois", "es": "Guisantes"},
    "sweetcorn": {"fr": "Maïs doux", "es": "Maíz dulce"},
    "white cabbage": {"fr": "Chou blanc", "es": "Repollo blanco"},
    "swede": {"fr": "Rutabaga", "es": "Nabo sueco"},
    "fennel bulb": {"fr": "Bulbe de fenouil", "es": "Bulbo de hinojo"},
    "vine leaves": {"fr": "Feuilles de vigne", "es": "Hojas de parra"},
    
    # Viandes
    "lamb kidney": {"fr": "Rognon d'agneau", "es": "Riñón de cordero"},
    "lamb leg": {"fr": "Gigot d'agneau", "es": "Pierna de cordero"},
    "lamb loin chops": {"fr": "Côtelettes d'agneau", "es": "Chuletas de cordero"},
    "lamb mince": {"fr": "Viande d'agneau hachée", "es": "Carne de cordero picada"},
    "minced beef": {"fr": "Bœuf haché", "es": "Carne de res picada"},
    "minced pork": {"fr": "Porc haché", "es": "Cerdo picado"},
    "pork shoulder": {"fr": "Épaule de porc", "es": "Paleta de cerdo"},
    "pork shoulder steaks": {"fr": "Steaks d'épaule de porc", "es": "Filetes de paleta de cerdo"},
    "sirloin steak": {"fr": "Entrecôte", "es": "Entrecot"},
    "skirty steak": {"fr": "Steak de bavette", "es": "Filete de falda"},
    "sausages": {"fr": "Saucisses", "es": "Salchichas"},
    
    # Pâtes et céréales
    "lasagne sheets": {"fr": "Feuilles de lasagnes", "es": "Láminas de lasaña"},
    "linguine pasta": {"fr": "Pâtes linguine", "es": "Pasta linguine"},
    "macaroni": {"fr": "Macaronis", "es": "Macarrones"},
    "spaghetti": {"fr": "Spaghettis", "es": "Espaguetis"},
    "penne rigate": {"fr": "Pennes rigate", "es": "Penne rigate"},
    "rice noodles": {"fr": "Nouilles de riz", "es": "Fideos de arroz"},
    "vermicelli rice noodles": {"fr": "Nouilles vermicelles de riz", "es": "Fideos vermicelli de arroz"},
    "rice paper sheets": {"fr": "Feuilles de papier de riz", "es": "Hojas de papel de arroz"},
    "basmati rice": {"fr": "Riz basmati", "es": "Arroz basmati"},
    "sushi rice": {"fr": "Riz à sushi", "es": "Arroz para sushi"},
    "porridge oats": {"fr": "Flocons d'avoine", "es": "Copos de avena"},
    "rolled oats": {"fr": "Flocons d'avoine", "es": "Copos de avena"},
    "mixed grain": {"fr": "Céréales mélangées", "es": "Cereales mixtas"},
    
    # Farines et pâtes
    "plain flour": {"fr": "Farine ordinaire", "es": "Harina común"},
    "self-raising flour": {"fr": "Farine à lever", "es": "Harina con levadura"},
    "strong white bread flour": {"fr": "Farine de blé forte", "es": "Harina de trigo fuerte"},
    "icing sugar": {"fr": "Sucre glace", "es": "Azúcar glas"},
    "light brown soft sugar": {"fr": "Sucre roux clair", "es": "Azúcar moreno claro"},
    "dark soft brown sugar": {"fr": "Sucre roux foncé", "es": "Azúcar moreno oscuro"},
    "muscovado sugar": {"fr": "Sucre muscovado", "es": "Azúcar muscovado"},
    "palm sugar": {"fr": "Sucre de palme", "es": "Azúcar de palma"},
    "maple syrup": {"fr": "Sirop d'érable", "es": "Jarabe de arce"},
    
    # Pains
    "naan bread": {"fr": "Pain naan", "es": "Pan naan"},
    "pita bread": {"fr": "Pain pita", "es": "Pita"},
    "white bread": {"fr": "Pain blanc", "es": "Pan blanco"},
    "wholegrain bread": {"fr": "Pain complet", "es": "Pan integral"},
    "toast": {"fr": "Pain grillé", "es": "Tostada"},
    "sesame seed burger buns": {"fr": "Pains à hamburger aux graines de sésame", "es": "Bollos de hamburguesa con semillas de sésamo"},
    "corn tortillas": {"fr": "Tortillas de maïs", "es": "Tortillas de maíz"},
    
    # Pâtes à tarte
    "puff pastry": {"fr": "Pâte feuilletée", "es": "Masa de hojaldre"},
    "shortcrust pastry": {"fr": "Pâte brisée", "es": "Masa quebrada"},
    
    # Herbes et aromates
    "mint": {"fr": "Menthe", "es": "Menta"},
    "rosemary": {"fr": "Romarin", "es": "Romero"},
    "sage": {"fr": "Sauge", "es": "Salvia"},
    "thyme": {"fr": "Thym", "es": "Tomillo"},
    "basil": {"fr": "Basilic", "es": "Albahaca"},
    "parsley": {"fr": "Persil", "es": "Perejil"},
    "chopped parsley": {"fr": "Persil haché", "es": "Perejil picado"},
    "lime leaves": {"fr": "Feuilles de citron vert", "es": "Hojas de lima"},
    "rocket": {"fr": "Roquette", "es": "Rúcula"},
    
    # Épices spéciales
    "nutmeg": {"fr": "Muscade", "es": "Nuez moscada"},
    "saffron": {"fr": "Safran", "es": "Azafrán"},
    "turmeric": {"fr": "Curcuma", "es": "Cúrcuma"},
    "paprika": {"fr": "Paprika", "es": "Pimentón"},
    "clove": {"fr": "Clou de girofle", "es": "Clavo"},
    
    # Sauces et condiments
    "soy sauce": {"fr": "Sauce soja", "es": "Salsa de soja"},
    "tomato ketchup": {"fr": "Ketchup", "es": "Ketchup"},
    "tomato puree": {"fr": "Purée de tomate", "es": "Puré de tomate"},
    "worcestershire sauce": {"fr": "Sauce Worcestershire", "es": "Salsa Worcestershire"},
    "pickle juice": {"fr": "Jus de cornichon", "es": "Jugo de pepinillo"},
    "red wine vinegar": {"fr": "Vinaigre de vin rouge", "es": "Vinagre de vino tinto"},
    "white wine vinegar": {"fr": "Vinaigre de vin blanc", "es": "Vinagre de vino blanco"},
    "rice vinegar": {"fr": "Vinaigre de riz", "es": "Vinagre de arroz"},
    "vinegar": {"fr": "Vinaigre", "es": "Vinagre"},
    "mustard": {"fr": "Moutarde", "es": "Mostaza"},
    "hummus": {"fr": "Houmous", "es": "Hummus"},
    "tahini": {"fr": "Tahini", "es": "Tahini"},
    "tamarind paste": {"fr": "Pâte de tamarin", "es": "Pasta de tamarindo"},
    
    # Huiles
    "olive oil": {"fr": "Huile d'olive", "es": "Aceite de oliva"},
    "vegetable oil": {"fr": "Huile végétale", "es": "Aceite vegetal"},
    "sunflower oil": {"fr": "Huile de tournesol", "es": "Aceite de girasol"},
    "sesame seed oil": {"fr": "Huile de sésame", "es": "Aceite de sésamo"},
    
    # Boissons
    "red wine": {"fr": "Vin rouge", "es": "Vino tinto"},
    "red wine jelly": {"fr": "Gelée de vin rouge", "es": "Mermelada de vino tinto"},
    "soda water": {"fr": "Eau gazeuse", "es": "Agua con gas"},
    "stout": {"fr": "Stout", "es": "Stout"},
    "water": {"fr": "Eau", "es": "Agua"},
    
    # Produits spéciaux
    "mirin": {"fr": "Mirin", "es": "Mirin"},
    "paneer": {"fr": "Paneer", "es": "Paneer"},
    "tofu": {"fr": "Tofu", "es": "Tofu"},
    "marinated tofu": {"fr": "Tofu mariné", "es": "Tofu marinado"},
    "roasted vegetables": {"fr": "Légumes rôtis", "es": "Verduras asadas"},
    
    # Fruits secs et noix
    "pine nuts": {"fr": "Pignons de pin", "es": "Piñones"},
    "walnuts": {"fr": "Noix", "es": "Nueces"},
    "peanut butter": {"fr": "Beurre de cacahuète", "es": "Mantequilla de cacahuete"},
    "peanut brittle": {"fr": "Brittle aux cacahuètes", "es": "Brittle de cacahuetes"},
    "peanut cookies": {"fr": "Biscuits aux cacahuètes", "es": "Galletas de cacahuetes"},
    
    # Autres
    "lemon": {"fr": "Citron", "es": "Limón"},
    "lime": {"fr": "Citron vert", "es": "Lima"},
    "orange": {"fr": "Orange", "es": "Naranja"},
    "vanilla": {"fr": "Vanille", "es": "Vainilla"},
    "vanilla extract": {"fr": "Extrait de vanille", "es": "Extracto de vainilla"},
    "yeast": {"fr": "Levure", "es": "Levadura"},
    "suet": {"fr": "Suif", "es": "Sebo"},
    "mixed peel": {"fr": "Écorces confites mélangées", "es": "Cáscaras confitadas mixtas"},
    "meringue nests": {"fr": "Nids de meringue", "es": "Nidos de merengue"},
    "ginger cordial": {"fr": "Sirop de gingembre", "es": "Jarabe de jengibre"},
    "vegetable stock": {"fr": "Bouillon de légumes", "es": "Caldo de verduras"},
}

def translate_ingredient(ingredient_key, english_name):
    """Traduit un ingrédient en utilisant le dictionnaire ou des règles"""
    key_lower = ingredient_key.lower()
    
    # Vérifier d'abord le dictionnaire
    if key_lower in TRANSLATIONS:
        return TRANSLATIONS[key_lower]
    
    # Règles de traduction automatique
    fr_translation = english_name
    es_translation = english_name
    
    # Règles simples pour les mots communs
    simple_translations = {
        "cheese": {"fr": "fromage", "es": "queso"},
        "cream": {"fr": "crème", "es": "crema"},
        "butter": {"fr": "beurre", "es": "mantequilla"},
        "sugar": {"fr": "sucre", "es": "azúcar"},
        "salt": {"fr": "sel", "es": "sal"},
        "pepper": {"fr": "poivre", "es": "pimienta"},
        "oil": {"fr": "huile", "es": "aceite"},
        "flour": {"fr": "farine", "es": "harina"},
        "rice": {"fr": "riz", "es": "arroz"},
        "pasta": {"fr": "pâtes", "es": "pasta"},
        "bread": {"fr": "pain", "es": "pan"},
        "sauce": {"fr": "sauce", "es": "salsa"},
        "vinegar": {"fr": "vinaigre", "es": "vinagre"},
        "wine": {"fr": "vin", "es": "vino"},
    }
    
    # Appliquer les traductions simples
    for word, trans in simple_translations.items():
        if word in key_lower:
            # Remplacer dans la traduction
            if word in fr_translation.lower():
                fr_translation = fr_translation.replace(word, trans["fr"])
            if word in es_translation.lower():
                es_translation = es_translation.replace(word, trans["es"])
    
    return {"fr": fr_translation, "es": es_translation}

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_file = project_root / "frontend" / "lib" / "data" / "culinary_dictionaries" / "ingredients_fr_en_es.json"
    
    if not json_file.exists():
        print(f"❌ Fichier non trouvé: {json_file}")
        sys.exit(1)
    
    # Lire le fichier JSON
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    ingredients = data.get("ingredients", {})
    updated_count = 0
    
    # Traiter tous les ingrédients à partir de "gruyère" (ligne 689)
    start_key = "gruyère"
    started = False
    
    for key, value in ingredients.items():
        if key == start_key:
            started = True
        
        if not started:
            continue
        
        en_name = value.get("en", key)
        fr_name = value.get("fr", "")
        es_name = value.get("es", "")
        
        # Si la traduction FR est identique à EN (non traduite)
        if fr_name == en_name or fr_name == "":
            translations = translate_ingredient(key, en_name)
            value["fr"] = translations["fr"]
            value["es"] = translations["es"]
            updated_count += 1
            print(f"✓ {key}: {en_name} → FR: {translations['fr']}, ES: {translations['es']}")
    
    # Sauvegarder le fichier
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ {updated_count} ingrédients traduits avec succès!")
    print(f"📁 Fichier sauvegardé: {json_file}")

if __name__ == "__main__":
    main()

