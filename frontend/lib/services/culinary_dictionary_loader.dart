import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Chargeur de dictionnaires culinaires multilingues
class CulinaryDictionaryLoader {
  static Map<String, Map<String, String>>? _ingredientsDictionary;
  static Map<String, Map<String, String>>? _recipeNamesDictionary;
  static bool _isLoading = false;
  static bool _isLoaded = false;

  /// Charge les dictionnaires depuis les fichiers JSON (chargement asynchrone optimisé)
  static Future<void> loadDictionaries() async {
    if (_isLoaded || _isLoading) return;
    
    _isLoading = true;
    
    try {
      // Charger les dictionnaires en parallèle pour optimiser
      final futures = await Future.wait([
        rootBundle.loadString('lib/data/culinary_dictionaries/ingredients_fr_en_es.json'),
        rootBundle.loadString('lib/data/culinary_dictionaries/recipe_names_fr_en_es.json'),
      ]);
      
      // Parser en parallèle
      final ingredientsData = json.decode(futures[0]) as Map<String, dynamic>;
      final recipeNamesData = json.decode(futures[1]) as Map<String, dynamic>;
      
      _ingredientsDictionary = {};
      _recipeNamesDictionary = {};
      
      // Construire les dictionnaires de manière optimisée
      if (ingredientsData['ingredients'] != null) {
        final ingredients = ingredientsData['ingredients'] as Map<String, dynamic>;
        _ingredientsDictionary = Map.fromEntries(
          ingredients.entries.map((entry) {
            final translations = entry.value as Map<String, dynamic>;
            return MapEntry(
              entry.key.toLowerCase(),
              {
                'en': entry.key,
                'fr': translations['fr'] as String? ?? entry.key,
                'es': translations['es'] as String? ?? entry.key,
              },
            );
          }),
        );
      }
      
      if (recipeNamesData['recipe_names'] != null) {
        final recipeNames = recipeNamesData['recipe_names'] as Map<String, dynamic>;
        _recipeNamesDictionary = Map.fromEntries(
          recipeNames.entries.map((entry) {
            final translations = entry.value as Map<String, dynamic>;
            return MapEntry(
              entry.key.toLowerCase(),
              {
                'en': entry.key,
                'fr': translations['fr'] as String? ?? entry.key,
                'es': translations['es'] as String? ?? entry.key,
              },
            );
          }),
        );
      }
      
      _isLoaded = true;
      if (kDebugMode) {
        print('✅ Dictionnaires culinaires chargés: ${_ingredientsDictionary?.length} ingrédients, ${_recipeNamesDictionary?.length} noms de recettes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors du chargement des dictionnaires: $e');
      }
      // Créer des dictionnaires vides en cas d'erreur
      _ingredientsDictionary = {};
      _recipeNamesDictionary = {};
    } finally {
      _isLoading = false;
    }
  }

  /// Traduit un ingrédient
  static String? translateIngredient(String ingredient, String targetLanguage) {
    if (!_isLoaded) return null;
    
    final key = ingredient.toLowerCase().trim();
    
    // Chercher une correspondance exacte
    if (_ingredientsDictionary?.containsKey(key) == true) {
      return _ingredientsDictionary![key]![targetLanguage];
    }
    
    // Chercher une correspondance partielle (pour les mots composés)
    for (var entry in _ingredientsDictionary!.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value[targetLanguage];
      }
    }
    
    return null;
  }

  /// Traduit un nom de recette
  static String? translateRecipeName(String recipeName, String targetLanguage) {
    if (!_isLoaded) return null;
    
    final key = recipeName.toLowerCase().trim();
    
    // Chercher une correspondance exacte
    if (_recipeNamesDictionary?.containsKey(key) == true) {
      return _recipeNamesDictionary![key]![targetLanguage];
    }
    
    // Chercher une correspondance partielle
    for (var entry in _recipeNamesDictionary!.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value[targetLanguage];
      }
    }
    
    return null;
  }

  /// Obtient toutes les traductions d'un terme
  static Map<String, String>? getAllTranslations(String term, {bool isRecipeName = false}) {
    if (!_isLoaded) return null;
    
    final key = term.toLowerCase().trim();
    final dictionary = isRecipeName ? _recipeNamesDictionary : _ingredientsDictionary;
    
    if (dictionary?.containsKey(key) == true) {
      return Map<String, String>.from(dictionary![key]!);
    }
    
    return null;
  }

  /// Vérifie si les dictionnaires sont chargés
  static bool get isLoaded => _isLoaded;

  /// Obtient le nombre d'ingrédients dans le dictionnaire
  static int get ingredientsCount => _ingredientsDictionary?.length ?? 0;

  /// Obtient le nombre de noms de recettes dans le dictionnaire
  static int get recipeNamesCount => _recipeNamesDictionary?.length ?? 0;
}


