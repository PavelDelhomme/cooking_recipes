import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'http_client.dart';

/// Service pour la gestion admin de l'IA de traduction
/// Accès réservé aux admins (dumb@delhomme.ovh, dev@delhomme.ovh)
class MLAdminService {
  static const String _basePath = '/ml-admin';
  final AuthService _authService = AuthService();

  /// Récupère les statistiques des feedbacks
  Future<Map<String, dynamic>> getStats() async {
    try {
      final token = await _authService.getToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$_basePath/stats');
      
      final response = await HttpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération stats: $e');
    }
  }

  /// Approuve tous les feedbacks en attente
  Future<Map<String, dynamic>> approveAllFeedbacks() async {
    try {
      final token = await _authService.getToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$_basePath/approve-all');
      
      final response = await HttpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'confirm': true}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur approbation en masse: $e');
    }
  }

  /// Réentraîne le modèle ML
  Future<Map<String, dynamic>> retrainML() async {
    try {
      final token = await _authService.getToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$_basePath/retrain');
      
      final response = await HttpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réentraînement ML: $e');
    }
  }

  /// Réentraîne le réseau de neurones
  Future<Map<String, dynamic>> retrainNeural() async {
    try {
      final token = await _authService.getToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$_basePath/retrain-neural');
      
      final response = await HttpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      } else if (response.statusCode == 503) {
        throw Exception('TensorFlow.js non installé. Utilisez: make install-neural');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réentraînement neural: $e');
    }
  }

  /// Récupère les feedbacks
  Future<Map<String, dynamic>> getFeedbacks({
    int limit = 50,
    int offset = 0,
    bool? approved,
  }) async {
    try {
      final token = await _authService.getToken();
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (approved != null) {
        queryParams['approved'] = approved.toString();
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/feedbacks')
          .replace(queryParameters: queryParams);
      
      final response = await HttpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération feedbacks: $e');
    }
  }

  /// Approuve un feedback spécifique
  Future<bool> approveFeedback(String feedbackId) async {
    try {
      final token = await _authService.getToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$_basePath/approve/$feedbackId');
      
      final response = await HttpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Réservé aux administrateurs.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur approbation feedback: $e');
    }
  }
}

