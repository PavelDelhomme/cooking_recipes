import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

/// Service pour gérer l'historique des recettes consultées
class RecipeHistoryService {
  static const String _historyKey = 'recipe_history';
  static const int _maxHistorySize = 500; // Nombre maximum de recettes dans l'historique

  /// Ajouter une recette à l'historique
  static Future<void> addToHistory(Recipe recipe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      List<Map<String, dynamic>> history = [];
      if (historyJson != null) {
        history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      }
      
      // Vérifier si la recette existe déjà dans l'historique
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Supprimer les anciennes entrées pour cette recette (garder seulement la plus récente par jour)
      history.removeWhere((entry) {
        final entryDate = DateTime.parse(entry['timestamp'] as String);
        final entryDay = DateTime(entryDate.year, entryDate.month, entryDate.day);
        return entry['recipeId'] == recipe.id && entryDay == today;
      });
      
      // Ajouter la nouvelle entrée
      history.add({
        'recipeId': recipe.id,
        'recipeData': recipe.toJson(),
        'timestamp': now.toIso8601String(),
      });
      
      // Trier par date (plus récent d'abord)
      history.sort((a, b) {
        final dateA = DateTime.parse(a['timestamp'] as String);
        final dateB = DateTime.parse(b['timestamp'] as String);
        return dateB.compareTo(dateA);
      });
      
      // Limiter la taille de l'historique
      if (history.length > _maxHistorySize) {
        history = history.take(_maxHistorySize).toList();
      }
      
      // Sauvegarder
      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      print('Erreur lors de l\'ajout à l\'historique: $e');
    }
  }

  /// Récupérer l'historique des recettes consultées
  static Future<List<Recipe>> getHistory({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) {
        return [];
      }
      
      final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      
      // Trier par date (plus récent d'abord)
      history.sort((a, b) {
        final dateA = DateTime.parse(a['timestamp'] as String);
        final dateB = DateTime.parse(b['timestamp'] as String);
        return dateB.compareTo(dateA);
      });
      
      // Limiter si nécessaire
      final limitedHistory = limit != null && limit < history.length
          ? history.take(limit).toList()
          : history;
      
      // Convertir en Recipe
      final recipes = <Recipe>[];
      for (var entry in limitedHistory) {
        try {
          final recipeData = entry['recipeData'] as Map<String, dynamic>;
          recipes.add(Recipe.fromJson(recipeData));
        } catch (e) {
          print('Erreur lors de la conversion de la recette: $e');
        }
      }
      
      return recipes;
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Vider l'historique
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Erreur lors du vidage de l\'historique: $e');
    }
  }

  /// Supprimer une recette de l'historique
  static Future<void> removeFromHistory(String recipeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) {
        return;
      }
      
      final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      history.removeWhere((entry) => entry['recipeId'] == recipeId);
      
      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      print('Erreur lors de la suppression de l\'historique: $e');
    }
  }
}

