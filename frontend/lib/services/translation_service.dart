import 'dart:convert';
import 'package:flutter/material.dart';
import 'locale_service.dart';

/// Service de traduction pour convertir les éléments de recettes
class TranslationService {
  // Langue actuelle (par défaut français)
  static String _currentLanguage = 'fr';
  
  // Initialiser la langue
  static Future<void> init() async {
    _currentLanguage = await LocaleService.getLanguageCode();
  }
  
  // Définir la langue
  static void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
  }
  
  // Obtenir la langue actuelle
  static String get currentLanguage => _currentLanguage;
  // Dictionnaire de traduction des ingrédients courants
  static final Map<String, String> _ingredientTranslations = {
    // Viandes
    'chicken': 'Poulet',
    'beef': 'Bœuf',
    'pork': 'Porc',
    'lamb': 'Agneau',
    'turkey': 'Dinde',
    'duck': 'Canard',
    'steak': 'Steak',
    'mince': 'Viande hachée',
    'ground beef': 'Bœuf haché',
    'bacon': 'Bacon',
    'sausage': 'Saucisse',
    
    // Poissons
    'salmon': 'Saumon',
    'tuna': 'Thon',
    'cod': 'Morue',
    'trout': 'Truite',
    'mackerel': 'Maquereau',
    'fish': 'Poisson',
    
    // Légumes
    'tomato': 'Tomate',
    'tomatoes': 'Tomates',
    'onion': 'Oignon',
    'onions': 'Oignons',
    'garlic': 'Ail',
    'carrot': 'Carotte',
    'carrots': 'Carottes',
    'potato': 'Pomme de terre',
    'potatoes': 'Pommes de terre',
    'pepper': 'Poivron',
    'peppers': 'Poivrons',
    'bell pepper': 'Poivron',
    'zucchini': 'Courgette',
    'courgette': 'Courgette',
    'eggplant': 'Aubergine',
    'aubergine': 'Aubergine',
    'lettuce': 'Laitue',
    'spinach': 'Épinards',
    'cucumber': 'Concombre',
    'mushroom': 'Champignon',
    'mushrooms': 'Champignons',
    'broccoli': 'Brocoli',
    'cauliflower': 'Chou-fleur',
    'cabbage': 'Chou',
    'celery': 'Céleri',
    'leek': 'Poireau',
    'asparagus': 'Asperges',
    
    // Fruits
    'apple': 'Pomme',
    'apples': 'Pommes',
    'banana': 'Banane',
    'bananas': 'Bananes',
    'orange': 'Orange',
    'oranges': 'Oranges',
    'lemon': 'Citron',
    'lemons': 'Citrons',
    'lime': 'Citron vert',
    'strawberry': 'Fraise',
    'strawberries': 'Fraises',
    'blueberry': 'Myrtille',
    'blueberries': 'Myrtilles',
    'raspberry': 'Framboise',
    'raspberries': 'Framboises',
    
    // Produits laitiers
    'milk': 'Lait',
    'cheese': 'Fromage',
    'butter': 'Beurre',
    'cream': 'Crème',
    'yogurt': 'Yaourt',
    'yoghurt': 'Yaourt',
    'sour cream': 'Crème fraîche',
    'cottage cheese': 'Fromage blanc',
    
    // Céréales et féculents
    'rice': 'Riz',
    'pasta': 'Pâtes',
    'spaghetti': 'Spaghettis',
    'noodles': 'Nouilles',
    'bread': 'Pain',
    'flour': 'Farine',
    'wheat flour': 'Farine de blé',
    'corn': 'Maïs',
    'quinoa': 'Quinoa',
    'couscous': 'Couscous',
    'bulgur': 'Boulgour',
    'oats': 'Avoine',
    'barley': 'Orge',
    
    // Épices et herbes
    'salt': 'Sel',
    'pepper': 'Poivre',
    'black pepper': 'Poivre noir',
    'paprika': 'Paprika',
    'cumin': 'Cumin',
    'coriander': 'Coriandre',
    'parsley': 'Persil',
    'basil': 'Basilic',
    'oregano': 'Origan',
    'thyme': 'Thym',
    'rosemary': 'Romarin',
    'sage': 'Sauge',
    'mint': 'Menthe',
    'dill': 'Aneth',
    'chives': 'Ciboulette',
    'bay leaf': 'Feuille de laurier',
    'bay leaves': 'Feuilles de laurier',
    
    // Huiles et vinaigres
    'oil': 'Huile',
    'olive oil': 'Huile d\'olive',
    'vegetable oil': 'Huile végétale',
    'sunflower oil': 'Huile de tournesol',
    'vinegar': 'Vinaigre',
    'balsamic vinegar': 'Vinaigre balsamique',
    'white vinegar': 'Vinaigre blanc',
    'apple cider vinegar': 'Vinaigre de cidre',
    
    // Autres
    'egg': 'Œuf',
    'eggs': 'Œufs',
    'sugar': 'Sucre',
    'brown sugar': 'Sucre roux',
    'honey': 'Miel',
    'vanilla': 'Vanille',
    'vanilla extract': 'Extrait de vanille',
    'cinnamon': 'Cannelle',
    'nutmeg': 'Muscade',
    'ginger': 'Gingembre',
    'turmeric': 'Curcuma',
    'curry': 'Curry',
    'chili': 'Piment',
    'chili pepper': 'Piment',
    'chili powder': 'Piment en poudre',
    'soy sauce': 'Sauce soja',
    'worcestershire sauce': 'Sauce Worcestershire',
    'tomato paste': 'Concentré de tomate',
    'tomato sauce': 'Sauce tomate',
    'chicken broth': 'Bouillon de poulet',
    'beef broth': 'Bouillon de bœuf',
    'vegetable broth': 'Bouillon de légumes',
    'stock': 'Bouillon',
    'water': 'Eau',
    'wine': 'Vin',
    'white wine': 'Vin blanc',
    'red wine': 'Vin rouge',
  };

  /// Traduit un ingrédient selon la langue sélectionnée
  static String translateIngredient(String ingredient) {
    if (ingredient.isEmpty) return ingredient;
    
    // Si la langue est déjà en français, ne pas traduire
    if (_currentLanguage == 'fr') {
      final lowerIngredient = ingredient.toLowerCase().trim();
      
      // Vérifier d'abord la correspondance exacte
      if (_ingredientTranslations.containsKey(lowerIngredient)) {
        return _ingredientTranslations[lowerIngredient]!;
      }
      
      // Chercher une correspondance partielle
      for (var entry in _ingredientTranslations.entries) {
        if (lowerIngredient.contains(entry.key) || entry.key.contains(lowerIngredient)) {
          return entry.value;
        }
      }
    }
    
    // Si aucune traduction trouvée ou langue différente, capitaliser la première lettre
    if (ingredient.length > 1) {
      return ingredient[0].toUpperCase() + ingredient.substring(1).toLowerCase();
    }
    
    return ingredient;
  }

  /// Traduit une liste d'ingrédients
  static List<String> translateIngredients(List<String> ingredients) {
    return ingredients.map((ingredient) => translateIngredient(ingredient)).toList();
  }

  /// Nettoie et traduit un texte de recette (instructions, etc.)
  static String cleanAndTranslate(String text) {
    if (text.isEmpty) return text;
    
    // Décoder les entités HTML si présentes
    String cleaned = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    
    // Traduire les ingrédients dans le texte seulement si la langue est française
    if (_currentLanguage == 'fr') {
      for (var entry in _ingredientTranslations.entries) {
        final regex = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
        cleaned = cleaned.replaceAll(regex, entry.value);
      }
    }
    
    return cleaned;
  }

  /// Traduit le nom d'une recette
  static String translateRecipeName(String recipeName) {
    if (recipeName.isEmpty) return recipeName;
    
    // Nettoyer l'encodage d'abord
    String cleaned = fixEncoding(recipeName);
    
    // Si la langue est française, traduire les termes courants dans les noms de recettes
    if (_currentLanguage == 'fr') {
      // Dictionnaire de traductions pour les termes courants dans les noms de recettes
      final recipeTermTranslations = {
        'chicken': 'Poulet',
        'beef': 'Bœuf',
        'pork': 'Porc',
        'fish': 'Poisson',
        'salmon': 'Saumon',
        'pasta': 'Pâtes',
        'spaghetti': 'Spaghettis',
        'rice': 'Riz',
        'soup': 'Soupe',
        'salad': 'Salade',
        'sandwich': 'Sandwich',
        'burger': 'Burger',
        'pizza': 'Pizza',
        'cake': 'Gâteau',
        'pie': 'Tarte',
        'bread': 'Pain',
        'stew': 'Ragoût',
        'curry': 'Curry',
        'stir fry': 'Sauté',
        'roast': 'Rôti',
        'grilled': 'Grillé',
        'baked': 'Cuit au four',
        'fried': 'Frit',
        'boiled': 'Bouilli',
        'steamed': 'Cuit à la vapeur',
      };
      
      // Traduire les termes courants (insensible à la casse)
      String translated = cleaned;
      for (var entry in recipeTermTranslations.entries) {
        final regex = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
        translated = translated.replaceAll(regex, entry.value);
      }
      
      // Capitaliser la première lettre
      if (translated.isNotEmpty) {
        translated = translated[0].toUpperCase() + translated.substring(1);
      }
      
      return translated;
    }
    
    // Pour les autres langues, juste capitaliser la première lettre
    if (cleaned.isNotEmpty) {
      return cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned;
  }

  /// Décode les caractères UTF-8 mal encodés
  static String fixEncoding(String text) {
    if (text.isEmpty) return text;
    
    try {
      // Essayer de détecter et corriger les problèmes d'encodage courants
      // Caractères mal encodés courants
      final fixes = {
        'Ã©': 'é',
        'Ã¨': 'è',
        'Ãª': 'ê',
        'Ã«': 'ë',
        'Ã ': 'à',
        'Ã¢': 'â',
        'Ã§': 'ç',
        'Ã´': 'ô',
        'Ã¹': 'ù',
        'Ã»': 'û',
        'Ã¯': 'ï',
        'Ã°': 'ð',
        'Ã½': 'ý',
        'Ã¾': 'þ',
        'â€™': "'",
        'â€œ': '"',
        'â€': '"',
        'â€"': '—',
        'â€"': '–',
      };
      
      String fixed = text;
      for (var entry in fixes.entries) {
        fixed = fixed.replaceAll(entry.key, entry.value);
      }
      
      return fixed;
    } catch (e) {
      return text;
    }
  }

  /// Dictionnaire de traduction des unités de mesure
  static final Map<String, Map<String, String>> _unitTranslations = {
    'fr': {
      'cup': 'tasse',
      'cups': 'tasses',
      'tablespoon': 'cuillère à soupe',
      'tablespoons': 'cuillères à soupe',
      'tbsp': 'cuillère à soupe',
      'teaspoon': 'cuillère à café',
      'teaspoons': 'cuillères à café',
      'tsp': 'cuillère à café',
      'ounce': 'once',
      'ounces': 'onces',
      'oz': 'oz',
      'pound': 'livre',
      'pounds': 'livres',
      'lb': 'lb',
      'lbs': 'lbs',
      'gram': 'gramme',
      'grams': 'grammes',
      'g': 'g',
      'kilogram': 'kilogramme',
      'kilograms': 'kilogrammes',
      'kg': 'kg',
      'milliliter': 'millilitre',
      'milliliters': 'millilitres',
      'ml': 'ml',
      'liter': 'litre',
      'liters': 'litres',
      'l': 'l',
      'piece': 'pièce',
      'pieces': 'pièces',
      'pcs': 'pièces',
      'slice': 'tranche',
      'slices': 'tranches',
      'clove': 'gousse',
      'cloves': 'gousses',
      'head': 'tête',
      'heads': 'têtes',
      'bunch': 'botte',
      'bunches': 'bottes',
      'pinch': 'pincée',
      'pinches': 'pincées',
      'can': 'boîte',
      'cans': 'boîtes',
      'package': 'paquet',
      'packages': 'paquets',
      'pack': 'paquet',
      'packs': 'paquets',
      'bottle': 'bouteille',
      'bottles': 'bouteilles',
      'bag': 'sachet',
      'bags': 'sachets',
      'box': 'boîte',
      'boxes': 'boîtes',
    },
    'en': {
      'cup': 'cup',
      'cups': 'cups',
      'tablespoon': 'tablespoon',
      'tablespoons': 'tablespoons',
      'tbsp': 'tbsp',
      'teaspoon': 'teaspoon',
      'teaspoons': 'teaspoons',
      'tsp': 'tsp',
      'ounce': 'ounce',
      'ounces': 'ounces',
      'oz': 'oz',
      'pound': 'pound',
      'pounds': 'pounds',
      'lb': 'lb',
      'lbs': 'lbs',
      'gram': 'gram',
      'grams': 'grams',
      'g': 'g',
      'kilogram': 'kilogram',
      'kilograms': 'kilograms',
      'kg': 'kg',
      'milliliter': 'milliliter',
      'milliliters': 'milliliters',
      'ml': 'ml',
      'liter': 'liter',
      'liters': 'liters',
      'l': 'l',
      'piece': 'piece',
      'pieces': 'pieces',
      'pcs': 'pcs',
      'slice': 'slice',
      'slices': 'slices',
      'clove': 'clove',
      'cloves': 'cloves',
      'head': 'head',
      'heads': 'heads',
      'bunch': 'bunch',
      'bunches': 'bunches',
      'pinch': 'pinch',
      'pinches': 'pinches',
      'can': 'can',
      'cans': 'cans',
      'package': 'package',
      'packages': 'packages',
      'pack': 'pack',
      'packs': 'packs',
      'bottle': 'bottle',
      'bottles': 'bottles',
      'bag': 'bag',
      'bags': 'bags',
      'box': 'box',
      'boxes': 'boxes',
    },
    'es': {
      'cup': 'taza',
      'cups': 'tazas',
      'tablespoon': 'cucharada',
      'tablespoons': 'cucharadas',
      'tbsp': 'cucharada',
      'teaspoon': 'cucharadita',
      'teaspoons': 'cucharaditas',
      'tsp': 'cucharadita',
      'ounce': 'onza',
      'ounces': 'onzas',
      'oz': 'oz',
      'pound': 'libra',
      'pounds': 'libras',
      'lb': 'lb',
      'lbs': 'lbs',
      'gram': 'gramo',
      'grams': 'gramos',
      'g': 'g',
      'kilogram': 'kilogramo',
      'kilograms': 'kilogramos',
      'kg': 'kg',
      'milliliter': 'mililitro',
      'milliliters': 'mililitros',
      'ml': 'ml',
      'liter': 'litro',
      'liters': 'litros',
      'l': 'l',
      'piece': 'pieza',
      'pieces': 'piezas',
      'pcs': 'piezas',
      'slice': 'rodaja',
      'slices': 'rodajas',
      'clove': 'diente',
      'cloves': 'dientes',
      'head': 'cabeza',
      'heads': 'cabezas',
      'bunch': 'manojo',
      'bunches': 'manojos',
      'pinch': 'pizca',
      'pinches': 'pizcas',
      'can': 'lata',
      'cans': 'latas',
      'package': 'paquete',
      'packages': 'paquetes',
      'pack': 'paquete',
      'packs': 'paquetes',
      'bottle': 'botella',
      'bottles': 'botellas',
      'bag': 'bolsa',
      'bags': 'bolsas',
      'box': 'caja',
      'boxes': 'cajas',
    },
  };

  /// Traduit une unité de mesure selon la langue sélectionnée
  static String translateUnit(String unit) {
    if (unit.isEmpty) return unit;
    
    final langTranslations = _unitTranslations[_currentLanguage] ?? _unitTranslations['fr']!;
    final lowerUnit = unit.toLowerCase().trim();
    
    // Vérifier d'abord la correspondance exacte
    if (langTranslations.containsKey(lowerUnit)) {
      return langTranslations[lowerUnit]!;
    }
    
    // Chercher une correspondance partielle
    for (var entry in langTranslations.entries) {
      if (lowerUnit.contains(entry.key) || entry.key.contains(lowerUnit)) {
        return entry.value;
      }
    }
    
    // Si aucune traduction trouvée, retourner l'unité originale
    return unit;
  }
}

