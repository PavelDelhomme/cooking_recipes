import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import 'api_logger.dart'; // Logger pour les requêtes API

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  
  // Utiliser la configuration centralisée de l'API
  static String get _baseUrl => ApiConfig.baseUrl;

  // Inscription
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      // Préparer le body
      final bodyData = <String, dynamic>{
        'email': email.trim(),
        'password': password,
      };
      if (name != null && name.trim().isNotEmpty) {
        bodyData['name'] = name.trim();
      }
      
      final bodyJson = json.encode(bodyData);
      final url = '$_baseUrl/auth/signup';
      
      // Utiliser le logger pour intercepter la requête
      final response = await ApiLogger.interceptRequest(
        () => http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: bodyJson,
        ),
        'POST',
        url,
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveToken(data['token'] as String);
        await _saveUser(User.fromJson(data['user'] as Map<String, dynamic>));
        return {'success': true, 'user': data['user']};
      } else {
        // Essayer de parser le JSON d'erreur
        try {
          final error = json.decode(response.body);
          final errorMessage = error['message'] ?? 'Erreur d\'inscription (${response.statusCode})';
          print('Signup error: $errorMessage');
          return {'success': false, 'error': errorMessage};
        } catch (e) {
          // Si le body n'est pas du JSON valide
          print('Signup error - cannot parse response: ${response.body}');
          return {'success': false, 'error': 'Erreur d\'inscription (${response.statusCode}): ${response.body}'};
        }
      }
    } catch (e, stackTrace) {
      print('Signup exception: $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'error': 'Erreur de connexion: $e'};
    }
  }

  // Connexion
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final url = '$_baseUrl/auth/signin';
      
      // Utiliser le logger pour intercepter la requête
      final response = await ApiLogger.interceptRequest(
        () => http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: json.encode({
            'email': email.trim(),
            'password': password,
          }),
        ),
        'POST',
        url,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveToken(data['token'] as String);
        await _saveUser(User.fromJson(data['user'] as Map<String, dynamic>));
        return {'success': true, 'user': data['user']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Erreur de connexion'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur de connexion: $e'};
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Obtenir l'utilisateur actuel
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return null;
      return User.fromJson(json.decode(userJson) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Obtenir le token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Sauvegarder le token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Sauvegarder l'utilisateur
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  // Mettre à jour l'utilisateur
  Future<void> updateUser(User user) async {
    await _saveUser(user);
  }

  // Vérifier le statut premium
  Future<bool> checkPremiumStatus() async {
    final user = await getCurrentUser();
    if (user == null) return false;
    return user.isPremiumActive;
  }
}

