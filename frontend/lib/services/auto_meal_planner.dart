import '../models/recipe.dart';
import '../models/pantry_item.dart';
import '../models/meal_plan.dart';
import '../services/recipe_api_service.dart';
import '../services/pantry_service.dart';
import '../services/meal_plan_service.dart';

class AutoMealPlanner {
  final RecipeApiService _recipeService = RecipeApiService();
  final PantryService _pantryService = PantryService();
  final MealPlanService _mealPlanService = MealPlanService();

  // Calculer les ingrédients disponibles en tenant compte des repas déjà planifiés
  Future<Map<String, double>> _calculateAvailableIngredients(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Récupérer le placard actuel
    final pantryItems = await _pantryService.getPantryItems();
    final Map<String, double> availableIngredients = {};
    
    for (var item in pantryItems) {
      availableIngredients[item.name.toLowerCase()] = item.quantity;
    }

    // Récupérer tous les repas planifiés dans la période
    final allPlans = await _mealPlanService.getMealPlans();
    final plansInPeriod = allPlans.where((plan) {
      return plan.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          plan.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Soustraire les ingrédients qui seront utilisés par les repas planifiés
    for (var plan in plansInPeriod) {
      for (var ingredient in plan.recipe.ingredients) {
        final ingredientName = ingredient.name.toLowerCase().trim();
        final quantityUsed = ingredient.quantity ?? 1.0;
        
        // Chercher une correspondance dans les ingrédients disponibles
        String? matchedKey;
        for (var availableName in availableIngredients.keys) {
          if (ingredientName.contains(availableName) || 
              availableName.contains(ingredientName) ||
              ingredientName == availableName) {
            matchedKey = availableName;
            break;
          }
        }
        
        if (matchedKey != null) {
          availableIngredients[matchedKey] = 
              (availableIngredients[matchedKey]! - quantityUsed).clamp(0.0, double.infinity);
        }
      }
    }

    return availableIngredients;
  }

  // Vérifier si une recette peut être préparée avec les ingrédients disponibles
  bool _canMakeRecipe(Recipe recipe, Map<String, double> availableIngredients) {
    // Créer une copie des ingrédients disponibles pour ne pas les modifier
    final remainingIngredients = Map<String, double>.from(availableIngredients);
    
    for (var ingredient in recipe.ingredients) {
      final ingredientName = ingredient.name.toLowerCase().trim();
      final requiredQuantity = ingredient.quantity ?? 1.0;
      
      // Vérifier si l'ingrédient est disponible
      bool found = false;
      String? matchedKey;
      
      for (var availableName in remainingIngredients.keys) {
        // Correspondance flexible : soit le nom contient l'autre, soit ils sont similaires
        if (ingredientName.contains(availableName) || 
            availableName.contains(ingredientName) ||
            ingredientName == availableName) {
          if (remainingIngredients[availableName]! >= requiredQuantity) {
            found = true;
            matchedKey = availableName;
            break;
          }
        }
      }
      
      if (!found) {
        return false;
      }
      
      // Soustraire la quantité utilisée
      if (matchedKey != null) {
        remainingIngredients[matchedKey] = 
            (remainingIngredients[matchedKey]! - requiredQuantity).clamp(0.0, double.infinity);
      }
    }
    return true;
  }

  // Générer un planning automatique pour une période
  Future<List<MealPlan>> generateMealPlan({
    required DateTime startDate,
    required int days,
    required String mealType,
  }) async {
    final endDate = startDate.add(Duration(days: days - 1));
    final availableIngredients = await _calculateAvailableIngredients(startDate, endDate);
    
    // Filtrer les ingrédients qui ont une quantité > 0
    final usableIngredients = availableIngredients.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    if (usableIngredients.isEmpty) {
      return [];
    }

    // Chercher des recettes basées sur les ingrédients disponibles
    final recipes = await _recipeService.searchRecipesByIngredients(usableIngredients);
    
    // Filtrer les recettes qui peuvent vraiment être faites
    final feasibleRecipes = recipes.where((recipe) {
      return _canMakeRecipe(recipe, availableIngredients);
    }).toList();

    if (feasibleRecipes.isEmpty) {
      return [];
    }

    // Générer un planning pour chaque jour
    final List<MealPlan> mealPlans = [];
    final usedRecipeIds = <String>{};
    
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      
      // Vérifier si un repas de ce type est déjà planifié pour ce jour
      final existingPlans = await _mealPlanService.getMealPlans();
      final hasMealOnDate = existingPlans.any((plan) {
        return plan.date.year == date.year &&
            plan.date.month == date.month &&
            plan.date.day == date.day &&
            plan.mealType == mealType;
      });

      if (!hasMealOnDate) {
        // Trouver une recette qui n'a pas encore été utilisée
        Recipe? selectedRecipe;
        for (var recipe in feasibleRecipes) {
          if (!usedRecipeIds.contains(recipe.id)) {
            // Recalculer les ingrédients disponibles jusqu'à cette date
            final ingredientsUpToDate = await _calculateAvailableIngredients(
              startDate,
              date,
            );
            
            if (_canMakeRecipe(recipe, ingredientsUpToDate)) {
              selectedRecipe = recipe;
              usedRecipeIds.add(recipe.id);
              break;
            }
          }
        }

        // Si aucune recette unique trouvée, prendre la première disponible
        if (selectedRecipe == null && feasibleRecipes.isNotEmpty) {
          final ingredientsUpToDate = await _calculateAvailableIngredients(
            startDate,
            date,
          );
          
          for (var recipe in feasibleRecipes) {
            if (_canMakeRecipe(recipe, ingredientsUpToDate)) {
              selectedRecipe = recipe;
              break;
            }
          }
        }

        if (selectedRecipe != null) {
          mealPlans.add(MealPlan(
            id: '${date.millisecondsSinceEpoch}_$mealType',
            date: date,
            mealType: mealType,
            recipe: selectedRecipe,
          ));
        }
      }
    }

    return mealPlans;
  }

  // Proposer une alternative à un repas refusé
  Future<Recipe?> suggestAlternative({
    required DateTime date,
    required String mealType,
    required Recipe rejectedRecipe,
  }) async {
    // Calculer les ingrédients disponibles pour cette date
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));
    final availableIngredients = await _calculateAvailableIngredients(startDate, endDate);
    
    // Filtrer les ingrédients disponibles
    final usableIngredients = availableIngredients.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    if (usableIngredients.isEmpty) {
      return null;
    }

    // Chercher des recettes alternatives
    final recipes = await _recipeService.searchRecipesByIngredients(usableIngredients);
    
    // Filtrer les recettes faisables et différentes de celle refusée
    final alternatives = recipes.where((recipe) {
      return recipe.id != rejectedRecipe.id &&
          _canMakeRecipe(recipe, availableIngredients);
    }).toList();

    return alternatives.isNotEmpty ? alternatives.first : null;
  }

  // Vérifier si un repas peut être ajouté sans dépasser les stocks
  Future<bool> canAddMeal(MealPlan mealPlan) async {
    final startDate = DateTime(
      mealPlan.date.year,
      mealPlan.date.month,
      mealPlan.date.day,
    );
    final endDate = startDate.add(const Duration(days: 1));
    final availableIngredients = await _calculateAvailableIngredients(startDate, endDate);
    
    return _canMakeRecipe(mealPlan.recipe, availableIngredients);
  }
}

