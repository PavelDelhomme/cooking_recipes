import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../services/meal_plan_service.dart';
import '../services/recipe_api_service.dart';
import '../services/pantry_service.dart';
import '../services/auto_meal_planner.dart';
import 'recipe_detail_screen.dart';
import 'recipes_screen.dart';
import 'meal_plan_config_screen.dart';

class MealPlanScreen extends StatefulWidget {
  final Recipe? recipe;
  final DateTime? initialDate;

  const MealPlanScreen({
    super.key,
    this.recipe,
    this.initialDate,
  });

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final MealPlanService _mealPlanService = MealPlanService();
  final RecipeApiService _recipeService = RecipeApiService();
  final PantryService _pantryService = PantryService();
  final AutoMealPlanner _autoPlanner = AutoMealPlanner();
  DateTime _selectedDate = DateTime.now();
  List<MealPlan> _mealPlans = [];
  bool _isLoading = true;
  String _viewMode = 'day'; // 'day' ou 'week'

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    _loadMealPlans();
    
    // Si une recette est fournie, proposer de l'ajouter
    if (widget.recipe != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddMealDialog(widget.recipe!);
      });
    }
  }

  Future<void> _loadMealPlans() async {
    setState(() => _isLoading = true);
    final plans = await _mealPlanService.getMealPlans();
    setState(() {
      _mealPlans = plans;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showAddMealDialog([Recipe? recipe, DateTime? date, String? mealType]) async {
    Recipe? selectedRecipe = recipe;
    String selectedMealType = mealType ?? 'dinner';
    DateTime selectedDate = date ?? _selectedDate;

    // Si aucune recette n'est fournie, ouvrir un dialogue pour en sélectionner une
    if (selectedRecipe == null) {
      final result = await showDialog<Recipe>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sélectionner une recette'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Rechercher une recette'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecipesScreen(),
                      ),
                    ).then((_) {
                      // Après retour, on peut réessayer d'ajouter
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: const Text('Recettes suggérées'),
                  onTap: () async {
                    if (!mounted) return;
                    Navigator.pop(context);
                    
                    try {
                      final pantryItems = await _pantryService.getPantryItems();
                      final ingredientNames = pantryItems.map((item) => item.name).toList();
                      List<Recipe> recipes;
                      if (ingredientNames.isEmpty) {
                        recipes = await _recipeService.getRandomRecipes(10);
                      } else {
                        recipes = await _recipeService.searchRecipesByIngredients(ingredientNames);
                      }
                      if (mounted && recipes.isNotEmpty) {
                        final recipe = await showDialog<Recipe>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Choisir une recette'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 400,
                              child: ListView.builder(
                                itemCount: recipes.length,
                                itemBuilder: (context, index) {
                                  final recipe = recipes[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: recipe.image != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                recipe.image!,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(Icons.restaurant);
                                                },
                                              ),
                                            )
                                          : const Icon(Icons.restaurant),
                                      title: Text(recipe.title),
                                      subtitle: recipe.summary != null && recipe.summary!.isNotEmpty
                                          ? Text(
                                              recipe.summary!.length > 50 
                                                  ? '${recipe.summary!.substring(0, 50)}...'
                                                  : recipe.summary!,
                                            )
                                          : null,
                                      onTap: () {
                                        if (mounted) {
                                          Navigator.pop(context, recipe);
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                        if (recipe != null && mounted) {
                          // Utiliser un délai pour s'assurer que le contexte est valide
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            _showAddMealDialog(recipe, selectedDate, selectedMealType);
                          }
                        }
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Aucune recette trouvée')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
      
      if (result != null) {
        selectedRecipe = result;
      } else {
        return;
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter au planning'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Type de repas:'),
                RadioListTile<String>(
                  title: const Text('Petit-déjeuner'),
                  value: 'breakfast',
                  groupValue: selectedMealType,
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Déjeuner'),
                  value: 'lunch',
                  groupValue: selectedMealType,
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Dîner'),
                  value: 'dinner',
                  groupValue: selectedMealType,
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Collation'),
                  value: 'snack',
                  groupValue: selectedMealType,
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedRecipe != null) {
      final mealPlan = MealPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: selectedDate,
        mealType: selectedMealType,
        recipe: selectedRecipe,
      );
      await _mealPlanService.addMealPlan(mealPlan);
      _loadMealPlans();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _showAutoPlanDialog() async {
    String selectedMealType = 'dinner';
    int days = 7;
    DateTime startDate = _selectedDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Planification automatique'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Générer un planning basé sur votre placard'),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date de début'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Nombre de jours:'),
                Slider(
                  value: days.toDouble(),
                  min: 1,
                  max: 14,
                  divisions: 13,
                  label: '$days jours',
                  onChanged: (value) {
                    setDialogState(() => days = value.toInt());
                  },
                ),
                const SizedBox(height: 8),
                const Text('Type de repas:'),
                RadioListTile<String>(
                  title: const Text('Petit-déjeuner'),
                  value: 'breakfast',
                  groupValue: selectedMealType,
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Déjeuner'),
                  value: 'lunch',
                  groupValue: selectedMealType,
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Dîner'),
                  value: 'dinner',
                  groupValue: selectedMealType,
                  onChanged: (value) {
                    setDialogState(() => selectedMealType = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Générer'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _generateAutoPlan(startDate, days, selectedMealType);
    }
  }

  Future<void> _generateAutoPlan(DateTime startDate, int days, String mealType) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final plans = await _autoPlanner.generateMealPlan(
        startDate: startDate,
        days: days,
        mealType: mealType,
      );

      if (mounted) {
        Navigator.pop(context); // Fermer le loading

        if (plans.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune recette trouvée avec les ingrédients disponibles'),
            ),
          );
        } else {
          // Ajouter les plans générés
          for (var plan in plans) {
            await _mealPlanService.addMealPlan(plan);
          }

          _loadMealPlans();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${plans.length} repas ajoutés au planning'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
          ),
        );
      }
    }
  }

  Future<void> _rejectAndSuggestAlternative(MealPlan mealPlan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remplacer ce repas?'),
        content: Text(
          'Voulez-vous remplacer "${mealPlan.recipe.title}" par une alternative basée sur votre placard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remplacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final alternative = await _autoPlanner.suggestAlternative(
          date: mealPlan.date,
          mealType: mealPlan.mealType,
          rejectedRecipe: mealPlan.recipe,
        );

        if (mounted) {
          Navigator.pop(context); // Fermer le loading

          if (alternative == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aucune alternative trouvée avec les ingrédients disponibles'),
              ),
            );
          } else {
            // Supprimer l'ancien plan et ajouter le nouveau
            await _mealPlanService.removeMealPlan(mealPlan.id);
            
            final newPlan = MealPlan(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              date: mealPlan.date,
              mealType: mealPlan.mealType,
              recipe: alternative,
            );
            
            await _mealPlanService.addMealPlan(newPlan);
            _loadMealPlans();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Remplacé par "${alternative.title}"'),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Fermer le loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteMealPlan(MealPlan mealPlan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text(
          'Voulez-vous supprimer ${mealPlan.recipe.title} du planning ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _mealPlanService.removeMealPlan(mealPlan.id);
      _loadMealPlans();
    }
  }

  String _getMealTypeLabel(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Petit-déjeuner';
      case 'lunch':
        return 'Déjeuner';
      case 'dinner':
        return 'Dîner';
      case 'snack':
        return 'Collation';
      default:
        return mealType;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  List<MealPlan> _getMealPlansForDate(DateTime date) {
    return _mealPlans.where((plan) {
      return plan.date.year == date.year &&
          plan.date.month == date.month &&
          plan.date.day == date.day;
    }).toList();
  }

  List<MealPlan> _getMealPlansForWeek(DateTime startDate) {
    final endDate = startDate.add(const Duration(days: 6));
    return _mealPlans.where((plan) {
      return plan.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          plan.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todayPlans = _getMealPlansForDate(_selectedDate);

    return Scaffold(
      // Pas d'AppBar ici car c'est géré par MainScreen
      body: Column(
        children: [
          // Barre d'actions personnalisée
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Planning de repas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'auto_plan') {
                      _showAutoPlanDialog();
                    } else if (value == 'refresh') {
                      _loadMealPlans();
                    } else if (value == 'config') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MealPlanConfigScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'auto_plan',
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome),
                          SizedBox(width: 8),
                          Text('Planification automatique'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'config',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Configuration'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Actualiser'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sélecteur de date
                Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      _selectedDate.day == DateTime.now().day &&
                              _selectedDate.month == DateTime.now().month &&
                              _selectedDate.year == DateTime.now().year
                          ? 'Aujourd\'hui'
                          : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                            });
                          },
                          tooltip: 'Jour précédent',
                        ),
                        IconButton(
                          icon: const Icon(Icons.today),
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                            });
                          },
                          tooltip: 'Aujourd\'hui',
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(const Duration(days: 1));
                            });
                          },
                          tooltip: 'Jour suivant',
                        ),
                      ],
                    ),
                    onTap: _selectDate,
                  ),
                ),
                
                // Options de vue
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Jour'),
                          selected: _viewMode == 'day',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _viewMode = 'day');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Semaine'),
                          selected: _viewMode == 'week',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _viewMode = 'week');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Liste des repas selon la vue
                Expanded(
                  child: _viewMode == 'day' ? _buildDayView(todayPlans) : _buildWeekView(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un repas'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildDayView(List<MealPlan> plans) {
    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun repas planifié',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ajoutez une recette au planning',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: plans.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final mealPlan = plans[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getMealTypeIcon(mealPlan.mealType),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              mealPlan.recipe.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getMealTypeLabel(mealPlan.mealType),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer,
                  ),
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () => _rejectAndSuggestAlternative(mealPlan),
                  tooltip: 'Remplacer',
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _deleteMealPlan(mealPlan),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(
                    recipe: mealPlan.recipe,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWeekView() {
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays = List.generate(7, (index) => weekStart.add(Duration(days: index)));
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final day = weekDays[index];
        final dayPlans = _getMealPlansForDate(day);
        final isToday = day.day == DateTime.now().day &&
            day.month == DateTime.now().month &&
            day.year == DateTime.now().year;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isToday
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
              : null,
          child: ExpansionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  DateFormat('d', 'fr_FR').format(day),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            title: Text(
              DateFormat('EEEE', 'fr_FR').format(day),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              DateFormat('dd MMMM yyyy', 'fr_FR').format(day),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text('${dayPlans.length}'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => _showAddMealDialog(null, day, null),
                  tooltip: 'Ajouter un repas',
                ),
              ],
            ),
            children: dayPlans.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Aucun repas planifié',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ]
                : dayPlans.map((mealPlan) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            _getMealTypeIcon(mealPlan.mealType),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            mealPlan.recipe.title,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            _getMealTypeLabel(mealPlan.mealType),
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                onPressed: () => _rejectAndSuggestAlternative(mealPlan),
                                tooltip: 'Remplacer',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () => _deleteMealPlan(mealPlan),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(
                                  recipe: mealPlan.recipe,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
          ),
        );
      },
    );
  }
}

