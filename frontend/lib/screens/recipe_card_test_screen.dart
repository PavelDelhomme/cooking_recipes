import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_api_service.dart';
import 'recipe_card_variants.dart';
import 'recipe_detail_screen.dart';
import '../widgets/translation_builder.dart';

class RecipeCardTestScreen extends StatefulWidget {
  const RecipeCardTestScreen({super.key});

  @override
  State<RecipeCardTestScreen> createState() => _RecipeCardTestScreenState();
}

class _RecipeCardTestScreenState extends State<RecipeCardTestScreen> {
  final RecipeApiService _recipeService = RecipeApiService();
  List<Recipe> _testRecipes = [];
  bool _isLoading = true;
  int _selectedVariant = 1;

  @override
  void initState() {
    super.initState();
    _loadTestRecipes();
  }

  Future<void> _loadTestRecipes() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger 2 recettes aléatoires pour les tests
      final recipes = await _recipeService.getRandomRecipes(2);
      
      if (mounted) {
        setState(() {
          _testRecipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  Widget _buildCardVariant(Recipe recipe, int variant) {
    switch (variant) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Variantes de Cartes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTestRecipes,
            tooltip: 'Recharger les recettes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _testRecipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Aucune recette chargée'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTestRecipes,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sélecteur de variante
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sélectionner une variante:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(5, (index) {
                                  final variant = index + 1;
                                  return ChoiceChip(
                                    label: Text('Variante $variant'),
                                    selected: _selectedVariant == variant,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedVariant = variant);
                                      }
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Affichage de toutes les variantes pour chaque recette
                      ..._testRecipes.map((recipe) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre de la recette
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TranslationBuilder(
                                builder: (context) => Text(
                                  recipe.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Toutes les variantes côte à côte (ou empilées sur mobile)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 800;
                                return isWide
                                    ? Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: List.generate(5, (index) {
                                          final variant = index + 1;
                                          return Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: _selectedVariant == variant
                                                          ? Theme.of(context).colorScheme.primaryContainer
                                                          : Theme.of(context).colorScheme.surfaceVariant,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'V$variant',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: _selectedVariant == variant
                                                              ? Theme.of(context).colorScheme.onPrimaryContainer
                                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  AspectRatio(
                                                    aspectRatio: 0.75,
                                                    child: InkWell(
                                                      onTap: () => _navigateToRecipeDetail(recipe),
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: _buildCardVariant(recipe, variant),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      )
                                    : Column(
                                        children: List.generate(5, (index) {
                                          final variant = index + 1;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 24),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: _selectedVariant == variant
                                                        ? Theme.of(context).colorScheme.primaryContainer
                                                        : Theme.of(context).colorScheme.surfaceVariant,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Variante $variant',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: _selectedVariant == variant
                                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                AspectRatio(
                                                  aspectRatio: 0.75,
                                                  child: InkWell(
                                                    onTap: () => _navigateToRecipeDetail(recipe),
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: _buildCardVariant(recipe, variant),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      );
                              },
                            ),
                            
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 32),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }
}

