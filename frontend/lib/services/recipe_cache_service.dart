import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

/// Service de cache pour les recettes
class RecipeCacheService {
  static const String _cacheKeyPrefix = 'recipe_cache_';
  static const String _cacheTimestampPrefix = 'recipe_cache_timestamp_';
  static const int _maxCacheSize = 1000; // Nombre maximum de recettes en cache
  static const Duration _cacheExpiration = Duration(days: 30); // Expiration du cache

  /// Récupérer une recette depuis le cache
  static Future<Recipe?> getCachedRecipe(String recipeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKeyPrefix + recipeId;
      final timestampKey = _cacheTimestampPrefix + recipeId;
      
      final cachedData = prefs.getString(cacheKey);
      final timestampStr = prefs.getString(timestampKey);
      
      if (cachedData == null || timestampStr == null) {
        return null;
      }
      
      // Vérifier si le cache n'a pas expiré
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        // Cache expiré, le supprimer
        await prefs.remove(cacheKey);
        await prefs.remove(timestampKey);
        return null;
      }
      
      // Décoder la recette
      final json = jsonDecode(cachedData) as Map<String, dynamic>;
      return Recipe.fromJson(json);
    } catch (e) {
      print('Erreur lors de la récupération du cache: $e');
      return null;
    }
  }

  /// Mettre une recette en cache
  static Future<void> cacheRecipe(Recipe recipe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKeyPrefix + recipe.id;
      final timestampKey = _cacheTimestampPrefix + recipe.id;
      
      // Vérifier la taille du cache et nettoyer si nécessaire
      await _cleanCacheIfNeeded(prefs);
      
      // Mettre en cache
      final json = recipe.toJson();
      final jsonString = jsonEncode(json);
      
      await prefs.setString(cacheKey, jsonString);
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors de la mise en cache: $e');
    }
  }

  /// Nettoyer le cache si nécessaire
  static Future<void> _cleanCacheIfNeeded(SharedPreferences prefs) async {
    try {
      // Récupérer toutes les clés de cache
      final allKeys = prefs.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith(_cacheKeyPrefix)).toList();
      
      if (cacheKeys.length >= _maxCacheSize) {
        // Récupérer les timestamps et trier par date (plus ancien d'abord)
        final cacheEntries = <MapEntry<String, DateTime>>[];
        for (var key in cacheKeys) {
          final recipeId = key.substring(_cacheKeyPrefix.length);
          final timestampKey = _cacheTimestampPrefix + recipeId;
          final timestampStr = prefs.getString(timestampKey);
          if (timestampStr != null) {
            try {
              final timestamp = DateTime.parse(timestampStr);
              cacheEntries.add(MapEntry(recipeId, timestamp));
            } catch (e) {
              // Timestamp invalide, supprimer
              await prefs.remove(key);
              await prefs.remove(timestampKey);
            }
          }
        }
        
        // Trier par date (plus ancien d'abord)
        cacheEntries.sort((a, b) => a.value.compareTo(b.value));
        
        // Supprimer les 10% les plus anciens
        final toRemove = (cacheEntries.length * 0.1).ceil();
        for (var i = 0; i < toRemove && i < cacheEntries.length; i++) {
          final recipeId = cacheEntries[i].key;
          await prefs.remove(_cacheKeyPrefix + recipeId);
          await prefs.remove(_cacheTimestampPrefix + recipeId);
        }
      }
    } catch (e) {
      print('Erreur lors du nettoyage du cache: $e');
    }
  }

  /// Vider le cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final cacheKeys = allKeys.where((key) => 
        key.startsWith(_cacheKeyPrefix) || key.startsWith(_cacheTimestampPrefix)
      ).toList();
      
      for (var key in cacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Erreur lors du vidage du cache: $e');
    }
  }
}

