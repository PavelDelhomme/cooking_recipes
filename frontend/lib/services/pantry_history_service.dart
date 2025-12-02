import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pantry_history_item.dart';

class PantryHistoryService {
  static const String _historyKey = 'pantry_history';

  // Obtenir tout l'historique
  Future<List<PantryHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_historyKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => PantryHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.usedDate.compareTo(a.usedDate)); // Plus récent en premier
    } catch (e) {
      print('Erreur lors du chargement de l\'historique: $e');
      return [];
    }
  }

  // Ajouter un élément à l'historique
  Future<bool> addHistoryItem(PantryHistoryItem item) async {
    try {
      final history = await getHistory();
      history.insert(0, item); // Ajouter au début
      
      // Limiter à 1000 entrées pour éviter de surcharger
      if (history.length > 1000) {
        history.removeRange(1000, history.length);
      }
      
      return await saveHistory(history);
    } catch (e) {
      print('Erreur lors de l\'ajout à l\'historique: $e');
      return false;
    }
  }

  // Sauvegarder tout l'historique
  Future<bool> saveHistory(List<PantryHistoryItem> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(
        history.map((item) => item.toJson()).toList(),
      );
      return await prefs.setString(_historyKey, jsonString);
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'historique: $e');
      return false;
    }
  }

  // Supprimer un élément de l'historique
  Future<bool> removeHistoryItem(String id) async {
    try {
      final history = await getHistory();
      history.removeWhere((item) => item.id == id);
      return await saveHistory(history);
    } catch (e) {
      print('Erreur lors de la suppression de l\'historique: $e');
      return false;
    }
  }

  // Vider l'historique
  Future<bool> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_historyKey);
    } catch (e) {
      print('Erreur lors de la suppression de l\'historique: $e');
      return false;
    }
  }

  // Obtenir l'historique filtré par ingrédient
  Future<List<PantryHistoryItem>> getHistoryByIngredient(String ingredientName) async {
    final history = await getHistory();
    return history
        .where((item) => 
            item.ingredientName.toLowerCase().contains(ingredientName.toLowerCase()))
        .toList();
  }

  // Obtenir l'historique pour une période
  Future<List<PantryHistoryItem>> getHistoryForPeriod(DateTime start, DateTime end) async {
    final history = await getHistory();
    return history
        .where((item) => 
            item.usedDate.isAfter(start.subtract(const Duration(days: 1))) &&
            item.usedDate.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }
}

