import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';
import 'api_logger.dart'; // Logger pour les requêtes API

class IngredientImageService {
  static const String _cacheKeyPrefix = 'ingredient_image_';
  
  // Utiliser Unsplash API (gratuite, pas besoin de clé pour les requêtes publiques)
  // Alternative: utiliser une API de recettes qui fournit des images d'ingrédients
  Future<String?> getIngredientImage(String ingredientName) async {
    try {
      // Vérifier le cache local d'abord
      final cachedImage = await _getCachedImage(ingredientName);
      if (cachedImage != null) {
        return cachedImage;
      }

      // Essayer TheMealDB en premier (gratuit, pas de clé, utilise noms anglais)
      final mealDbImage = await getImageFromMealDB(ingredientName);
      if (mealDbImage != null) {
        return mealDbImage;
      }

      // Si TheMealDB ne fonctionne pas, essayer Unsplash (API publique)
      final imageUrl = await _fetchFromUnsplash(ingredientName);
      
      if (imageUrl != null) {
        // Mettre en cache
        await _cacheImage(ingredientName, imageUrl);
        return imageUrl;
      }

      // Si rien ne fonctionne, retourner null (l'UI utilisera une icône par défaut)
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'image: $e');
      return null;
    }
  }

  Future<String?> _fetchFromUnsplash(String ingredientName) async {
    try {
      // Utiliser l'API Unsplash Search (publique, pas besoin de clé pour les requêtes limitées)
      final query = ingredientName.toLowerCase().replaceAll(' ', '+');
      final url = Uri.parse('https://api.unsplash.com/search/photos?query=$query&per_page=1&client_id=YOUR_ACCESS_KEY');
      
      // Note: Pour une utilisation en production, il faudrait une clé API Unsplash
      // Pour l'instant, on utilise une alternative sans clé
      return await _fetchFromFoodish(ingredientName);
    } catch (e) {
      print('Erreur Unsplash: $e');
      return null;
    }
  }

  // Utiliser Foodish API (gratuite, pas de clé requise) pour les images de nourriture
  Future<String?> _fetchFromFoodish(String ingredientName) async {
    try {
      // Foodish API simple pour les images de nourriture
      // Note: Cette API est limitée mais fonctionne sans clé
      final query = ingredientName.toLowerCase().replaceAll(' ', '%20');
      
      // Utiliser une API alternative: Pixabay (gratuite, pas de clé requise pour les requêtes limitées)
      return await _fetchFromPixabay(ingredientName);
    } catch (e) {
      print('Erreur Foodish: $e');
      return null;
    }
  }

  // Utiliser Pixabay API (gratuite, pas de clé requise pour les requêtes limitées)
  Future<String?> _fetchFromPixabay(String ingredientName) async {
    try {
      final query = ingredientName.toLowerCase().replaceAll(' ', '+');
      // Pixabay permet quelques requêtes sans clé, mais pour la production il faudrait une clé
      // Pour l'instant, on retourne une URL d'image par défaut
      return _getDefaultImageUrl(ingredientName);
    } catch (e) {
      return null;
    }
  }

  // Générer une URL d'image par défaut basée sur le nom de l'ingrédient
  String? _getDefaultImageUrl(String ingredientName) {
    // Utiliser un service d'images de placeholder ou une image générique
    // Pour l'instant, on peut utiliser un service comme placeholder.com ou similar
    final encodedName = Uri.encodeComponent(ingredientName.toLowerCase());
    
    // Utiliser un service d'images de nourriture gratuit
    // Exemple: utiliser une API comme "TheMealDB" qui a des images d'ingrédients
    // Ou utiliser un service de placeholder pour les images de nourriture
    
    // Pour l'instant, retourner null et utiliser une icône par défaut dans l'UI
    return null;
  }

  Future<String?> _getCachedImage(String ingredientName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKeyPrefix + ingredientName.toLowerCase();
      return prefs.getString(cacheKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheImage(String ingredientName, String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKeyPrefix + ingredientName.toLowerCase();
      await prefs.setString(cacheKey, imageUrl);
    } catch (e) {
      print('Erreur lors de la mise en cache: $e');
    }
  }

  // Utiliser TheMealDB pour récupérer des images d'ingrédients (gratuit, pas de clé)
  // IMPORTANT: TheMealDB utilise les noms anglais, donc on doit convertir le nom français en anglais
  // Si originalName est fourni, l'utiliser directement (c'est le nom anglais original)
  Future<String?> getImageFromMealDB(String ingredientName, {String? originalName}) async {
    try {
      print('🖼️ Récupération image pour ingrédient: "$ingredientName" (originalName: ${originalName ?? "null"})');
      
      // Si on a le nom anglais original, l'utiliser directement
      String englishName;
      if (originalName != null && originalName.isNotEmpty) {
        englishName = originalName;
        print('✅ Utilisation du nom original: "$originalName"');
      } else {
        // Sinon, convertir le nom français en anglais
        englishName = TranslationService.getEnglishName(ingredientName);
        // Log pour déboguer
        if (ingredientName != englishName) {
          print('🔄 Conversion ingrédient: "$ingredientName" -> "$englishName"');
        } else {
          print('⚠️ Pas de conversion trouvée pour: "$ingredientName" (utilisé tel quel)');
          // Si pas de conversion, essayer de normaliser le nom français pour l'URL
          // Par exemple : "bœuf" -> "boeuf" -> "beef" via getEnglishName
          final normalized = ingredientName.toLowerCase()
              .replaceAll('œ', 'oe')
              .replaceAll('é', 'e')
              .replaceAll('è', 'e')
              .replaceAll('ê', 'e')
              .replaceAll('à', 'a')
              .replaceAll('â', 'a')
              .replaceAll('ç', 'c')
              .replaceAll('ô', 'o')
              .replaceAll('ù', 'u')
              .replaceAll('û', 'u')
              .replaceAll('ï', 'i')
              .replaceAll('î', 'i');
          final retryEnglish = TranslationService.getEnglishName(normalized);
          if (retryEnglish != normalized && retryEnglish != ingredientName) {
            englishName = retryEnglish;
            print('🔄 Conversion après normalisation: "$normalized" -> "$englishName"');
          }
        }
      }
      
      // Nettoyer le nom pour l'URL (minuscules, remplacer espaces par underscores, enlever apostrophes et accents)
      String query = englishName.toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll("'", '')
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
          .replaceAll('œ', 'oe')
          .replaceAll('æ', 'ae')
          .replaceAll('ñ', 'n')
          .replaceAll('ü', 'u')
          .replaceAll('ö', 'o')
          .replaceAll('ä', 'a');
      
      // TheMealDB a des images d'ingrédients à cette URL
      final imageUrl = 'https://www.themealdb.com/images/ingredients/$query.png';
      
      print('🔍 Tentative de récupération image: $imageUrl');
      
      // Vérifier si l'image existe
      final response = await ApiLogger.interceptRequest(
        () => http.head(Uri.parse(imageUrl)),
        'HEAD',
        imageUrl,
      );
      if (response.statusCode == 200) {
        print('✅ Image trouvée: $imageUrl');
        await _cacheImage(ingredientName, imageUrl);
        return imageUrl;
      } else {
        print('❌ Image non trouvée (${response.statusCode}): $imageUrl');
      }
    } catch (e) {
      print('❌ Erreur TheMealDB pour $ingredientName: $e');
    }
    return null;
  }
}
