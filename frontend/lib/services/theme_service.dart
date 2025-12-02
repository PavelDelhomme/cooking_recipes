import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'is_dark_mode';

  // Obtenir le mode sombre (par défaut: true pour mode sombre)
  Future<bool> isDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Si la clé n'existe pas, retourner true (mode sombre par défaut)
      if (!prefs.containsKey(_themeKey)) {
        await setDarkMode(true);
        return true;
      }
      return prefs.getBool(_themeKey) ?? true;
    } catch (e) {
      return true; // Mode sombre par défaut en cas d'erreur
    }
  }

  // Sauvegarder le mode sombre
  Future<bool> setDarkMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      return false;
    }
  }

  // Toggle le mode sombre
  Future<bool> toggleTheme() async {
    final current = await isDarkMode();
    return await setDarkMode(!current);
  }
}

