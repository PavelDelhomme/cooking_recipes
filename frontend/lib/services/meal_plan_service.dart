import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan.dart';
import '../models/recurring_meal_plan.dart';

class MealPlanService {
  static const String _mealPlanKey = 'meal_plans';
  static const String _recurringMealPlanKey = 'recurring_meal_plans';

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

  // ========== GESTION DES REPAS RÉCURRENTS ==========

  // Charger tous les repas récurrents
  Future<List<RecurringMealPlan>> getRecurringMealPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_recurringMealPlanKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => RecurringMealPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des repas récurrents: $e');
      return [];
    }
  }

  // Sauvegarder tous les repas récurrents
  Future<bool> saveRecurringMealPlans(List<RecurringMealPlan> plans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(
        plans.map((plan) => plan.toJson()).toList(),
      );
      return await prefs.setString(_recurringMealPlanKey, jsonString);
    } catch (e) {
      print('Erreur lors de la sauvegarde des repas récurrents: $e');
      return false;
    }
  }

  // Ajouter un repas récurrent
  Future<bool> addRecurringMealPlan(RecurringMealPlan plan) async {
    final plans = await getRecurringMealPlans();
    plans.add(plan);
    return await saveRecurringMealPlans(plans);
  }

  // Mettre à jour un repas récurrent
  Future<bool> updateRecurringMealPlan(RecurringMealPlan plan) async {
    final plans = await getRecurringMealPlans();
    final index = plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      plans[index] = plan;
      return await saveRecurringMealPlans(plans);
    }
    return false;
  }

  // Supprimer un repas récurrent
  Future<bool> removeRecurringMealPlan(String id) async {
    final plans = await getRecurringMealPlans();
    plans.removeWhere((plan) => plan.id == id);
    return await saveRecurringMealPlans(plans);
  }

  // Obtenir tous les repas (normaux + récurrents) pour une date
  Future<List<MealPlan>> getAllMealPlansForDate(DateTime date) async {
    final normalPlans = await getMealPlansForDate(date);
    final recurringPlans = await getRecurringMealPlans();
    
    // Convertir les repas récurrents applicables en MealPlan
    final List<MealPlan> allPlans = List.from(normalPlans);
    
    for (final recurring in recurringPlans) {
      if (recurring.appliesToDate(date)) {
        allPlans.add(MealPlan(
          id: '${recurring.id}_${date.toIso8601String()}',
          date: date,
          mealType: recurring.getMealTypeForDate(date),
          recipe: recurring.recipe,
        ));
      }
    }
    
    return allPlans;
  }

  // Obtenir tous les repas (normaux + récurrents) pour une période
  Future<List<MealPlan>> getAllMealPlansForPeriod(DateTime startDate, DateTime endDate) async {
    final normalPlans = await getMealPlansForPeriod(startDate, endDate);
    final recurringPlans = await getRecurringMealPlans();
    
    final List<MealPlan> allPlans = List.from(normalPlans);
    
    // Pour chaque jour de la période, vérifier les repas récurrents
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      for (final recurring in recurringPlans) {
        if (recurring.appliesToDate(currentDate)) {
          allPlans.add(MealPlan(
            id: '${recurring.id}_${currentDate.toIso8601String()}',
            date: currentDate,
            mealType: recurring.getMealTypeForDate(currentDate),
            recipe: recurring.recipe,
          ));
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return allPlans;
  }
}

