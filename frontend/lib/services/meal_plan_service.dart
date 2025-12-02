import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan.dart';

class MealPlanService {
  static const String _mealPlanKey = 'meal_plans';

  // Charger tous les plans de repas
  Future<List<MealPlan>> getMealPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_mealPlanKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => MealPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des plans de repas: $e');
      return [];
    }
  }

  // Sauvegarder tous les plans de repas
  Future<bool> saveMealPlans(List<MealPlan> plans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(
        plans.map((plan) => plan.toJson()).toList(),
      );
      return await prefs.setString(_mealPlanKey, jsonString);
    } catch (e) {
      print('Erreur lors de la sauvegarde des plans de repas: $e');
      return false;
    }
  }

  // Ajouter un plan de repas
  Future<bool> addMealPlan(MealPlan plan) async {
    final plans = await getMealPlans();
    plans.add(plan);
    return await saveMealPlans(plans);
  }

  // Supprimer un plan de repas
  Future<bool> removeMealPlan(String id) async {
    final plans = await getMealPlans();
    plans.removeWhere((plan) => plan.id == id);
    return await saveMealPlans(plans);
  }

  // Obtenir les plans de repas pour une date
  Future<List<MealPlan>> getMealPlansForDate(DateTime date) async {
    final plans = await getMealPlans();
    return plans.where((plan) {
      return plan.date.year == date.year &&
          plan.date.month == date.month &&
          plan.date.day == date.day;
    }).toList();
  }

  // Obtenir les plans de repas pour une période
  Future<List<MealPlan>> getMealPlansForPeriod(DateTime startDate, DateTime endDate) async {
    final plans = await getMealPlans();
    return plans.where((plan) {
      return plan.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          plan.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
}

