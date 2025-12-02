import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../models/ingredient.dart';

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
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          return (data['meals'] as List)
              .map((meal) => _convertMealToRecipe(meal))
              .toList();
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
        final data = json.decode(response.body);
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
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return _convertMealToRecipe(data['meals'][0]);
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
          final data = json.decode(response.body);
          if (data['meals'] != null && data['meals'].isNotEmpty) {
            recipes.add(_convertMealToRecipe(data['meals'][0]));
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

  // Convertir un meal de TheMealDB en Recipe
  Recipe _convertMealToRecipe(Map<String, dynamic> meal) {
    final List<Ingredient> ingredients = [];
    final List<String> instructions = [];

    // Extraire les ingrédients (TheMealDB utilise strIngredient1, strIngredient2, etc.)
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(Ingredient(
          id: '${meal['idMeal']}_ingredient_$i',
          name: ingredient.toString().trim(),
          quantity: _parseQuantity(measure?.toString() ?? ''),
          unit: _parseUnit(measure?.toString() ?? ''),
        ));
      }
    }

    // Extraire les instructions
    final instructionsText = meal['strInstructions']?.toString() ?? '';
    if (instructionsText.isNotEmpty) {
      // Diviser par les retours à la ligne ou les numéros
      instructions.addAll(instructionsText
          .split(RegExp(r'\n|\r\n'))
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim()));
    }

    return Recipe(
      id: meal['idMeal'].toString(),
      title: meal['strMeal']?.toString() ?? 'Recette sans nom',
      image: meal['strMealThumb']?.toString(),
      summary: meal['strInstructions']?.toString(),
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

  // Parser l'unité depuis une mesure
  String? _parseUnit(String measure) {
    if (measure.isEmpty) return null;
    final regex = RegExp(r'\d+\.?\d*\s*(.+)');
    final match = regex.firstMatch(measure);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return measure.trim();
  }
}

