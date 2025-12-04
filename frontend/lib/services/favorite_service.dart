import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/recipe.dart';
import 'auth_service.dart';
import 'api_logger.dart';

class FavoriteService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }
    return token;
  }

  // Obtenir tous les favoris
  Future<List<Recipe>> getFavorites() async {
    try {
      final token = await _getToken();
      final response = await ApiLogger.interceptRequest(
        () => http.get(
          Uri.parse('${ApiConfig.baseUrl}/favorites'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        'GET',
        '${ApiConfig.baseUrl}/favorites',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) {
          final recipeData = json['recipeData'] as Map<String, dynamic>;
          return Recipe.fromJson(recipeData);
        }).toList();
      } else {
        throw Exception('Erreur lors de la récupération des favoris');
      }
    } catch (e) {
      print('Erreur getFavorites: $e');
      rethrow;
    }
  }

  // Vérifier si une recette est en favoris
  Future<bool> isFavorite(String recipeId) async {
    try {
      final token = await _getToken();
      final response = await ApiLogger.interceptRequest(
        () => http.get(
          Uri.parse('${ApiConfig.baseUrl}/favorites/check/$recipeId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        'GET',
        '${ApiConfig.baseUrl}/favorites/check/$recipeId',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['isFavorite'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      print('Erreur isFavorite: $e');
      return false;
    }
  }

  // Ajouter un favori
  Future<bool> addFavorite(Recipe recipe) async {
    try {
      final token = await _getToken();
      final response = await ApiLogger.interceptRequest(
        () => http.post(
          Uri.parse('${ApiConfig.baseUrl}/favorites'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'recipeId': recipe.id,
            'recipeTitle': recipe.title,
            'recipeImage': recipe.image,
            'recipeData': recipe.toJson(),
          }),
        ),
        'POST',
        '${ApiConfig.baseUrl}/favorites',
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Erreur addFavorite: $e');
      return false;
    }
  }

  // Supprimer un favori
  Future<bool> removeFavorite(String recipeId) async {
    try {
      final token = await _getToken();
      final response = await ApiLogger.interceptRequest(
        () => http.delete(
          Uri.parse('${ApiConfig.baseUrl}/favorites/$recipeId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        'DELETE',
        '${ApiConfig.baseUrl}/favorites/$recipeId',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur removeFavorite: $e');
      return false;
    }
  }

  // Toggle favori (ajouter si absent, supprimer si présent)
  Future<bool> toggleFavorite(Recipe recipe) async {
    final isFav = await isFavorite(recipe.id);
    if (isFav) {
      return await removeFavorite(recipe.id);
    } else {
      return await addFavorite(recipe);
    }
  }
}

