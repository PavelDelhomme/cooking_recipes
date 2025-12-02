import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget intelligent pour saisir quantité et unité ensemble
/// Permet des formats comme "2L", "2 brique", "500g", "1.5 kg", etc.
class QuantityUnitInput extends StatefulWidget {
  final TextEditingController quantityController;
  final String? selectedUnit;
  final ValueChanged<String?> onUnitChanged;
  final String? ingredientName;
  final List<String>? suggestedUnits;

  const QuantityUnitInput({
    super.key,
    required this.quantityController,
    this.selectedUnit,
    required this.onUnitChanged,
    this.ingredientName,
    this.suggestedUnits,
  });

  @override
  State<QuantityUnitInput> createState() => _QuantityUnitInputState();
}

class _QuantityUnitInputState extends State<QuantityUnitInput> {
  final TextEditingController _combinedController = TextEditingController();
  bool _isParsed = false;

  @override
  void initState() {
    super.initState();
    _updateCombinedField();
    _combinedController.addListener(_parseInput);
  }

  @override
  void dispose() {
    _combinedController.dispose();
    super.dispose();
  }

  void _updateCombinedField() {
    if (widget.quantityController.text.isNotEmpty || widget.selectedUnit != null) {
      final qty = widget.quantityController.text;
      final unit = widget.selectedUnit ?? '';
      _combinedController.text = qty.isNotEmpty && unit.isNotEmpty ? '$qty $unit' : qty;
    }
  }

  void _parseInput() {
    final text = _combinedController.text.trim();
    if (text.isEmpty) {
      widget.quantityController.clear();
      widget.onUnitChanged(null);
      return;
    }

    // Patterns pour parser différents formats
    // Exemples: "2L", "2 L", "2L de lait", "500g", "1.5 kg", "2 brique", "2 briques"
    final patterns = [
      RegExp(r'^(\d+\.?\d*)\s*([a-zA-ZÀ-ÿ]+)$'), // "2L", "500g", "1.5 kg"
      RegExp(r'^(\d+\.?\d*)\s+([a-zA-ZÀ-ÿ]+)$'), // "2 L", "500 g"
      RegExp(r'^(\d+\.?\d*)\s+([a-zA-ZÀ-ÿ]+)\s+de\s+', caseSensitive: false), // "2 L de lait"
    ];

    String? quantity;
    String? unit;

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        quantity = match.group(1);
        unit = match.group(2)?.trim();
        break;
      }
    }

    // Si aucun pattern ne correspond, essayer de séparer par espace
    if (quantity == null && text.contains(' ')) {
      final parts = text.split(' ');
      if (parts.length >= 2) {
        final firstPart = parts[0];
        if (double.tryParse(firstPart) != null) {
          quantity = firstPart;
          unit = parts.sublist(1).join(' ');
        }
      }
    }

    // Si toujours rien, vérifier si c'est juste un nombre
    if (quantity == null) {
      final numValue = double.tryParse(text);
      if (numValue != null) {
        quantity = text;
        unit = null;
      }
    }

    if (quantity != null) {
      setState(() {
        _isParsed = true;
      });
      widget.quantityController.text = quantity;
      if (unit != null && unit.isNotEmpty) {
        widget.onUnitChanged(unit);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _combinedController,
          decoration: InputDecoration(
            labelText: 'Quantité et unité',
            hintText: 'Ex: 2L, 500g, 1.5 kg, 2 brique, 3 pièces...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: const Icon(Icons.numbers),
            suffixIcon: _isParsed
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s\.a-zA-ZÀ-ÿ]')),
          ],
        ),
        if (_isParsed && widget.selectedUnit != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Quantité: ${widget.quantityController.text} | Unité: ${widget.selectedUnit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

