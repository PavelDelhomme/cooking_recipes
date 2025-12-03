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
        // Utiliser l'import conditionnel pour obtenir le hostname
        final hostname = getWebHostname();
        
        // Si on est sur le domaine de production, utiliser l'API de production (HTTPS)
        if (hostname == 'cooking-recipe.delhomme.ovh' || 
            hostname == 'www.cooking-recipe.delhomme.ovh' ||
            hostname == 'cookingrecipe.delhomme.ovh' ||
            hostname == 'www.cookingrecipe.delhomme.ovh') {
          return productionApiUrl;
        }
        
        // Si on est sur localhost, utiliser localhost (HTTP pour dev local)
        if (hostname == 'localhost' || hostname == '127.0.0.1') {
          return 'http://localhost:$backendPort/api';
        }
        
        // Sinon, utiliser l'hostname avec le port (pour développement réseau)
        // Utiliser HTTPS si la page est en HTTPS, sinon HTTP
        if (hostname != null) {
          final protocol = hostname.contains('localhost') || hostname.contains('127.0.0.1') 
              ? 'http' 
              : 'https';
          return '$protocol://$hostname:$backendPort/api';
        }
        
        // Fallback si hostname est null
        return 'http://localhost:$backendPort/api';
      } catch (e) {
        // Fallback si erreur
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

