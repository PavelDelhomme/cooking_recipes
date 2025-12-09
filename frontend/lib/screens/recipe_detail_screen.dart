import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';
import '../services/pantry_service.dart';
import '../services/shopping_list_service.dart';
import '../services/profile_service.dart';
import '../services/meal_plan_service.dart';
import '../services/theme_service.dart';
import '../services/app_localizations.dart';
import '../services/translation_service.dart';
import '../services/favorite_service.dart';
import '../services/ingredient_image_service.dart';
import '../services/recipe_history_service.dart';
import '../widgets/locale_notifier.dart';
import '../widgets/translation_builder.dart';
import '../widgets/translation_feedback_widget.dart';
import '../models/pantry_item.dart';
import '../models/shopping_list_item.dart';
import '../models/user_profile.dart';
import '../models/meal_plan.dart';
import '../models/translation_feedback.dart';
import '../main.dart' show ThemeNotifier;

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
  final ThemeService _themeService = ThemeService();
  final FavoriteService _favoriteService = FavoriteService();
  final IngredientImageService _imageService = IngredientImageService();
  List<PantryItem> _pantryItems = [];
  UserProfile? _currentProfile;
  bool _isDarkMode = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  final Map<String, String?> _ingredientImages = {};

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
    _loadProfile();
    _loadTheme();
    _checkFavorite();
    _loadIngredientImages();
    // Ajouter à l'historique
    RecipeHistoryService.addToHistory(widget.recipe);
  }

  Future<void> _loadIngredientImages() async {
    final Map<String, String?> images = {};
    for (var ingredient in widget.recipe.ingredients) {
      if (!_ingredientImages.containsKey(ingredient.name)) {
        final imageUrl = await _imageService.getImageFromMealDB(
          ingredient.name,
          originalName: ingredient.originalName,
        );
        images[ingredient.name] = imageUrl;
      }
    }
    if (mounted) {
      setState(() {
        _ingredientImages.addAll(images);
      });
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final isFav = await _favoriteService.isFavorite(widget.recipe.id);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    } catch (e) {
      print('Erreur vérification favori: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;
    
    setState(() => _isLoadingFavorite = true);
    
    try {
      final success = await _favoriteService.toggleFavorite(widget.recipe);
      if (success && mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoadingFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Recette ajoutée aux favoris' : 'Recette retirée des favoris'),
            duration: const Duration(seconds: 2),
          ),
        );
        // Notifier que les favoris ont changé (pour recharger la liste)
        if (_isFavorite) {
          // Optionnel : utiliser un callback ou un service pour notifier
        }
      } else {
        setState(() => _isLoadingFavorite = false);
      }
    } catch (e) {
      setState(() => _isLoadingFavorite = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadTheme() async {
    final isDark = await _themeService.isDarkMode();
    if (mounted) {
      setState(() => _isDarkMode = isDark);
    }
  }

  Future<void> _toggleTheme() async {
    final newValue = !_isDarkMode;
    await _themeService.setDarkMode(newValue);
    if (mounted) {
      setState(() => _isDarkMode = newValue);
      
      // Utiliser l'InheritedWidget pour notifier le parent
      // Le thème sera appliqué automatiquement via themeMode, pas besoin de recharger
      final themeNotifier = ThemeNotifier.of(context);
      if (themeNotifier != null) {
        themeNotifier.toggleTheme();
        // Le thème est maintenant appliqué, pas besoin de recharger la page
        // Le MaterialApp se met à jour automatiquement grâce à themeMode
      }
    }
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

  void _showTranslationFeedback(
    FeedbackType type,
    String originalText,
    String currentTranslation, {
    String? contextInfo,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => TranslationFeedbackWidget(
        recipeId: widget.recipe.id,
        recipeTitle: widget.recipe.title,
        type: type,
        originalText: originalText,
        currentTranslation: currentTranslation,
        context: contextInfo,
      ),
    );
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
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Retour',
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: _isLoadingFavorite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                  tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  onPressed: _toggleFavorite,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  tooltip: _isDarkMode ? 'Mode clair' : 'Mode sombre',
                  onPressed: _toggleTheme,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                children: [
                  Expanded(
                    child: TranslationBuilder(
                      builder: (context) {
                        return Text(
                          TranslationService.translateRecipeNameSync(widget.recipe.title),
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
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.translate, color: Colors.white, size: 20),
                    tooltip: 'Améliorer la traduction du nom',
                    onPressed: () => _showTranslationFeedback(
                      FeedbackType.recipeName,
                      widget.recipe.title,
                      TranslationService.translateRecipeNameSync(widget.recipe.title),
                    ),
                  ),
                ],
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
                            if (widget.recipe.prepTimeMinutes != null)
                              _buildInfoChip(
                                Icons.restaurant_outlined,
                                'Préparation: ${widget.recipe.prepTimeMinutes} min',
                              ),
                            if (widget.recipe.cookTimeMinutes != null)
                              _buildInfoChip(
                                Icons.local_fire_department_outlined,
                                'Cuisson: ${widget.recipe.cookTimeMinutes} min',
                              ),
                            if (widget.recipe.readyInMinutes != null)
                              _buildInfoChip(
                                Icons.timer_outlined,
                                'Total: ${widget.recipe.readyInMinutes} min',
                              ),
                      if (widget.recipe.servings != null)
                        Builder(
                          builder: (context) {
                            // Écouter les changements de locale
                            LocaleNotifier.of(context);
                            final portionsText = TranslationService.currentLanguageStatic == 'fr' 
                                ? 'portions' 
                                : TranslationService.currentLanguageStatic == 'es'
                                    ? 'porciones'
                                    : 'servings';
                            final personnesText = TranslationService.currentLanguageStatic == 'fr' 
                                ? 'personnes' 
                                : TranslationService.currentLanguageStatic == 'es'
                                    ? 'personas'
                                    : 'people';
                            final originalesText = TranslationService.currentLanguageStatic == 'fr' 
                                ? 'originales' 
                                : TranslationService.currentLanguageStatic == 'es'
                                    ? 'originales'
                                    : 'original';
                            return _buildInfoChip(
                              Icons.people_outline,
                              _currentProfile != null
                                  ? '${_currentProfile!.numberOfPeople} $personnesText (${widget.recipe.servings} $portionsText $originalesText)'
                                  : '${widget.recipe.servings} $portionsText',
                            );
                          },
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
                      Text(
                        AppLocalizations.of(context)?.ingredients ?? 'Ingrédients',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _addMissingIngredientsToShoppingList,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text(AppLocalizations.of(context)?.addMissingIngredients ?? 'Ajouter manquants'),
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
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: hasIngredient
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _ingredientImages[ingredient.name] != null
                                    ? Image.network(
                                        _ingredientImages[ingredient.name]!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            hasIngredient
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: hasIngredient
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.onSurfaceVariant,
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      )
                                    : Icon(
                                        hasIngredient
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: hasIngredient
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  // Écouter les changements de locale
                                  LocaleNotifier.of(context);
                                  return Text(
                                    TranslationService.translateIngredientSync(ingredient.name),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.translate,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              tooltip: 'Améliorer la traduction',
                              onPressed: () => _showTranslationFeedback(
                                FeedbackType.ingredient,
                                ingredient.name,
                                TranslationService.translateIngredientSync(ingredient.name),
                                context: 'Ingrédient ${widget.recipe.ingredients.indexOf(ingredient) + 1}',
                              ),
                            ),
                          ],
                        ),
                        subtitle: ingredient.quantity != null || ingredient.preparation != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (ingredient.quantity != null)
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
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${_getAdjustedQuantity(ingredient.quantity, widget.recipe.servings).toStringAsFixed(ingredient.quantity! % 1 == 0 ? 0 : 1)} ${ingredient.unit != null ? TranslationService.translateUnit(ingredient.unit!) : ''}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                              ),
                                            ),
                                            if (ingredient.preparation != null && ingredient.preparation!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiaryContainer
                                                      .withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  TranslationService.translatePreparation(ingredient.preparation!),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      )
                                    else if (ingredient.preparation != null && ingredient.preparation!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer
                                              .withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          TranslationService.translatePreparation(ingredient.preparation!),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onTertiaryContainer,
                                          ),
                                        ),
                                      ),
                                    if (_currentProfile != null && widget.recipe.servings != null && _currentProfile!.numberOfPeople != widget.recipe.servings)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Builder(
                                          builder: (context) {
                                            // Écouter les changements de locale
                                            LocaleNotifier.of(context);
                                            final originalText = TranslationService.currentLanguageStatic == 'fr' 
                                                ? 'Original' 
                                                : TranslationService.currentLanguageStatic == 'es'
                                                    ? 'Original'
                                                    : 'Original';
                                            final portionsText = TranslationService.currentLanguageStatic == 'fr' 
                                                ? 'portions' 
                                                : TranslationService.currentLanguageStatic == 'es'
                                                    ? 'porciones'
                                                    : 'servings';
                                            return Text(
                                              '$originalText: ${ingredient.quantity} ${ingredient.unit != null ? TranslationService.translateUnit(ingredient.unit!) : ''} (${widget.recipe.servings} $portionsText)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.7),
                                              ),
                                            );
                                          },
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
                  Text(
                    AppLocalizations.of(context)?.instructions ?? 'Instructions',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.recipe.instructions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Aucune instruction disponible',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    TranslationBuilder(
                      builder: (context) {
                        // Retraduire les instructions depuis le texte original si disponible
                        List<String> translatedInstructions;
                        if (widget.recipe.originalInstructionsText != null && 
                            widget.recipe.originalInstructionsText!.isNotEmpty) {
                          // Nettoyer et retraduire le texte original
                          String instructionsText = widget.recipe.originalInstructionsText!;
                          instructionsText = instructionsText.replaceAll(RegExp(r'step\s+\d+[:\s]*', caseSensitive: false), '');
                          instructionsText = instructionsText.replaceAll(RegExp(r'Step\s+\d+[:\s]*', caseSensitive: false), '');
                          instructionsText = instructionsText.replaceAll(RegExp(r'STEP\s+\d+[:\s]*', caseSensitive: false), '');
                          instructionsText = TranslationService.cleanAndTranslate(instructionsText);
                          
                          // Diviser en lignes
                          translatedInstructions = instructionsText
                              .split(RegExp(r'\n|\r\n|(?<=\d)\.\s+|(?<=[.!?])\s+(?=[A-Z])|(?<=[.!?])\s+(?=\d+\.)'))
                              .where((line) => line.trim().isNotEmpty)
                              .map((line) {
                                String cleaned = line.trim();
                                cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s*'), '');
                                cleaned = cleaned.replaceAll(RegExp(r'^step\s+\d+[:\s]*', caseSensitive: false), '');
                                cleaned = cleaned.replaceAll(RegExp(r'^Step\s+\d+[:\s]*', caseSensitive: false), '');
                                cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
                                return cleaned;
                              })
                              .where((line) => line.trim().isNotEmpty && line.trim().length > 5)
                              .toList();
                        } else {
                          // Fallback : utiliser les instructions déjà traduites
                          translatedInstructions = widget.recipe.instructions;
                        }
                        
                        return Column(
                          children: translatedInstructions.asMap().entries.map((entry) {
                            String instructionText = entry.value.trim();
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        instructionText,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.6,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.translate,
                                        size: 18,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      tooltip: 'Améliorer la traduction',
                                      onPressed: () {
                                        // Récupérer le texte original de l'instruction
                                        String originalInstruction = '';
                                        if (widget.recipe.originalInstructionsText != null) {
                                          final originalInstructions = widget.recipe.originalInstructionsText!
                                              .split(RegExp(r'\n|\r\n|(?<=\d)\.\s+|(?<=[.!?])\s+(?=[A-Z])'))
                                              .where((line) => line.trim().isNotEmpty)
                                              .toList();
                                          if (entry.key < originalInstructions.length) {
                                            originalInstruction = originalInstructions[entry.key].trim();
                                          }
                                        }
                                        // Fallback sur l'instruction traduite si pas d'original
                                        if (originalInstruction.isEmpty) {
                                          originalInstruction = instructionText;
                                        }
                                        
                                        _showTranslationFeedback(
                                          FeedbackType.instruction,
                                          originalInstruction,
                                          instructionText,
                                          context: 'Instruction ${entry.key + 1}',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  
                  // Résumé/Description
                  if (widget.recipe.summary != null &&
                      widget.recipe.summary!.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)?.description ?? 'Description',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TranslationBuilder(
                      builder: (context) {
                        // Retraduire le summary depuis le texte original si disponible
                        String translatedSummary;
                        if (widget.recipe.originalSummaryText != null && 
                            widget.recipe.originalSummaryText!.isNotEmpty) {
                          String summary = widget.recipe.originalSummaryText!;
                          summary = summary.replaceAll(RegExp(r'step\s+\d+[:\s]*', caseSensitive: false), '');
                          summary = summary.replaceAll(RegExp(r'Step\s+\d+[:\s]*', caseSensitive: false), '');
                          summary = TranslationService.cleanAndTranslate(summary);
                          
                          // Prendre la première phrase ou les 200 premiers caractères
                          final firstSentence = summary.split(RegExp(r'[.!?]')).first.trim();
                          if (firstSentence.length > 20) {
                            translatedSummary = firstSentence;
                          } else {
                            translatedSummary = summary.length > 200 ? summary.substring(0, 200) + '...' : summary;
                          }
                        } else {
                          // Fallback : utiliser le summary déjà traduit
                          translatedSummary = widget.recipe.summary!;
                        }
                        
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              translatedSummary,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
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
        heroTag: "recipe_detail_fab",
        onPressed: _addToMealPlan,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(
          AppLocalizations.of(context)?.addToMealPlan ?? 'Ajouter au planning',
          style: const TextStyle(fontWeight: FontWeight.bold),
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

