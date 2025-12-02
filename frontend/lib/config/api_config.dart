import 'package:flutter/foundation.dart' show kIsWeb;

// Import conditionnel pour le web
import 'api_config_web.dart' if (dart.library.io) 'dart:io';

class ApiConfig {
  // Port du backend
  static const int backendPort = 7272;
  
  // URL de l'API en production
  static const String productionApiUrl = 'https://cooking-recipe-api.delhomme.ovh/api';
  
  // Détecter automatiquement l'URL de l'API
  static String get baseUrl {
    if (kIsWeb) {
      try {
        // Utiliser l'import conditionnel pour obtenir le hostname
        final hostname = getWebHostname();
        
        // Si on est sur le domaine de production, utiliser l'API de production
        if (hostname == 'cooking-recipe.delhomme.ovh' || 
            hostname == 'www.cooking-recipe.delhomme.ovh') {
          return productionApiUrl;
        }
        
        // Si on est sur localhost, utiliser localhost
        if (hostname == 'localhost' || hostname == '127.0.0.1') {
          return 'http://localhost:$backendPort/api';
        }
        
        // Sinon, utiliser l'hostname avec le port (pour développement réseau)
        return 'http://$hostname:$backendPort/api';
      } catch (e) {
        // Fallback si erreur
        return 'http://localhost:$backendPort/api';
      }
    } else {
      // Pour mobile, utiliser l'IP de la machine (sera configurée via make configure-mobile-api)
      // Par défaut, on essaie de détecter ou utiliser localhost
      return 'http://localhost:$backendPort/api';
    }
  }
  
  // URL complète pour un endpoint
  static String endpoint(String path) {
    // Enlever le slash initial s'il existe
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$cleanPath';
  }
}

