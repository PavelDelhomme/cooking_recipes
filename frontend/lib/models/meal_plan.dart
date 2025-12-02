import 'recipe.dart';

class MealPlan {
  final String id;
  final DateTime date;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final Recipe recipe;

  MealPlan({
    required this.id,
    required this.date,
    required this.mealType,
    required this.recipe,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mealType': mealType,
      'recipe': recipe.toJson(),
    };
  }

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: json['mealType'] as String,
      recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
    );
  }
}

