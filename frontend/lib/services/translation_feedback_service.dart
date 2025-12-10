import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/translation_feedback.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'http_client.dart';
import 'translation_service.dart';

/// Service pour gérer les retours utilisateur sur les traductions
class TranslationFeedbackService {
  final AuthService _authService = AuthService();
  static const String _feedbackKey = 'translation_feedbacks';
  static const String _learnedTranslationsKey = 'learned_translations';

  /// Enregistre un retour utilisateur (localement ET sur le backend)
  Future<bool> submitFeedback(TranslationFeedback feedback) async {
    try {
      // 1. Enregistrer localement (pour utilisation immédiate)
      final prefs = await SharedPreferences.getInstance();
      final feedbacks = await getAllFeedbacks();
      feedbacks.add(feedback);
      
      final jsonString = json.encode(
        feedbacks.map((f) => f.toJson()).toList(),
      );
      
      await prefs.setString(_feedbackKey, jsonString);
      
      // 2. Envoyer au backend (pour tracking et entraînement)
      try {
        final token = await _authService.getToken();
        if (token != null) {
          final response = await HttpClient.post(
            Uri.parse('${ApiConfig.baseUrl}/translation-feedback'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'recipeId': feedback.recipeId,
              'recipeTitle': feedback.recipeTitle,
              'type': feedback.type.toString().split('.').last,
              'originalText': feedback.originalText,
              'currentTranslation': feedback.currentTranslation,
              'suggestedTranslation': feedback.suggestedTranslation,
              'targetLanguage': feedback.targetLanguage,
              'context': feedback.context,
            }),
          );
          
          if (response.statusCode != 201) {
            print('⚠️ Erreur envoi feedback au backend: ${response.statusCode}');
            // Continuer quand même, le feedback local est enregistré
          }
        }
      } catch (e) {
        print('⚠️ Erreur envoi feedback au backend (continuons): $e');
        // Continuer quand même, le feedback local est enregistré
      }
      
      // 3. Si l'utilisateur a suggéré une traduction, l'ajouter aux traductions apprises
      if (feedback.suggestedTranslation != null && 
          feedback.suggestedTranslation!.isNotEmpty) {
        await _addLearnedTranslation(
          feedback.originalText,
          feedback.suggestedTranslation!,
          feedback.targetLanguage,
          feedback.type,
        );
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'enregistrement du feedback: $e');
      return false;
    }
  }

  /// Récupère tous les retours utilisateur (depuis le backend si possible, sinon local)
  Future<List<TranslationFeedback>> getAllFeedbacks() async {
    try {
      // Essayer de récupérer depuis le backend d'abord
      try {
        final token = await _authService.getToken();
        if (token != null) {
          final response = await HttpClient.get(
            Uri.parse('${ApiConfig.baseUrl}/translation-feedback'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true && data['feedbacks'] != null) {
              final List<dynamic> feedbacksJson = data['feedbacks'];
              final feedbacks = feedbacksJson
                  .map((json) => TranslationFeedback.fromJson({
                    'id': json['id'],
                    'recipeId': json['recipe_id'],
                    'recipeTitle': json['recipe_title'],
                    'type': json['type'],
                    'originalText': json['original_text'],
                    'currentTranslation': json['current_translation'],
                    'suggestedTranslation': json['suggested_translation'],
                    'targetLanguage': json['target_language'],
                    'timestamp': json['timestamp'],
                    'context': json['context'],
                  }))
                  .toList();
              
              // Synchroniser avec le stockage local
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_feedbackKey, json.encode(
                feedbacks.map((f) => f.toJson()).toList(),
              ));
              
              return feedbacks;
            }
          }
        }
      } catch (e) {
        print('⚠️ Erreur récupération feedbacks depuis backend (fallback local): $e');
      }
      
      // Fallback : récupérer depuis le stockage local
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_feedbackKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => TranslationFeedback.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des feedbacks: $e');
      return [];
    }
  }

  /// Ajoute une traduction apprise au dictionnaire
  Future<void> _addLearnedTranslation(
    String originalText,
    String translation,
    String targetLanguage,
    FeedbackType type,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final learned = await getLearnedTranslations();
      
      final key = _getTranslationKey(originalText, targetLanguage, type);
      learned[key] = {
        'original': originalText,
        'translation': translation,
        'language': targetLanguage,
        'type': type.toString().split('.').last,
        'confidence': 1.0, // Commence avec une confiance de 1.0 (approuvé par l'utilisateur)
        'usageCount': 1,
      };
      
      final jsonString = json.encode(learned);
      await prefs.setString(_learnedTranslationsKey, jsonString);
      
      // Mettre à jour le cache immédiatement pour utilisation synchrone
      _cachedLearnedTranslations = Map<String, Map<String, dynamic>>.from(learned);
      
      // Notifier TranslationService pour rafraîchir les widgets qui utilisent les traductions
      try {
        TranslationService().notifyListeners();
      } catch (e) {
        // Ignorer si TranslationService n'est pas encore initialisé
      }
    } catch (e) {
      print('Erreur lors de l\'ajout de la traduction apprise: $e');
    }
  }

  /// Récupère toutes les traductions apprises
  Future<Map<String, dynamic>> getLearnedTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_learnedTranslationsKey);
      
      if (jsonString == null) {
        return {};
      }

      return Map<String, dynamic>.from(json.decode(jsonString));
    } catch (e) {
      print('Erreur lors du chargement des traductions apprises: $e');
      return {};
    }
  }

  /// Obtient une traduction apprise (synchrone via cache)
  static Map<String, Map<String, dynamic>>? _cachedLearnedTranslations;
  static bool _cacheLoaded = false;

  /// Charge le cache des traductions apprises
  static Future<void> loadCache({bool force = false}) async {
    if (_cacheLoaded && !force) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_learnedTranslationsKey);
      if (jsonString != null) {
        _cachedLearnedTranslations = Map<String, Map<String, dynamic>>.from(
          json.decode(jsonString) as Map,
        );
      } else {
        _cachedLearnedTranslations = {};
      }
      _cacheLoaded = true;
    } catch (e) {
      _cachedLearnedTranslations = {};
      _cacheLoaded = true;
    }
  }
  
  /// Force le rechargement du cache (utile après modification d'une traduction)
  static Future<void> reloadCache() async {
    _cacheLoaded = false;
    await loadCache(force: true);
  }

  /// Obtient une traduction apprise (synchrone)
  static String? getLearnedTranslationSync(
    String originalText,
    String targetLanguage,
    FeedbackType type,
  ) {
    if (!_cacheLoaded) {
      // Si le cache n'est pas chargé, retourner null (sera chargé au prochain appel async)
      return null;
    }
    final key = _getTranslationKeyStatic(originalText, targetLanguage, type);
    return _cachedLearnedTranslations?[key]?['translation'] as String?;
  }

  /// Obtient une traduction apprise (asynchrone)
  Future<String?> getLearnedTranslation(
    String originalText,
    String targetLanguage,
    FeedbackType type,
  ) async {
    final learned = await getLearnedTranslations();
    final key = _getTranslationKey(originalText, targetLanguage, type);
    return learned[key]?['translation'] as String?;
  }

  static String _getTranslationKeyStatic(String original, String language, FeedbackType type) {
    return '${type.toString().split('.').last}_${original.toLowerCase().trim()}_$language';
  }

  /// Augmente le compteur d'utilisation d'une traduction apprise
  Future<void> incrementUsageCount(
    String originalText,
    String targetLanguage,
    FeedbackType type,
  ) async {
    try {
      final learned = await getLearnedTranslations();
      final key = _getTranslationKey(originalText, targetLanguage, type);
      
      if (learned.containsKey(key)) {
        final currentCount = (learned[key]?['usageCount'] as int? ?? 0);
        learned[key]?['usageCount'] = currentCount + 1;
        
        final prefs = await SharedPreferences.getInstance();
        final jsonString = json.encode(learned);
        await prefs.setString(_learnedTranslationsKey, jsonString);
      }
    } catch (e) {
      print('Erreur lors de l\'incrémentation du compteur: $e');
    }
  }

  String _getTranslationKey(String original, String language, FeedbackType type) {
    return '${type.toString().split('.').last}_${original.toLowerCase().trim()}_$language';
  }

  /// Exporte les feedbacks pour l'entraînement du modèle
  Future<String> exportFeedbacksForTraining() async {
    final feedbacks = await getAllFeedbacks();
    final learned = await getLearnedTranslations();
    
    final export = {
      'feedbacks': feedbacks.map((f) => f.toJson()).toList(),
      'learnedTranslations': learned,
      'exportDate': DateTime.now().toIso8601String(),
    };
    
    return json.encode(export);
  }

  /// Supprime tous les feedbacks (pour réinitialiser)
  Future<void> clearAllFeedbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_feedbackKey);
    } catch (e) {
      print('Erreur lors de la suppression des feedbacks: $e');
    }
  }

  /// Vérifie si l'utilisateur actuel est admin
  Future<bool> isAdmin() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return false;
      final email = user.email.toLowerCase();
      return email == 'dumb@delhomme.ovh' || email == 'dev@delhomme.ovh';
    } catch (e) {
      return false;
    }
  }

  /// Récupère les feedbacks en attente de validation (admin uniquement)
  Future<List<TranslationFeedback>> getPendingFeedbacks() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await HttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/translation-feedback/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['feedbacks'] != null) {
          final List<dynamic> feedbacksJson = data['feedbacks'];
          return feedbacksJson
              .map((json) => TranslationFeedback.fromJson({
                    'id': json['id'],
                    'recipeId': json['recipe_id'],
                    'recipeTitle': json['recipe_title'],
                    'type': json['type'],
                    'originalText': json['original_text'],
                    'currentTranslation': json['current_translation'],
                    'suggestedTranslation': json['suggested_translation'],
                    'targetLanguage': json['target_language'],
                    'timestamp': json['timestamp'],
                    'context': json['context'],
                  }))
              .toList();
        }
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      }
      return [];
    } catch (e) {
      print('Erreur récupération feedbacks en attente: $e');
      rethrow;
    }
  }

  /// Approuve un feedback (admin uniquement)
  Future<bool> approveFeedback(String feedbackId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await HttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/translation-feedback/$feedbackId/approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      }
      return false;
    } catch (e) {
      print('Erreur approbation feedback: $e');
      rethrow;
    }
  }

  /// Rejette un feedback (admin uniquement)
  Future<bool> rejectFeedback(String feedbackId, {String? reason}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await HttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/translation-feedback/$feedbackId/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      }
      return false;
    } catch (e) {
      print('Erreur rejet feedback: $e');
      rethrow;
    }
  }

  /// Réentraîne le modèle ML (admin uniquement)
  Future<bool> retrainML() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await HttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/translation-feedback/retrain'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      }
      return false;
    } catch (e) {
      print('Erreur réentraînement ML: $e');
      rethrow;
    }
  }
}

