import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pantry_item.dart';

class PantryService {
  static const String _pantryKey = 'pantry_items';

  // Charger tous les items du placard
  Future<List<PantryItem>> getPantryItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_pantryKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => PantryItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement du placard: $e');
      return [];
    }
  }

  // Sauvegarder tous les items du placard
  Future<bool> savePantryItems(List<PantryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(
        items.map((item) => item.toJson()).toList(),
      );
      return await prefs.setString(_pantryKey, jsonString);
    } catch (e) {
      print('Erreur lors de la sauvegarde du placard: $e');
      return false;
    }
  }

  // Ajouter un item au placard
  Future<bool> addPantryItem(PantryItem item) async {
    final items = await getPantryItems();
    items.add(item);
    return await savePantryItems(items);
  }

  // Mettre à jour un item du placard
  Future<bool> updatePantryItem(PantryItem item) async {
    final items = await getPantryItems();
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      return await savePantryItems(items);
    }
    return false;
  }

  // Supprimer un item du placard
  Future<bool> removePantryItem(String id) async {
    final items = await getPantryItems();
    items.removeWhere((item) => item.id == id);
    return await savePantryItems(items);
  }

  // Utiliser une quantité d'un ingrédient (diminuer la quantité)
  Future<bool> useIngredient(String id, double quantity) async {
    final items = await getPantryItems();
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final item = items[index];
      final newQuantity = item.quantity - quantity;
      if (newQuantity <= 0) {
        // Supprimer l'item si la quantité est épuisée
        items.removeAt(index);
      } else {
        items[index] = item.copyWith(quantity: newQuantity);
      }
      return await savePantryItems(items);
    }
    return false;
  }

  // Obtenir les noms des ingrédients disponibles
  Future<List<String>> getAvailableIngredientNames() async {
    final items = await getPantryItems();
    return items.map((item) => item.name.toLowerCase()).toList();
  }
}

