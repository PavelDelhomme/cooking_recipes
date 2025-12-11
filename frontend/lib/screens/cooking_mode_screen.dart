import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../services/translation_service.dart';
import '../widgets/translation_builder.dart';
import 'dart:async';

/// Écran de mode cuisson guidé étape par étape
class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;

  const CookingModeScreen({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int _currentStep = 0; // 0 = préparation ingrédients, 1+ = instructions
  final Map<String, bool> _ingredientsChecked = {};
  final Map<int, bool> _instructionsCompleted = {};
  Timer? _cookingTimer;
  int _timerSeconds = 0;
  bool _timerRunning = false;
  String? _timerLabel;

  @override
  void initState() {
    super.initState();
    // Initialiser tous les ingrédients comme non cochés
    for (var ingredient in widget.recipe.ingredients) {
      _ingredientsChecked[ingredient.name] = false;
    }
    // Initialiser toutes les instructions comme non complétées
    for (int i = 0; i < widget.recipe.instructions.length; i++) {
      _instructionsCompleted[i] = false;
    }
  }

  @override
  void dispose() {
    _cookingTimer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes, String label) {
    _timerSeconds = minutes * 60;
    _timerLabel = label;
    _timerRunning = true;
    _cookingTimer?.cancel();
    _cookingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        _stopTimer();
        // Notification sonore et visuelle
        HapticFeedback.heavyImpact();
        _showTimerFinishedDialog(label);
      }
    });
  }

  void _stopTimer() {
    _cookingTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _timerSeconds = 0;
      _timerLabel = null;
    });
  }

  void _showTimerFinishedDialog(String label) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_off, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            const Expanded(child: Text('Timer terminé !')),
          ],
        ),
        content: Text('Le temps de cuisson pour "$label" est terminé.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool get _allIngredientsReady {
    if (widget.recipe.ingredients.isEmpty) return true;
    return _ingredientsChecked.values.every((checked) => checked);
  }

  void _nextStep() {
    if (_currentStep == 0 && !_allIngredientsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez préparer tous les ingrédients avant de continuer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_currentStep < widget.recipe.instructions.length) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslationBuilder(
          builder: (context) => Text(
            TranslationService.translateRecipeNameSync(widget.recipe.title),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        actions: [
          if (_timerRunning)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimer(_timerSeconds),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.stop, size: 18),
                    onPressed: _stopTimer,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Arrêter le timer',
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _currentStep == 0
                        ? _ingredientsChecked.values.where((v) => v).length / 
                          (widget.recipe.ingredients.isEmpty ? 1 : widget.recipe.ingredients.length)
                        : (_currentStep) / (widget.recipe.instructions.length + 1),
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _currentStep == 0
                      ? 'Préparation'
                      : 'Étape $_currentStep/${widget.recipe.instructions.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu de l'étape
          Expanded(
            child: _currentStep == 0
                ? _buildIngredientsStep()
                : _buildInstructionStep(_currentStep - 1),
          ),
          
          // Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentStep > 0 ? _previousStep : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Précédent'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  if (_currentStep == 0)
                    ElevatedButton.icon(
                      onPressed: _allIngredientsReady ? _nextStep : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Commencer la cuisson'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  else if (_currentStep < widget.recipe.instructions.length)
                    ElevatedButton.icon(
                      onPressed: _nextStep,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Suivant'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.celebration, color: Colors.orange, size: 32),
                                SizedBox(width: 12),
                                Expanded(child: Text('Félicitations !')),
                              ],
                            ),
                            content: const Text('Vous avez terminé la recette ! Bon appétit ! 🎉'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Fermer le dialog
                                  Navigator.pop(context); // Fermer le mode cuisson
                                },
                                child: const Text('Terminer'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Terminer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_basket,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Préparation des ingrédients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cochez chaque ingrédient une fois préparé',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...widget.recipe.ingredients.asMap().entries.map((entry) {
            final index = entry.key;
            final ingredient = entry.value;
            final isChecked = _ingredientsChecked[ingredient.name] ?? false;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isChecked ? 2 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isChecked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: isChecked ? 2 : 1,
                ),
              ),
              child: CheckboxListTile(
                value: isChecked,
                onChanged: (checked) {
                  setState(() {
                    _ingredientsChecked[ingredient.name] = checked ?? false;
                  });
                  if (checked == true) {
                    HapticFeedback.lightImpact();
                  }
                },
                title: TranslationBuilder(
                  builder: (context) => Text(
                    TranslationService.translateIngredientSync(ingredient.name),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                subtitle: ingredient.quantity != null || ingredient.unit != null
                    ? Text(
                        '${ingredient.quantity?.toStringAsFixed(ingredient.quantity! % 1 == 0 ? 0 : 1) ?? ''} ${ingredient.unit ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                secondary: Icon(
                  isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isChecked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int instructionIndex) {
    if (instructionIndex >= widget.recipe.instructions.length) {
      return const Center(child: Text('Instruction non trouvée'));
    }

    final instruction = widget.recipe.instructions[instructionIndex];
    final isCompleted = _instructionsCompleted[instructionIndex] ?? false;
    
    // Détecter les temps de cuisson dans l'instruction
    final timePattern = RegExp(r'(\d+)\s*(?:minutes?|min|m|heures?|h)');
    final timeMatches = timePattern.allMatches(instruction);
    List<Map<String, dynamic>> timers = [];
    for (var match in timeMatches) {
      final timeStr = match.group(1);
      final unit = match.group(0)?.contains('heure') == true ? 'heure' : 'minute';
      if (timeStr != null) {
        final minutes = unit == 'heure' ? int.parse(timeStr) * 60 : int.parse(timeStr);
        timers.add({
          'minutes': minutes,
          'label': 'Étape ${instructionIndex + 1}',
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de l'étape
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        '${instructionIndex + 1}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Étape ${instructionIndex + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (widget.recipe.instructions.length > 1)
                          Text(
                            '${instructionIndex + 1} sur ${widget.recipe.instructions.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isCompleted,
                    onChanged: (checked) {
                      setState(() {
                        _instructionsCompleted[instructionIndex] = checked ?? false;
                      });
                      if (checked == true) {
                        HapticFeedback.mediumImpact();
                      }
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Instruction
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TranslationBuilder(
                builder: (context) => Text(
                  TranslationService.cleanAndTranslate(instruction),
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ),
          
          // Timers si disponibles
          if (timers.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Timers disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...timers.map((timer) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  Icons.timer,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('${timer['minutes']} minutes'),
                subtitle: Text(timer['label']),
                trailing: _timerRunning && _timerLabel == timer['label']
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _startTimer(timer['minutes'], timer['label']),
                        tooltip: 'Démarrer le timer',
                      ),
              ),
            )),
          ],
          
          // Informations de temps si disponibles
          if (widget.recipe.readyInMinutes != null || 
              widget.recipe.prepTimeMinutes != null ||
              widget.recipe.cookTimeMinutes != null) ...[
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temps estimés',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (widget.recipe.prepTimeMinutes != null)
                          _buildTimeChip(
                            Icons.restaurant_outlined,
                            'Préparation',
                            '${widget.recipe.prepTimeMinutes} min',
                          ),
                        if (widget.recipe.cookTimeMinutes != null)
                          _buildTimeChip(
                            Icons.local_fire_department_outlined,
                            'Cuisson',
                            '${widget.recipe.cookTimeMinutes} min',
                          ),
                        if (widget.recipe.readyInMinutes != null)
                          _buildTimeChip(
                            Icons.timer_outlined,
                            'Total',
                            '${widget.recipe.readyInMinutes} min',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

