import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';

class AddMealPlanDialog extends StatefulWidget {
  final Recipe recipe;
  final DateTime initialDate;
  final String initialMealType;

  const AddMealPlanDialog({
    super.key,
    required this.recipe,
    required this.initialDate,
    this.initialMealType = 'lunch',
  });

  @override
  State<AddMealPlanDialog> createState() => _AddMealPlanDialogState();
}

class _AddMealPlanDialogState extends State<AddMealPlanDialog> {
  late bool _isRecurring;
  late DateTime _selectedDate;
  late String _selectedMealType;
  int? _numberOfWeeks;
  int? _dayOfWeek;
  DateTime? _endDate;
  bool _isIndefinite = false;

  @override
  void initState() {
    super.initState();
    _isRecurring = false;
    _selectedDate = widget.initialDate;
    _selectedMealType = widget.initialMealType;
    _dayOfWeek = _selectedDate.weekday % 7;
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    return days[dayOfWeek];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter au planning'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Choix entre repas unique ou récurrent
            const Text(
              'Type d\'ajout:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              title: const Text('Repas unique'),
              subtitle: const Text('Pour une date spécifique'),
              value: false,
              groupValue: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value!;
                  if (!_isRecurring) {
                    _numberOfWeeks = null;
                    _endDate = null;
                    _isIndefinite = false;
                  }
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('Repas récurrent'),
              subtitle: const Text('Se répète chaque semaine'),
              value: true,
              groupValue: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value!;
                  if (_isRecurring) {
                    _dayOfWeek = _selectedDate.weekday % 7;
                    if (!_isIndefinite) {
                      _numberOfWeeks = 4;
                      _endDate = _selectedDate.add(const Duration(days: 21));
                    }
                  }
                });
              },
            ),
            const Divider(height: 24),
            
            // Configuration selon le type
            if (!_isRecurring) ...[
              // Repas unique
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ),
            ] else ...[
              // Repas récurrent
              ListTile(
                title: const Text('Jour de la semaine'),
                subtitle: Text(_getDayName(_dayOfWeek ?? 0)),
                trailing: DropdownButton<int>(
                  value: _dayOfWeek ?? (_selectedDate.weekday % 7),
                  items: List.generate(7, (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text(_getDayName(index)),
                    );
                  }),
                  onChanged: (value) {
                    setState(() => _dayOfWeek = value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Date de début'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _dayOfWeek = picked.weekday % 7;
                        if (!_isIndefinite && _numberOfWeeks != null) {
                          _endDate = _selectedDate.add(Duration(days: (_numberOfWeeks! - 1) * 7));
                        }
                      });
                    }
                  },
                ),
              ),
              if (!_isIndefinite) ...[
                ListTile(
                  title: const Text('Nombre de semaines'),
                  subtitle: Slider(
                    value: (_numberOfWeeks ?? 4).toDouble(),
                    min: 1,
                    max: 52,
                    divisions: 51,
                    label: '${_numberOfWeeks ?? 4} semaines',
                    onChanged: (value) {
                      setState(() {
                        _numberOfWeeks = value.toInt();
                        _endDate = _selectedDate.add(Duration(days: (_numberOfWeeks! - 1) * 7));
                      });
                    },
                  ),
                  trailing: Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_numberOfWeeks ?? 4}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
              CheckboxListTile(
                title: const Text('Sans date de fin (indéfini)'),
                value: _isIndefinite,
                onChanged: (value) {
                  setState(() {
                    _isIndefinite = value ?? false;
                    if (_isIndefinite) {
                      _numberOfWeeks = null;
                      _endDate = null;
                    } else {
                      _numberOfWeeks = 4;
                      _endDate = _selectedDate.add(const Duration(days: 21));
                    }
                  });
                },
              ),
            ],
            
            const Divider(height: 24),
            const Text(
              'Type de repas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            RadioListTile<String>(
              title: const Text('Petit-déjeuner'),
              value: 'breakfast',
              groupValue: _selectedMealType,
              onChanged: (value) {
                setState(() => _selectedMealType = value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Déjeuner'),
              value: 'lunch',
              groupValue: _selectedMealType,
              onChanged: (value) {
                setState(() => _selectedMealType = value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dîner'),
              value: 'dinner',
              groupValue: _selectedMealType,
              onChanged: (value) {
                setState(() => _selectedMealType = value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Collation'),
              value: 'snack',
              groupValue: _selectedMealType,
              onChanged: (value) {
                setState(() => _selectedMealType = value!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'isRecurring': _isRecurring,
              'date': _selectedDate,
              'mealType': _selectedMealType,
              'dayOfWeek': _dayOfWeek,
              'numberOfWeeks': _isIndefinite ? null : _numberOfWeeks,
              'endDate': _isIndefinite ? null : _endDate,
            });
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

