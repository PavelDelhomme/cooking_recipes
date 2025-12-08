import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_logger.dart';

/// Service HTTP wrapper qui ajoute automatiquement les headers anti-replay
/// pour les requêtes modifiantes (POST, PUT, DELETE, PATCH)
class HttpClient {
  /// Génère un nonce aléatoire (32 caractères hexadécimaux)
  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Génère un timestamp actuel en millisecondes
  static String _generateTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Ajoute les headers anti-replay si nécessaire
  static Map<String, String> _addReplayProtectionHeaders(
    String method,
    Map<String, String>? existingHeaders,
  ) {
    final headers = Map<String, String>.from(existingHeaders ?? {});
    
    // Ajouter les headers anti-replay uniquement pour les méthodes modifiantes
    const protectedMethods = ['POST', 'PUT', 'DELETE', 'PATCH'];
    if (protectedMethods.contains(method.toUpperCase())) {
      headers['x-nonce'] = _generateNonce();
      headers['x-timestamp'] = _generateTimestamp();
    }
    
    return headers;
  }

  /// GET request avec protection anti-replay si nécessaire
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final finalHeaders = _addReplayProtectionHeaders('GET', headers);
    return await ApiLogger.interceptRequest(
      () => http.get(url, headers: finalHeaders),
      'GET',
      url.toString(),
    );
  }

  /// POST request avec protection anti-replay
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final finalHeaders = _addReplayProtectionHeaders('POST', headers);
    return await ApiLogger.interceptRequest(
      () => http.post(url, headers: finalHeaders, body: body, encoding: encoding),
      'POST',
      url.toString(),
    );
  }

  /// PUT request avec protection anti-replay
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final finalHeaders = _addReplayProtectionHeaders('PUT', headers);
    return await ApiLogger.interceptRequest(
      () => http.put(url, headers: finalHeaders, body: body, encoding: encoding),
      'PUT',
      url.toString(),
    );
  }

  /// DELETE request avec protection anti-replay
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final finalHeaders = _addReplayProtectionHeaders('DELETE', headers);
    return await ApiLogger.interceptRequest(
      () => http.delete(url, headers: finalHeaders, body: body, encoding: encoding),
      'DELETE',
      url.toString(),
    );
  }

  /// PATCH request avec protection anti-replay
  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final finalHeaders = _addReplayProtectionHeaders('PATCH', headers);
    return await ApiLogger.interceptRequest(
      () => http.patch(url, headers: finalHeaders, body: body, encoding: encoding),
      'PATCH',
      url.toString(),
    );
  }
}

