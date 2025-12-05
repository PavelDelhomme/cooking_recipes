#!/usr/bin/env python3
"""
Script final pour compléter TOUTES les traductions manquantes
"""

import json
from pathlib import Path

# Dictionnaire exhaustif
TRANSLATIONS = {
    "almond essence": {"fr": "Arôme d'amande", "es": "Esencia de almendra"},
    "almonds": {"fr": "Amandes", "es": "Almendras"},
    "aubergine": {"fr": "Aubergine", "es": "Berenjena"},
    "bacon": {"fr": "Bacon", "es": "Tocino"},
    "baguette": {"fr": "Baguette", "es": "Baguette"},
    "banana": {"fr": "Banane", "es": "Plátano"},
    "basil leaves": {"fr": "Feuilles de basilic", "es": "Hojas de albahaca"},
    "bay leaf": {"fr": "Feuille de laurier", "es": "Hoja de laurel"},
    "bay leaves": {"fr": "Feuilles de laurier", "es": "Hojas de laurel"},
    "bean sprouts": {"fr": "Germes de soja", "es": "Brotes de soja"},
    "beef brisket": {"fr": "Poitrine de bœuf", "es": "Pecho de res"},
    "beef cutlet": {"fr": "Côtelette de bœuf", "es": "Chuleta de res"},
    "beetroot": {"fr": "Betterave", "es": "Remolacha"},
    "brandy": {"fr": "Cognac", "es": "Brandy"},
    "broccoli": {"fr": "Brocoli", "es": "Brócoli"},
    "brown lentils": {"fr": "Lentilles brunes", "es": "Lentejas marrones"},
    "brown rice noodle": {"fr": "Nouille de riz brun", "es": "Fideo de arroz integral"},
    "can of chickpeas": {"fr": "Boîte de pois chiches", "es": "Lata de garbanzos"},
    "canned tomatoes": {"fr": "Tomates en conserve", "es": "Tomates enlatados"},
    "cardamom": {"fr": "Cardamome", "es": "Cardamomo"},
    "cherry tomatoes": {"fr": "Tomates cerises", "es": "Tomates cherry"},
    "chives": {"fr": "Ciboulette", "es": "Cebollino"},
    "chopped tomatoes": {"fr": "Tomates concassées", "es": "Tomates picados"},
    "cinnamon": {"fr": "Cannelle", "es": "Canela"},
    "coriander": {"fr": "Coriandre", "es": "Cilantro"},
    "coriander leaves": {"fr": "Feuilles de coriandre", "es": "Hojas de cilantro"},
    "cream of tartar": {"fr": "Crème de tartre", "es": "Crema de tártaro"},
    "creme fraiche": {"fr": "Crème fraîche", "es": "Crema fresca"},
    "cumin": {"fr": "Cumin", "es": "Comino"},
    "gruyère": {"fr": "Gruyère", "es": "Gruyère"},
    "mascarpone": {"fr": "Mascarpone", "es": "Mascarpone"},
    "mayonnaise": {"fr": "Mayonnaise", "es": "Mayonesa"},
    "mirin": {"fr": "Mirin", "es": "Mirin"},
    "orange": {"fr": "Orange", "es": "Naranja"},
    "pak choi": {"fr": "Pak choi", "es": "Pak choi"},
    "paneer": {"fr": "Paneer", "es": "Paneer"},
    "paprika": {"fr": "Paprika", "es": "Pimentón"},
    "parmesan": {"fr": "Parmesan", "es": "Parmesano"},
    "parmigiano-reggiano": {"fr": "Parmigiano-Reggiano", "es": "Parmigiano-Reggiano"},
    "pecorino": {"fr": "Pecorino", "es": "Pecorino"},
    "ricotta": {"fr": "Ricotta", "es": "Ricotta"},
    "sake": {"fr": "Saké", "es": "Sake"},
    "stout": {"fr": "Stout", "es": "Stout"},
    "tofu": {"fr": "Tofu", "es": "Tofu"},
    "hummus": {"fr": "Houmous", "es": "Hummus"},
    "tahini": {"fr": "Tahini", "es": "Tahini"},
}

