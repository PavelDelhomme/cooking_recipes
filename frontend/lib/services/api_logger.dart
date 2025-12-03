import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service pour logger les requêtes et réponses API dans la console JS
class ApiLogger {
  static const bool _enableLogging = kDebugMode; // Actif uniquement en mode debug
  
  /// Log une requête HTTP
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!_enableLogging) return;
    
    final logData = {
      'type': 'API_REQUEST',
      'timestamp': DateTime.now().toIso8601String(),
      'method': method,
      'url': url,
      'headers': headers,
      'body': body,
    };
    
    _logToConsole('📤 API Request', logData);
  }
  
  /// Log une réponse HTTP
  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    Map<String, String>? headers,
    dynamic body,
    Duration? duration,
  }) {
    if (!_enableLogging) return;
    
    final logData = {
      'type': 'API_RESPONSE',
      'timestamp': DateTime.now().toIso8601String(),
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'headers': headers,
      'body': body,
      'duration': duration?.inMilliseconds,
    };
    
    final emoji = statusCode >= 200 && statusCode < 300 
        ? '✅' 
        : statusCode >= 400 && statusCode < 500 
            ? '⚠️' 
            : statusCode >= 500 
                ? '❌' 
                : 'ℹ️';
    
    _logToConsole('$emoji API Response ($statusCode)', logData);
  }
  
  /// Log une erreur HTTP
  static void logError({
    required String method,
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!_enableLogging) return;
    
    final logData = {
      'type': 'API_ERROR',
      'timestamp': DateTime.now().toIso8601String(),
      'method': method,
      'url': url,
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
    };
    
    _logToConsole('❌ API Error', logData);
  }
  
  /// Log dans la console (web et mobile)
  static void _logToConsole(String title, Map<String, dynamic> data) {
    if (kIsWeb) {
      // Sur le web, utiliser console.log avec formatage JSON
      try {
        final jsonString = const JsonEncoder.withIndent('  ').convert(data);
        // Utiliser dart:html pour accéder à la console JS
        // Note: Ceci nécessite un import conditionnel
        print('$title:\n$jsonString');
      } catch (e) {
        print('$title: ${data.toString()}');
      }
    } else {
      // Sur mobile, utiliser print standard
      print('$title: ${data.toString()}');
    }
  }
  
  /// Wrapper pour intercepter les requêtes HTTP
  static Future<http.Response> interceptRequest(
    Future<http.Response> Function() request,
    String method,
    String url,
  ) async {
    final startTime = DateTime.now();
    
    try {
      logRequest(method: method, url: url);
      
      final response = await request();
      
      final duration = DateTime.now().difference(startTime);
      
      // Parser le body si possible
      dynamic body;
      try {
        if (response.body.isNotEmpty) {
          body = json.decode(response.body);
        }
      } catch (e) {
        body = response.body;
      }
      
      logResponse(
        method: method,
        url: url,
        statusCode: response.statusCode,
        headers: response.headers,
        body: body,
        duration: duration,
      );
      
      return response;
    } catch (e, stackTrace) {
      logError(
        method: method,
        url: url,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

