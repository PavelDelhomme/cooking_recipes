import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/recipe_api_service.dart';
import '../services/pantry_service.dart';
import '../services/translation_service.dart';
import '../widgets/locale_notifier.dart';
import '../widgets/translation_builder.dart';
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
  List<Recipe> _suggestedRecipes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false; // Pour le scroll infini
  bool _hasMoreRecipes = true; // Indique s'il y a plus de recettes à charger
  bool _isLoadingSuggestions = false;
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<String> _searchSuggestions = [];
  bool _isLoadingSearchSuggestions = false;
  bool _suggestionsLoaded = false; // Flag pour savoir si les suggestions ont été chargées
  int _cardVariant = 1; // Variante de carte actuelle (1-5)
  static const String _cardVariantKey = 'recipe_card_variant';
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  static const int _recipesPerPage = 10; // Nombre de recettes par page

  @override
  void initState() {
    super.initState();
    // Charger la variante sauvegardée
    _loadCardVariant();
    // Écouter les changements dans le champ de recherche pour l'autocomplétion
    _searchController.addListener(_onSearchChanged);
    // Écouter le scroll pour le chargement infini
    _scrollController.addListener(_onScroll);
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

  Future<void> _loadCardVariant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVariant = prefs.getInt(_cardVariantKey);
      if (savedVariant != null && savedVariant >= 1 && savedVariant <= 5) {
        setState(() => _cardVariant = savedVariant);
      }
    } catch (e) {
      // Utiliser la variante par défaut en cas d'erreur
    }
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
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
      _currentPage = 0;
      _hasMoreRecipes = true;
    });

    // Charger la première page de recettes progressivement
    await _loadRecipesPage(0);
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
              _isLoading = false; // Arrêter le loading dès la première recette
            });
            loadedCount++;
            // Petit délai pour l'effet visuel progressif
            await Future.delayed(const Duration(milliseconds: 50));
          } else {
            // Pages suivantes : chargement plus rapide
            setState(() {
              _recipes.add(recipe);
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
                PopupMenuButton<int>(
                  icon: const Icon(Icons.view_module),
                  tooltip: 'Changer le style de carte',
                  onSelected: (value) async {
                    setState(() => _cardVariant = value);
                    await _saveCardVariant(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Style de carte ${value} sélectionné'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          if (_cardVariant == 1) const Icon(Icons.check, size: 20),
                          if (_cardVariant == 1) const SizedBox(width: 8),
                          const Text('Style 1: Compacte'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Row(
                        children: [
                          if (_cardVariant == 2) const Icon(Icons.check, size: 20),
                          if (_cardVariant == 2) const SizedBox(width: 8),
                          const Text('Style 2: Horizontale'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 3,
                      child: Row(
                        children: [
                          if (_cardVariant == 3) const Icon(Icons.check, size: 20),
                          if (_cardVariant == 3) const SizedBox(width: 8),
                          const Text('Style 3: Overlay'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 4,
                      child: Row(
                        children: [
                          if (_cardVariant == 4) const Icon(Icons.check, size: 20),
                          if (_cardVariant == 4) const SizedBox(width: 8),
                          const Text('Style 4: Badges'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 5,
                      child: Row(
                        children: [
                          if (_cardVariant == 5) const Icon(Icons.check, size: 20),
                          if (_cardVariant == 5) const SizedBox(width: 8),
                          const Text('Style 5: Minimaliste'),
                        ],
                      ),
                    ),
                  ],
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
                      : _buildEmptyState(), // Afficher un état vide au lieu des suggestions
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: _getAspectRatioForVariant(crossAxisCount, isWideScreen),
          ),
          padding: const EdgeInsets.all(8),
          itemCount: _recipes.length + (_isLoadingMore ? 1 : 0), // +1 pour l'indicateur de chargement
          itemBuilder: (context, index) {
            // Afficher l'indicateur de chargement à la fin
            if (index == _recipes.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            return _buildSuggestedRecipeCard(_recipes[index], isWideScreen: isWideScreen);
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
              'Utilisez le menu (icône view_module) pour changer le style des cartes',
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

        return CustomScrollView(
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
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    // Ratio adapté selon la variante et la taille de l'écran
                    childAspectRatio: _getAspectRatioForVariant(crossAxisCount, isWideScreen),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildSuggestedRecipeCard(_suggestedRecipes[index], isWideScreen: isWideScreen);
                    },
                    childCount: _suggestedRecipes.length,
                  ),
                ),
              ),
          ],
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

