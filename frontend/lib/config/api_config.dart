import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Port du backend
  static const int backendPort = 7272;
  
  // Détecter automatiquement l'URL de l'API
  static String get baseUrl {
    if (kIsWeb) {
      // En web, utiliser l'hostname actuel pour l'API
      try {
        // Utiliser une approche simple qui fonctionne à l'exécution
        final hostname = _getWebHostname();
        if (hostname != null) {
          // Si on est sur localhost, utiliser localhost, sinon utiliser l'IP
          if (hostname == 'localhost' || hostname == '127.0.0.1') {
            return 'http://localhost:$backendPort/api';
          } else {
            return 'http://$hostname:$backendPort/api';
          }
        }
      } catch (e) {
        // Fallback si erreur
      }
      return 'http://localhost:$backendPort/api';
    } else {
      // Pour mobile, utiliser l'IP de la machine (sera configurée via make configure-mobile-api)
      // Par défaut, on essaie de détecter ou utiliser localhost
      return 'http://localhost:$backendPort/api';
    }
  }
  
  // Fonction pour obtenir le hostname web
  // Cette fonction sera remplacée par une version avec dart:html lors du build web
  // Pour l'instant, on retourne null pour éviter les erreurs de compilation
  static String? _getWebHostname() {
    // En mode web, cette fonction devrait utiliser dart:html
    // Mais pour éviter les erreurs de compilation sur mobile, on retourne null
    // et on utilise localhost par défaut
    return null;
  }
  
  // URL complète pour un endpoint
  static String endpoint(String path) {
    // Enlever le slash initial s'il existe
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$cleanPath';
  }
}

