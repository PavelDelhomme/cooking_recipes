import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../models/ingredient.dart';
import 'translation_service.dart';
import 'locale_service.dart';

class RecipeApiService {
  // Utilisation de TheMealDB (gratuit, pas besoin d'API key)
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  
  // Alternative: Spoonacular (nécessite une clé API gratuite)
  // static const String spoonacularBaseUrl = 'https://api.spoonacular.com/recipes';
  // static const String apiKey = 'VOTRE_CLE_API';

  // Rechercher des recettes par nom
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search.php?s=$query'),
      );

      if (response.statusCode == 200) {
        // Définir l'encodage UTF-8 explicitement
        final utf8Body = utf8.decode(response.bodyBytes);
        final data = json.decode(utf8Body);
        if (data['meals'] != null) {
          final recipes = <Recipe>[];
          for (var meal in data['meals'] as List) {
            recipes.add(await _convertMealToRecipe(meal));
          }
          return recipes;
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la recherche de recettes: $e');
      return [];
    }
  }

  // Rechercher des recettes par ingrédient (retourne seulement les IDs)
  Future<List<String>> searchRecipeIdsByIngredient(String ingredient) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter.php?i=$ingredient'),
      );

      if (response.statusCode == 200) {
        // Définir l'encodage UTF-8 explicitement
        final utf8Body = utf8.decode(response.bodyBytes);
        final data = json.decode(utf8Body);
        if (data['meals'] != null) {
          return (data['meals'] as List)
              .map((meal) => meal['idMeal'].toString())
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la recherche par ingrédient: $e');
      return [];
    }
  }

  // Rechercher des recettes par ingrédient (avec détails complets)
  Future<List<Recipe>> searchRecipesByIngredient(String ingredient) async {
    try {
      final ids = await searchRecipeIdsByIngredient(ingredient);
      // Limiter à 10 recettes pour éviter trop d'appels API
      final limitedIds = ids.take(10).toList();
      
      // Récupérer les détails en parallèle
      final recipes = await Future.wait(
        limitedIds.map((id) => getRecipeById(id)),
      );
      
      return recipes.whereType<Recipe>().toList();
    } catch (e) {
      print('Erreur lors de la recherche par ingrédient: $e');
      return [];
    }
  }

  // Rechercher des recettes par plusieurs ingrédients
  Future<List<Recipe>> searchRecipesByIngredients(List<String> ingredients) async {
    try {
      // TheMealDB ne supporte pas directement la recherche multi-ingrédients
      // On va chercher pour chaque ingrédient et faire une intersection
      if (ingredients.isEmpty) {
        return await getRandomRecipes(10);
      }

      Map<String, int> recipeCounts = {};
      
      // Récupérer les IDs pour chaque ingrédient
      for (var ingredient in ingredients) {
        final ids = await searchRecipeIdsByIngredient(ingredient);
        for (var id in ids) {
          recipeCounts[id] = (recipeCounts[id] ?? 0) + 1;
        }
      }

      // Trier par nombre d'ingrédients correspondants
      final sortedIds = recipeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Limiter à 15 recettes pour éviter trop d'appels API
      final topIds = sortedIds.take(15).map((e) => e.key).toList();

      // Récupérer les détails en parallèle
      final recipes = await Future.wait(
        topIds.map((id) => getRecipeById(id)),
      );

      return recipes.whereType<Recipe>().toList();
    } catch (e) {
      print('Erreur lors de la recherche multi-ingrédients: $e');
      return [];
    }
  }

  // Obtenir une recette par ID
  Future<Recipe?> getRecipeById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lookup.php?i=$id'),
      );

      if (response.statusCode == 200) {
        // Définir l'encodage UTF-8 explicitement
        final utf8Body = utf8.decode(response.bodyBytes);
        final data = json.decode(utf8Body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return await _convertMealToRecipe(data['meals'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la recette: $e');
      return null;
    }
  }

  // Obtenir des recettes aléatoires
  Future<List<Recipe>> getRandomRecipes(int count) async {
    try {
      final List<Recipe> recipes = [];
      for (int i = 0; i < count; i++) {
        final response = await http.get(
          Uri.parse('$baseUrl/random.php'),
        );

        if (response.statusCode == 200) {
          // Définir l'encodage UTF-8 explicitement
          final utf8Body = utf8.decode(response.bodyBytes);
          final data = json.decode(utf8Body);
          if (data['meals'] != null && data['meals'].isNotEmpty) {
            recipes.add(await _convertMealToRecipe(data['meals'][0]));
          }
        }
        // Petite pause pour éviter de surcharger l'API
        await Future.delayed(const Duration(milliseconds: 200));
      }
      return recipes;
    } catch (e) {
      print('Erreur lors de la récupération de recettes aléatoires: $e');
      return [];
    }
  }

  // Obtenir des suggestions de recherche (noms de recettes populaires)
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.trim().isEmpty) {
        // Retourner des suggestions populaires par défaut
        return [
          'chicken', 'pasta', 'salad', 'soup', 'dessert',
          'beef', 'fish', 'rice', 'pizza', 'cake',
          'bread', 'soup', 'stew', 'curry', 'burger'
        ];
      }

      // Rechercher des recettes correspondant à la requête
      final recipes = await searchRecipes(query);
      
      // Extraire les noms de recettes comme suggestions
      final suggestions = recipes
          .map((recipe) => recipe.title)
          .where((title) => title.toLowerCase().contains(query.toLowerCase()))
          .take(10)
          .toList();

      // Si pas assez de suggestions, ajouter des termes populaires
      if (suggestions.length < 5) {
        final popularTerms = [
          'chicken', 'pasta', 'salad', 'soup', 'dessert',
          'beef', 'fish', 'rice', 'pizza', 'cake'
        ];
        for (var term in popularTerms) {
          if (term.toLowerCase().contains(query.toLowerCase()) && 
              !suggestions.contains(term)) {
            suggestions.add(term);
          }
        }
      }

      return suggestions.take(10).toList();
    } catch (e) {
      print('Erreur lors de la récupération des suggestions: $e');
      return [];
    }
  }

  // Convertir un meal de TheMealDB en Recipe
  Future<Recipe> _convertMealToRecipe(Map<String, dynamic> meal) async {
    // Initialiser la langue si nécessaire
    await TranslationService.init();
    
    final List<Ingredient> ingredients = [];
    final List<String> instructions = [];

    // Extraire les ingrédients (TheMealDB utilise strIngredient1, strIngredient2, etc.)
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        // Nettoyer et traduire l'ingrédient
        String ingredientName = TranslationService.fixEncoding(ingredient.toString().trim());
        ingredientName = TranslationService.translateIngredient(ingredientName);
        
        // Parser la quantité et l'unité
        final measureStr = measure?.toString().trim() ?? '';
        double? quantity = _parseQuantity(measureStr);
        String? unitString = _parseUnitSync(measureStr);
        
        // Si l'unité est null ou vide, essayer de la déduire du nom de l'ingrédient
        if (unitString == null || unitString.isEmpty) {
          unitString = _guessUnitFromIngredient(ingredientName);
        }
        
        // Traduire l'unité
        String? unit = unitString != null ? TranslationService.translateUnit(unitString) : null;
        
        // Si l'unité est toujours vide après traduction, la mettre à null
        if (unit != null && unit.isEmpty) {
          unit = null;
        }
        
        // Pour les herbes et épices, s'assurer que la quantité et l'unité sont cohérentes
        if (_isHerbOrSpice(ingredientName)) {
          // Si l'unité contient "L" ou "l" (absurde pour une herbe), la remplacer
          if (unit != null && (unit.toLowerCase().contains('l') || unit.toLowerCase().contains('litre'))) {
            unit = 'pot';
            if (quantity == null || quantity <= 0) {
              quantity = 1.0;
            }
          }
          // Si pas d'unité mais une quantité, ajouter une unité par défaut
          if (unit == null && quantity != null && quantity > 0) {
            unit = 'pot';
          }
          // Si pas de quantité mais une unité, ajouter une quantité par défaut
          if (quantity == null && unit != null) {
            quantity = 1.0;
          }
        }
        
        ingredients.add(Ingredient(
          id: '${meal['idMeal']}_ingredient_$i',
          name: ingredientName,
          quantity: quantity,
          unit: unit,
        ));
      }
    }

    // Extraire les instructions
    String instructionsText = meal['strInstructions']?.toString() ?? '';
    if (instructionsText.isNotEmpty) {
      // Nettoyer l'encodage d'abord
      instructionsText = TranslationService.fixEncoding(instructionsText);
      
      // Nettoyer les "step 1", "step 2", etc. AVANT la traduction
      instructionsText = instructionsText.replaceAll(RegExp(r'step\s+\d+[:\s]*', caseSensitive: false), '');
      instructionsText = instructionsText.replaceAll(RegExp(r'Step\s+\d+[:\s]*', caseSensitive: false), '');
      instructionsText = instructionsText.replaceAll(RegExp(r'STEP\s+\d+[:\s]*', caseSensitive: false), '');
      
      // Traduire après le nettoyage
      instructionsText = TranslationService.cleanAndTranslate(instructionsText);
      
      // Diviser par les retours à la ligne, les numéros, ou les points suivis d'un espace
      final lines = instructionsText
          .split(RegExp(r'\n|\r\n|(?<=\d)\.\s+|(?<=[.!?])\s+(?=[A-Z])|(?<=[.!?])\s+(?=\d+\.)'))
          .where((line) => line.trim().isNotEmpty)
          .map((line) {
            // Nettoyer chaque ligne
            String cleaned = line.trim();
            // Enlever les numéros au début (1., 2., etc.)
            cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s*'), '');
            // Enlever les "step" restants
            cleaned = cleaned.replaceAll(RegExp(r'^step\s+\d+[:\s]*', caseSensitive: false), '');
            cleaned = cleaned.replaceAll(RegExp(r'^Step\s+\d+[:\s]*', caseSensitive: false), '');
            cleaned = cleaned.replaceAll(RegExp(r'^STEP\s+\d+[:\s]*', caseSensitive: false), '');
            // Enlever les espaces multiples
            cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
            return cleaned;
          })
          .where((line) => line.trim().isNotEmpty && line.trim().length > 5) // Filtrer les lignes trop courtes (réduit de 10 à 5)
          .toList();
      
      instructions.addAll(lines);
    }

    // Nettoyer et traduire le titre
    String title = meal['strMeal']?.toString() ?? 'Recette sans nom';
    title = TranslationService.fixEncoding(title);
    title = TranslationService.translateRecipeName(title);
    
    // La description est un résumé des instructions (première phrase ou 200 premiers caractères)
    String summary = meal['strInstructions']?.toString() ?? '';
    summary = TranslationService.fixEncoding(summary);
    
    // Nettoyer les "step" avant la traduction
    summary = summary.replaceAll(RegExp(r'step\s+\d+[:\s]*', caseSensitive: false), '');
    summary = summary.replaceAll(RegExp(r'Step\s+\d+[:\s]*', caseSensitive: false), '');
    
    // Traduire
    summary = TranslationService.cleanAndTranslate(summary);
    
    // Prendre la première phrase ou les 200 premiers caractères
    final firstSentence = summary.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.length > 20) {
      summary = firstSentence;
    } else {
      summary = summary.length > 200 ? summary.substring(0, 200) + '...' : summary;
    }

    return Recipe(
      id: meal['idMeal'].toString(),
      title: title,
      image: meal['strMealThumb']?.toString(),
      summary: summary,
      ingredients: ingredients,
      instructions: instructions,
      servings: 4, // TheMealDB ne fournit pas cette info
    );
  }

  // Parser la quantité depuis une mesure
  double? _parseQuantity(String measure) {
    if (measure.isEmpty) return null;
    
    // Nettoyer la mesure
    String cleaned = measure.trim();
    
    // Patterns pour extraire les nombres (supporte fractions, décimales, etc.)
    // Exemples: "1.5", "1/2", "2", "0.5", "1 1/2"
    final patterns = [
      RegExp(r'^(\d+\.?\d*)\s*'), // "1.5", "2", "0.5"
      RegExp(r'(\d+\.?\d*)'), // N'importe quel nombre dans la chaîne
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(cleaned);
      if (match != null) {
        final quantityStr = match.group(1) ?? '';
        final quantity = double.tryParse(quantityStr);
        if (quantity != null && quantity > 0) {
          return quantity;
        }
      }
    }
    
    return null;
  }

  // Parser l'unité depuis une mesure (synchrone)
  String? _parseUnitSync(String measure) {
    if (measure.isEmpty) return null;
    
    String cleaned = measure.trim();
    
    // Enlever les nombres au début pour extraire l'unité
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.?\d*\s*'), '');
    cleaned = cleaned.trim();
    
    if (cleaned.isEmpty) return null;
    
    // Liste des unités invalides à ignorer ou remplacer
    final invalidUnits = {
      'medium': null, // "Medium" n'est pas une unité valide
      'large': null,
      'small': null,
      'big': null,
      'little': null,
      'few': null,
      'some': null,
      'to taste': 'au goût',
      'pinch': 'pincée',
      'handful': 'poignée',
    };
    
    final lowerCleaned = cleaned.toLowerCase();
    
    // Vérifier si c'est une unité invalide
    for (var entry in invalidUnits.entries) {
      if (lowerCleaned == entry.key || lowerCleaned.contains(entry.key)) {
        return entry.value; // Retourne null si invalide, ou la traduction si disponible
      }
    }
    
    // Nettoyer les unités bizarres ou mal formatées
    // Exemples: "0.5 1" -> "L" (si on détecte que c'est probablement "0.5 L")
    if (RegExp(r'^\d+\.?\d*\s*\d+$').hasMatch(cleaned)) {
      // Si c'est juste des nombres, essayer de deviner l'unité
      // Par exemple "0.5 1" pourrait être "0.5 L"
      return null; // On ne peut pas deviner, donc null
    }
    
    // Nettoyer les espaces multiples et caractères bizarres
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\sÀ-ÿ]'), ''); // Enlever caractères spéciaux sauf lettres et accents
    
    // Unités communes à détecter et normaliser
    final unitNormalizations = {
      'l': 'L',
      'ml': 'ml',
      'g': 'g',
      'kg': 'kg',
      'cup': 'tasse',
      'cups': 'tasses',
      'tbsp': 'cuillère à soupe',
      'tsp': 'cuillère à café',
      'oz': 'oz',
      'lb': 'lb',
      'piece': 'pièce',
      'pieces': 'pièces',
      'pcs': 'pièces',
      'bunch': 'botte',
      'bunches': 'bottes',
      'head': 'tête',
      'heads': 'têtes',
      'clove': 'gousse',
      'cloves': 'gousses',
      'sprig': 'brin',
      'sprigs': 'brins',
      'leaf': 'feuille',
      'leaves': 'feuilles',
      'stalk': 'branche',
      'stalks': 'branches',
    };
    
    final lowerUnit = cleaned.toLowerCase();
    
    // Vérifier les normalisations
    for (var entry in unitNormalizations.entries) {
      if (lowerUnit == entry.key || lowerUnit.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Si l'unité contient des mots-clés d'herbes/épices, utiliser une unité appropriée
    final herbKeywords = ['thyme', 'thym', 'basil', 'basilic', 'oregano', 'origan', 'rosemary', 'romarin', 'parsley', 'persil', 'mint', 'menthe', 'dill', 'aneth', 'sage', 'sauge', 'chives', 'ciboulette'];
    final spiceKeywords = ['pepper', 'poivre', 'salt', 'sel', 'paprika', 'cumin', 'coriander', 'coriandre', 'cinnamon', 'cannelle', 'nutmeg', 'muscade', 'ginger', 'gingembre', 'turmeric', 'curcuma', 'curry'];
    
    final isHerb = herbKeywords.any((keyword) => lowerUnit.contains(keyword));
    final isSpice = spiceKeywords.any((keyword) => lowerUnit.contains(keyword));
    
    if (isHerb || isSpice) {
      // Pour les herbes et épices, utiliser des unités appropriées
      if (lowerUnit.contains('bunch') || lowerUnit.contains('botte')) {
        return 'botte';
      } else if (lowerUnit.contains('sprig') || lowerUnit.contains('brin')) {
        return 'brin';
      } else if (lowerUnit.contains('tbsp') || lowerUnit.contains('cuillère à soupe')) {
        return 'cuillère à soupe';
      } else if (lowerUnit.contains('tsp') || lowerUnit.contains('cuillère à café')) {
        return 'cuillère à café';
      } else {
        // Par défaut pour les herbes/épices, utiliser "pot" ou "pincée"
        return 'pot';
      }
    }
    
    // Si l'unité contient "L" ou "l" mais que c'est pour une herbe/épice, c'est une erreur
    if ((lowerUnit.contains('l') || lowerUnit.contains('liter') || lowerUnit.contains('litre')) && (isHerb || isSpice)) {
      return 'pot'; // Remplacer par une unité appropriée
    }
    
    // Retourner l'unité nettoyée si elle semble valide
    if (cleaned.length > 0 && cleaned.length < 30) {
      return cleaned;
    }
    
    return null;
  }
  
  // Deviner l'unité à partir du nom de l'ingrédient
  String? _guessUnitFromIngredient(String ingredientName) {
    final lowerName = ingredientName.toLowerCase();
    
    // Herbes (généralement en pot, botte, ou brin)
    final herbs = ['thym', 'thyme', 'basilic', 'basil', 'origan', 'oregano', 'romarin', 'rosemary', 
                   'persil', 'parsley', 'menthe', 'mint', 'aneth', 'dill', 'sauge', 'sage', 
                   'ciboulette', 'chives', 'coriandre', 'coriander'];
    if (herbs.any((herb) => lowerName.contains(herb))) {
      return 'pot';
    }
    
    // Épices (généralement en pot, cuillère, ou pincée)
    final spices = ['poivre', 'pepper', 'sel', 'salt', 'paprika', 'cumin', 'cannelle', 'cinnamon',
                   'muscade', 'nutmeg', 'gingembre', 'ginger', 'curcuma', 'turmeric', 'curry'];
    if (spices.any((spice) => lowerName.contains(spice))) {
      return 'pot';
    }
    
    // Légumes entiers (généralement en pièce)
    final wholeVegetables = ['oignon', 'onion', 'ail', 'garlic', 'citron', 'lemon', 'pomme', 'apple',
                            'tomate', 'tomato', 'courgette', 'zucchini', 'poivron', 'pepper'];
    if (wholeVegetables.any((veg) => lowerName.contains(veg))) {
      return 'pièce';
    }
    
    // Liquides (généralement en L ou ml)
    final liquids = ['huile', 'oil', 'lait', 'milk', 'eau', 'water', 'vin', 'wine', 'vinaigre', 'vinegar',
                    'crème', 'cream', 'bouillon', 'broth', 'stock'];
    if (liquids.any((liquid) => lowerName.contains(liquid))) {
      return 'ml';
    }
    
    // Produits en poudre/farine (généralement en g)
    final powders = ['farine', 'flour', 'sucre', 'sugar', 'cacao', 'cocoa', 'café', 'coffee'];
    if (powders.any((powder) => lowerName.contains(powder))) {
      return 'g';
    }
    
    return null;
  }
  
  // Vérifier si un ingrédient est une herbe ou une épice
  bool _isHerbOrSpice(String ingredientName) {
    final lowerName = ingredientName.toLowerCase();
    
    final herbs = ['thym', 'thyme', 'basilic', 'basil', 'origan', 'oregano', 'romarin', 'rosemary', 
                   'persil', 'parsley', 'menthe', 'mint', 'aneth', 'dill', 'sauge', 'sage', 
                   'ciboulette', 'chives', 'coriandre', 'coriander'];
    final spices = ['poivre', 'pepper', 'sel', 'salt', 'paprika', 'cumin', 'cannelle', 'cinnamon',
                   'muscade', 'nutmeg', 'gingembre', 'ginger', 'curcuma', 'turmeric', 'curry'];
    
    return herbs.any((herb) => lowerName.contains(herb)) || 
           spices.any((spice) => lowerName.contains(spice));
  }
}

