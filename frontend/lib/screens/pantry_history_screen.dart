import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pantry_history_item.dart';
import '../services/pantry_history_service.dart';

class PantryHistoryScreen extends StatefulWidget {
  const PantryHistoryScreen({super.key});

  @override
  State<PantryHistoryScreen> createState() => _PantryHistoryScreenState();
}

class _PantryHistoryScreenState extends State<PantryHistoryScreen> {
  final PantryHistoryService _historyService = PantryHistoryService();
  List<PantryHistoryItem> _history = [];
  bool _isLoading = true;
  String _filterText = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    List<PantryHistoryItem> history;
    
    if (_filterStartDate != null && _filterEndDate != null) {
      history = await _historyService.getHistoryForPeriod(_filterStartDate!, _filterEndDate!);
    } else if (_filterText.isNotEmpty) {
      history = await _historyService.getHistoryByIngredient(_filterText);
    } else {
      history = await _historyService.getHistory();
    }
    
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider l\'historique'),
        content: const Text('Voulez-vous vraiment supprimer tout l\'historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historique vidé')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique du placard'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearHistory,
              tooltip: 'Vider l\'historique',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Rechercher un ingrédient',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _filterText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _filterText = '');
                              _loadHistory();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() => _filterText = value);
                    _loadHistory();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filterStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            locale: const Locale('fr', 'FR'),
                          );
                          if (picked != null) {
                            setState(() => _filterStartDate = picked);
                            _loadHistory();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _filterStartDate != null
                              ? DateFormat('dd/MM/yyyy').format(_filterStartDate!)
                              : 'Date début',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filterEndDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            locale: const Locale('fr', 'FR'),
                          );
                          if (picked != null) {
                            setState(() => _filterEndDate = picked);
                            _loadHistory();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _filterEndDate != null
                              ? DateFormat('dd/MM/yyyy').format(_filterEndDate!)
                              : 'Date fin',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (_filterStartDate != null || _filterEndDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _filterStartDate = null;
                            _filterEndDate = null;
                          });
                          _loadHistory();
                        },
                        tooltip: 'Effacer les filtres de date',
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Liste de l'historique
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
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
                                  Icons.history,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Aucun historique',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'L\'historique des ingrédients utilisés apparaîtra ici',
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
                        itemCount: _history.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          final isToday = item.usedDate.year == DateTime.now().year &&
                              item.usedDate.month == DateTime.now().month &&
                              item.usedDate.day == DateTime.now().day;
                          final isYesterday = item.usedDate.year == DateTime.now().year &&
                              item.usedDate.month == DateTime.now().month &&
                              item.usedDate.day == DateTime.now().day - 1;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: isToday
                                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
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
                                  color: isToday
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.remove_circle,
                                  color: isToday
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                              title: Text(
                                item.ingredientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
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
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isToday
                                        ? 'Aujourd\'hui à ${DateFormat('HH:mm').format(item.usedDate)}'
                                        : isYesterday
                                            ? 'Hier à ${DateFormat('HH:mm').format(item.usedDate)}'
                                            : DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR')
                                                .format(item.usedDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (item.reason != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.reason!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () async {
                                  await _historyService.removeHistoryItem(item.id);
                                  _loadHistory();
                                },
                                tooltip: 'Supprimer',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

