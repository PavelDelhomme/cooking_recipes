// Fichier spécifique pour le web avec l'import dart:html
import 'dart:html' as html;

String? getWebHostname() {
  try {
    return html.window.location.hostname;
  } catch (e) {
    return null;
  }
}

