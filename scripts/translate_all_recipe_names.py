#!/usr/bin/env python3
"""
Script pour traduire automatiquement TOUS les noms de recettes
dans recipe_names_fr_en_es.json
"""

import json
import re
from pathlib import Path

# Dictionnaire de traductions pour les noms de recettes courants
RECIPE_NAME_TRANSLATIONS = {
    # Patterns de traduction
    'chicken': {'fr': 'poulet', 'es': 'pollo'},
    'beef': {'fr': 'bœuf', 'es': 'carne de res'},
    'pork': {'fr': 'porc', 'es': 'cerdo'},
    'lamb': {'fr': 'agneau', 'es': 'cordero'},
    'fish': {'fr': 'poisson', 'es': 'pescado'},
    'salmon': {'fr': 'saumon', 'es': 'salmón'},
    'curry': {'fr': 'curry', 'es': 'curry'},
    'soup': {'fr': 'soupe', 'es': 'sopa'},
    'salad': {'fr': 'salade', 'es': 'ensalada'},
    'stew': {'fr': 'ragoût', 'es': 'estofado'},
    'burger': {'fr': 'burger', 'es': 'hamburguesa'},
    'pizza': {'fr': 'pizza', 'es': 'pizza'},
    'pasta': {'fr': 'pâtes', 'es': 'pasta'},
    'rice': {'fr': 'riz', 'es': 'arroz'},
    'bread': {'fr': 'pain', 'es': 'pan'},
    'cake': {'fr': 'gâteau', 'es': 'pastel'},
    'pie': {'fr': 'tarte', 'es': 'tarta'},
    'sauce': {'fr': 'sauce', 'es': 'salsa'},
    'roasted': {'fr': 'rôti', 'es': 'asado'},
    'fried': {'fr': 'frit', 'es': 'frito'},
    'baked': {'fr': 'cuit au four', 'es': 'al horno'},
    'grilled': {'fr': 'grillé', 'es': 'a la parrilla'},
    'vegetable': {'fr': 'légume', 'es': 'verdura'},
    'vegetables': {'fr': 'légumes', 'es': 'verduras'},
}

