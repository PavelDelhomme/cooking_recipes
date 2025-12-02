import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LocaleService {
  static const String _localeKey = 'selected_locale';
  static const Locale defaultLocale = Locale('fr', 'FR');
  
  // Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];
  
  // Noms des langues
  static Map<String, String> get languageNames => {
    'fr': 'Français',
    'en': 'English',
    'es': 'Español',
  };
  
  // Obtenir la locale sauvegardée
  static Future<Locale> getLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      
      if (localeCode != null) {
        final parts = localeCode.split('_');
        if (parts.length == 2) {
          return Locale(parts[0], parts[1]);
        } else if (parts.length == 1) {
          return Locale(parts[0]);
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de la locale: $e');
    }
    
    return defaultLocale;
  }
  
  // Sauvegarder la locale
  static Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode ?? ''}');
    } catch (e) {
      print('Erreur lors de la sauvegarde de la locale: $e');
    }
  }
  
  // Obtenir le code de langue (fr, en, es)
  static Future<String> getLanguageCode() async {
    final locale = await getLocale();
    return locale.languageCode;
  }
}

