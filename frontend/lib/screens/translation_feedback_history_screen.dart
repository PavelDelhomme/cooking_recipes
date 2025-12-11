import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/translation_feedback.dart';
import '../services/translation_feedback_service.dart';
import '../services/translation_service.dart';

/// Écran pour afficher l'historique des modifications de traductions
class TranslationFeedbackHistoryScreen extends StatefulWidget {
  const TranslationFeedbackHistoryScreen({super.key});

  @override
  State<TranslationFeedbackHistoryScreen> createState() => _TranslationFeedbackHistoryScreenState();
}

class _TranslationFeedbackHistoryScreenState extends State<TranslationFeedbackHistoryScreen> {
  final TranslationFeedbackService _feedbackService = TranslationFeedbackService();
  List<TranslationFeedback> _feedbacks = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, instruction, ingredient, recipeName

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final feedbacks = await _feedbackService.getAllFeedbacks();
      setState(() {
        _feedbacks = feedbacks;
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

  List<TranslationFeedback> get _filteredFeedbacks {
    if (_selectedFilter == 'all') {
      return _feedbacks;
    }
    return _feedbacks.where((f) {
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
      case FeedbackType.quantity:
        return 'Quantité';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des traductions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedbacks,
            tooltip: 'Actualiser',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFeedbacks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.translate_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune traduction modifiée',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vos corrections de traductions apparaîtront ici',
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
                        Text(
                          feedback.context!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                // Traduction actuelle (problématique)
                _buildTranslationSection(
                  'Traduction actuelle (à améliorer)',
                  feedback.currentTranslation,
                  Icons.warning_amber_rounded,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                // Traduction suggérée
                if (feedback.suggestedTranslation != null)
                  _buildTranslationSection(
                    'Votre traduction améliorée',
                    feedback.suggestedTranslation!,
                    Icons.check_circle,
                    Colors.green,
                  ),
                const SizedBox(height: 12),
                // Langue cible
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.public,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Langue cible: ${feedback.targetLanguage.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
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

