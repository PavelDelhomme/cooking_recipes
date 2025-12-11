import 'dart:convert';
import '../config/api_config.dart';
import '../models/recipe.dart';
import 'auth_service.dart';
import 'http_client.dart';

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
      final url = Uri.parse('${ApiConfig.baseUrl}/favorites');
      print('🔍 Récupération favoris depuis: $url');
      
      final response = await HttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Réponse favoris: status=${response.statusCode}, body=${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('📋 Nombre de favoris reçus: ${jsonList.length}');
        
        if (jsonList.isEmpty) {
          print('⚠️ Aucun favori dans la réponse');
          return [];
        }
        
        final recipes = <Recipe>[];
        for (var i = 0; i < jsonList.length; i++) {
          final item = jsonList[i];
          try {
            print('🔍 Traitement favori $i: recipeId=${item['recipeId']}, recipeTitle=${item['recipeTitle']}');
            
            // recipeData peut être un Map ou une String JSON
            dynamic recipeData = item['recipeData'];
            if (recipeData is String) {
              print('   → recipeData est une string, parsing...');
              recipeData = json.decode(recipeData);
            }
            
            // S'assurer que recipeData est un Map
            if (recipeData is! Map<String, dynamic>) {
              print('⚠️ recipeData n\'est pas un Map: $recipeData (type: ${recipeData.runtimeType})');
              continue;
            }
            
            // Utiliser les champs de l'item si manquants dans recipeData
            if (!recipeData.containsKey('title') && item['recipeTitle'] != null) {
              recipeData['title'] = item['recipeTitle'];
            }
            if (!recipeData.containsKey('id') && item['recipeId'] != null) {
              recipeData['id'] = item['recipeId'];
            }
            if (!recipeData.containsKey('image') && item['recipeImage'] != null) {
              recipeData['image'] = item['recipeImage'];
            }
            
            final recipe = Recipe.fromJson(recipeData);
            print('✅ Favori $i parsé: ${recipe.title} (id: ${recipe.id})');
            recipes.add(recipe);
          } catch (e, stackTrace) {
            print('❌ Erreur parsing favori $i: $e');
            print('   Stack trace: $stackTrace');
            print('   Item: $item');
          }
        }
        
        print('✅ Total favoris parsés: ${recipes.length}');
        return recipes;
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception('Erreur lors de la récupération des favoris: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur getFavorites: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Vérifier si une recette est en favoris
  Future<bool> isFavorite(String recipeId) async {
    try {
      final token = await _getToken();
      final response = await HttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/favorites/check/$recipeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
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
      final response = await HttpClient.post(
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
      );

      // Accepter 200 (déjà en favoris) ou 201 (créé)
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Erreur addFavorite: $e');
      return false;
    }
  }

  // Supprimer un favori
  Future<bool> removeFavorite(String recipeId) async {
    try {
      final token = await _getToken();
      final response = await HttpClient.delete(
        Uri.parse('${ApiConfig.baseUrl}/favorites/$recipeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
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

