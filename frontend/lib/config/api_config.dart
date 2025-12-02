import 'package:flutter/foundation.dart' show kIsWeb;

// Import conditionnel pour le web
import 'dart:html' as html show window if (dart.library.html);

class ApiConfig {
  // Port du backend
  static const int backendPort = 7373;
  
  // Détecter automatiquement l'URL de l'API
  static String get baseUrl {
    if (kIsWeb) {
      // En web, utiliser l'hostname actuel pour l'API
      try {
        final hostname = html.window.location.hostname;
        // Si on est sur localhost, utiliser localhost, sinon utiliser l'IP
        if (hostname == 'localhost' || hostname == '127.0.0.1') {
          return 'http://localhost:$backendPort/api';
        } else {
          return 'http://$hostname:$backendPort/api';
        }
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

