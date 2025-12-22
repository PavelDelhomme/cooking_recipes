import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

/// Service pour la reconnaissance d'intention dans les recherches
class IntentRecognitionService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  /// Reconnnaît l'intention d'une requête de recherche
  /// Retourne l'intention détectée et les entités extraites
  Future<IntentResult> recognizeIntent(String query, {Map<String, dynamic>? context}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        // Si pas de token, retourner une intention par défaut
        return IntentResult(
          intent: 'SEARCH_BY_NAME',
          confidence: 0.5,
          extracted: {},
        );
      }

      final url = Uri.parse('${baseUrl}/recipes/search');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'query': query,
          'context': context ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['intent'] != null) {
          return IntentResult.fromJson(data['intent']);
        }
      }

      // Fallback si l'API ne répond pas
      return IntentResult(
        intent: 'SEARCH_BY_NAME',
        confidence: 0.5,
        extracted: {},
      );
    } catch (e) {
      print('Erreur reconnaissance d\'intention: $e');
      // Fallback en cas d'erreur
      return IntentResult(
        intent: 'SEARCH_BY_NAME',
        confidence: 0.5,
        extracted: {},
      );
    }
  }
}

/// Résultat de la reconnaissance d'intention
class IntentResult {
  final String intent;
  final double confidence;
  final Map<String, dynamic> extracted;

  IntentResult({
    required this.intent,
    required this.confidence,
    required this.extracted,
  });

  factory IntentResult.fromJson(Map<String, dynamic> json) {
    return IntentResult(
      intent: json['intent'] ?? 'SEARCH_BY_NAME',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      extracted: json['extracted'] ?? {},
    );
  }

  /// Vérifie si l'intention est de type recherche par ingrédients
  bool get isIngredientSearch => intent == 'SEARCH_BY_INGREDIENTS';

  /// Vérifie si l'intention est de type recherche par contraintes
  bool get isConstraintSearch => intent == 'SEARCH_BY_CONSTRAINTS';

  /// Vérifie si l'intention est de type recherche par type
  bool get isTypeSearch => intent == 'SEARCH_BY_TYPE';

  /// Vérifie si l'intention est de type recherche par difficulté
  bool get isDifficultySearch => intent == 'SEARCH_BY_DIFFICULTY';

  /// Vérifie si l'intention est de type recherche par temps
  bool get isTimeSearch => intent == 'SEARCH_BY_TIME';

  /// Récupère les ingrédients extraits
  List<String> get extractedIngredients {
    final ingredients = extracted['ingredients'];
    if (ingredients is List) {
      return ingredients.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Récupère les contraintes extraites
  List<String> get extractedConstraints {
    final constraints = extracted['constraints'];
    if (constraints is List) {
      return constraints.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Récupère le type extrait
  String? get extractedType => extracted['type']?.toString();

  /// Récupère la difficulté extraite
  String? get extractedDifficulty => extracted['difficulty']?.toString();

  /// Récupère le temps extrait
  String? get extractedTime => extracted['time']?.toString();
}

