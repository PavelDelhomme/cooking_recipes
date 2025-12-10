import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/recipe_api_service.dart';
import '../services/pantry_service.dart';
import '../services/translation_service.dart';
import '../widgets/locale_notifier.dart';
import '../widgets/translation_builder.dart';
import '../widgets/recipe_filters.dart';
import '../widgets/styled_header.dart';
import 'recipe_detail_screen.dart';
import 'recipe_card_variants.dart';

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
  List<Recipe> _filteredRecipes = []; // Recettes filtrées
  List<Recipe> _suggestedRecipes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false; // Pour le scroll infini
  bool _hasMoreRecipes = true; // Indique s'il y a plus de recettes à charger
  bool _isLoadingSuggestions = false;
  bool _isLoadingMoreSuggestions = false; // Pour le scroll infini des suggestions
  bool _hasMoreSuggestions = true; // Indique s'il y a plus de suggestions à charger
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<String> _searchSuggestions = [];
  bool _isLoadingSearchSuggestions = false;
  bool _suggestionsLoaded = false; // Flag pour savoir si les suggestions ont été chargées
  int _cardVariant = 6; // Variante de carte actuelle (fixée à 6 - Détaillée)
  static const String _cardVariantKey = 'recipe_card_variant';
  final ScrollController _scrollController = ScrollController();
  final ScrollController _suggestionsScrollController = ScrollController(); // ScrollController pour les suggestions
  int _currentPage = 0;
  int _currentSuggestionsPage = 0; // Page actuelle pour les suggestions
  static const int _recipesPerPage = 10; // Nombre de recettes par page
  static const int _suggestionsPerPage = 3; // Nombre de suggestions par page (réduit pour accélérer le chargement initial)
  Set<String> _suggestedRecipeIds = {}; // Cache des IDs de recettes déjà suggérées pour éviter les doublons
  DateTime? _lastSuggestionsLoadTime; // Pour throttling
  static const Duration _suggestionsThrottleDuration = Duration(milliseconds: 800); // Délai minimum entre les chargements (réduit pour un scroll plus fluide)
  List<String> _allSuggestedRecipeIds = []; // Tous les IDs de recettes disponibles (pour pagination)
  int _suggestedRecipesOffset = 0; // Offset pour la pagination des suggestions
  Timer? _scrollDebounceTimer; // Timer pour debounce le scroll

  @override
  void initState() {
    super.initState();
    // Variante fixée à 6 (Détaillée) - plus de chargement nécessaire
    // _loadCardVariant(); // Désactivé
    // Écouter les changements dans le champ de recherche pour l'autocomplétion
    _searchController.addListener(_onSearchChanged);
    // Écouter le scroll pour le chargement infini
    _scrollController.addListener(_onScroll);
    // Écouter le scroll pour les suggestions
    _suggestionsScrollController.addListener(_onSuggestionsScroll);
    // Charger les recettes suggérées au démarrage
    _loadSuggestedRecipes();
  }

  void _onScroll() {
    // Vérifier si on peut scroller (éviter les erreurs si pas encore initialisé)
    if (!_scrollController.hasClients) return;
    
    // Charger plus de recettes quand on approche de la fin (200px avant la fin)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll >= maxScroll - 200) {
      if (!_isLoadingMore && _hasMoreRecipes && _searchQuery.isNotEmpty && !_isLoading) {
        _loadMoreRecipes();
      }
    }
  }

  void _onSuggestionsScroll() {
    // Vérifier si on peut scroller (éviter les erreurs si pas encore initialisé)
    if (!_suggestionsScrollController.hasClients) return;
    
    // Ne pas charger si on est en train de rechercher
    if (_searchQuery.isNotEmpty) return;
    
    // Annuler le timer précédent si l'utilisateur scroll encore
    _scrollDebounceTimer?.cancel();
    
    // Débouncer le scroll : attendre 300ms après le dernier mouvement de scroll
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _checkAndLoadMoreSuggestions();
    });
  }
  
  void _checkAndLoadMoreSuggestions() {
    if (!_suggestionsScrollController.hasClients) return;
    if (_searchQuery.isNotEmpty) return;
    
    final position = _suggestionsScrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    
    // Charger plus de suggestions quand on approche de la fin (600px avant la fin pour déclencher plus tôt)
    if (maxScroll > 0 && currentScroll >= maxScroll - 600) {
      // Throttling : ne pas charger trop souvent
      final now = DateTime.now();
      if (_lastSuggestionsLoadTime != null && 
          now.difference(_lastSuggestionsLoadTime!) < _suggestionsThrottleDuration) {
        return;
      }
      
      if (!_isLoadingMoreSuggestions && _hasMoreSuggestions && !_isLoadingSuggestions) {
        _loadMoreSuggestions();
      }
    }
  }

  Future<void> _loadCardVariant() async {
    // Variante fixée à 6 (Détaillée) - plus de chargement nécessaire
    // Gardé pour compatibilité mais toujours 6
  }

  Future<void> _saveCardVariant(int variant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cardVariantKey, variant);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _suggestionsScrollController.removeListener(_onSuggestionsScroll);
    _scrollController.dispose();
    _suggestionsScrollController.dispose();
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
        _filteredRecipes = []; // Réinitialiser les filtres
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
    
    setState(() {
      _isLoadingSuggestions = true;
      _suggestedRecipes = [];
      _suggestedRecipeIds.clear();
      _allSuggestedRecipeIds.clear();
      _currentSuggestionsPage = 0;
      _suggestedRecipesOffset = 0;
      _hasMoreSuggestions = true;
    });
    
    // Charger la première page
    await _loadMoreSuggestions();
    
    setState(() {
      _isLoadingSuggestions = false;
      _suggestionsLoaded = true;
      _lastSuggestionsLoadTime = DateTime.now();
    });
  }

  Future<void> _loadMoreSuggestions() async {
    if (_isLoadingMoreSuggestions || !_hasMoreSuggestions) {
      return;
    }

    // Throttling : ne pas charger trop souvent
    final now = DateTime.now();
    if (_lastSuggestionsLoadTime != null && 
        now.difference(_lastSuggestionsLoadTime!) < _suggestionsThrottleDuration) {
      return;
    }

    setState(() {
      _isLoadingMoreSuggestions = true;
      _lastSuggestionsLoadTime = now;
    });

    try {
      // Récupérer les ingrédients du placard
      final pantryItems = await _pantryService.getPantryItems();
      final ingredientNames = pantryItems.map((item) => item.name).toList();
      
      List<Recipe> newRecipes = [];
      
      if (ingredientNames.isNotEmpty) {
        // Si c'est la première page, charger toutes les IDs disponibles
        if (_currentSuggestionsPage == 0) {
          // Charger plus d'IDs pour avoir de la pagination
          Map<String, int> recipeCounts = {};
          
          // Paralléliser les appels pour chaque ingrédient pour accélérer le chargement
          final List<Future<List<String>>> idFutures = ingredientNames.map(
            (ingredient) => _recipeService.searchRecipeIdsByIngredient(ingredient)
          ).toList();
          
          final List<List<String>> allIds = await Future.wait(idFutures);
          
          // Compter les occurrences de chaque ID
          for (var ids in allIds) {
            for (var id in ids) {
              recipeCounts[id] = (recipeCounts[id] ?? 0) + 1;
            }
          }
          
          // Trier par nombre d'ingrédients correspondants
          final sortedIds = recipeCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          // Limiter à 100 IDs pour permettre plus de pagination, mais éviter trop d'appels API
          _allSuggestedRecipeIds = sortedIds.take(100).map((e) => e.key).toList();
          
          // Charger les premières recettes
          final firstIds = _allSuggestedRecipeIds.take(_suggestionsPerPage).toList();
          final recipeFutures = firstIds.map((id) => _recipeService.getRecipeById(id));
          final loadedRecipes = await Future.wait(recipeFutures);
          newRecipes = loadedRecipes.whereType<Recipe>().toList();
          _suggestedRecipesOffset = _suggestionsPerPage;
        } else {
          // Pages suivantes : utiliser la pagination sur les IDs déjà chargés
          final startIndex = _suggestedRecipesOffset;
          final endIndex = startIndex + _suggestionsPerPage;
          
          if (startIndex < _allSuggestedRecipeIds.length) {
            final idsToLoad = _allSuggestedRecipeIds.sublist(
              startIndex,
              endIndex > _allSuggestedRecipeIds.length ? _allSuggestedRecipeIds.length : endIndex,
            );
            
            // Charger les détails des recettes
            final recipeFutures = idsToLoad.map((id) => _recipeService.getRecipeById(id));
            final loadedRecipes = await Future.wait(recipeFutures);
            newRecipes = loadedRecipes.whereType<Recipe>().toList();
            _suggestedRecipesOffset = endIndex;
          } else {
            // Plus de recettes disponibles
            _hasMoreSuggestions = false;
          }
        }
      } else {
        // Si le placard est vide, charger des recettes populaires et variées
        if (_currentSuggestionsPage == 0) {
          // Première page : recettes aléatoires
          final randomRecipes = await _recipeService.getRandomRecipes(_suggestionsPerPage);
          newRecipes = randomRecipes
              .where((recipe) => !_suggestedRecipeIds.contains(recipe.id))
              .toList();
        } else {
          // Pages suivantes : recettes populaires variées (liste étendue pour plus de variété)
          final popularTerms = [
            'chicken', 'pasta', 'salad', 'soup', 'dessert', 'beef', 'fish', 'rice', 'pizza', 'cake',
            'bread', 'vegetarian', 'vegan', 'healthy', 'breakfast', 'lunch', 'dinner', 'snack',
            'italian', 'french', 'asian', 'mexican', 'indian', 'thai', 'japanese', 'chinese',
            'seafood', 'vegetables', 'fruit', 'cheese', 'chocolate', 'ice cream', 'smoothie',
            'sandwich', 'burger', 'steak', 'grilled', 'baked', 'fried', 'roasted', 'steamed'
          ];
          final termIndex = _currentSuggestionsPage % popularTerms.length;
          final term = popularTerms[termIndex];
          
          try {
            final recipes = await _recipeService.searchRecipes(term);
            newRecipes = recipes
                .where((recipe) => !_suggestedRecipeIds.contains(recipe.id))
                .take(_suggestionsPerPage)
                .toList();
            
            // Si on n'a pas assez de recettes avec ce terme, essayer des recettes aléatoires
            if (newRecipes.length < _suggestionsPerPage) {
              final randomRecipes = await _recipeService.getRandomRecipes(_suggestionsPerPage - newRecipes.length);
              final additionalRecipes = randomRecipes
                  .where((recipe) => !_suggestedRecipeIds.contains(recipe.id))
                  .take(_suggestionsPerPage - newRecipes.length)
                  .toList();
              newRecipes.addAll(additionalRecipes);
            }
          } catch (e) {
            // En cas d'erreur, essayer des recettes aléatoires
            final randomRecipes = await _recipeService.getRandomRecipes(_suggestionsPerPage);
            newRecipes = randomRecipes
                .where((recipe) => !_suggestedRecipeIds.contains(recipe.id))
                .toList();
          }
        }
      }
      
      if (mounted) {
        setState(() {
          // Ajouter les nouvelles recettes
          for (var recipe in newRecipes) {
            if (!_suggestedRecipeIds.contains(recipe.id)) {
              _suggestedRecipes.add(recipe);
              _suggestedRecipeIds.add(recipe.id);
            }
          }
          
          // Pour le scroll infini, on continue toujours à charger
          // Seulement arrêter si vraiment aucune recette n'est disponible
          if (ingredientNames.isNotEmpty) {
            // Si on a des ingrédients et qu'on a épuisé toutes les IDs, on peut continuer avec d'autres termes
            if (_suggestedRecipesOffset >= _allSuggestedRecipeIds.length && newRecipes.isEmpty) {
              // Essayer de charger plus d'IDs en cherchant avec d'autres combinaisons
              // Pour l'instant, on continue avec des recettes aléatoires
              _hasMoreSuggestions = true; // Toujours permettre de charger plus
            }
          } else {
            // Pour le placard vide, on continue indéfiniment avec différents termes
            _hasMoreSuggestions = true; // Toujours permettre de charger plus
          }
          
          _currentSuggestionsPage++;
          _isLoadingMoreSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMoreSuggestions = false;
          // Ne pas mettre _hasMoreSuggestions à false en cas d'erreur, on peut réessayer
        });
      }
    }
  }

  Future<void> _searchRecipes() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _recipes = [];
        _searchQuery = '';
        _currentPage = 0;
        _hasMoreRecipes = true;
      });
      return;
    }

    final query = _searchController.text.trim();
    setState(() {
      _isLoading = true;
      _searchQuery = query;
      _recipes = []; // Réinitialiser la liste
      _filteredRecipes = []; // Réinitialiser les recettes filtrées (réinitialiser les filtres)
      _currentPage = 0;
      _hasMoreRecipes = true;
    });

    // Charger la première page de recettes progressivement
    await _loadRecipesPage(0);
  }

  void _onFiltersChanged(List<Recipe> filteredRecipes) {
    setState(() {
      _filteredRecipes = filteredRecipes;
    });
  }

  int _getActiveFiltersCount() {
    // Compter le nombre de filtres actifs en comparant les listes
    if (_filteredRecipes.isEmpty && _recipes.isEmpty) return 0;
    if (_filteredRecipes.length == _recipes.length) return 0;
    // Si les listes sont différentes, il y a des filtres actifs
    // On peut estimer le nombre en fonction de la différence
    return _filteredRecipes.length < _recipes.length ? 1 : 0;
  }

  void _showFilters() {
    // Extraire tous les ingrédients uniques des recettes
    final allIngredients = <String>{};
    for (var recipe in _recipes) {
      for (var ingredient in recipe.ingredients) {
        allIngredients.add(ingredient.name);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => RecipeFilters(
          allRecipes: _recipes,
          onFiltersChanged: _onFiltersChanged,
          availableIngredients: allIngredients.toList(),
        ),
      ),
    );
  }

  Future<void> _loadRecipesPage(int page) async {
    if (!mounted || _searchQuery.isEmpty) return;

    try {
      // Calculer l'offset et la limite pour cette page
      int startIndex = page * _recipesPerPage;
      int limit = _recipesPerPage;
      
        // Charger uniquement les recettes de cette page avec limite
        int loadedCount = 0;
        int skippedCount = 0;
        
        await for (var recipe in _recipeService.searchRecipesStream(_searchQuery, limit: (page + 1) * _recipesPerPage)) {
          if (!mounted || _searchQuery != _searchController.text.trim()) {
            break; // Arrêter si la requête a changé
          }

          // Ignorer les recettes des pages précédentes
          if (skippedCount < startIndex) {
            skippedCount++;
            continue;
          }

          // Charger uniquement les recettes de cette page
          if (loadedCount < limit) {
            if (page == 0) {
              // Première page : affichage progressif
              setState(() {
                _recipes.add(recipe);
                _filteredRecipes = List.from(_recipes); // Initialiser les recettes filtrées
                _isLoading = false; // Arrêter le loading dès la première recette
              });
              loadedCount++;
              // Petit délai pour l'effet visuel progressif
              await Future.delayed(const Duration(milliseconds: 50));
            } else {
              // Pages suivantes : chargement plus rapide
              setState(() {
                _recipes.add(recipe);
                _filteredRecipes = List.from(_recipes); // Mettre à jour les recettes filtrées
                _isLoadingMore = false;
              });
              loadedCount++;
            }
          } else {
            // On a chargé toutes les recettes de cette page
            break;
          }
        }

      // Vérifier s'il y a plus de recettes à charger
      if (mounted) {
        setState(() {
          if (page == 0) {
            _isLoading = false;
          } else {
            _isLoadingMore = false;
          }
          // Si on a chargé moins que _recipesPerPage, c'est qu'il n'y a plus de recettes
          if (loadedCount < _recipesPerPage) {
            _hasMoreRecipes = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoadingMore || !_hasMoreRecipes || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadRecipesPage(_currentPage);
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
          // Header stylisé dans le style du drawer
          StyledHeader(
            title: 'Recettes',
            icon: Icons.restaurant_menu,
            trailing: _recipes.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Stack(
                        children: [
                          const Icon(
                            Icons.tune,
                            color: Colors.white,
                            size: 22,
                          ),
                          if (_getActiveFiltersCount() > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${_getActiveFiltersCount()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: _showFilters,
                      tooltip: 'Filtres',
                    ),
                  )
                : null,
          ),
          // Barre de recherche et contenu
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
                      : _buildSuggestedRecipes(), // Afficher les recettes suggérées
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

    // Utiliser les recettes filtrées si des filtres sont actifs, sinon les recettes normales
    final recipesToDisplay = _filteredRecipes.isNotEmpty && _filteredRecipes.length != _recipes.length
        ? _filteredRecipes
        : _recipes;

    if (recipesToDisplay.isEmpty) {
      final hasActiveFilters = _filteredRecipes.isNotEmpty && _filteredRecipes.length != _recipes.length;
      
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
                  hasActiveFilters ? Icons.filter_alt_off_outlined : Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                hasActiveFilters ? 'Aucune recette ne correspond aux filtres' : 'Aucune recette trouvée',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                hasActiveFilters
                    ? 'Essayez de modifier vos filtres ou de réinitialiser'
                    : 'Essayez avec d\'autres mots-clés',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasActiveFilters) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Réinitialiser les filtres'),
                  onPressed: () {
                    setState(() {
                      _filteredRecipes = [];
                    });
                    Navigator.pop(context); // Fermer le bottom sheet si ouvert
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Utiliser les variantes de cartes pour les résultats de recherche avec scroll infini
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 600;
        final crossAxisCount = constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 600
                    ? 2
                    : 1;
        
        return GridView.builder(
          controller: _scrollController, // Ajouter le controller pour le scroll infini
          physics: const ClampingScrollPhysics(), // Améliorer le comportement du scroll
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: _getAspectRatioForVariant(crossAxisCount, isWideScreen),
          ),
          padding: const EdgeInsets.all(12),
          itemCount: recipesToDisplay.length + (_isLoadingMore ? 1 : 0), // +1 pour l'indicateur de chargement
          itemBuilder: (context, index) {
            // Afficher l'indicateur de chargement à la fin
            if (index == recipesToDisplay.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            return _buildSuggestedRecipeCard(recipesToDisplay[index], isWideScreen: isWideScreen);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recherchez une recette',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tapez le nom d\'une recette dans la barre de recherche ci-dessus',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cartes de recettes détaillées avec ingrédients et instructions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedRecipes() {
    if (_isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Déterminer le nombre de colonnes selon la largeur de l'écran
        // Adapté pour les grands écrans
        int crossAxisCount;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4; // Très grands écrans : 4 colonnes
        } else if (constraints.maxWidth >= 900) {
          crossAxisCount = 3; // Grands écrans : 3 colonnes
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2; // Tablettes : 2 colonnes
        } else {
          crossAxisCount = 1; // Mobiles : 1 colonne
        }
        final isWideScreen = crossAxisCount >= 2;

        return RefreshIndicator(
          onRefresh: () async {
            // Recharger les recettes suggérées
            await _loadSuggestedRecipes(force: true);
          },
          child: CustomScrollView(
            controller: _suggestionsScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(), // Permet le pull-to-refresh avec effet de rebond
            ),
            slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder<List<String>>(
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
            ),
            if (_suggestedRecipes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    // Ratio adapté selon la variante et la taille de l'écran
                    childAspectRatio: _getAspectRatioForVariant(crossAxisCount, isWideScreen),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _suggestedRecipes.length) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildSuggestedRecipeCard(_suggestedRecipes[index], isWideScreen: isWideScreen);
                    },
                    childCount: _suggestedRecipes.length,
                  ),
                ),
              ),
              // Indicateur de chargement en bas si on charge plus de suggestions
              if (_isLoadingMoreSuggestions)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              // Pas de message de fin - scroll infini continu
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe, {bool isWideScreen = false}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToRecipeDetail(recipe),
        borderRadius: BorderRadius.circular(16),
        child: isWideScreen
            ? _buildWideScreenCard(recipe)
            : _buildMobileCard(recipe),
      ),
    );
  }

  // Carte pour mobile (layout horizontal)
  Widget _buildMobileCard(Recipe recipe) {
    return Row(
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
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              cacheWidth: 240, // Optimisation mémoire
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 120,
                  height: 120,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.restaurant,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TranslationBuilder(
                  builder: (context) {
                    return Text(
                      TranslationService.translateRecipeNameSync(recipe.title),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (recipe.prepTimeMinutes != null)
                      _buildInfoChip(
                        Icons.restaurant_outlined,
                        'Prép: ${recipe.prepTimeMinutes} min',
                        context,
                      ),
                    if (recipe.cookTimeMinutes != null)
                      _buildInfoChip(
                        Icons.local_fire_department_outlined,
                        'Cuisson: ${recipe.cookTimeMinutes} min',
                        context,
                      ),
                    if (recipe.readyInMinutes != null)
                      _buildInfoChip(
                        Icons.timer_outlined,
                        'Total: ${recipe.readyInMinutes} min',
                        context,
                      ),
                    if (recipe.servings != null)
                      Builder(
                        builder: (context) {
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
    );
  }

  // Carte pour grands écrans (layout vertical optimisé)
  Widget _buildWideScreenCard(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Important : éviter l'espace inutile en bas
      children: [
        if (recipe.image != null)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              recipe.image!,
              width: double.infinity,
              height: 100, // Réduit la hauteur de l'image pour les grands écrans
              fit: BoxFit.cover,
              cacheWidth: 300, // Optimisation mémoire
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 100, // Correspond à la nouvelle hauteur
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 100, // Correspond à la nouvelle hauteur
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.restaurant,
                    size: 35, // Icône légèrement plus petite
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 100, // Réduit la hauteur pour correspondre à l'image
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.restaurant,
              size: 35, // Icône légèrement plus petite
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6), // Réduit le padding du bas
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important : éviter l'espace inutile
            children: [
              TranslationBuilder(
                builder: (context) {
                  return Text(
                    TranslationService.translateRecipeNameSync(recipe.title),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              const SizedBox(height: 3), // Réduit l'espace entre titre et badges
              Wrap(
                spacing: 3, // Réduit l'espacement horizontal
                runSpacing: 2, // Réduit l'espacement vertical entre lignes
                children: [
                  if (recipe.prepTimeMinutes != null)
                    _buildInfoChip(
                      Icons.restaurant_outlined,
                      'Prép: ${recipe.prepTimeMinutes} min',
                      context,
                    ),
                  if (recipe.cookTimeMinutes != null)
                    _buildInfoChip(
                      Icons.local_fire_department_outlined,
                      'Cuisson: ${recipe.cookTimeMinutes} min',
                      context,
                    ),
                  if (recipe.readyInMinutes != null)
                    _buildInfoChip(
                      Icons.timer_outlined,
                      'Total: ${recipe.readyInMinutes} min',
                      context,
                    ),
                  if (recipe.servings != null)
                    Builder(
                      builder: (context) {
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
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Réduit le padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5), // Légèrement plus petit
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary), // Icône plus petite
          const SizedBox(width: 3), // Espacement réduit
          Text(
            label,
            style: TextStyle(
              fontSize: 11, // Texte plus petit
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode pour les cartes de suggestions avec variantes
  Widget _buildSuggestedRecipeCard(Recipe recipe, {bool isWideScreen = false}) {
    return InkWell(
      onTap: () => _navigateToRecipeDetail(recipe),
      borderRadius: BorderRadius.circular(12),
      child: _getCardVariant(recipe),
    );
  }

  Widget _getCardVariant(Recipe recipe) {
    switch (_cardVariant) {
      case 1:
        return RecipeCardVariants.variant1(recipe, context);
      case 2:
        return RecipeCardVariants.variant2(recipe, context);
      case 3:
        return RecipeCardVariants.variant3(recipe, context);
      case 4:
        return RecipeCardVariants.variant4(recipe, context);
      case 5:
        return RecipeCardVariants.variant5(recipe, context);
      case 6:
        return RecipeCardVariants.variant6(recipe, context);
      case 7:
        return RecipeCardVariants.variant7(recipe, context);
      default:
        return RecipeCardVariants.variant1(recipe, context);
    }
  }

  // Calcule le ratio d'aspect selon la variante et la taille de l'écran
  double _getAspectRatioForVariant(int crossAxisCount, bool isWideScreen) {
    // Hauteurs approximatives des variantes (en tenant compte du contenu)
    final Map<int, Map<String, double>> variantHeights = {
      1: {'mobile': 0.85, 'tablet': 0.75, 'desktop': 0.7},   // Compacte
      2: {'mobile': 0.9, 'tablet': 0.8, 'desktop': 0.75},    // Horizontale
      3: {'mobile': 0.8, 'tablet': 0.7, 'desktop': 0.65},    // Overlay
      4: {'mobile': 0.85, 'tablet': 0.75, 'desktop': 0.7},  // Badges
      5: {'mobile': 0.9, 'tablet': 0.8, 'desktop': 0.75},   // Minimaliste
      6: {'mobile': 1.4, 'tablet': 1.3, 'desktop': 1.2},   // Détaillée (plus haute pour contenir tous les ingrédients)
      7: {'mobile': 1.0, 'tablet': 0.9, 'desktop': 0.85},   // Avec ingrédients
    };

    final heights = variantHeights[_cardVariant] ?? variantHeights[1]!;
    
    if (crossAxisCount >= 4) {
      return heights['desktop']!;
    } else if (crossAxisCount >= 3) {
      return heights['tablet']!;
    } else if (isWideScreen) {
      return heights['tablet']!;
    } else {
      return heights['mobile']!;
    }
  }
}

