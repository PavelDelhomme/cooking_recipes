import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list_item.dart';

class ShoppingListService {
  static const String _shoppingListKey = 'shopping_list_items';

  // Charger tous les items de la liste de courses
  Future<List<ShoppingListItem>> getShoppingListItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_shoppingListKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => ShoppingListItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement de la liste de courses: $e');
      return [];
    }
  }

  // Sauvegarder tous les items de la liste de courses
  Future<bool> saveShoppingListItems(List<ShoppingListItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(
        items.map((item) => item.toJson()).toList(),
      );
      return await prefs.setString(_shoppingListKey, jsonString);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la liste de courses: $e');
      return false;
    }
  }

  // Ajouter un item à la liste de courses
  Future<bool> addShoppingListItem(ShoppingListItem item) async {
    final items = await getShoppingListItems();
    // Vérifier si l'item existe déjà (non coché)
    final existingIndex = items.indexWhere(
      (i) => i.name.toLowerCase() == item.name.toLowerCase() && !i.isChecked,
    );
    
    if (existingIndex != -1) {
      // Mettre à jour la quantité si nécessaire
      final existing = items[existingIndex];
      final newQuantity = (existing.quantity ?? 0) + (item.quantity ?? 0);
      items[existingIndex] = existing.copyWith(quantity: newQuantity);
    } else {
      items.add(item);
    }
    
    return await saveShoppingListItems(items);
  }

  // Ajouter plusieurs items à la liste de courses
  Future<bool> addShoppingListItems(List<ShoppingListItem> items) async {
    for (var item in items) {
      await addShoppingListItem(item);
    }
    return true;
  }

  // Mettre à jour un item de la liste de courses
  Future<bool> updateShoppingListItem(ShoppingListItem item) async {
    final items = await getShoppingListItems();
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      return await saveShoppingListItems(items);
    }
    return false;
  }

  // Cocher/décocher un item
  Future<bool> toggleShoppingListItem(String id) async {
    final items = await getShoppingListItems();
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(isChecked: !items[index].isChecked);
      return await saveShoppingListItems(items);
    }
    return false;
  }

  // Supprimer un item de la liste de courses
  Future<bool> removeShoppingListItem(String id) async {
    final items = await getShoppingListItems();
    items.removeWhere((item) => item.id == id);
    return await saveShoppingListItems(items);
  }

  // Supprimer tous les items cochés
  Future<bool> removeCheckedItems() async {
    final items = await getShoppingListItems();
    items.removeWhere((item) => item.isChecked);
    return await saveShoppingListItems(items);
  }

  // Obtenir les items non cochés
  Future<List<ShoppingListItem>> getUncheckedItems() async {
    final items = await getShoppingListItems();
    return items.where((item) => !item.isChecked).toList();
  }
}

