import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'culinary_dictionary_loader.dart';

/// Service de traduction automatique basé sur des règles et des patterns
/// Ne nécessite pas d'API externe payante
class AutoTranslator {
  // Dictionnaire de base étendu pour les ingrédients et termes courants
  static final Map<String, String> _baseDictionary = {
    // Viandes
    'chicken': 'poulet', 'beef': 'bœuf', 'pork': 'porc', 'lamb': 'agneau',
    'turkey': 'dinde', 'duck': 'canard', 'steak': 'steak', 'mince': 'viande hachée',
    'ground beef': 'bœuf haché', 'bacon': 'bacon', 'sausage': 'saucisse',
    
    // Poissons
    'salmon': 'saumon', 'tuna': 'thon', 'cod': 'morue', 'trout': 'truite',
    'mackerel': 'maquereau', 'fish': 'poisson',
    
    // Légumes
    'tomato': 'tomate', 'tomatoes': 'tomates', 'onion': 'oignon', 'onions': 'oignons',
    'garlic': 'ail', 'carrot': 'carotte', 'carrots': 'carottes',
    'potato': 'pomme de terre', 'potatoes': 'pommes de terre',
    'pepper': 'poivron', 'peppers': 'poivrons', 'bell pepper': 'poivron',
    'zucchini': 'courgette', 'eggplant': 'aubergine', 'lettuce': 'laitue',
    'spinach': 'épinards', 'cucumber': 'concombre', 'mushroom': 'champignon',
    'mushrooms': 'champignons', 'broccoli': 'brocoli', 'cauliflower': 'chou-fleur',
    'cabbage': 'chou', 'celery': 'céleri', 'leek': 'poireau', 'asparagus': 'asperges',
    
    // Légumineuses
    'kidney beans': 'haricots rouges', 'kidney bean': 'haricot rouge',
    'red kidney beans': 'haricots rouges', 'red kidney bean': 'haricot rouge',
    'black beans': 'haricots noirs', 'black bean': 'haricot noir',
    'white beans': 'haricots blancs', 'white bean': 'haricot blanc',
    'butter beans': 'haricots de lima', 'butter bean': 'haricot de lima',
    'green beans': 'haricots verts', 'green bean': 'haricot vert',
    'chickpeas': 'pois chiches', 'chickpea': 'pois chiche',
    'lentils': 'lentilles', 'lentil': 'lentille',
    'beans': 'haricots', 'bean': 'haricot', 'peas': 'pois', 'pea': 'pois',
    
    // Fruits
    'apple': 'pomme', 'apples': 'pommes', 'banana': 'banane', 'bananas': 'bananes',
    'orange': 'orange', 'oranges': 'oranges', 'lemon': 'citron', 'lemons': 'citrons',
    'lime': 'citron vert', 'strawberry': 'fraise', 'strawberries': 'fraises',
    
    // Produits laitiers
    'milk': 'lait', 'cheese': 'fromage', 'butter': 'beurre', 'cream': 'crème',
    'yogurt': 'yaourt', 'sour cream': 'crème fraîche',
    
    // Céréales
    'rice': 'riz', 'pasta': 'pâtes', 'spaghetti': 'spaghettis', 'bread': 'pain',
    'flour': 'farine', 'wheat flour': 'farine de blé', 'corn': 'maïs',
    
    // Épices
    'salt': 'sel', 'pepper': 'poivre', 'black pepper': 'poivre noir',
    'paprika': 'paprika', 'cumin': 'cumin', 'coriander': 'coriandre',
    'parsley': 'persil', 'basil': 'basilic', 'oregano': 'origan',
    'thyme': 'thym', 'rosemary': 'romarin', 'curry': 'curry',
    
    // Huiles
    'oil': 'huile', 'olive oil': 'huile d\'olive', 'vegetable oil': 'huile végétale',
    
    // Autres
    'egg': 'œuf', 'eggs': 'œufs', 'sugar': 'sucre', 'honey': 'miel',
    'water': 'eau', 'wine': 'vin', 'white wine': 'vin blanc', 'red wine': 'vin rouge',
    
    // Types de plats
    'soup': 'soupe', 'salad': 'salade', 'sandwich': 'sandwich',
    'burger': 'burger', 'burgers': 'burgers', 'pizza': 'pizza',
    'cake': 'gâteau', 'pie': 'tarte', 'stew': 'ragoût', 'curry': 'curry',
    'lasagna': 'lasagne', 'lasagne': 'lasagne', 'pasta': 'pâtes',
    
    // Méthodes de cuisson
    'grilled': 'grillé', 'baked': 'cuit au four', 'fried': 'frit',
    'boiled': 'bouilli', 'steamed': 'cuit à la vapeur', 'roast': 'rôti',
    'smoked': 'fumé', 'braised': 'braisé', 'stir fry': 'sauté',
    
    // Types de régimes
    'vegan': 'végétalien', 'vegetarian': 'végétarien',
    'vegetable': 'légume', 'vegetables': 'légumes',
    
    // Mots de liaison
    'and': 'et', 'with': 'aux', 'in': 'en', 'on': 'sur', 'of': 'de',
  };

