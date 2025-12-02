import 'package:flutter/material.dart';
import '../models/meal_plan_config.dart';
import '../services/meal_plan_config_service.dart';

class MealPlanConfigScreen extends StatefulWidget {
  const MealPlanConfigScreen({super.key});

  @override
  State<MealPlanConfigScreen> createState() => _MealPlanConfigScreenState();
}

class _MealPlanConfigScreenState extends State<MealPlanConfigScreen> {
  final MealPlanConfigService _configService = MealPlanConfigService();
  MealPlanConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final config = await _configService.getConfig();
    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    if (_config != null) {
      await _configService.saveConfig(_config!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration enregistrée')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _config == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration du planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Planification automatique',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Activer la planification automatique'),
                    subtitle: const Text(
                      'Permet au système de générer automatiquement des repas',
                    ),
                    value: _config!.autoPlanEnabled,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(autoPlanEnabled: value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Paramètres par défaut',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Nombre de jours par défaut'),
                    subtitle: Text('${_config!.defaultDays} jours'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _config!.defaultDays > 1
                              ? () {
                                  setState(() {
                                    _config = _config!.copyWith(
                                      defaultDays: _config!.defaultDays - 1,
                                    );
                                  });
                                }
                              : null,
                        ),
                        Text('${_config!.defaultDays}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _config = _config!.copyWith(
                                defaultDays: _config!.defaultDays + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Type de repas par défaut'),
                    subtitle: Text(_getMealTypeLabel(_config!.defaultMealType)),
                    trailing: DropdownButton<String>(
                      value: _config!.defaultMealType,
                      items: const [
                        DropdownMenuItem(
                          value: 'breakfast',
                          child: Text('Petit-déjeuner'),
                        ),
                        DropdownMenuItem(
                          value: 'lunch',
                          child: Text('Déjeuner'),
                        ),
                        DropdownMenuItem(
                          value: 'dinner',
                          child: Text('Dîner'),
                        ),
                        DropdownMenuItem(
                          value: 'snack',
                          child: Text('Collation'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _config = _config!.copyWith(defaultMealType: value);
                          });
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Nombre maximum de recettes par semaine'),
                    subtitle: Text('${_config!.maxRecipesPerWeek} recettes'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _config!.maxRecipesPerWeek > 1
                              ? () {
                                  setState(() {
                                    _config = _config!.copyWith(
                                      maxRecipesPerWeek: _config!.maxRecipesPerWeek - 1,
                                    );
                                  });
                                }
                              : null,
                        ),
                        Text('${_config!.maxRecipesPerWeek}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _config = _config!.copyWith(
                                maxRecipesPerWeek: _config!.maxRecipesPerWeek + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Préférences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Privilégier les ingrédients du placard'),
                    subtitle: const Text(
                      'Le système préférera les recettes utilisant vos ingrédients disponibles',
                    ),
                    value: _config!.preferPantryIngredients,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(preferPantryIngredients: value);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Éviter les répétitions de recettes'),
                    subtitle: const Text(
                      'Le système évitera de proposer la même recette plusieurs fois',
                    ),
                    value: _config!.avoidRepeatingRecipes,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(avoidRepeatingRecipes: value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _saveConfig,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer la configuration'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getMealTypeLabel(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Petit-déjeuner';
      case 'lunch':
        return 'Déjeuner';
      case 'dinner':
        return 'Dîner';
      case 'snack':
        return 'Collation';
      default:
        return mealType;
    }
  }
}

