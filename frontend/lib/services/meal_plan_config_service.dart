import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan_config.dart';

class MealPlanConfigService {
  static const String _configKey = 'meal_plan_config';

  Future<MealPlanConfig> getConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? configJson = prefs.getString(_configKey);
      
      if (configJson == null) {
        // Retourner la configuration par défaut
        final defaultConfig = MealPlanConfig();
        await saveConfig(defaultConfig);
        return defaultConfig;
      }

      final Map<String, dynamic> decoded = json.decode(configJson);
      return MealPlanConfig.fromJson(decoded);
    } catch (e) {
      print('Erreur lors du chargement de la configuration: $e');
      return MealPlanConfig(); // Configuration par défaut en cas d'erreur
    }
  }

  Future<bool> saveConfig(MealPlanConfig config) async {
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

