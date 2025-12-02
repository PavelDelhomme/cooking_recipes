class MealPlanConfig {
  final bool autoPlanEnabled;
  final int defaultDays;
  final String defaultMealType;
  final bool preferPantryIngredients;
  final bool avoidRepeatingRecipes;
  final int maxRecipesPerWeek;

  MealPlanConfig({
    this.autoPlanEnabled = true,
    this.defaultDays = 7,
    this.defaultMealType = 'dinner',
    this.preferPantryIngredients = true,
    this.avoidRepeatingRecipes = true,
    this.maxRecipesPerWeek = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'autoPlanEnabled': autoPlanEnabled,
      'defaultDays': defaultDays,
      'defaultMealType': defaultMealType,
      'preferPantryIngredients': preferPantryIngredients,
      'avoidRepeatingRecipes': avoidRepeatingRecipes,
      'maxRecipesPerWeek': maxRecipesPerWeek,
    };
  }

  factory MealPlanConfig.fromJson(Map<String, dynamic> json) {
    return MealPlanConfig(
      autoPlanEnabled: json['autoPlanEnabled'] as bool? ?? true,
      defaultDays: json['defaultDays'] as int? ?? 7,
      defaultMealType: json['defaultMealType'] as String? ?? 'dinner',
      preferPantryIngredients: json['preferPantryIngredients'] as bool? ?? true,
      avoidRepeatingRecipes: json['avoidRepeatingRecipes'] as bool? ?? true,
      maxRecipesPerWeek: json['maxRecipesPerWeek'] as int? ?? 10,
    );
  }

  MealPlanConfig copyWith({
    bool? autoPlanEnabled,
    int? defaultDays,
    String? defaultMealType,
    bool? preferPantryIngredients,
    bool? avoidRepeatingRecipes,
    int? maxRecipesPerWeek,
  }) {
    return MealPlanConfig(
      autoPlanEnabled: autoPlanEnabled ?? this.autoPlanEnabled,
      defaultDays: defaultDays ?? this.defaultDays,
      defaultMealType: defaultMealType ?? this.defaultMealType,
      preferPantryIngredients: preferPantryIngredients ?? this.preferPantryIngredients,
      avoidRepeatingRecipes: avoidRepeatingRecipes ?? this.avoidRepeatingRecipes,
      maxRecipesPerWeek: maxRecipesPerWeek ?? this.maxRecipesPerWeek,
    );
  }
}

