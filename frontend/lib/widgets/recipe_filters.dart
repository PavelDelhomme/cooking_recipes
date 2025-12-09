import 'package:flutter/material.dart';
import '../models/recipe.dart';

/// Widget pour filtrer les recettes
class RecipeFilters extends StatefulWidget {
  final List<Recipe> allRecipes;
  final Function(List<Recipe>) onFiltersChanged;
  final List<String> availableIngredients;

  const RecipeFilters({
    super.key,
    required this.allRecipes,
    required this.onFiltersChanged,
    required this.availableIngredients,
  });

  @override
  State<RecipeFilters> createState() => _RecipeFiltersState();
}

class _RecipeFiltersState extends State<RecipeFilters> {
  // Filtres
  int? _maxTotalTime; // Temps total maximum en minutes
  int? _maxPrepTime; // Temps de préparation maximum
  int? _maxCookTime; // Temps de cuisson maximum
  int? _minServings; // Nombre de portions minimum
  int? _maxServings; // Nombre de portions maximum
  Set<String> _selectedIngredients = {}; // Ingrédients à inclure
  Set<String> _excludedIngredients = {}; // Ingrédients à exclure

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  void _applyFilters() {
    List<Recipe> filtered = List.from(widget.allRecipes);

    // Filtrer par temps total
    if (_maxTotalTime != null) {
      filtered = filtered.where((recipe) {
        return recipe.readyInMinutes != null && recipe.readyInMinutes! <= _maxTotalTime!;
      }).toList();
    }

    // Filtrer par temps de préparation
    if (_maxPrepTime != null) {
      filtered = filtered.where((recipe) {
        return recipe.prepTimeMinutes != null && recipe.prepTimeMinutes! <= _maxPrepTime!;
      }).toList();
    }

    // Filtrer par temps de cuisson
    if (_maxCookTime != null) {
      filtered = filtered.where((recipe) {
        return recipe.cookTimeMinutes != null && recipe.cookTimeMinutes! <= _maxCookTime!;
      }).toList();
    }

    // Filtrer par nombre de portions
    if (_minServings != null) {
      filtered = filtered.where((recipe) {
        return recipe.servings != null && recipe.servings! >= _minServings!;
      }).toList();
    }
    if (_maxServings != null) {
      filtered = filtered.where((recipe) {
        return recipe.servings != null && recipe.servings! <= _maxServings!;
      }).toList();
    }

    // Filtrer par ingrédients à inclure
    if (_selectedIngredients.isNotEmpty) {
      filtered = filtered.where((recipe) {
        final recipeIngredientNames = recipe.ingredients
            .map((ing) => ing.name.toLowerCase())
            .toSet();
        return _selectedIngredients.every((selected) =>
            recipeIngredientNames.contains(selected.toLowerCase()));
      }).toList();
    }

    // Filtrer par ingrédients à exclure
    if (_excludedIngredients.isNotEmpty) {
      filtered = filtered.where((recipe) {
        final recipeIngredientNames = recipe.ingredients
            .map((ing) => ing.name.toLowerCase())
            .toSet();
        return !_excludedIngredients.any((excluded) =>
            recipeIngredientNames.contains(excluded.toLowerCase()));
      }).toList();
    }

    widget.onFiltersChanged(filtered);
  }

