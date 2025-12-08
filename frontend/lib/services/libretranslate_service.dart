import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'http_client.dart';

/// Service pour utiliser LibreTranslate via l'API backend
/// Fallback sur les dictionnaires JSON si LibreTranslate n'est pas disponible
class LibreTranslateService {
  static final LibreTranslateService _instance = LibreTranslateService._internal();
  factory LibreTranslateService() => _instance;
  LibreTranslateService._internal();

  bool _isAvailable = true; // Par défaut, on suppose qu'il est disponible
  String? _lastError;

  /// Vérifie si LibreTranslate est disponible
  Future<bool> checkAvailability() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/translation/status');
      final response = await HttpClient.get(url).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw Exception('Timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isAvailable = data['available'] == true;
        return _isAvailable;
      }
      _isAvailable = false;
      return false;
    } catch (e) {
      _isAvailable = false;
      _lastError = e.toString();
      if (kDebugMode) {
        print('⚠️ LibreTranslate non disponible: $_lastError');
      }
      return false;
    }
  }

  /// Traduit un texte
  Future<String?> translate(
    String text, {
    String source = 'en',
    String target = 'fr',
  }) async {
    if (text.isEmpty) return text;
    if (source == target) return text;

    // Vérifier la disponibilité
    if (!_isAvailable) {
      final available = await checkAvailability();
      if (!available) {
        return null; // Indique au client d'utiliser le fallback
      }
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/translation/translate');
      final response = await HttpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'source': source,
          'target': target,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['translatedText'] != null) {
          return data['translatedText'] as String;
        }
      } else if (response.statusCode == 503) {
        // Service non disponible, utiliser le fallback
        _isAvailable = false;
        return null;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur traduction LibreTranslate: $e');
      }
      _isAvailable = false;
      return null;
    }
  }

  /// Traduit un ingrédient
  Future<String?> translateIngredient(String ingredient, {String target = 'fr'}) async {
    return await translate(ingredient, source: 'en', target: target);
  }

  /// Traduit un nom de recette
  Future<String?> translateRecipeName(String recipeName, {String target = 'fr'}) async {
    return await translate(recipeName, source: 'en', target: target);
  }

  /// Traduit un texte (instructions, etc.)
  Future<String?> translateText(String text, {String source = 'en', String target = 'fr'}) async {
    return await translate(text, source: source, target: target);
  }

  /// Indique si le service est disponible
  bool get isAvailable => _isAvailable;
}

