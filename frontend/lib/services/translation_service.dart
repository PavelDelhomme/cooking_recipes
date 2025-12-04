import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'locale_service.dart';
import 'auto_translator.dart';
import 'culinary_dictionary_loader.dart';
import 'auto_translator.dart';

/// Service de traduction pour convertir les éléments de recettes
class TranslationService extends ChangeNotifier {
  // Instance singleton
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();
  
  // Langue actuelle (par défaut français)
  String _currentLanguage = 'fr';
  
  // Initialiser la langue
  Future<void> init() async {
    _currentLanguage = await LocaleService.getLanguageCode();
    // Charger les dictionnaires culinaires
    await CulinaryDictionaryLoader.loadDictionaries();
    notifyListeners();
  }
  
  // Définir la langue
  void setLanguage(String languageCode) {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }
  
  // Obtenir la langue actuelle
  String get currentLanguage => _currentLanguage;
  
  // Méthodes statiques pour compatibilité avec le code existant
  static Future<void> initStatic() async {
    await _instance.init();
  }
  
  static void setLanguageStatic(String languageCode) {
    _instance.setLanguage(languageCode);
  }
  
  static String get currentLanguageStatic => _instance.currentLanguage;
  // Dictionnaire de traduction des ingrédients courants (anglais -> français)
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

  // Dictionnaire de traduction espagnol -> français pour les ingrédients
  static final Map<String, String> _spanishToFrenchIngredients = {
    // Viandes
    'pollo': 'Poulet',
    'carne de res': 'Bœuf',
    'res': 'Bœuf',
    'cerdo': 'Porc',
    'cordero': 'Agneau',
    'pavo': 'Dinde',
    'pato': 'Canard',
    'bistec': 'Steak',
    'carne molida': 'Viande hachée',
    'tocino': 'Bacon',
    'salchicha': 'Saucisse',
    
    // Poissons
    'salmón': 'Saumon',
    'atún': 'Thon',
    'bacalao': 'Morue',
    'trucha': 'Truite',
    'caballa': 'Maquereau',
    'pescado': 'Poisson',
    
    // Légumes
    'tomate': 'Tomate',
    'tomates': 'Tomates',
    'cebolla': 'Oignon',
    'cebollas': 'Oignons',
    'ajo': 'Ail',
    'zanahoria': 'Carotte',
    'zanahorias': 'Carottes',
    'patata': 'Pomme de terre',
    'patatas': 'Pommes de terre',
    'pimiento': 'Poivron',
    'pimientos': 'Poivrons',
    'calabacín': 'Courgette',
    'berenjena': 'Aubergine',
    'lechuga': 'Laitue',
    'espinacas': 'Épinards',
    'pepino': 'Concombre',
    'champiñón': 'Champignon',
    'champiñones': 'Champignons',
    'brócoli': 'Brocoli',
    'coliflor': 'Chou-fleur',
    'repollo': 'Chou',
    'apio': 'Céleri',
    'puerro': 'Poireau',
    'espárragos': 'Asperges',
    
    // Fruits
    'manzana': 'Pomme',
    'manzanas': 'Pommes',
    'plátano': 'Banane',
    'plátanos': 'Bananes',
    'naranja': 'Orange',
    'naranjas': 'Oranges',
    'limón': 'Citron',
    'limones': 'Citrons',
    'lima': 'Citron vert',
    'fresa': 'Fraise',
    'fresas': 'Fraises',
    'arándano': 'Myrtille',
    'arándanos': 'Myrtilles',
    'frambuesa': 'Framboise',
    'frambuesas': 'Framboises',
    
    // Produits laitiers
    'leche': 'Lait',
    'queso': 'Fromage',
    'mantequilla': 'Beurre',
    'crema': 'Crème',
    'yogur': 'Yaourt',
    'crema agria': 'Crème fraîche',
    'requesón': 'Fromage blanc',
    
    // Céréales et féculents
    'arroz': 'Riz',
    'pasta': 'Pâtes',
    'espagueti': 'Spaghettis',
    'fideos': 'Nouilles',
    'pan': 'Pain',
    'harina': 'Farine',
    'maíz': 'Maïs',
    'quinoa': 'Quinoa',
    'couscous': 'Couscous',
    'trigo': 'Boulgour',
    'avena': 'Avoine',
    'cebada': 'Orge',
    
    // Épices et herbes
    'sal': 'Sel',
    'pimienta': 'Poivre',
    'pimienta negra': 'Poivre noir',
    'pimentón': 'Paprika',
    'comino': 'Cumin',
    'cilantro': 'Coriandre',
    'perejil': 'Persil',
    'albahaca': 'Basilic',
    'orégano': 'Origan',
    'tomillo': 'Thym',
    'romero': 'Romarin',
    'salvia': 'Sauge',
    'menta': 'Menthe',
    'eneldo': 'Aneth',
    'cebollino': 'Ciboulette',
    'hoja de laurel': 'Feuille de laurier',
    'hojas de laurel': 'Feuilles de laurier',
    
    // Huiles et vinaigres
    'aceite': 'Huile',
    'aceite de oliva': 'Huile d\'olive',
    'aceite vegetal': 'Huile végétale',
    'aceite de girasol': 'Huile de tournesol',
    'vinagre': 'Vinaigre',
    'vinagre balsámico': 'Vinaigre balsamique',
    'vinagre blanco': 'Vinaigre blanc',
    'vinagre de sidra': 'Vinaigre de cidre',
    
    // Autres
    'huevo': 'Œuf',
    'huevos': 'Œufs',
    'azúcar': 'Sucre',
    'azúcar moreno': 'Sucre roux',
    'miel': 'Miel',
    'vainilla': 'Vanille',
    'extracto de vainilla': 'Extrait de vanille',
    'canela': 'Cannelle',
    'nuez moscada': 'Muscade',
    'jengibre': 'Gingembre',
    'cúrcuma': 'Curcuma',
    'curry': 'Curry',
    'chile': 'Piment',
    'salsa de soja': 'Sauce soja',
    'salsa worcestershire': 'Sauce Worcestershire',
    'pasta de tomate': 'Concentré de tomate',
    'salsa de tomate': 'Sauce tomate',
    'caldo de pollo': 'Bouillon de poulet',
    'caldo de res': 'Bouillon de bœuf',
    'caldo de verduras': 'Bouillon de légumes',
    'caldo': 'Bouillon',
    'agua': 'Eau',
    'vino': 'Vin',
    'vino blanco': 'Vin blanc',
    'vino tinto': 'Vin rouge',
  };

