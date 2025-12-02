import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pantry_config.dart';

class PantryConfigService {
  static const String _configKey = 'pantry_config';

  Future<PantryConfig> getConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? configJson = prefs.getString(_configKey);

      if (configJson == null) {
        // Retourner la configuration par défaut
        final defaultConfig = PantryConfig();
        await saveConfig(defaultConfig);
        return defaultConfig;
      }

      final Map<String, dynamic> decoded = json.decode(configJson);
      return PantryConfig.fromJson(decoded);
    } catch (e) {
      print('Erreur lors du chargement de la configuration: $e');
      return PantryConfig(); // Configuration par défaut en cas d'erreur
    }
  }

  Future<bool> saveConfig(PantryConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String configJson = json.encode(config.toJson());
      return await prefs.setString(_configKey, configJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la configuration: $e');
      return false;
    }
  }
}

