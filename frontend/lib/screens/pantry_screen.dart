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
import '../services/ingredient_cleaner.dart';
import '../services/translation_service.dart';
import '../widgets/locale_notifier.dart';
import '../widgets/styled_header.dart';
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
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Utiliser ${item.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quantité disponible: ${item.quantity} ${item.unit ?? 'unité'}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantité à utiliser',
                  suffixText: item.unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                  LengthLimitingTextInputFormatter(10), // Limiter à 10 caractères
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  final quantity = double.tryParse(value.trim());
                  if (quantity == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  if (quantity <= 0) {
                    return 'La quantité doit être supérieure à 0';
                  }
                  if (quantity > item.quantity) {
                    return 'La quantité ne peut pas dépasser ${item.quantity} ${item.unit ?? 'unité'}';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Utiliser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final quantity = double.tryParse(quantityController.text.trim());
      if (quantity != null && quantity > 0) {
        // Vérifier que la quantité ne dépasse pas la quantité disponible
        if (quantity > item.quantity) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erreur: Vous ne pouvez pas utiliser plus que la quantité disponible (${item.quantity} ${item.unit ?? 'unité'})',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        // Vérifier que la quantité ne devient pas négative
        final newQuantity = item.quantity - quantity;
        if (newQuantity < 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Erreur: Impossible d\'utiliser cette quantité. La quantité ne peut pas être négative.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

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
            SnackBar(content: Text('${quantity} ${item.unit ?? 'unité'} de ${item.name} utilisé(s)')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Veuillez entrer une quantité valide'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
          // Header stylisé dans le style du drawer
          StyledHeader(
            title: 'Placard',
            icon: Icons.kitchen,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantryHistoryScreen(),
                      ),
                    );
                    loadItems();
                  },
                  tooltip: 'Historique',
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantryConfigScreen(),
                      ),
                    );
                    loadItems();
                  },
                  tooltip: 'Configuration',
                ),
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: Column(
              children: [
                // Liste des ingrédients
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.kitchen_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Votre placard est vide',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ajoutez des ingrédients pour commencer',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return _buildPantryItemCard(item);
                              },
                            ),
                ),
              ],
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

  Widget _buildPantryItemCard(PantryItem item) {
    final hasImage = _ingredientImages[item.name] != null;
    final isExpired = item.expiryDate != null &&
        item.expiryDate!.isBefore(DateTime.now());
    final isExpiringSoon = item.expiryDate != null &&
        !isExpired &&
        item.expiryDate!.difference(DateTime.now()).inDays <= 3;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? Image.network(
                    _ingredientImages[item.name]!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.shopping_basket,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      );
                    },
                  )
                : Icon(
                    Icons.shopping_basket,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
          ),
        ),
        title: Builder(
          builder: (context) {
            LocaleNotifier.of(context);
            return Text(
              TranslationService.translateIngredientSync(item.name),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            );
          },
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.unit ?? 'unité'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (item.expiryDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  isExpired
                      ? 'Expiré le ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}'
                      : isExpiringSoon
                          ? 'Expire le ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}'
                          : 'Expire le ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired
                        ? Theme.of(context).colorScheme.error
                        : isExpiringSoon
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isExpired || isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.quantity > 0)
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () => _useIngredient(item),
                tooltip: 'Utiliser',
              ),
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _editItem(item),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _deleteItem(item),
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}

// Classe pour ajouter/modifier un ingrédient
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
  final PantryService _pantryService = PantryService();
  final IngredientSuggestions _suggestions = IngredientSuggestions();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity.toString();
      _selectedUnit = widget.item!.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Nettoyer le nom avant de sauvegarder
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom d\'ingrédient')),
      );
      return;
    }
    
    // Nettoyer automatiquement le nom
    final name = IngredientCleaner.cleanIngredientName(rawName);
    
    // Si le nom a été nettoyé, informer l'utilisateur
    if (name != rawName && IngredientCleaner.isLikelyIncorrect(rawName)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nom corrigé automatiquement : "$rawName" → "$name"'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    }

    final quantityText = _quantityController.text.trim();
    double? quantity;
    if (quantityText.isNotEmpty) {
      final parsedQty = double.tryParse(quantityText);
      if (parsedQty == null || parsedQty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer une quantité valide (supérieure à 0)')),
        );
        return;
      }
      // Vérifier les limites pour prévenir les buffer overflows
      if (parsedQty > 999999.999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La quantité ne peut pas dépasser 999999.999')),
        );
        return;
      }
      if (parsedQty < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La quantité ne peut pas être négative')),
        );
        return;
      }
      quantity = parsedQty;
    } else {
      quantity = 1.0; // Valeur par défaut
    }

    try {
      if (widget.item == null) {
        // Ajouter un nouvel ingrédient
        final newItem = PantryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          quantity: quantity,
          unit: _selectedUnit ?? 'unité',
        );
        await _pantryService.addPantryItem(newItem);
      } else {
        // Modifier un ingrédient existant
        final updatedItem = PantryItem(
          id: widget.item!.id,
          name: name,
          quantity: quantity,
          unit: _selectedUnit ?? widget.item!.unit,
          expiryDate: widget.item!.expiryDate,
        );
        await _pantryService.updatePantryItem(updatedItem);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
              optionsBuilder: (TextEditingValue textEditingValue) {
                // Nettoyer la requête et obtenir des suggestions nettoyées
                final query = textEditingValue.text.trim();
                final cleanedQuery = IngredientCleaner.cleanIngredientName(query);
                
                // Si la requête a été nettoyée, suggérer la correction
                if (query.isNotEmpty && cleanedQuery != query && IngredientCleaner.isLikelyIncorrect(query)) {
                  final suggestions = IngredientSuggestions.getFilteredSuggestions(cleanedQuery);
                  return [cleanedQuery, ...suggestions];
                }
                
                // Sinon, suggestions normales
                return IngredientSuggestions.getFilteredSuggestions(query);
              },
              onSelected: (String selection) {
                // Nettoyer automatiquement la sélection
                final cleaned = IngredientCleaner.cleanIngredientName(selection);
                _nameController.text = cleaned;
                
                // Si le nom était incorrect, afficher une notification
                if (IngredientCleaner.isLikelyIncorrect(selection) && cleaned != selection) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nom corrigé : "$selection" → "$cleaned"'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  );
                }
                
                // Mettre à jour les suggestions d'unités
                setState(() {});
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                // Initialiser le controller avec la valeur existante si on modifie un item
                if (widget.item != null && textEditingController.text.isEmpty) {
                  textEditingController.text = _nameController.text;
                }
                
                return TextFormField(
                  controller: textEditingController,
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nom d\'ingrédient';
                    }
                    return null;
                  },
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: const Icon(Icons.numbers_outlined),
                hintText: 'Ex: 500',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final quantity = double.tryParse(value.trim());
                  if (quantity == null || quantity <= 0) {
                    return 'Veuillez entrer une quantité valide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              decoration: InputDecoration(
                labelText: 'Unité',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: const Icon(Icons.straighten_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'unité', child: Text('Unité')),
                DropdownMenuItem(value: 'g', child: Text('Grammes (g)')),
                DropdownMenuItem(value: 'kg', child: Text('Kilogrammes (kg)')),
                DropdownMenuItem(value: 'ml', child: Text('Millilitres (ml)')),
                DropdownMenuItem(value: 'l', child: Text('Litres (l)')),
                DropdownMenuItem(value: 'pièce', child: Text('Pièce(s)')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveItem,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.item == null ? 'Ajouter' : 'Modifier',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// Supprimer la classe dupliquée

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
