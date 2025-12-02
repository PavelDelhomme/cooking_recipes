import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';
import '../services/pantry_service.dart';
import '../services/shopping_list_service.dart';
import '../services/profile_service.dart';
import '../services/meal_plan_service.dart';
import '../models/pantry_item.dart';
import '../models/shopping_list_item.dart';
import '../models/user_profile.dart';
import '../models/meal_plan.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final PantryService _pantryService = PantryService();
  final ShoppingListService _shoppingListService = ShoppingListService();
  final ProfileService _profileService = ProfileService();
  List<PantryItem> _pantryItems = [];
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
    _loadProfile();
  }

  Future<void> _loadPantryItems() async {
    final items = await _pantryService.getPantryItems();
    setState(() => _pantryItems = items);
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getCurrentProfile();
    setState(() => _currentProfile = profile);
  }

  // Calculer la quantité adaptée selon le profil
  double _getAdjustedQuantity(double? originalQuantity, int? originalServings) {
    if (originalQuantity == null) return 1.0;
    if (_currentProfile == null) return originalQuantity;
    
    final originalServingsCount = originalServings ?? 4; // Par défaut 4 personnes
    final multiplier = _currentProfile!.numberOfPeople / originalServingsCount;
    
    return (originalQuantity * multiplier);
  }

  bool _hasIngredient(String ingredientName) {
    return _pantryItems.any((item) =>
        item.name.toLowerCase().contains(ingredientName.toLowerCase()) ||
        ingredientName.toLowerCase().contains(item.name.toLowerCase()));
  }

  Future<void> _addToMealPlan() async {
    DateTime? selectedDate = DateTime.now();
    String selectedMealType = 'lunch';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter au planning'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection de la date
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(selectedDate!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate!,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const Divider(),
                // Sélection du type de repas
                ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: const Text('Type de repas'),
                  subtitle: DropdownButton<String>(
                    value: selectedMealType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'breakfast',
                        child: Text('Petit-déjeuner'),
                      ),
                      DropdownMenuItem(
                        value: 'lunch',
                        child: Text('Déjeuner'),
                      ),
                      DropdownMenuItem(
                        value: 'dinner',
                        child: Text('Dîner'),
                      ),
                      DropdownMenuItem(
                        value: 'snack',
                        child: Text('Collation'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedMealType = value);
                      }
                    },
                  ),
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
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedDate != null) {
      final mealPlanService = MealPlanService();
      final mealPlan = MealPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: selectedDate!,
        mealType: selectedMealType,
        recipe: widget.recipe,
      );

      await mealPlanService.addMealPlan(mealPlan);

      if (mounted && selectedDate != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recette ajoutée au planning pour le ${DateFormat('dd/MM/yyyy', 'fr_FR').format(selectedDate!)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _addMissingIngredientsToShoppingList() async {
    final missingIngredients = widget.recipe.ingredients
        .where((ingredient) => !_hasIngredient(ingredient.name))
        .toList();

    if (missingIngredients.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez tous les ingrédients nécessaires !'),
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter à la liste de courses'),
        content: Text(
          'Ajouter ${missingIngredients.length} ingrédient(s) manquant(s) à votre liste de courses ?',
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
    );

    if (confirmed == true) {
      final shoppingItems = missingIngredients.map((ingredient) {
        final adjustedQuantity = _getAdjustedQuantity(
          ingredient.quantity,
          widget.recipe.servings,
        );
        return ShoppingListItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              '_${ingredient.id}',
          name: ingredient.name,
          quantity: adjustedQuantity,
          unit: ingredient.unit,
          addedDate: DateTime.now(),
        );
      }).toList();

      await _shoppingListService.addShoppingListItems(shoppingItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${missingIngredients.length} ingrédient(s) ajouté(s) à la liste de courses',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: widget.recipe.image != null
                  ? Image.network(
                      widget.recipe.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 64),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 64),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations générales
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (widget.recipe.readyInMinutes != null)
                        _buildInfoChip(
                          Icons.timer_outlined,
                          '${widget.recipe.readyInMinutes} min',
                        ),
                      if (widget.recipe.servings != null)
                        _buildInfoChip(
                          Icons.people_outline,
                          _currentProfile != null
                              ? '${_currentProfile!.numberOfPeople} personnes (${widget.recipe.servings} portions originales)'
                              : '${widget.recipe.servings} portions',
                        ),
                      if (widget.recipe.ingredients.isNotEmpty)
                        _buildInfoChip(
                          Icons.shopping_basket_outlined,
                          '${widget.recipe.ingredients.length} ingrédients',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Ingrédients
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ingrédients',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _addMissingIngredientsToShoppingList,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Ajouter manquants'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.recipe.ingredients.map((ingredient) {
                    final hasIngredient = _hasIngredient(ingredient.name);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: hasIngredient
                          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                          : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: hasIngredient
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            hasIngredient
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: hasIngredient
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          ingredient.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: ingredient.quantity != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
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
                                        '${_getAdjustedQuantity(ingredient.quantity, widget.recipe.servings).toStringAsFixed(ingredient.quantity! % 1 == 0 ? 0 : 1)} ${ingredient.unit ?? ''}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    if (_currentProfile != null && widget.recipe.servings != null && _currentProfile!.numberOfPeople != widget.recipe.servings)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Original: ${ingredient.quantity} ${ingredient.unit ?? ''} (${widget.recipe.servings} portions)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  
                  // Instructions
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.recipe.instructions.isEmpty)
                    const Text('Aucune instruction disponible')
                  else
                    ...widget.recipe.instructions.asMap().entries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  
                  // Résumé
                  if (widget.recipe.summary != null &&
                      widget.recipe.summary!.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.recipe.summary!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addToMealPlan,
        icon: const Icon(Icons.calendar_today_outlined),
        label: const Text(
          'Ajouter au planning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

