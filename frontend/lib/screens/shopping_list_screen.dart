import 'package:flutter/material.dart';
import '../models/shopping_list_item.dart';
import '../models/pantry_item.dart';
import '../services/shopping_list_service.dart';
import '../services/pantry_service.dart';
import '../services/ingredient_image_service.dart';
import '../services/translation_service.dart';
import '../widgets/locale_notifier.dart';
import '../widgets/styled_header.dart';
import '../widgets/unit_selector.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => ShoppingListScreenState();
}

class ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _shoppingListService = ShoppingListService();
  final PantryService _pantryService = PantryService();
  final IngredientImageService _imageService = IngredientImageService();
  List<ShoppingListItem> _items = [];
  bool _isLoading = true;
  bool _showChecked = false;
  final Map<String, String?> _ingredientImages = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  // Méthode publique pour recharger les items
  Future<void> loadItems() async {
    setState(() => _isLoading = true);
    final items = await _shoppingListService.getShoppingListItems();
    
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
      MaterialPageRoute(builder: (context) => const AddShoppingItemScreen()),
    );

    if (result == true) {
      loadItems();
    }
  }

  Future<void> _editItem(ShoppingListItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddShoppingItemScreen(item: item),
      ),
    );

    if (result == true) {
      loadItems();
    }
  }

  Future<void> _toggleItem(ShoppingListItem item) async {
    await _shoppingListService.toggleShoppingListItem(item.id);
    loadItems();
  }

  Future<void> _deleteItem(ShoppingListItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Voulez-vous supprimer ${item.name} de la liste ?'),
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
      await _shoppingListService.removeShoppingListItem(item.id);
      loadItems();
    }
  }

  Future<void> _removeCheckedItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les articles cochés'),
        content: const Text(
          'Voulez-vous supprimer tous les articles cochés de la liste ?',
        ),
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
      await _shoppingListService.removeCheckedItems();
      loadItems();
    }
  }

  Future<void> _addToPantry(ShoppingListItem item) async {
    if (item.isChecked) {
      // Ajouter au placard et supprimer de la liste
      await _pantryService.addPantryItem(
        PantryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: item.name,
          quantity: item.quantity ?? 1.0,
          unit: item.unit ?? 'unité',
        ),
      );
      await _shoppingListService.removeShoppingListItem(item.id);
      loadItems();
      
      // Le placard sera rechargé automatiquement quand l'utilisateur y accède
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} ajouté au placard')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cochez l\'article avant de l\'ajouter au placard'),
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(ShoppingListItem item) {
    setState(() {
      if (_selectedItems.contains(item.id)) {
        _selectedItems.remove(item.id);
      } else {
        _selectedItems.add(item.id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedItems.clear();
      for (var item in _displayedItems) {
        _selectedItems.add(item.id);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedItems.clear();
    });
  }

  Future<void> _addSelectedToPantry() async {
    if (_selectedItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sélectionnez au moins un article'),
          ),
        );
      }
      return;
    }

    final selectedItemsList = _items.where((item) => _selectedItems.contains(item.id)).toList();
    int successCount = 0;
    int failCount = 0;

    for (var item in selectedItemsList) {
      try {
        await _pantryService.addPantryItem(
          PantryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_${item.id}',
            name: item.name,
            quantity: item.quantity ?? 1.0,
            unit: item.unit ?? 'unité',
          ),
        );
        await _shoppingListService.removeShoppingListItem(item.id);
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    loadItems();
    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });

    if (mounted) {
      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount article(s) ajouté(s) au placard'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount ajouté(s), $failCount erreur(s)'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // Notifier que le placard a été mis à jour
  void _notifyPantryUpdate() {
    // Utiliser un callback via le contexte parent
    // Le MainScreen écoutera les changements via un InheritedWidget ou un callback
    // Pour l'instant, on utilise un mécanisme simple : recharger quand on change d'onglet
    // Le rechargement se fera automatiquement quand l'utilisateur reviendra sur l'onglet placard
  }

  List<ShoppingListItem> get _displayedItems {
    if (_showChecked) {
      return _items;
    }
    return _items.where((item) => !item.isChecked).toList();
  }

  int get _checkedCount => _items.where((item) => item.isChecked).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pas d'AppBar ici car c'est géré par MainScreen
      body: Column(
        children: [
          // Header stylisé dans le style du drawer
          StyledHeader(
            title: 'Liste de courses',
            icon: Icons.shopping_cart,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_items.isNotEmpty && _items.any((item) => item.isChecked))
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.white),
                    onPressed: _removeCheckedItems,
                    tooltip: 'Supprimer les articles cochés',
                  ),
                IconButton(
                  icon: const Icon(Icons.select_all, color: Colors.white),
                  onPressed: _isSelectionMode ? _deselectAll : _toggleSelectionMode,
                  tooltip: _isSelectionMode ? 'Désélectionner' : 'Sélectionner',
                ),
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: Column(
              children: [
                // Barre d'actions
                if (_items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (_isSelectionMode) ...[
                                Text(
                                  '${_selectedItems.length} sélectionné(s)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Liste de courses',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSelectionMode) ...[
                              if (_selectedItems.length < _displayedItems.length)
                                IconButton(
                                  icon: const Icon(Icons.select_all),
                                  onPressed: _selectAll,
                                  tooltip: 'Tout sélectionner',
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.deselect),
                                  onPressed: _deselectAll,
                                  tooltip: 'Tout désélectionner',
                                ),
                              if (_selectedItems.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  onPressed: _addSelectedToPantry,
                                  tooltip: 'Ajouter au placard',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _toggleSelectionMode,
                                tooltip: 'Annuler la sélection',
                              ),
                            ] else ...[
                              if (_checkedCount > 0)
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep),
                                  onPressed: _removeCheckedItems,
                                  tooltip: 'Supprimer les articles cochés',
                                ),
                              IconButton(
                                icon: Icon(_showChecked ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() => _showChecked = !_showChecked);
                                },
                                tooltip: _showChecked ? 'Masquer les articles cochés' : 'Afficher les articles cochés',
                              ),
                              IconButton(
                                icon: const Icon(Icons.checklist),
                                onPressed: _toggleSelectionMode,
                                tooltip: 'Mode sélection',
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: loadItems,
                                tooltip: 'Actualiser',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _displayedItems.isEmpty
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
                                        Icons.shopping_cart_outlined,
                                        size: 64,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      _showChecked
                                          ? 'Aucun article coché'
                                          : 'Votre liste de courses est vide',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Ajoutez des articles pour commencer',
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
                  itemCount: _displayedItems.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final item = _displayedItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: item.isChecked
                          ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)
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
                                            Icons.shopping_cart,
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
                                        Icons.shopping_cart,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_isSelectionMode)
                              Checkbox(
                                value: _selectedItems.contains(item.id),
                                onChanged: (_) => _toggleItemSelection(item),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )
                            else
                              Checkbox(
                                value: item.isChecked,
                                onChanged: (_) => _toggleItem(item),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        onTap: _isSelectionMode
                            ? () => _toggleItemSelection(item)
                            : null,
                        title: Builder(
                          builder: (context) {
                            // Écouter les changements de locale
                            LocaleNotifier.of(context);
                            return Text(
                              TranslationService.translateIngredientSync(item.name),
                              style: TextStyle(
                                decoration: item.isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: item.isChecked
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                                color: item.isChecked
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : null,
                              ),
                            );
                          },
                        ),
                        subtitle: item.quantity != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
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
                                    '${item.quantity} ${item.unit != null ? TranslationService.translateUnit(item.unit!) : ''}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                        trailing: _isSelectionMode
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.isChecked)
                                    IconButton(
                                      icon: Icon(
                                        Icons.add_shopping_cart,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      onPressed: () => _addToPantry(item),
                                      tooltip: 'Ajouter au placard',
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "shopping_list_fab",
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddShoppingItemScreen extends StatefulWidget {
  final ShoppingListItem? item;

  const AddShoppingItemScreen({super.key, this.item});

  @override
  State<AddShoppingItemScreen> createState() => _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends State<AddShoppingItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity?.toString() ?? '';
      _selectedUnit = widget.item!.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final shoppingListService = ShoppingListService();
      final item = ShoppingListItem(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        quantity: _quantityController.text.trim().isNotEmpty
            ? double.tryParse(_quantityController.text)
            : null,
        unit: _selectedUnit,
        addedDate: widget.item?.addedDate ?? DateTime.now(),
      );

      if (widget.item != null) {
        await shoppingListService.updateShoppingListItem(item);
      } else {
        await shoppingListService.addShoppingListItem(item);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null
            ? 'Ajouter un article'
            : 'Modifier l\'article'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom de l\'article',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantité (optionnel)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: UnitSelector(
                    selectedUnit: _selectedUnit,
                    onChanged: (unit) {
                      setState(() => _selectedUnit = unit);
                    },
                  ),
                ),
              ],
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
    );
  }
}

