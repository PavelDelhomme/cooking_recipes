import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_api_service.dart';
import '../services/pantry_service.dart';
import '../services/translation_service.dart';
import '../widgets/locale_notifier.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final RecipeApiService _recipeService = RecipeApiService();
  final PantryService _pantryService = PantryService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Recipe> _recipes = [];
  List<Recipe> _suggestedRecipes = [];
  bool _isLoading = false;
  bool _isLoadingSuggestions = false;
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<String> _searchSuggestions = [];
  bool _isLoadingSearchSuggestions = false;
  bool _suggestionsLoaded = false; // Flag pour savoir si les suggestions ont été chargées

  @override
  void initState() {
    super.initState();
    // Charger les suggestions seulement au premier démarrage
    if (!_suggestionsLoaded) {
      _loadSuggestedRecipes();
      _suggestionsLoaded = true;
    }
    // Écouter les changements dans le champ de recherche pour l'autocomplétion
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Annuler le timer précédent
    _debounceTimer?.cancel();
    
    // Si le champ est vide, réinitialiser
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _recipes = [];
        _searchQuery = '';
        _searchSuggestions = [];
      });
      return;
    }

    // Charger les suggestions d'autocomplétion
    _loadSearchSuggestions(_searchController.text.trim());

    // Attendre 500ms après la dernière frappe avant de rechercher
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        _searchRecipes();
      }
    });
  }

  Future<void> _loadSearchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }

    setState(() {
      _isLoadingSearchSuggestions = true;
    });

    try {
      final suggestions = await _recipeService.getSearchSuggestions(query);
      if (mounted) {
        setState(() {
          _searchSuggestions = suggestions;
          _isLoadingSearchSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchSuggestions = [];
          _isLoadingSearchSuggestions = false;
        });
      }
    }
  }

  Future<void> _loadSuggestedRecipes({bool force = false}) async {
    // Ne pas recharger si déjà chargé et pas de force
    if (_suggestionsLoaded && !force) {
      return;
    }
    
    setState(() => _isLoadingSuggestions = true);
    
    // Récupérer les ingrédients du placard
    final pantryItems = await _pantryService.getPantryItems();
    final ingredientNames = pantryItems.map((item) => item.name).toList();
    
    if (ingredientNames.isNotEmpty) {
      // Chercher des recettes basées sur les ingrédients disponibles
      final recipes = await _recipeService.searchRecipesByIngredients(ingredientNames);
      setState(() {
        _suggestedRecipes = recipes.take(10).toList();
        _isLoadingSuggestions = false;
        _suggestionsLoaded = true;
      });
    } else {
      // Si le placard est vide, charger des recettes populaires et variées
      // Essayer plusieurs catégories pour avoir des suggestions intéressantes
      final List<Recipe> allRecipes = [];
      
      // Recettes aléatoires
      final randomRecipes = await _recipeService.getRandomRecipes(5);
      allRecipes.addAll(randomRecipes);
      
      // Recettes populaires (chercher des termes génériques)
      final popularTerms = ['chicken', 'pasta', 'salad', 'soup', 'dessert'];
      for (var term in popularTerms) {
        try {
          final recipes = await _recipeService.searchRecipes(term);
          if (recipes.isNotEmpty) {
            allRecipes.add(recipes.first);
          }
        } catch (e) {
          // Ignorer les erreurs pour les termes qui ne donnent pas de résultats
        }
      }
      
      // Éliminer les doublons
      final uniqueRecipes = <String, Recipe>{};
      for (var recipe in allRecipes) {
        uniqueRecipes[recipe.id] = recipe;
      }
      
      setState(() {
        _suggestedRecipes = uniqueRecipes.values.take(10).toList();
        _isLoadingSuggestions = false;
        _suggestionsLoaded = true;
      });
    }
  }

  Future<void> _searchRecipes() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _recipes = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = _searchController.text.trim();
    });

    final recipes = await _recipeService.searchRecipes(_searchQuery);
    
    setState(() {
      _recipes = recipes;
      _isLoading = false;
    });
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Recettes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadSuggestedRecipes(force: true),
                  tooltip: 'Actualiser les suggestions',
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: _searchController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        // Retourner des suggestions populaires par défaut
                        return [
                          'chicken', 'pasta', 'salad', 'soup', 'dessert',
                          'beef', 'fish', 'rice', 'pizza', 'cake'
                        ];
                      }
                      
                      // Charger les suggestions depuis l'API
                      await _loadSearchSuggestions(textEditingValue.text);
                      return _searchSuggestions;
                    },
                    onSelected: (String selection) {
                      _searchController.text = selection;
                      _searchRecipes();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      // Synchroniser le controller avec _searchController
                      if (controller.text != _searchController.text) {
                        controller.text = _searchController.text;
                      }
                      _searchController.addListener(() {
                        if (controller.text != _searchController.text) {
                          controller.text = _searchController.text;
                        }
                      });
                      controller.addListener(() {
                        if (_searchController.text != controller.text) {
                          _searchController.text = controller.text;
                          _onSearchChanged();
                        }
                      });
                      
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Rechercher une recette',
                          hintText: 'Tapez pour rechercher automatiquement...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchRecipes,
                            tooltip: 'Rechercher',
                          ),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, child) {
                              if (value.text.isNotEmpty) {
                                return IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.clear();
                                    setState(() {
                                      _recipes = [];
                                      _searchQuery = '';
                                      _searchSuggestions = [];
                                    });
                                  },
                                  tooltip: 'Effacer',
                                );
                              }
                          return IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => _loadSuggestedRecipes(force: true),
                            tooltip: 'Actualiser les suggestions',
                          );
                            },
                          ),
                        ),
                        onSubmitted: (_) => _searchRecipes(),
                        textInputAction: TextInputAction.search,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.restaurant_menu, size: 20),
                                  title: Text(option),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _searchQuery.isNotEmpty
                      ? _buildSearchResults()
                      : _buildSuggestedRecipes(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

      if (_recipes.isEmpty) {
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
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucune recette trouvée',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Essayez avec d\'autres mots-clés',
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
      itemCount: _recipes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return _buildRecipeCard(recipe);
      },
    );
  }

  Widget _buildSuggestedRecipes() {
    if (_isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        FutureBuilder<List<String>>(
          future: _pantryService.getPantryItems().then((items) => items.map((item) => item.name).toList()),
          builder: (context, snapshot) {
            final hasItems = snapshot.hasData && snapshot.data!.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasItems
                        ? 'Suggestions basées sur votre placard'
                        : 'Recettes suggérées',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                      if (!hasItems)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Votre placard est vide. Nous vous proposons des recettes populaires. Ajoutez des ingrédients à votre placard pour recevoir des suggestions personnalisées basées sur ce que vous avez !',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
        if (_suggestedRecipes.isEmpty)
          Center(
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
                      Icons.restaurant_menu,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucune suggestion disponible',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ajoutez des ingrédients à votre placard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._suggestedRecipes.map((recipe) => _buildRecipeCard(recipe)),
      ],
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToRecipeDetail(recipe),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.image != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.network(
                  recipe.image!,
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 140,
                      height: 140,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.restaurant,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        // Écouter les changements de locale
                        LocaleNotifier.of(context);
                        return Text(
                          TranslationService.translateRecipeName(recipe.title),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (recipe.readyInMinutes != null)
                          _buildInfoChip(
                            Icons.timer_outlined,
                            '${recipe.readyInMinutes} min',
                            context,
                          ),
                        if (recipe.servings != null)
                          Builder(
                            builder: (context) {
                              // Écouter les changements de locale
                              LocaleNotifier.of(context);
                              final portionsText = TranslationService.currentLanguageStatic == 'fr' 
                                  ? 'portions' 
                                  : TranslationService.currentLanguageStatic == 'es'
                                      ? 'porciones'
                                      : 'servings';
                              return _buildInfoChip(
                                Icons.people_outline,
                                '${recipe.servings} $portionsText',
                                context,
                              );
                            },
                          ),
                        if (recipe.ingredients.isNotEmpty)
                          _buildInfoChip(
                            Icons.shopping_basket_outlined,
                            '${recipe.ingredients.length} ingrédients',
                            context,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

