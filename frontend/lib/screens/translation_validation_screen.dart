import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/translation_feedback.dart';
import '../services/translation_feedback_service.dart';
import '../services/auth_service.dart';

/// Écran pour valider les traductions (admin uniquement)
class TranslationValidationScreen extends StatefulWidget {
  const TranslationValidationScreen({super.key});

  @override
  State<TranslationValidationScreen> createState() => _TranslationValidationScreenState();
}

class _TranslationValidationScreenState extends State<TranslationValidationScreen> {
  final TranslationFeedbackService _feedbackService = TranslationFeedbackService();
  final AuthService _authService = AuthService();
  List<TranslationFeedback> _pendingFeedbacks = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    setState(() => _isLoading = true);
    try {
      // Vérifier si admin (pour afficher les actions admin)
      final admin = await _feedbackService.isAdmin();
      setState(() {
        _isAdmin = admin;
        _isLoading = false;
      });

      // Charger les feedbacks pour tous les utilisateurs
      await _loadPendingFeedbacks();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPendingFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final feedbacks = await _feedbackService.getPendingFeedbacks();
      setState(() {
        _pendingFeedbacks = feedbacks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveFeedback(TranslationFeedback feedback) async {
    try {
      final success = await _feedbackService.approveFeedback(feedback.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Traduction approuvée et modèle ML entraîné'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadPendingFeedbacks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectFeedback(TranslationFeedback feedback) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter cette traduction ?'),
        content: const Text('Cette traduction ne sera pas utilisée pour entraîner le modèle ML.'),
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
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _feedbackService.rejectFeedback(feedback.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Traduction rejetée'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          await _loadPendingFeedbacks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _retrainML() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réentraîner le modèle ML ?'),
        content: const Text('Le modèle ML sera réentraîné avec tous les feedbacks approuvés. Cela peut prendre quelques instants.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réentraîner'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _feedbackService.retrainML();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Réentraînement démarré en arrière-plan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<TranslationFeedback> get _filteredFeedbacks {
    if (_selectedFilter == 'all') {
      return _pendingFeedbacks;
    }
    return _pendingFeedbacks.where((f) {
      return f.type.toString().split('.').last == _selectedFilter;
    }).toList();
  }

  String _getTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.instruction:
        return 'Instruction';
      case FeedbackType.ingredient:
        return 'Ingrédient';
      case FeedbackType.recipeName:
        return 'Nom de recette';
      case FeedbackType.unit:
        return 'Unité de mesure';
      case FeedbackType.summary:
        return 'Description/Résumé';
    }
  }

  IconData _getTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.instruction:
        return Icons.list_alt;
      case FeedbackType.ingredient:
        return Icons.shopping_basket;
      case FeedbackType.recipeName:
        return Icons.restaurant_menu;
      case FeedbackType.unit:
        return Icons.straighten;
      case FeedbackType.quantity:
        return Icons.numbers;
      case FeedbackType.summary:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Validation des traductions')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // L'écran est maintenant accessible à tous les utilisateurs
    // _isAdmin est utilisé uniquement pour afficher les actions admin supplémentaires

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des traductions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingFeedbacks,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: _retrainML,
            tooltip: 'Réentraîner le modèle ML',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Filtrer:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Tous'),
                        const SizedBox(width: 8),
                        _buildFilterChip('instruction', 'Instructions'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ingredient', 'Ingrédients'),
                        const SizedBox(width: 8),
                        _buildFilterChip('recipeName', 'Noms'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Liste des feedbacks
          Expanded(
            child: _filteredFeedbacks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune traduction en attente',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toutes les traductions ont été validées !',
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
                    itemCount: _filteredFeedbacks.length,
                    itemBuilder: (context, index) {
                      final feedback = _filteredFeedbacks[index];
                      return _buildFeedbackCard(feedback);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildFeedbackCard(TranslationFeedback feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTypeIcon(feedback.type),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          feedback.recipeTitle,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'En attente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeLabel(feedback.type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(feedback.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contexte si disponible
                if (feedback.context != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feedback.context!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Texte original
                _buildTranslationSection(
                  'Texte original (anglais)',
                  feedback.originalText,
                  Icons.language,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                // Traduction actuelle
                _buildTranslationSection(
                  'Traduction actuelle',
                  feedback.currentTranslation,
                  Icons.warning_amber_rounded,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                // Traduction suggérée
                if (feedback.suggestedTranslation != null)
                  _buildTranslationSection(
                    'Traduction suggérée',
                    feedback.suggestedTranslation!,
                    Icons.check_circle,
                    Colors.green,
                  ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _rejectFeedback(feedback),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _approveFeedback(feedback),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSection(String title, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
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