  // Patterns de traduction automatique
  static final List<TranslationPattern> _translationPatterns = [
    // Pattern: "X Y" où Y est un type de plat -> "Y aux X"
    TranslationPattern(
      pattern: RegExp(r'^(.+?)\s+(curry|soup|salad|stew|burger|burgers|sandwich|pizza|pie|roast|stir fry)$', caseSensitive: false),
      translator: (match) {
        final ingredient = match.group(1)!.trim();
        final dishType = match.group(2)!.toLowerCase();
        final translatedIngredient = translateWord(ingredient);
        final translatedDishType = _baseDictionary[dishType] ?? dishType;
        return '$translatedDishType aux $translatedIngredient';
      },
    ),
    
    // Pattern: "X and Y" -> "X et Y"
    TranslationPattern(
      pattern: RegExp(r'^(.+?)\s+and\s+(.+)$', caseSensitive: false),
      translator: (match) {
        final part1 = match.group(1)!.trim();
        final part2 = match.group(2)!.trim();
        return '${translateWord(part1)} et ${translateWord(part2)}';
      },
    ),
    
    // Pattern: "X with Y" -> "X aux Y"
    TranslationPattern(
      pattern: RegExp(r'^(.+?)\s+with\s+(.+)$', caseSensitive: false),
      translator: (match) {
        final part1 = match.group(1)!.trim();
        final part2 = match.group(2)!.trim();
        return '${translateWord(part1)} aux ${translateWord(part2)}';
      },
    ),
    
    // Pattern: "Adjective Noun" -> "Noun Adjective" (pour certains adjectifs)
    TranslationPattern(
      pattern: RegExp(r'^(vegan|vegetarian|grilled|baked|fried|boiled|steamed|roast|smoked|braised)\s+(.+)$', caseSensitive: false),
      translator: (match) {
        final adjective = match.group(1)!.toLowerCase();
        final noun = match.group(2)!.trim();
        final translatedAdjective = _baseDictionary[adjective] ?? adjective;
        final translatedNoun = translateWord(noun);
        return '$translatedNoun $translatedAdjective';
      },
    ),
  ];

  /// Traduit un mot ou une phrase automatiquement
  static String translateWord(String text, {String targetLanguage = 'fr'}) {
    if (text.isEmpty) return text;
    
    final lowerText = text.toLowerCase().trim();
    
    // Essayer d'abord le dictionnaire culinaire chargé
    if (CulinaryDictionaryLoader.isLoaded) {
      final culinaryTranslation = CulinaryDictionaryLoader.translateIngredient(text, targetLanguage);
      if (culinaryTranslation != null && culinaryTranslation.toLowerCase() != lowerText) {
        return capitalize(culinaryTranslation);
      }
    }
    
    // Vérifier ensuite dans le dictionnaire de base
    if (_baseDictionary.containsKey(lowerText)) {
      return capitalize(_baseDictionary[lowerText]!);
    }
    
    // Chercher une correspondance partielle (pour les mots composés)
    for (var entry in _baseDictionary.entries) {
      if (lowerText.contains(entry.key) || entry.key.contains(lowerText)) {
        // Remplacer la partie correspondante
        final regex = RegExp(RegExp.escape(entry.key), caseSensitive: false);
        return capitalize(text.replaceAll(regex, entry.value));
      }
    }
    
    // Si c'est un mot composé (avec espaces ou tirets), traduire chaque partie
    if (text.contains(' ') || text.contains('-')) {
      final parts = text.split(RegExp(r'[\s-]+'));
      final translatedParts = parts.map((part) => translateWord(part, targetLanguage: targetLanguage)).toList();
      return translatedParts.join(' ');
    }
    
    // Si aucune traduction trouvée, retourner le texte original capitalisé
    return capitalize(text);
  }

  /// Traduit une phrase complète automatiquement
  static String translatePhrase(String phrase, {String targetLanguage = 'fr'}) {
    if (phrase.isEmpty) return phrase;
    
    // Nettoyer la phrase
    String cleaned = phrase.trim();
    
    // Essayer d'abord les patterns de traduction
    for (var pattern in _translationPatterns) {
      final match = pattern.pattern.firstMatch(cleaned);
      if (match != null) {
        final translated = pattern.translator(match);
        if (translated != cleaned) {
          return capitalizeFirst(translated);
        }
      }
    }
    
    // Si aucun pattern ne correspond, traduire mot par mot
    final words = cleaned.split(RegExp(r'\s+'));
    final translatedWords = words.map((word) {
      // Nettoyer le mot (enlever ponctuation)
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s-]'), '');
      if (cleanWord.isEmpty) return word;
      
      final translated = translateWord(cleanWord, targetLanguage: targetLanguage);
      // Garder la ponctuation originale
      if (word != cleanWord) {
        final punctuation = word.replaceAll(RegExp(r'[\w\s-]'), '');
        return translated + punctuation;
      }
      return translated;
    }).toList();
    
    return translatedWords.join(' ');
  }

  /// Capitalise la première lettre de chaque mot
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Capitalise seulement la première lettre de la phrase
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Traduit un nom de recette automatiquement
  static String translateRecipeName(String recipeName) {
    if (recipeName.isEmpty) return recipeName;
    
    // Nettoyer l'encodage
    String cleaned = recipeName.trim();
    
    // Essayer d'abord les patterns de traduction
    for (var pattern in _translationPatterns) {
      final match = pattern.pattern.firstMatch(cleaned);
      if (match != null) {
        final translated = pattern.translator(match);
        if (translated != cleaned) {
          return capitalizeFirst(translated);
        }
      }
    }
    
    // Si aucun pattern ne correspond, traduire mot par mot
    return translatePhrase(cleaned);
  }
}

/// Pattern de traduction avec regex et fonction de traduction
class TranslationPattern {
  final RegExp pattern;
  final String Function(RegExpMatch) translator;

  TranslationPattern({
    required this.pattern,
    required this.translator,
  });
}

