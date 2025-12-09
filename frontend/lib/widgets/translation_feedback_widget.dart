import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/translation_feedback.dart';
import '../services/translation_feedback_service.dart';
import '../services/translation_service.dart';
import '../services/libretranslate_service.dart';

/// Widget pour signaler et améliorer une traduction
class TranslationFeedbackWidget extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;
  final FeedbackType type;
  final String originalText;
  final String currentTranslation;
  final String? context; // Ex: "Instruction 3", "Ingredient 2"

  const TranslationFeedbackWidget({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
    required this.type,
    required this.originalText,
    required this.currentTranslation,
    this.context,
  });

  @override
  State<TranslationFeedbackWidget> createState() => _TranslationFeedbackWidgetState();
}

class _TranslationFeedbackWidgetState extends State<TranslationFeedbackWidget> {
  final TranslationFeedbackService _feedbackService = TranslationFeedbackService();
  final LibreTranslateService _translateService = LibreTranslateService();
  bool _isLoading = false;
  bool _isSuggesting = false;
  String? _aiSuggestion;
  final TextEditingController _suggestionController = TextEditingController();

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _getAISuggestion() async {
    setState(() {
      _isSuggesting = true;
      _aiSuggestion = null;
    });

    try {
      final targetLanguage = TranslationService.currentLanguageStatic;
      if (targetLanguage == 'en') {
        setState(() {
          _isSuggesting = false;
        });
        return;
      }

      // Demander une suggestion à l'IA via LibreTranslate
      final suggestion = await _translateService.translate(
        widget.originalText,
        source: 'en',
        target: targetLanguage,
      );

      if (mounted && suggestion != null) {
        setState(() {
          _aiSuggestion = suggestion;
          _suggestionController.text = suggestion;
          _isSuggesting = false;
        });
      } else {
        setState(() {
          _isSuggesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSuggesting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération de la suggestion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_suggestionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez proposer une traduction améliorée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final feedback = TranslationFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipeId: widget.recipeId,
        recipeTitle: widget.recipeTitle,
        type: widget.type,
        originalText: widget.originalText,
        currentTranslation: widget.currentTranslation,
        suggestedTranslation: _suggestionController.text.trim(),
        targetLanguage: TranslationService.currentLanguageStatic,
        timestamp: DateTime.now(),
        context: widget.context,
      );

      final success = await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Merci ! Votre correction a été enregistrée et améliorera les traductions futures.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de l\'enregistrement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTypeLabel() {
    switch (widget.type) {
      case FeedbackType.instruction:
        return 'Instruction';
      case FeedbackType.ingredient:
        return 'Ingrédient';
      case FeedbackType.recipeName:
        return 'Nom de recette';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.translate,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Améliorer la traduction',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Texte original
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Texte original (anglais)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.originalText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Traduction actuelle (problématique)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Traduction actuelle (à améliorer)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.currentTranslation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Suggestion améliorée
              Text(
                'Votre traduction améliorée:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              // Champ de texte avec bouton IA
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _suggestionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Entrez votre traduction améliorée...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Obtenir une suggestion IA',
                    child: IconButton(
                      icon: _isSuggesting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.auto_awesome,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      onPressed: _isSuggesting ? null : _getAISuggestion,
                    ),
                  ),
                ],
              ),
              
              // Afficher la suggestion IA si disponible
              if (_aiSuggestion != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Suggestion IA générée',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _suggestionController.text = _aiSuggestion!;
                        },
                        child: const Text('Utiliser'),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitFeedback,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

