import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import '../services/pantry_history_service.dart';
import '../services/ingredient_image_service.dart';
import '../models/pantry_history_item.dart';
import '../widgets/unit_selector.dart';
import '../widgets/quantity_unit_input.dart';
import '../services/ingredient_suggestions.dart';
import 'pantry_history_screen.dart';
import 'pantry_config_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => PantryScreenState();
}

class PantryScreenState extends State<PantryScreen> {
  final PantryService _pantryService = PantryService();
  final PantryHistoryService _historyService = PantryHistoryService();
  final IngredientImageService _imageService = IngredientImageService();
  List<PantryItem> _items = [];
  bool _isLoading = true;
  final Map<String, String?> _ingredientImages = {};

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  // Méthode publique pour recharger les items
  Future<void> loadItems() async {
    setState(() => _isLoading = true);
    final items = await _pantryService.getPantryItems();
    
    // Charger les images pour chaque ingrédient
    final Map<String, String?> images = {};
    for (var item in items) {
      if (!_ingredientImages.containsKey(item.name)) {
        final imageUrl = await _imageService.getImageFromMealDB(item.name);
        images[item.name] = imageUrl;
      }
    }
    
    setState(() {
      _items = items;
      _ingredientImages.addAll(images);
      _isLoading = false;
    });
  }

