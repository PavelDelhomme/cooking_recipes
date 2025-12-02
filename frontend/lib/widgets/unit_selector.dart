import 'package:flutter/material.dart';
import '../services/ingredient_suggestions.dart';

class UnitSelector extends StatelessWidget {
  final String? selectedUnit;
  final ValueChanged<String?> onChanged;
  final bool allowCustom;
  final String? ingredientName; // Nom de l'ingrédient pour suggestions contextuelles

  const UnitSelector({
    super.key,
    this.selectedUnit,
    required this.onChanged,
    this.allowCustom = true,
    this.ingredientName,
  });

  static const List<String> commonUnits = [
    'unité',
    'g',
    'kg',
    'ml',
    'l',
    'cl',
    'cuillère à soupe',
    'cuillère à café',
    'tasse',
    'tranche',
    'pièce',
    'botte',
    'tête',
    'gousse',
    'branche',
    'feuille',
    'pincée',
    'verre',
    'boîte',
    'sachet',
    'paquet',
    'portion',
    'pot',
  ];

  List<String> get _suggestedUnits {
    if (ingredientName != null && ingredientName!.isNotEmpty) {
      final suggestions = IngredientSuggestions.getSuggestedUnits(ingredientName!);
      // Combiner les suggestions avec les unités communes, en priorisant les suggestions
      final allUnits = <String>[];
      allUnits.addAll(suggestions);
      for (var unit in commonUnits) {
        if (!allUnits.contains(unit)) {
          allUnits.add(unit);
        }
      }
      return allUnits;
    }
    return commonUnits;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedUnit,
      decoration: InputDecoration(
        labelText: 'Unité',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: [
        // Afficher d'abord les suggestions si un nom d'ingrédient est fourni
        if (ingredientName != null && ingredientName!.isNotEmpty)
          ...IngredientSuggestions.getSuggestedUnits(ingredientName!)
              .take(5)
              .map((unit) => DropdownMenuItem(
                    value: unit,
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(unit),
                      ],
                    ),
                  )),
        if (ingredientName != null && ingredientName!.isNotEmpty)
          const DropdownMenuItem(
            value: 'divider',
            enabled: false,
            child: Divider(),
          ),
        ..._suggestedUnits.map((unit) => DropdownMenuItem(
              value: unit,
              child: Text(unit),
            )),
        if (allowCustom)
          const DropdownMenuItem(
            value: 'custom',
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 18),
                SizedBox(width: 8),
                Text('Autre...'),
              ],
            ),
          ),
      ],
      onChanged: (value) {
        if (value == 'custom') {
          _showCustomUnitDialog(context);
        } else if (value != 'divider') {
          onChanged(value);
        }
      },
    );
  }

  void _showCustomUnitDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unité personnalisée'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Entrez l\'unité',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onChanged(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

