import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        setState(() {
          _error = 'Vous devez être connecté pour voir vos favoris';
          _isLoading = false;
        });
        return;
      }

      final apiUrl = ApiConfig.baseUrl;
      print('🔍 Chargement favoris depuis: $apiUrl/favorites');
      final response = await http.get(
        Uri.parse('$apiUrl/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('🔍 Favoris reçus: ${data.length}');
        print('🔍 Premier favori: ${data.isNotEmpty ? data[0] : 'aucun'}');
        
        setState(() {
          _favorites = data.map((item) {
            try {
              // Si recipeData est une string JSON, la parser
              dynamic recipeData = item['recipeData'];
              if (recipeData is String) {
                recipeData = json.decode(recipeData);
              }
              // S'assurer que recipeData a les champs nécessaires
              if (recipeData is Map<String, dynamic>) {
                // Utiliser recipeTitle si title n'existe pas
                if (!recipeData.containsKey('title') && item['recipeTitle'] != null) {
                  recipeData['title'] = item['recipeTitle'];
                }
                // Utiliser recipeId si id n'existe pas
                if (!recipeData.containsKey('id') && item['recipeId'] != null) {
                  recipeData['id'] = item['recipeId'];
                }
                // Utiliser recipeImage si image n'existe pas
                if (!recipeData.containsKey('image') && item['recipeImage'] != null) {
                  recipeData['image'] = item['recipeImage'];
                }
                return Recipe.fromJson(recipeData);
              } else {
                print('⚠️ recipeData n\'est pas un Map: $recipeData');
                return null;
              }
            } catch (e) {
              print('❌ Erreur parsing favori: $e');
              print('   Item: $item');
              return null;
            }
          }).where((recipe) => recipe != null).cast<Recipe>().toList();
          print('✅ Favoris parsés: ${_favorites.length}');
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Session expirée. Veuillez vous reconnecter.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur lors du chargement des favoris';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur de connexion: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String recipeId) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) return;

      final apiUrl = ApiConfig.baseUrl;
      final response = await http.delete(
        Uri.parse('$apiUrl/favorites/$recipeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Retirer de la liste locale
        setState(() {
          _favorites.removeWhere((recipe) => recipe.id == recipeId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recette retirée des favoris'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadFavorites,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun favori pour le moment',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez des recettes à vos favoris\npour les retrouver facilement',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final recipe = _favorites[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailScreen(recipe: recipe),
                                  ),
                                ).then((_) {
                                  // Recharger après retour si nécessaire
                                  _loadFavorites();
                                });
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        recipe.image != null && recipe.image!.isNotEmpty
                                            ? Image.network(
                                                recipe.image!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.restaurant,
                                                      size: 48,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.restaurant,
                                                  size: 48,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _removeFavorite(recipe.id),
                                            tooltip: 'Retirer des favoris',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