def simple_translate(word, lang):
    """Traduction simple d'un mot"""
    trans = {
        'fr': {
            'almond': 'amande', 'almonds': 'amandes', 'aubergine': 'aubergine',
            'bacon': 'bacon', 'banana': 'banane', 'broccoli': 'brocoli',
            'beetroot': 'betterave', 'brandy': 'cognac', 'cardamom': 'cardamome',
            'chive': 'ciboulette', 'chives': 'ciboulette', 'cinnamon': 'cannelle',
            'coriander': 'coriandre', 'cumin': 'cumin', 'gruyère': 'gruyère',
            'mascarpone': 'mascarpone', 'mayonnaise': 'mayonnaise', 'mirin': 'mirin',
            'orange': 'orange', 'pak choi': 'pak choi', 'paneer': 'paneer',
            'paprika': 'paprika', 'parmesan': 'parmesan', 'pecorino': 'pecorino',
            'ricotta': 'ricotta', 'sake': 'saké', 'stout': 'stout', 'tofu': 'tofu',
            'hummus': 'houmous', 'tahini': 'tahini',
        },
        'es': {
            'almond': 'almendra', 'almonds': 'almendras', 'aubergine': 'berenjena',
            'bacon': 'tocino', 'banana': 'plátano', 'broccoli': 'brócoli',
            'beetroot': 'remolacha', 'brandy': 'brandy', 'cardamom': 'cardamomo',
            'chive': 'cebollino', 'chives': 'cebollino', 'cinnamon': 'canela',
            'coriander': 'cilantro', 'cumin': 'comino', 'gruyère': 'gruyère',
            'mascarpone': 'mascarpone', 'mayonnaise': 'mayonesa', 'mirin': 'mirin',
            'orange': 'naranja', 'pak choi': 'pak choi', 'paneer': 'paneer',
            'paprika': 'pimentón', 'parmesan': 'parmesano', 'pecorino': 'pecorino',
            'ricotta': 'ricotta', 'sake': 'sake', 'stout': 'stout', 'tofu': 'tofu',
            'hummus': 'hummus', 'tahini': 'tahini',
        }
    }
    return trans.get(lang, {}).get(word.lower(), word)

def translate_ingredient(key, en_name):
    """Traduit un ingrédient"""
    key_lower = key.lower()
    
    if key_lower in TRANSLATIONS:
        return TRANSLATIONS[key_lower]
    
    en_lower = en_name.lower()
    
    # Patterns spéciaux
    if 'leaves' in en_lower or 'leaf' in en_lower:
        base = en_lower.replace(' leaves', '').replace(' leaf', '').replace('leaves', '').replace('leaf', '').strip()
        base_trans_fr = simple_translate(base, 'fr')
        base_trans_es = simple_translate(base, 'es')
        return {
            "fr": f"Feuilles de {base_trans_fr}" if base_trans_fr != base else f"Feuilles de {base}",
            "es": f"Hojas de {base_trans_es}" if base_trans_es != base else f"Hojas de {base}"
        }
    
    if 'essence' in en_lower:
        base = en_lower.replace(' essence', '').replace('essence', '').strip()
        base_trans_fr = simple_translate(base, 'fr')
        base_trans_es = simple_translate(base, 'es')
        return {
            "fr": f"Arôme de {base_trans_fr}" if base_trans_fr != base else f"Arôme de {base}",
            "es": f"Esencia de {base_trans_es}" if base_trans_es != base else f"Esencia de {base}"
        }
    
    # Mots simples
    words = en_lower.split()
    if len(words) == 1:
        return {
            "fr": simple_translate(words[0], 'fr').title(),
            "es": simple_translate(words[0], 'es').title()
        }
    
    # Par défaut, garder l'anglais (noms propres, termes techniques)
    return {"fr": en_name.title(), "es": en_name.title()}

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_file = project_root / "frontend" / "lib" / "data" / "culinary_dictionaries" / "ingredients_fr_en_es.json"
    
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    ingredients = data.get("ingredients", {})
    updated = 0
    
    for key, value in ingredients.items():
        en = value.get("en", key).strip()
        fr = value.get("fr", "").strip()
        es = value.get("es", "").strip()
        
        changed = False
        
        if not fr or fr == en or fr.lower() == en.lower():
            trans = translate_ingredient(key, en)
            if trans["fr"] != fr:
                value["fr"] = trans["fr"]
                changed = True
        
        if not es or es == en or es.lower() == en.lower():
            trans = translate_ingredient(key, en)
            if trans["es"] != es:
                value["es"] = trans["es"]
                changed = True
        
        if changed:
            updated += 1
    
    data["metadata"]["total_terms"] = len(ingredients)
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ {updated} ingrédients mis à jour")
    print(f"📁 Fichier sauvegardé")

if __name__ == "__main__":
    main()