  void _resetFilters() {
    setState(() {
      _maxTotalTime = null;
      _maxPrepTime = null;
      _maxCookTime = null;
      _minServings = null;
      _maxServings = null;
      _selectedIngredients.clear();
      _excludedIngredients.clear();
    });
    _applyFilters();
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_maxTotalTime != null) count++;
    if (_maxPrepTime != null) count++;
    if (_maxCookTime != null) count++;
    if (_minServings != null) count++;
    if (_maxServings != null) count++;
    if (_selectedIngredients.isNotEmpty) count++;
    if (_excludedIngredients.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final activeFiltersCount = _getActiveFiltersCount();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtres',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (activeFiltersCount > 0)
                        Text(
                          '$activeFiltersCount filtre${activeFiltersCount > 1 ? 's' : ''} actif${activeFiltersCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                if (activeFiltersCount > 0)
                  IconButton(
                    icon: Icon(
                      Icons.clear_all,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: _resetFilters,
                    tooltip: 'Réinitialiser les filtres',
                  ),
              ],
            ),
          ),
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filtre par temps total
                  _buildTimeFilter(
                    title: 'Temps total maximum',
                    value: _maxTotalTime,
                    onChanged: (value) {
                      setState(() => _maxTotalTime = value);
                      _applyFilters();
                    },
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  // Filtre par temps de préparation
                  _buildTimeFilter(
                    title: 'Temps de préparation maximum',
                    value: _maxPrepTime,
                    onChanged: (value) {
                      setState(() => _maxPrepTime = value);
                      _applyFilters();
                    },
                    icon: Icons.restaurant_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  // Filtre par temps de cuisson
                  _buildTimeFilter(
                    title: 'Temps de cuisson maximum',
                    value: _maxCookTime,
                    onChanged: (value) {
                      setState(() => _maxCookTime = value);
                      _applyFilters();
                    },
                    icon: Icons.local_fire_department_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  // Filtre par nombre de portions
                  _buildServingsFilter(),
                  const SizedBox(height: 20),
                  
                  // Filtre par ingrédients à inclure
                  _buildIngredientsFilter(
                    title: 'Inclure ces ingrédients',
                    selected: _selectedIngredients,
                    onChanged: (ingredients) {
                      setState(() => _selectedIngredients = ingredients);
                      _applyFilters();
                    },
                    icon: Icons.add_circle_outline,
                  ),
                  const SizedBox(height: 20),
                  
                  // Filtre par ingrédients à exclure
                  _buildIngredientsFilter(
                    title: 'Exclure ces ingrédients',
                    selected: _excludedIngredients,
                    onChanged: (ingredients) {
                      setState(() => _excludedIngredients = ingredients);
                      _applyFilters();
                    },
                    icon: Icons.remove_circle_outline,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter({
    required String title,
    required int? value,
    required Function(int?) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value?.toDouble() ?? 0,
                  min: 0,
                  max: 180,
                  divisions: 18,
                  label: value != null ? '${value} min' : 'Aucun',
                  onChanged: (newValue) {
                    onChanged(newValue.toInt());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value != null ? '${value} min' : 'Tous',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (value != null)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => onChanged(null),
                  tooltip: 'Réinitialiser',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServingsFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Nombre de portions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _minServings?.toDouble() ?? 0,
                      min: 0,
                      max: 12,
                      divisions: 12,
                      label: _minServings != null ? '$_minServings pers.' : 'Aucun',
                      onChanged: (newValue) {
                        setState(() => _minServings = newValue.toInt());
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _minServings != null ? '$_minServings' : '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maximum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxServings?.toDouble() ?? 12,
                      min: 0,
                      max: 12,
                      divisions: 12,
                      label: _maxServings != null ? '$_maxServings pers.' : 'Tous',
                      onChanged: (newValue) {
                        setState(() => _maxServings = newValue.toInt());
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _maxServings != null ? '$_maxServings' : '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (_minServings != null || _maxServings != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.clear, size: 16),
                    label: const Text('Réinitialiser'),
                    onPressed: () {
                      setState(() {
                        _minServings = null;
                        _maxServings = null;
                      });
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIngredientsFilter({
    required String title,
    required Set<String> selected,
    required Function(Set<String>) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips des ingrédients sélectionnés
          if (selected.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.map((ingredient) {
                return Chip(
                  label: Text(ingredient),
                  onDeleted: () {
                    final newSet = Set<String>.from(selected)..remove(ingredient);
                    onChanged(newSet);
                  },
                  deleteIcon: Icon(
                    Icons.close,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          // Bouton pour ajouter des ingrédients
          OutlinedButton.icon(
            icon: Icon(Icons.add, size: 18),
            label: Text(selected.isEmpty ? 'Ajouter des ingrédients' : 'Ajouter d\'autres ingrédients'),
            onPressed: () => _showIngredientPicker(selected, onChanged),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIngredientPicker(Set<String> currentSelection, Function(Set<String>) onChanged) {
    // Extraire tous les ingrédients uniques des recettes
    final allIngredients = <String>{};
    for (var recipe in widget.allRecipes) {
      for (var ingredient in recipe.ingredients) {
        allIngredients.add(ingredient.name);
      }
    }
    final sortedIngredients = allIngredients.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sélectionner des ingrédients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Liste des ingrédients
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = sortedIngredients[index];
                  final isSelected = currentSelection.contains(ingredient);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        ingredient,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      onTap: () {
                        final newSet = Set<String>.from(currentSelection);
                        if (isSelected) {
                          newSet.remove(ingredient);
                        } else {
                          newSet.add(ingredient);
                        }
                        onChanged(newSet);
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

