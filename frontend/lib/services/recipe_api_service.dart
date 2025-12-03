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
        
        // Parser et traduire l'unité
        final unitString = _parseUnitSync(measure?.toString() ?? '');
        final unit = TranslationService.translateUnit(unitString ?? '');
        
        ingredients.add(Ingredient(
          id: '${meal['idMeal']}_ingredient_$i',
          name: ingredientName,
          quantity: _parseQuantity(measure?.toString() ?? ''),
          unit: unit.isEmpty ? null : unit,
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
    final regex = RegExp(r'(\d+\.?\d*)');
    final match = regex.firstMatch(measure);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  // Parser l'unité depuis une mesure (synchrone)
  String? _parseUnitSync(String measure) {
    if (measure.isEmpty) return null;
    final regex = RegExp(r'\d+\.?\d*\s*(.+)');
    final match = regex.firstMatch(measure);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return measure.trim();
  }
}