def translate_recipe_name(en_name):
    """Traduit un nom de recette"""
    en_lower = en_name.lower()
    
    # Traductions directes pour les recettes courantes
    direct_translations = {
        'chicken curry': {'fr': 'Curry de poulet', 'es': 'Curry de pollo'},
        'beef stew': {'fr': 'Ragoût de bœuf', 'es': 'Estofado de res'},
        'vegetable soup': {'fr': 'Soupe de légumes', 'es': 'Sopa de verduras'},
        'fish and chips': {'fr': 'Poisson frit et frites', 'es': 'Pescado con patatas fritas'},
        'pasta salad': {'fr': 'Salade de pâtes', 'es': 'Ensalada de pasta'},
        'tomato soup': {'fr': 'Soupe à la tomate', 'es': 'Sopa de tomate'},
        'lamb tagine': {'fr': 'Tajine d\'agneau', 'es': 'Tajine de cordero'},
        'pork chops': {'fr': 'Côtes de porc', 'es': 'Chuletas de cerdo'},
        'salmon fillet': {'fr': 'Filet de saumon', 'es': 'Filete de salmón'},
        'rice pudding': {'fr': 'Riz au lait', 'es': 'Arroz con leche'},
        'apple pie': {'fr': 'Tarte aux pommes', 'es': 'Tarta de manzana'},
        'chocolate cake': {'fr': 'Gâteau au chocolat', 'es': 'Pastel de chocolate'},
        'caesar salad': {'fr': 'Salade César', 'es': 'Ensalada César'},
        'beef burger': {'fr': 'Burger de bœuf', 'es': 'Hamburguesa de res'},
        'margherita pizza': {'fr': 'Pizza Margherita', 'es': 'Pizza Margherita'},
        'spaghetti bolognese': {'fr': 'Spaghettis bolognaise', 'es': 'Espaguetis a la boloñesa'},
        'chicken noodle soup': {'fr': 'Soupe de poulet aux nouilles', 'es': 'Sopa de pollo con fideos'},
        'roasted vegetables': {'fr': 'Légumes rôtis', 'es': 'Verduras asadas'},
        'garlic bread': {'fr': 'Pain à l\'ail', 'es': 'Pan de ajo'},
        'mashed potatoes': {'fr': 'Purée de pommes de terre', 'es': 'Puré de patatas'},
        'green bean casserole': {'fr': 'Gratin de haricots verts', 'es': 'Cazuela de judías verdes'},
        'lentil soup': {'fr': 'Soupe de lentilles', 'es': 'Sopa de lentejas'},
        'chickpea salad': {'fr': 'Salade de pois chiches', 'es': 'Ensalada de garbanzos'},
        'kidney bean curry': {'fr': 'Curry aux haricots rouges', 'es': 'Curry de frijoles rojos'},
        'black bean soup': {'fr': 'Soupe de haricots noirs', 'es': 'Sopa de frijoles negros'},
        'white bean stew': {'fr': 'Ragoût de haricots blancs', 'es': 'Estofado de frijoles blancos'},
    }
    
    # Vérifier les traductions directes
    for pattern, translation in direct_translations.items():
        if pattern in en_lower:
            return translation
    
    # Traduction par mots
    words = en_lower.split()
    fr_words = []
    es_words = []
    
    for word in words:
        # Nettoyer les caractères spéciaux
        clean_word = re.sub(r'[^\w\s]', '', word)
        
        if clean_word in RECIPE_NAME_TRANSLATIONS:
            fr_words.append(RECIPE_NAME_TRANSLATIONS[clean_word]['fr'])
            es_words.append(RECIPE_NAME_TRANSLATIONS[clean_word]['es'])
        else:
            # Garder le mot original si pas de traduction
            fr_words.append(word)
            es_words.append(word)
    
    # Construire les traductions
    fr_translation = ' '.join(fr_words).title()
    es_translation = ' '.join(es_words).title()
    
    # Règles spéciales pour le français (inversion)
    if len(words) == 2:
        # Ex: "Chicken Soup" -> "Soupe au Poulet"
        if words[1] in ['soup', 'soupe', 'salad', 'salade', 'stew', 'ragoût']:
            if words[0] in RECIPE_NAME_TRANSLATIONS:
                meat_fr = RECIPE_NAME_TRANSLATIONS[words[0]]['fr']
                type_fr = RECIPE_NAME_TRANSLATIONS.get(words[1], {}).get('fr', words[1])
                fr_translation = f"{type_fr.title()} au {meat_fr.title()}"
    
    return {
        'fr': fr_translation if fr_translation != en_name.title() else en_name.title(),
        'es': es_translation if es_translation != en_name.title() else en_name.title()
    }

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_file = project_root / "frontend" / "lib" / "data" / "culinary_dictionaries" / "recipe_names_fr_en_es.json"
    
    if not json_file.exists():
        print(f"❌ Fichier non trouvé: {json_file}")
        return
    
    # Lire le fichier
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    recipe_names = data.get("recipe_names", {})
    updated_fr = 0
    updated_es = 0
    
    print(f"📚 Traduction de {len(recipe_names)} noms de recettes...")
    print("")
    
    for key, value in recipe_names.items():
        en_name = value.get("en", key).strip()
        fr_name = value.get("fr", "").strip()
        es_name = value.get("es", "").strip()
        
        changed = False
        
        # Vérifier FR
        if not fr_name or fr_name == en_name or fr_name.lower() == en_name.lower():
            translations = translate_recipe_name(en_name)
            if translations["fr"] != fr_name:
                value["fr"] = translations["fr"]
                updated_fr += 1
                changed = True
        
        # Vérifier ES
        if not es_name or es_name == en_name or es_name.lower() == en_name.lower():
            translations = translate_recipe_name(en_name)
            if translations["es"] != es_name:
                value["es"] = translations["es"]
                updated_es += 1
                changed = True
        
        if changed and (updated_fr + updated_es) <= 30:
            print(f"✓ {key}: FR={value['fr']}, ES={value['es']}")
    
    # Sauvegarder
    data["metadata"]["total_terms"] = len(recipe_names)
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("")
    print(f"✅ {updated_fr} traductions FR ajoutées/corrigées")
    print(f"✅ {updated_es} traductions ES ajoutées/corrigées")
    print(f"📁 Fichier sauvegardé: {json_file}")

if __name__ == "__main__":
    main()

