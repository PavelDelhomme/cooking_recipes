import 'package:flutter/material.dart';
import '../models/pantry_config.dart';
import '../services/pantry_config_service.dart';

class PantryConfigScreen extends StatefulWidget {
  const PantryConfigScreen({super.key});

  @override
  State<PantryConfigScreen> createState() => _PantryConfigScreenState();
}

class _PantryConfigScreenState extends State<PantryConfigScreen> {
  final PantryConfigService _configService = PantryConfigService();
  PantryConfig? _config;
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
        title: const Text('Configuration du placard'),
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
          // Notifications et alertes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Notifications et alertes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Activer les notifications d\'expiration'),
                    subtitle: const Text(
                      'Recevoir des notifications pour les ingrédients qui expirent bientôt',
                    ),
                    value: _config!.enableExpiryNotifications,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(enableExpiryNotifications: value);
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Jours avant expiration pour notifier'),
                    subtitle: Text('${_config!.daysBeforeExpiryNotification} jours'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _config!.daysBeforeExpiryNotification > 1
                              ? () {
                                  setState(() {
                                    _config = _config!.copyWith(
                                      daysBeforeExpiryNotification: _config!.daysBeforeExpiryNotification - 1,
                                    );
                                  });
                                }
                              : null,
                        ),
                        Text('${_config!.daysBeforeExpiryNotification}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _config = _config!.copyWith(
                                daysBeforeExpiryNotification: _config!.daysBeforeExpiryNotification + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Afficher les avertissements d\'expiration'),
                    subtitle: const Text(
                      'Mettre en évidence visuellement les ingrédients qui expirent bientôt',
                    ),
                    value: _config!.showExpiryWarnings,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(showExpiryWarnings: value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Affichage
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Affichage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Afficher les dates d\'expiration'),
                    subtitle: const Text(
                      'Afficher la date d\'expiration pour chaque ingrédient',
                    ),
                    value: _config!.showExpiryDates,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(showExpiryDates: value);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Mettre en évidence les items qui expirent'),
                    subtitle: const Text(
                      'Colorer différemment les ingrédients qui expirent bientôt',
                    ),
                    value: _config!.highlightExpiringItems,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(highlightExpiringItems: value);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Afficher les images des ingrédients'),
                    subtitle: const Text(
                      'Afficher les images des ingrédients dans la liste',
                    ),
                    value: _config!.showIngredientImages,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(showIngredientImages: value);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Trier automatiquement par date d\'expiration'),
                    subtitle: const Text(
                      'Les ingrédients qui expirent bientôt apparaissent en premier',
                    ),
                    value: _config!.autoSortByExpiry,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(autoSortByExpiry: value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Suggestions et recommandations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Suggestions et recommandations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Suggérer des recettes pour les items qui expirent'),
                    subtitle: const Text(
                      'Proposer des recettes utilisant les ingrédients qui expirent bientôt',
                    ),
                    value: _config!.suggestRecipesForExpiringItems,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(suggestRecipesForExpiringItems: value);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Ajouter automatiquement à la liste de courses'),
                    subtitle: const Text(
                      'Ajouter automatiquement les ingrédients expirés à la liste de courses',
                    ),
                    value: _config!.autoAddToShoppingList,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(autoAddToShoppingList: value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Gestion automatique
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_delete,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Gestion automatique',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Supprimer automatiquement les items expirés'),
                    subtitle: const Text(
                      'Supprimer automatiquement les ingrédients expirés après un certain délai',
                    ),
                    value: _config!.autoRemoveExpiredItems,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(autoRemoveExpiredItems: value);
                      });
                    },
                  ),
                  if (_config!.autoRemoveExpiredItems) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Jours avant suppression automatique'),
                      subtitle: Text('${_config!.daysToKeepExpiredItems} jours'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _config!.daysToKeepExpiredItems > 1
                                ? () {
                                    setState(() {
                                      _config = _config!.copyWith(
                                        daysToKeepExpiredItems: _config!.daysToKeepExpiredItems - 1,
                                      );
                                    });
                                  }
                                : null,
                          ),
                          Text('${_config!.daysToKeepExpiredItems}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _config = _config!.copyWith(
                                  daysToKeepExpiredItems: _config!.daysToKeepExpiredItems + 1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Historique
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Historique',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Suivre l\'historique'),
                    subtitle: const Text(
                      'Enregistrer l\'historique des modifications du placard',
                    ),
                    value: _config!.trackHistory,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(trackHistory: value);
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Afficher le bouton historique'),
                    subtitle: const Text(
                      'Afficher le bouton pour accéder à l\'historique du placard',
                    ),
                    value: _config!.showHistoryButton,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(showHistoryButton: value);
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
}

