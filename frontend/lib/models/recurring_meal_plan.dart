import 'recipe.dart';

/// Représente un repas qui se répète de manière récurrente
class RecurringMealPlan {
  final String id;
  final Recipe recipe;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final int dayOfWeek; // 0 = dimanche, 1 = lundi, ..., 6 = samedi
  final DateTime startDate; // Date de début de la récurrence
  final DateTime? endDate; // Date de fin (null = indéfini)
  final List<String> excludedDates; // Dates où cette recette ne s'applique pas (format ISO)
  final Map<String, String> overrides; // Overrides: date ISO -> mealType différent

  RecurringMealPlan({
    required this.id,
    required this.recipe,
    required this.mealType,
    required this.dayOfWeek,
    required this.startDate,
    this.endDate,
    List<String>? excludedDates,
    Map<String, String>? overrides,
  }) : excludedDates = excludedDates ?? [],
       overrides = overrides ?? {};

  /// Vérifie si cette recette s'applique à une date donnée
  bool appliesToDate(DateTime date) {
    // Vérifier si la date est dans la plage
    if (date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    
    // Vérifier si c'est le bon jour de la semaine
    if (date.weekday % 7 != dayOfWeek) return false;
    
    // Vérifier si la date est exclue
    final dateStr = _dateToIso(date);
    if (excludedDates.contains(dateStr)) return false;
    
    return true;
  }

  /// Obtient le type de repas pour une date donnée (peut être overridé)
  String getMealTypeForDate(DateTime date) {
    final dateStr = _dateToIso(date);
    return overrides[dateStr] ?? mealType;
  }

  /// Exclure cette recette pour une date spécifique
  void excludeDate(DateTime date) {
    final dateStr = _dateToIso(date);
    if (!excludedDates.contains(dateStr)) {
      excludedDates.add(dateStr);
    }
  }

  /// Réinclure cette recette pour une date spécifique
  void includeDate(DateTime date) {
    final dateStr = _dateToIso(date);
    excludedDates.remove(dateStr);
    overrides.remove(dateStr); // Supprimer aussi l'override si présent
  }

  /// Override le type de repas pour une date spécifique
  void overrideMealType(DateTime date, String newMealType) {
    final dateStr = _dateToIso(date);
    overrides[dateStr] = newMealType;
    excludedDates.remove(dateStr); // Réinclure si elle était exclue
  }

  /// Supprimer l'override pour une date spécifique
  void removeOverride(DateTime date) {
    final dateStr = _dateToIso(date);
    overrides.remove(dateStr);
  }

  String _dateToIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe': recipe.toJson(),
      'mealType': mealType,
      'dayOfWeek': dayOfWeek,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'excludedDates': excludedDates,
      'overrides': overrides,
    };
  }

  factory RecurringMealPlan.fromJson(Map<String, dynamic> json) {
    return RecurringMealPlan(
      id: json['id'] as String,
      recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      mealType: json['mealType'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      excludedDates: (json['excludedDates'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      overrides: (json['overrides'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  RecurringMealPlan copyWith({
    String? id,
    Recipe? recipe,
    String? mealType,
    int? dayOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? excludedDates,
    Map<String, String>? overrides,
  }) {
    return RecurringMealPlan(
      id: id ?? this.id,
      recipe: recipe ?? this.recipe,
      mealType: mealType ?? this.mealType,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      excludedDates: excludedDates ?? List.from(this.excludedDates),
      overrides: overrides ?? Map.from(this.overrides),
    );
  }
}

