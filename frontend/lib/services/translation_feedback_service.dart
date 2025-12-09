import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_feedback.dart';
import 'translation_service.dart';

/// Service pour gérer les retours utilisateur sur les traductions
class TranslationFeedbackService {
  static const String _feedbackKey = 'translation_feedbacks';
  static const String _learnedTranslationsKey = 'learned_translations';

  /// Enregistre un retour utilisateur
  Future<bool> submitFeedback(TranslationFeedback feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbacks = await getAllFeedbacks();
      feedbacks.add(feedback);
      
      final jsonString = json.encode(
        feedbacks.map((f) => f.toJson()).toList(),
      );
      
      await prefs.setString(_feedbackKey, jsonString);
      
      // Si l'utilisateur a suggéré une traduction, l'ajouter aux traductions apprises
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

  /// Récupère tous les retours utilisateur
  Future<List<TranslationFeedback>> getAllFeedbacks() async {
    try {
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
  static Future<void> loadCache() async {
    if (_cacheLoaded) return;
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
}