  Future<void> _addItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPantryItemScreen()),
    );

    if (result == true) {
      loadItems();
    }
  }

  Future<void> _editItem(PantryItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPantryItemScreen(item: item),
      ),
    );

    if (result == true) {
      loadItems();
    }
  }

  Future<void> _deleteItem(PantryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Voulez-vous supprimer ${item.name} ?'),
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
      await _pantryService.removePantryItem(item.id);
      loadItems();
    }
  }

  Future<void> _useIngredient(PantryItem item) async {
    final quantityController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Utiliser ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quantité disponible: ${item.quantity} ${item.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantité à utiliser',
                suffixText: item.unit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Utiliser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final quantity = double.tryParse(quantityController.text);
      if (quantity != null && quantity > 0) {
        await _pantryService.useIngredient(item.id, quantity);
        
        // Ajouter à l'historique
        final historyItem = PantryHistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          ingredientName: item.name,
          quantity: quantity,
          unit: item.unit,
          usedDate: DateTime.now(),
        );
        await _historyService.addHistoryItem(historyItem);
        
        loadItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrédient utilisé')),
          );
        }
      }
    }
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
                  'Mon Placard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PantryHistoryScreen(),
                          ),
                        );
                      },
                      tooltip: 'Historique',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: loadItems,
                      tooltip: 'Actualiser',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'config') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PantryConfigScreen(),
                            ),
                          );
                        } else if (value == 'refresh') {
                          loadItems();
                        }
                      },
                      itemBuilder: (context) => [
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
              ],
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? Center(
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
                            Icons.kitchen_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Votre placard est vide',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ajoutez des ingrédients pour commencer',
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
              : ListView.builder(
                  itemCount: _items.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isExpired = item.expiryDate != null &&
                        item.expiryDate!.isBefore(DateTime.now());
                    final isExpiringSoon = item.expiryDate != null &&
                        !isExpired &&
                        item.expiryDate!.difference(DateTime.now()).inDays <= 3;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: isExpired
                          ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.3)
                          : isExpiringSoon
                              ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3)
                              : null,
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _ingredientImages[item.name] != null
                                ? Image.network(
                                    _ingredientImages[item.name]!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.shopping_basket,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                                    Icons.shopping_basket,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
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
                                '${item.quantity} ${item.unit}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                            ),
                            if (item.expiryDate != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    isExpired
                                        ? Icons.warning
                                        : Icons.calendar_today,
                                    size: 14,
                                    color: isExpired
                                        ? Theme.of(context).colorScheme.error
                                        : isExpiringSoon
                                            ? Theme.of(context).colorScheme.tertiary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isExpired
                                        ? 'Expiré le ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}'
                                        : 'Expire le ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isExpired
                                          ? Theme.of(context).colorScheme.error
                                          : isExpiringSoon
                                              ? Theme.of(context).colorScheme.tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      fontWeight: isExpired || isExpiringSoon
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () => _useIngredient(item),
                              tooltip: 'Utiliser',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              onPressed: () => _editItem(item),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _deleteItem(item),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "pantry_fab",
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddPantryItemScreen extends StatefulWidget {
  final PantryItem? item;

  const AddPantryItemScreen({super.key, this.item});

  @override
  State<AddPantryItemScreen> createState() => _AddPantryItemScreenState();
}

class _AddPantryItemScreenState extends State<AddPantryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedUnit;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity.toString();
      _selectedUnit = widget.item!.unit;
      _expiryDate = widget.item!.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionner la date d\'expiration',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _setQuickDate(int days) {
    setState(() {
      _expiryDate = DateTime.now().add(Duration(days: days));
    });
  }

  Future<void> _save() async {
    // Valider que le nom est rempli
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom d\'ingrédient')),
      );
      return;
    }

    // Valider et parser la quantité
    double quantity = 1.0;
    if (_quantityController.text.trim().isNotEmpty) {
      final parsedQty = double.tryParse(_quantityController.text.trim());
      if (parsedQty == null || parsedQty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer une quantité valide')),
        );
        return;
      }
      quantity = parsedQty;
    }

    // Utiliser l'unité sélectionnée ou 'unité' par défaut
    final unit = _selectedUnit ?? 'unité';

    final pantryService = PantryService();
    final item = PantryItem(
      id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      quantity: quantity,
      unit: unit,
      expiryDate: _expiryDate,
    );

    if (widget.item != null) {
      await pantryService.updatePantryItem(item);
    } else {
      await pantryService.addPantryItem(item);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.escape ||
             event.logicalKey.keyLabel == 'Escape')) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.item == null ? 'Ajouter un ingrédient' : 'Modifier l\'ingrédient'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _nameController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                // Retourner les suggestions de manière synchrone pour éviter les blocages
                final query = textEditingValue.text.trim().toLowerCase();
                final allIngredients = IngredientSuggestions.getCommonIngredients();
                
                if (query.isEmpty) {
                  return allIngredients;
                }
                
                // Filtrer les ingrédients qui correspondent à la requête
                return allIngredients
                    .where((ingredient) => 
                        ingredient.toLowerCase().contains(query))
                    .toList();
              },
              onSelected: (String selection) {
                _nameController.text = selection;
                // Mettre à jour les suggestions d'unités
                setState(() {});
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Initialiser le controller une seule fois
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (controller.text != _nameController.text && _nameController.text.isNotEmpty) {
                    controller.text = _nameController.text;
                  }
                });
                
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onFieldSubmitted: onFieldSubmitted != null ? (_) => onFieldSubmitted() : null,
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'ingrédient',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: const Icon(Icons.shopping_basket_outlined),
                    hintText: 'Ex: Steak haché, Pâtes, Tomates, Lait...',
                  ),
                  onChanged: (value) {
                    // Mettre à jour _nameController sans setState pour éviter les blocages
                    if (_nameController.text != value) {
                      _nameController.text = value;
                    }
                    // Mettre à jour les suggestions d'unités seulement si nécessaire
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Saisie combinée intelligente (recommandée)
            QuantityUnitInput(
              quantityController: _quantityController,
              selectedUnit: _selectedUnit,
              onUnitChanged: (unit) {
                setState(() => _selectedUnit = unit);
              },
              ingredientName: _nameController.text.trim(),
            ),
            const SizedBox(height: 8),
            // Aide contextuelle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Exemples: "2L", "500g", "1.5 kg", "2 brique", "3 pièces", "2L de lait"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Date d\'expiration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_expiryDate != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _expiryDate = null),
                            tooltip: 'Supprimer la date',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_expiryDate != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                                  .format(_expiryDate!),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'Aucune date sélectionnée',
                        style: TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickDateButton('Aujourd\'hui', 0),
                        _buildQuickDateButton('Demain', 1),
                        _buildQuickDateButton('Dans 3 jours', 3),
                        _buildQuickDateButton('Dans 7 jours', 7),
                        _buildQuickDateButton('Dans 30 jours', 30),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Choisir une date personnalisée'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, int days) {
    final date = DateTime.now().add(Duration(days: days));
    final isSelected = _expiryDate != null &&
        _expiryDate!.year == date.year &&
        _expiryDate!.month == date.month &&
        _expiryDate!.day == date.day;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setQuickDate(days),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

