import 'package:flutter/foundation.dart' show kIsWeb;

// Import conditionnel pour le web
import 'api_config_web.dart' if (dart.library.io) 'dart:io';

class ApiConfig {
  // Port du backend
  static const int backendPort = 7272;
  
  // URL de l'API en production (HTTPS)
  static const String productionApiUrl = 'https://cooking-recipe-api.delhomme.ovh/api';
  
  // Détecter automatiquement l'URL de l'API
  static String get baseUrl {
    if (kIsWeb) {
      try {
        // Utiliser l'import conditionnel pour obtenir le hostname et le protocole
        final hostname = getWebHostname();
        final protocol = getWebProtocol();
        final isHttps = protocol == 'https:';
        
        // Si on est sur un domaine de production (.delhomme.ovh), TOUJOURS utiliser HTTPS
        if (hostname != null && hostname.contains('.delhomme.ovh')) {
          return productionApiUrl;
        }
        
        // Si on est sur localhost, utiliser localhost (HTTP pour dev local)
        if (hostname == 'localhost' || hostname == '127.0.0.1') {
          return 'http://localhost:$backendPort/api';
        }
        
        // Si la page est en HTTPS, utiliser l'API de production en HTTPS
        if (isHttps) {
          return productionApiUrl;
        }
        
        // Sinon, utiliser HTTP avec le hostname et le port (pour développement réseau)
        if (hostname != null) {
          return 'http://$hostname:$backendPort/api';
        }
        
        // Fallback si hostname est null
        return 'http://localhost:$backendPort/api';
      } catch (e) {
        // Fallback si erreur - si on est en HTTPS, utiliser l'API de production
        try {
          final protocol = getWebProtocol();
          if (protocol == 'https:') {
            return productionApiUrl;
          }
        } catch (_) {}
        return 'http://localhost:$backendPort/api';
      }
    } else {
      // Pour mobile (Android/iOS)
      // En mode release, utiliser l'API de production (HTTPS)
      if (const bool.fromEnvironment('dart.vm.product')) {
        return productionApiUrl;
      } else {
        // Mode debug : utiliser localhost (pour développement local)
        return 'http://localhost:$backendPort/api';
      }
    }
  }
  
  // URL complète pour un endpoint
  static String endpoint(String path) {
    // Enlever le slash initial s'il existe
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$cleanPath';
  }
}