  /// Traduit un ingrédient selon la langue sélectionnée
  String translateIngredientInstance(String ingredient) {
    if (ingredient.isEmpty) return ingredient;
    
    // Si la langue est française, traduire depuis l'anglais ou l'espagnol
    if (_currentLanguage == 'fr') {
      final lowerIngredient = ingredient.toLowerCase().trim();
      
      // 1. Vérifier d'abord les traductions espagnol -> français
      if (TranslationService._spanishToFrenchIngredients.containsKey(lowerIngredient)) {
        return TranslationService._spanishToFrenchIngredients[lowerIngredient]!;
      }
      
      // Chercher une correspondance partielle dans le dictionnaire espagnol
      for (var entry in TranslationService._spanishToFrenchIngredients.entries) {
        if (lowerIngredient.contains(entry.key) || entry.key.contains(lowerIngredient)) {
          return entry.value;
        }
      }
      
      // 2. Vérifier ensuite les traductions anglais -> français
      if (TranslationService._ingredientTranslations.containsKey(lowerIngredient)) {
        return TranslationService._ingredientTranslations[lowerIngredient]!;
      }
      
      // Chercher une correspondance partielle dans le dictionnaire anglais
      for (var entry in TranslationService._ingredientTranslations.entries) {
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

  /// Traduit un ingrédient (méthode statique pour compatibilité)
  static String translateIngredient(String ingredient) {
    // Si la langue est française, utiliser le traducteur automatique
    if (_instance._currentLanguage == 'fr') {
      final autoTranslated = AutoTranslator.translateWord(ingredient);
      if (autoTranslated != ingredient && autoTranslated.toLowerCase() != ingredient.toLowerCase()) {
        return autoTranslated;
      }
    }
    // Fallback sur l'ancien système
    return _instance.translateIngredientInstance(ingredient);
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
    if (_instance._currentLanguage == 'fr') {
      // Utiliser le traducteur automatique pour traduire les phrases
      // Diviser en phrases et traduire chacune
      final sentences = cleaned.split(RegExp(r'[.!?]\s+'));
      final translatedSentences = sentences.map((sentence) {
        if (sentence.trim().isEmpty) return sentence;
        return AutoTranslator.translatePhrase(sentence.trim());
      }).toList();
      cleaned = translatedSentences.join('. ');
      
      // Continuer avec l'ancien système pour les ingrédients spécifiques qui n'ont pas été traduits
      // Créer un dictionnaire inverse français -> anglais pour détecter les mots français dans un texte anglais
      final frenchToEnglish = <String, String>{};
      for (var entry in TranslationService._ingredientTranslations.entries) {
        frenchToEnglish[entry.value.toLowerCase()] = entry.key;
      }
      for (var entry in TranslationService._spanishToFrenchIngredients.entries) {
        frenchToEnglish[entry.value.toLowerCase()] = entry.key;
      }
      
      // D'abord traduire les mots français qui apparaissent dans un texte anglais/espagnol
      // (ex: "Oeufs" dans "In a bowl, beat the Oeufs")
      final sortedFrenchEntries = frenchToEnglish.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length));
      
      for (var entry in sortedFrenchEntries) {
        // Chercher le mot français (avec majuscule possible)
        final frenchWord = entry.key;
        final capitalizedFrench = frenchWord[0].toUpperCase() + frenchWord.substring(1);
        final englishWord = entry.value;
        final capitalizedEnglish = englishWord[0].toUpperCase() + englishWord.substring(1);
        
        // Remplacer les occurrences avec majuscule
        cleaned = cleaned.replaceAll(RegExp(r'\b' + RegExp.escape(capitalizedFrench) + r'\b', caseSensitive: false), capitalizedEnglish);
        // Remplacer les occurrences avec minuscule
        cleaned = cleaned.replaceAll(RegExp(r'\b' + RegExp.escape(frenchWord) + r'\b', caseSensitive: false), englishWord);
      }
      
      // Ensuite traduire depuis l'espagnol vers français
      for (var entry in TranslationService._spanishToFrenchIngredients.entries) {
        final regex = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
        cleaned = cleaned.replaceAll(regex, entry.value);
      }
      
      // Enfin traduire depuis l'anglais vers français
      for (var entry in TranslationService._ingredientTranslations.entries) {
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
    
    // Si la langue est française, utiliser le traducteur automatique
    if (_instance._currentLanguage == 'fr') {
      // Utiliser le traducteur automatique en premier
      final autoTranslated = AutoTranslator.translateRecipeName(cleaned);
      if (autoTranslated != cleaned && autoTranslated.toLowerCase() != cleaned.toLowerCase()) {
        return autoTranslated;
      }
      
      // Fallback sur l'ancien système si le traducteur automatique ne trouve rien
      // Dictionnaire de traductions anglais -> français pour les termes courants dans les noms de recettes
      // IMPORTANT: Les termes longs doivent être en premier pour éviter les remplacements partiels
      final recipeTermTranslations = {
        // Légumineuses et haricots (en premier car termes longs)
        'kidney beans': 'Haricots Rouges',
        'kidney bean': 'Haricot Rouge',
        'red kidney beans': 'Haricots Rouges',
        'red kidney bean': 'Haricot Rouge',
        'black beans': 'Haricots Noirs',
        'black bean': 'Haricot Noir',
        'white beans': 'Haricots Blancs',
        'white bean': 'Haricot Blanc',
        'butter beans': 'Haricots de Lima',
        'butter bean': 'Haricot de Lima',
        'green beans': 'Haricots Verts',
        'green bean': 'Haricot Vert',
        'chickpeas': 'Pois Chiches',
        'chickpea': 'Pois Chiche',
        'lentils': 'Lentilles',
        'lentil': 'Lentille',
        'beans': 'Haricots',
        'bean': 'Haricot',
        'peas': 'Pois',
        'pea': 'Pois',
        // Viandes
        'chicken': 'Poulet',
        'beef': 'Bœuf',
        'pork': 'Porc',
        'lamb': 'Agneau',
        'turkey': 'Dinde',
        'duck': 'Canard',
        'fish': 'Poisson',
        'salmon': 'Saumon',
        'tuna': 'Thon',
        // Céréales et féculents
        'pasta': 'Pâtes',
        'spaghetti': 'Spaghettis',
        'lasagna': 'Lasagne',
        'lasagne': 'Lasagne',
        'rice': 'Riz',
        'bread': 'Pain',
        // Types de plats
        'soup': 'Soupe',
        'salad': 'Salade',
        'sandwich': 'Sandwich',
        'burger': 'Burger',
        'burgers': 'Burgers',
        'pizza': 'Pizza',
        'cake': 'Gâteau',
        'pie': 'Tarte',
        'stew': 'Ragoût',
        'curry': 'Curry',
        'stir fry': 'Sauté',
        'roast': 'Rôti',
        // Méthodes de cuisson
        'grilled': 'Grillé',
        'baked': 'Cuit au four',
        'fried': 'Frit',
        'boiled': 'Bouilli',
        'steamed': 'Cuit à la vapeur',
        'smoked': 'Fumé',
        'braised': 'Braisé',
        // Types de régimes
        'vegan': 'Végétalien',
        'vegetarian': 'Végétarien',
        'vegetable': 'Légume',
        'vegetables': 'Légumes',
        // Autres termes courants
        'and': 'et',
        'with': 'aux',
        'in': 'en',
        'on': 'sur',
      };
      
      // Dictionnaire de traductions espagnol -> français pour les termes courants dans les noms de recettes
      final spanishRecipeTermTranslations = {
        'pollo': 'Poulet',
        'res': 'Bœuf',
        'carne de res': 'Bœuf',
        'cerdo': 'Porc',
        'pescado': 'Poisson',
        'salmón': 'Saumon',
        'pasta': 'Pâtes',
        'espagueti': 'Spaghettis',
        'arroz': 'Riz',
        'sopa': 'Soupe',
        'ensalada': 'Salade',
        'sándwich': 'Sandwich',
        'hamburguesa': 'Burger',
        'pizza': 'Pizza',
        'pastel': 'Gâteau',
        'tarta': 'Tarte',
        'pan': 'Pain',
        'estofado': 'Ragoût',
        'curry': 'Curry',
        'salteado': 'Sauté',
        'asado': 'Rôti',
        'a la parrilla': 'Grillé',
        'al horno': 'Cuit au four',
        'frito': 'Frit',
        'hervido': 'Bouilli',
        'al vapor': 'Cuit à la vapeur',
        'paella': 'Paella',
        'tortilla': 'Tortilla',
        'gazpacho': 'Gaspacho',
        'tapas': 'Tapas',
        'empanada': 'Empanada',
        'flan': 'Flan',
        'churros': 'Churros',
      };
      
      // Traduire d'abord depuis l'espagnol
      String translated = cleaned;
      for (var entry in spanishRecipeTermTranslations.entries) {
        final regex = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
        translated = translated.replaceAll(regex, entry.value);
      }
      
      // Ensuite traduire depuis l'anglais (ordre important : termes longs d'abord)
      final sortedEntries = recipeTermTranslations.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length));
      
      for (var entry in sortedEntries) {
        final regex = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
        translated = translated.replaceAll(regex, entry.value);
      }
      
      // Réorganiser les mots pour un ordre plus naturel en français
      // Par exemple : "Kidney Bean Curry" -> "Curry aux Haricots Rouges"
      // ou "Vegan Lasagna" -> "Lasagne Végétalienne"
      final words = translated.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.length > 1) {
        // Réorganiser les structures "X Y" où Y est un type de plat et X est un ingrédient
        // Exemple : "Kidney Bean Curry" -> "Curry aux Haricots Rouges"
        final dishTypes = ['Curry', 'Soupe', 'Salade', 'Ragoût', 'Burger', 'Burgers', 'Sandwich', 'Pizza', 'Gâteau', 'Tarte', 'Rôti', 'Sauté'];
        for (var dishType in dishTypes) {
          final index = words.indexOf(dishType);
          if (index > 0) {
            // Si on trouve un type de plat qui n'est pas en premier
            // Réorganiser : "Kidney Bean Curry" -> "Curry aux Haricots Rouges"
            final beforeDish = words.sublist(0, index);
            final afterDish = words.sublist(index + 1);
            if (beforeDish.isNotEmpty) {
              // Construire "Curry aux Haricots Rouges"
              final dishTypeWord = words[index];
              final ingredients = beforeDish.join(' ');
              translated = '$dishTypeWord aux $ingredients${afterDish.isNotEmpty ? ' ${afterDish.join(' ')}' : ''}';
              break;
            }
          }
        }
        
        // Si le premier mot est un adjectif (Végétalien, Végétarien), le mettre à la fin
        final adjectives = ['Végétalien', 'Végétarien', 'Grillé', 'Frit', 'Cuit au four', 'Bouilli', 'Cuit à la vapeur', 'Rôti', 'Sauté', 'Fumé', 'Braisé'];
        if (adjectives.contains(words[0]) && !translated.contains('aux')) {
          final adj = words[0];
          words.removeAt(0);
          words.add(adj);
          translated = words.join(' ');
        }
      }
      
      // Capitaliser la première lettre de chaque mot (en respectant les mots composés)
      if (translated.isNotEmpty) {
        final capitalizedWords = translated.split(' ').map((word) {
          if (word.isEmpty) return word;
          // Ne pas modifier les mots qui commencent déjà par une majuscule (comme "Curry")
          if (word[0] == word[0].toUpperCase() && word.length > 1 && word[1] == word[1].toLowerCase()) {
            return word; // Déjà capitalisé correctement
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).toList();
        translated = capitalizedWords.join(' ');
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
      'knob': 'noix',
      'knobs': 'noix',
      'tbs': 'cuillère à soupe',
      'tb': 'cuillère à soupe',
      't': 'cuillère à soupe',
      'tbl': 'cuillère à soupe',
      'tblsp': 'cuillère à soupe',
      'tblspn': 'cuillère à soupe',
      'tablespoon': 'cuillère à soupe',
      'tablespoons': 'cuillères à soupe',
      'ts': 'cuillère à café',
      'tbsp': 'cuillère à soupe',
      'tsp': 'cuillère à café',
      'teaspoon': 'cuillère à café',
      'teaspoons': 'cuillères à café',
      'fl oz': 'fl oz',
      'fluid ounce': 'fl oz',
      'fluid ounces': 'fl oz',
      'pt': 'pinte',
      'pint': 'pinte',
      'pints': 'pintes',
      'qt': 'quart',
      'quart': 'quart',
      'quarts': 'quarts',
      'gal': 'gallon',
      'gallon': 'gallon',
      'gallons': 'gallons',
      'dash': 'filet',
      'dashes': 'filets',
      'drop': 'goutte',
      'drops': 'gouttes',
      'sprig': 'brin',
      'sprigs': 'brins',
      'stalk': 'branche',
      'stalks': 'branches',
      'rib': 'côte',
      'ribs': 'côtes',
      'fillet': 'filet',
      'fillets': 'filets',
      'strip': 'bande',
      'strips': 'bandes',
      'chunk': 'morceau',
      'chunks': 'morceaux',
      'wedge': 'quartier',
      'wedges': 'quartiers',
      'segment': 'segment',
      'segments': 'segments',
      'whole': 'entier',
      'halves': 'moitiés',
      'half': 'demi',
      'quarter': 'quart',
      'quarters': 'quarts',
      'third': 'tiers',
      'thirds': 'tiers',
      'eighth': 'huitième',
      'eighths': 'huitièmes',
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
    
    final langTranslations = _unitTranslations[_instance._currentLanguage] ?? _unitTranslations['fr']!;
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

  /// Dictionnaire de traduction des termes de préparation
  static final Map<String, Map<String, String>> _preparationTranslations = {
    'fr': {
      'chopped': 'haché',
      'diced': 'coupé en dés',
      'sliced': 'tranché',
      'minced': 'haché finement',
      'grated': 'râpé',
      'shredded': 'râpé',
      'crushed': 'écrasé',
      'mashed': 'écrasé',
      'pureed': 'en purée',
      'julienned': 'julienne',
      'cubed': 'coupé en cubes',
      'quartered': 'coupé en quartiers',
      'halved': 'coupé en deux',
      'whole': 'entier',
      'peeled': 'épluché',
      'seeded': 'épépiné',
      'cored': 'évidé',
      'trimmed': 'paré',
      'cleaned': 'nettoyé',
      'washed': 'lavé',
      'dried': 'séché',
      'toasted': 'grillé',
      'roasted': 'rôti',
      'grilled': 'grillé',
      'fried': 'frit',
      'cooked': 'cuit',
      'raw': 'cru',
      'fresh': 'frais',
      'frozen': 'congelé',
      'canned': 'en conserve',
      'drained': 'égoutté',
      'rinsed': 'rincé',
      'soaked': 'trempé',
      'marinated': 'mariné',
      'seasoned': 'assaisonné',
      'salted': 'salé',
      'unsalted': 'non salé',
      'melted': 'fondu',
      'softened': 'ramolli',
      'room temperature': 'température ambiante',
      'warm': 'tiède',
      'cold': 'froid',
      'hot': 'chaud',
      'optional': 'optionnel',
      'to taste': 'au goût',
      'as needed': 'selon besoin',
      'large': 'gros',
      'medium': 'moyen',
      'small': 'petit',
      'extra large': 'très gros',
      'extra small': 'très petit',
      'fine': 'fin',
      'coarse': 'gros',
      'thin': 'fin',
      'thick': 'épais',
      'round': 'rond',
      'square': 'carré',
      'long': 'long',
      'short': 'court',
      'wide': 'large',
      'narrow': 'étroit',
    },
    'es': {
      'chopped': 'picado',
      'diced': 'cortado en cubos',
      'sliced': 'cortado en rodajas',
      'minced': 'picado fino',
      'grated': 'rallado',
      'shredded': 'rallado',
      'crushed': 'triturado',
      'mashed': 'triturado',
      'pureed': 'en puré',
      'julienned': 'juliana',
      'cubed': 'cortado en cubos',
      'quartered': 'cortado en cuartos',
      'halved': 'cortado por la mitad',
      'whole': 'entero',
      'peeled': 'pelado',
      'seeded': 'sin semillas',
      'cored': 'sin corazón',
      'trimmed': 'recortado',
      'cleaned': 'limpio',
      'washed': 'lavado',
      'dried': 'seco',
      'toasted': 'tostado',
      'roasted': 'asado',
      'grilled': 'a la parrilla',
      'fried': 'frito',
      'cooked': 'cocido',
      'raw': 'crudo',
      'fresh': 'fresco',
      'frozen': 'congelado',
      'canned': 'enlatado',
      'drained': 'escurrido',
      'rinsed': 'enjuagado',
      'soaked': 'remojado',
      'marinated': 'marinado',
      'seasoned': 'sazonado',
      'salted': 'salado',
      'unsalted': 'sin sal',
      'melted': 'derretido',
      'softened': 'ablandado',
      'room temperature': 'temperatura ambiente',
      'warm': 'tibio',
      'cold': 'frío',
      'hot': 'caliente',
      'optional': 'opcional',
      'to taste': 'al gusto',
      'as needed': 'según necesidad',
      'large': 'grande',
      'medium': 'mediano',
      'small': 'pequeño',
      'extra large': 'muy grande',
      'extra small': 'muy pequeño',
      'fine': 'fino',
      'coarse': 'grueso',
      'thin': 'delgado',
      'thick': 'grueso',
      'round': 'redondo',
      'square': 'cuadrado',
      'long': 'largo',
      'short': 'corto',
      'wide': 'ancho',
      'narrow': 'estrecho',
    },
    'en': {
      'chopped': 'chopped',
      'diced': 'diced',
      'sliced': 'sliced',
      'minced': 'minced',
      'grated': 'grated',
      'shredded': 'shredded',
      'crushed': 'crushed',
      'mashed': 'mashed',
      'pureed': 'pureed',
      'julienned': 'julienned',
      'cubed': 'cubed',
      'quartered': 'quartered',
      'halved': 'halved',
      'whole': 'whole',
      'peeled': 'peeled',
      'seeded': 'seeded',
      'cored': 'cored',
      'trimmed': 'trimmed',
      'cleaned': 'cleaned',
      'washed': 'washed',
      'dried': 'dried',
      'toasted': 'toasted',
      'roasted': 'roasted',
      'grilled': 'grilled',
      'fried': 'fried',
      'cooked': 'cooked',
      'raw': 'raw',
      'fresh': 'fresh',
      'frozen': 'frozen',
      'canned': 'canned',
      'drained': 'drained',
      'rinsed': 'rinsed',
      'soaked': 'soaked',
      'marinated': 'marinated',
      'seasoned': 'seasoned',
      'salted': 'salted',
      'unsalted': 'unsalted',
      'melted': 'melted',
      'softened': 'softened',
      'room temperature': 'room temperature',
      'warm': 'warm',
      'cold': 'cold',
      'hot': 'hot',
      'optional': 'optional',
      'to taste': 'to taste',
      'as needed': 'as needed',
      'large': 'large',
      'medium': 'medium',
      'small': 'small',
      'extra large': 'extra large',
      'extra small': 'extra small',
      'fine': 'fine',
      'coarse': 'coarse',
      'thin': 'thin',
      'thick': 'thick',
      'round': 'round',
      'square': 'square',
      'long': 'long',
      'short': 'short',
      'wide': 'wide',
      'narrow': 'narrow',
    },
  };

  /// Traduit un terme de préparation selon la langue sélectionnée (méthode statique)
  static String translatePreparation(String preparation) {
    if (preparation.isEmpty) return preparation;
    
    final langTranslations = _preparationTranslations[_instance._currentLanguage] ?? _preparationTranslations['fr']!;
    final lowerPrep = preparation.toLowerCase().trim();
    
    // Vérifier d'abord la correspondance exacte
    if (langTranslations.containsKey(lowerPrep)) {
      return langTranslations[lowerPrep]!;
    }
    
    // Chercher une correspondance partielle
    for (var entry in langTranslations.entries) {
      if (lowerPrep.contains(entry.key) || entry.key.contains(lowerPrep)) {
        return entry.value;
      }
    }
    
    // Si aucune traduction trouvée, retourner le terme original
    return preparation;
  }

  /// Convertit un nom d'ingrédient français en nom anglais (pour les images TheMealDB)
  static String getEnglishName(String frenchName) {
    if (frenchName.isEmpty) return frenchName;
    
    // Nettoyer le nom (trim, etc.)
    final cleaned = frenchName.trim();
    if (cleaned.isEmpty) return frenchName;
    
    // Normaliser le nom (enlever accents, minuscules, etc.)
    String normalized = cleaned.toLowerCase();
    
    // Normaliser les caractères spéciaux (œ -> oe, etc.)
    // IMPORTANT: Faire cette normalisation AVANT de créer le dictionnaire inverse
    normalized = normalized
        .replaceAll('œ', 'oe')
        .replaceAll('æ', 'ae')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ä', 'a');
    
    // Créer un dictionnaire inverse (français -> anglais)
    final reverseTranslations = <String, String>{};
    for (var entry in TranslationService._ingredientTranslations.entries) {
      final frenchValue = entry.value.toLowerCase().trim();
      // Normaliser aussi la valeur française
      final normalizedFrench = frenchValue
          .replaceAll('œ', 'oe')
          .replaceAll('æ', 'ae')
          .replaceAll('é', 'e')
          .replaceAll('è', 'e')
          .replaceAll('ê', 'e')
          .replaceAll('ë', 'e')
          .replaceAll('à', 'a')
          .replaceAll('â', 'a')
          .replaceAll('ç', 'c')
          .replaceAll('ô', 'o')
          .replaceAll('ù', 'u')
          .replaceAll('û', 'u')
          .replaceAll('ï', 'i')
          .replaceAll('î', 'i')
          .replaceAll('ñ', 'n')
          .replaceAll('ü', 'u')
          .replaceAll('ö', 'o')
          .replaceAll('ä', 'a');
      reverseTranslations[normalizedFrench] = entry.key;
      // Ajouter aussi la version non normalisée pour correspondance exacte
      reverseTranslations[frenchValue] = entry.key;
    }
    
    // Ajouter des traductions spéciales pour les cas courants (avec et sans normalisation)
    // IMPORTANT: Vérifier d'abord la version originale, puis la version normalisée
    final specialTranslations = {
      'bœuf': 'beef',
      'boeuf': 'beef',
      'beuf': 'beef', // version normalisée
      'œuf': 'egg',
      'oeuf': 'egg',
      'œufs': 'eggs',
      'oeufs': 'eggs',
      'pain': 'bread',
      'laitue': 'lettuce',
      'tomate': 'tomato',
      'tomates': 'tomatoes',
      'oignon': 'onion',
      'oignons': 'onions',
      'poivre': 'pepper',
      'poivron': 'pepper',
      'poivrons': 'peppers',
      'poulet': 'chicken',
      'porc': 'pork',
      'poisson': 'fish',
      'saumon': 'salmon',
      'ail': 'garlic',
      'carotte': 'carrot',
      'carottes': 'carrots',
      'pomme de terre': 'potato',
      'pommes de terre': 'potatoes',
      'courgette': 'zucchini',
      'aubergine': 'eggplant',
      'epinards': 'spinach',
      'épinards': 'spinach',
      'concombre': 'cucumber',
      'champignon': 'mushroom',
      'champignons': 'mushrooms',
      'brocoli': 'broccoli',
      'chou-fleur': 'cauliflower',
      'chou': 'cabbage',
      'celeri': 'celery',
      'céleri': 'celery',
      'poireau': 'leek',
      'asperges': 'asparagus',
      'pomme': 'apple',
      'pommes': 'apples',
      'banane': 'banana',
      'bananes': 'bananas',
      'orange': 'orange',
      'oranges': 'oranges',
      'citron': 'lemon',
      'citrons': 'lemons',
      'citron vert': 'lime',
      'fraise': 'strawberry',
      'fraises': 'strawberries',
      'myrtille': 'blueberry',
      'myrtilles': 'blueberries',
      'framboise': 'raspberry',
      'framboises': 'raspberries',
      'lait': 'milk',
      'fromage': 'cheese',
      'beurre': 'butter',
      'creme': 'cream',
      'crème': 'cream',
      'yaourt': 'yogurt',
      'riz': 'rice',
      'pates': 'pasta',
      'pâtes': 'pasta',
      'spaghettis': 'spaghetti',
      'nouilles': 'noodles',
      'farine': 'flour',
      'farine de ble': 'wheat flour',
      'farine de blé': 'wheat flour',
      'mais': 'corn',
      'maïs': 'corn',
      'couscous': 'couscous',
      'boulgour': 'bulgur',
      'avoine': 'oats',
      'orge': 'barley',
      'sel': 'salt',
      'poivre noir': 'black pepper',
      'paprika': 'paprika',
      'cumin': 'cumin',
      'coriandre': 'coriander',
      'persil': 'parsley',
      'basilic': 'basil',
      'origan': 'oregano',
      'thym': 'thyme',
      'romarin': 'rosemary',
      'sauge': 'sage',
      'menthe': 'mint',
    };
    
    // Vérifier d'abord les traductions spéciales (version originale et normalisée)
    final lowerFrench = cleaned.toLowerCase();
    print('🔍 Recherche traduction pour: "$frenchName" (lower: "$lowerFrench", normalized: "$normalized")');
    
    if (specialTranslations.containsKey(lowerFrench)) {
      final result = specialTranslations[lowerFrench]!;
      print('✅ Traduction spéciale trouvée: "$frenchName" -> "$result"');
      return result;
    }
    if (specialTranslations.containsKey(normalized)) {
      final result = specialTranslations[normalized]!;
      print('✅ Traduction spéciale normalisée trouvée: "$frenchName" -> "$result"');
      return result;
    }
    
    // Vérifier ensuite la correspondance exacte dans le dictionnaire inverse (version originale et normalisée)
    if (reverseTranslations.containsKey(lowerFrench)) {
      final result = reverseTranslations[lowerFrench]!;
      print('✅ Traduction dictionnaire trouvée: "$frenchName" -> "$result"');
      return result;
    }
    if (reverseTranslations.containsKey(normalized)) {
      final result = reverseTranslations[normalized]!;
      print('✅ Traduction dictionnaire normalisée trouvée: "$frenchName" -> "$result"');
      return result;
    }
    
    // Chercher une correspondance partielle (termes longs d'abord)
    final sortedEntries = reverseTranslations.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    
    for (var entry in sortedEntries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        final result = entry.value;
        print('✅ Traduction partielle trouvée: "$frenchName" -> "$result"');
        return result;
      }
    }
    
    // Si aucune correspondance trouvée, retourner le nom tel quel (peut-être déjà en anglais)
    // Mais d'abord, essayer de normaliser pour voir si ça correspond à quelque chose
    print('⚠️ Aucune traduction trouvée pour: "$frenchName" (normalisé: "$normalized"), utilisation du nom original');
    return frenchName;
  }
}

