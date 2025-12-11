import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/translation_feedback.dart';
import '../services/translation_feedback_service.dart';
import '../services/translation_service.dart';
import '../services/libretranslate_service.dart';
import '../services/http_client.dart';
import '../config/api_config.dart';

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
  bool _aiSuggestionRejected = false; // Indique si la suggestion IA a été rejetée
  final TextEditingController _suggestionController = TextEditingController();
  String? _selectedText; // Texte sélectionné dans currentTranslation
  final TextEditingController _selectedTextTranslationController = TextEditingController();

  @override
  void dispose() {
    _suggestionController.dispose();
    _selectedTextTranslationController.dispose();
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

      // Demander une suggestion à l'IA via l'API backend (qui utilise ML puis LibreTranslate)
      // Utiliser le type correct pour une meilleure traduction
      final type = widget.type == FeedbackType.ingredient
          ? 'ingredient'
          : widget.type == FeedbackType.instruction
              ? 'instruction'
              : widget.type == FeedbackType.recipeName
                  ? 'recipeName'
                  : widget.type == FeedbackType.unit
                      ? 'unit'
                      : widget.type == FeedbackType.quantity
                          ? 'quantity'
                          : widget.type == FeedbackType.summary
                              ? 'summary'
                              : 'instruction';
      
      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/translation/translate');
        final response = await HttpClient.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'text': widget.originalText,
            'source': 'en',
            'target': targetLanguage,
            'type': type,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['translatedText'] != null) {
            final suggestion = data['translatedText'] as String;
            
            if (mounted && suggestion.isNotEmpty) {
              setState(() {
                _aiSuggestion = suggestion;
                _isSuggesting = false;
              });
              return;
            }
          }
        }
      } catch (e) {
        print('⚠️ Erreur suggestion API, fallback LibreTranslate: $e');
      }
      
      // Fallback sur LibreTranslate direct si l'API échoue
      final suggestion = await _translateService.translate(
        widget.originalText,
        source: 'en',
        target: targetLanguage,
      );

      if (mounted && suggestion != null) {
        setState(() {
          _aiSuggestion = suggestion;
          _aiSuggestionRejected = false; // Réinitialiser le statut de rejet
          // Ne pas remplir automatiquement le champ, laisser l'utilisateur choisir
          // _suggestionController.text = suggestion;
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

  /// Enregistre un feedback sur la suggestion IA (rejetée ou acceptée)
  Future<void> _submitAISuggestionFeedback({required bool rejected}) async {
    if (_aiSuggestion == null) return;
    
    try {
      // Créer un feedback spécial pour indiquer que la suggestion IA était incorrecte
      final feedback = TranslationFeedback(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai_feedback_${rejected ? 'rejected' : 'accepted'}',
        recipeId: widget.recipeId,
        recipeTitle: widget.recipeTitle,
        type: widget.type,
        originalText: widget.originalText,
        currentTranslation: widget.currentTranslation,
        suggestedTranslation: rejected ? null : _aiSuggestion, // Si rejetée, pas de traduction suggérée
        targetLanguage: TranslationService.currentLanguageStatic,
        timestamp: DateTime.now(),
        context: widget.context != null 
            ? '${widget.context} [Suggestion IA ${rejected ? 'rejetée' : 'acceptée'}]'
            : '[Suggestion IA ${rejected ? 'rejetée' : 'acceptée'}]',
      );

      // Enregistrer le feedback (même si rejetée, on l'enregistre pour statistiques)
      await _feedbackService.submitFeedback(feedback);
      
      if (mounted && rejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feedback enregistré : la suggestion IA était incorrecte'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement du feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Enregistre que la traduction actuelle est correcte
  Future<void> _submitCurrentTranslationAsCorrect() async {
    setState(() => _isLoading = true);

    try {
      // Enregistrer un feedback indiquant que la traduction actuelle est correcte
      final feedback = TranslationFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipeId: widget.recipeId,
        recipeTitle: widget.recipeTitle,
        type: widget.type,
        originalText: widget.originalText,
        currentTranslation: widget.currentTranslation,
        suggestedTranslation: widget.currentTranslation, // La même que l'actuelle = elle est correcte
        targetLanguage: TranslationService.currentLanguageStatic,
        timestamp: DateTime.now(),
        context: widget.context != null 
            ? '${widget.context} [Traduction actuelle confirmée comme correcte]'
            : '[Traduction actuelle confirmée comme correcte]',
      );

      final success = await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          await TranslationFeedbackService.reloadCache();
          TranslationService().notifyListeners();
          
          Navigator.pop(context, {
            'success': true,
            'type': widget.type,
            'originalText': widget.originalText,
            'suggestedTranslation': feedback.suggestedTranslation,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Traduction actuelle confirmée comme correcte !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          Navigator.pop(context, {'success': false});
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

  /// Enregistre que le texte original doit être gardé (pas de traduction)
  Future<void> _submitOriginalAsTranslation() async {
    setState(() => _isLoading = true);

    try {
      // Enregistrer un feedback indiquant que le texte original doit être gardé
      final feedback = TranslationFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipeId: widget.recipeId,
        recipeTitle: widget.recipeTitle,
        type: widget.type,
        originalText: widget.originalText,
        currentTranslation: widget.currentTranslation,
        suggestedTranslation: widget.originalText, // Garder l'original = pas de traduction
        targetLanguage: TranslationService.currentLanguageStatic,
        timestamp: DateTime.now(),
        context: widget.context != null 
            ? '${widget.context} [Texte original conservé - pas de traduction nécessaire]'
            : '[Texte original conservé - pas de traduction nécessaire]',
      );

      final success = await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          await TranslationFeedbackService.reloadCache();
          TranslationService().notifyListeners();
          
          Navigator.pop(context, {
            'success': true,
            'type': widget.type,
            'originalText': widget.originalText,
            'suggestedTranslation': feedback.suggestedTranslation,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Texte original conservé (pas de traduction nécessaire) !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          Navigator.pop(context, {'success': false});
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
      // Si une suggestion IA a été générée et utilisée, enregistrer qu'elle était bonne
      if (_aiSuggestion != null && 
          _suggestionController.text.trim() == _aiSuggestion!.trim() &&
          !_aiSuggestionRejected) {
        await _submitAISuggestionFeedback(rejected: false);
      }
      
      // Si la suggestion IA a été rejetée, on a déjà enregistré le feedback
      // Sinon, enregistrer le feedback normal avec la traduction améliorée
      final feedback = TranslationFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipeId: widget.recipeId,
        recipeTitle: widget.recipeTitle,
        type: widget.type,
        originalText: widget.originalText,
        currentTranslation: widget.currentTranslation,
        suggestedTranslation: _suggestionController.text.trim(),
        selectedText: _selectedText,
        selectedTextTranslation: _selectedTextTranslationController.text.trim().isNotEmpty
            ? _selectedTextTranslationController.text.trim()
            : null,
        targetLanguage: TranslationService.currentLanguageStatic,
        timestamp: DateTime.now(),
        context: widget.context,
      );

      final success = await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          // Forcer le rechargement du cache des traductions apprises pour utilisation immédiate
          await TranslationFeedbackService.reloadCache();
          
          // Notifier immédiatement TranslationService pour mettre à jour l'affichage
          TranslationService().notifyListeners();
          
          // Retourner les informations de la traduction enregistrée pour rafraîchissement intelligent
          Navigator.pop(context, {
            'success': true,
            'type': widget.type,
            'originalText': widget.originalText,
            'suggestedTranslation': feedback.suggestedTranslation,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Merci ! Votre correction a été enregistrée et la traduction a été mise à jour.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          Navigator.pop(context, {'success': false});
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
      case FeedbackType.unit:
        return 'Unité de mesure';
      case FeedbackType.quantity:
        return 'Quantité';
      case FeedbackType.summary:
        return 'Description/Résumé';
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
                    onPressed: () => Navigator.pop(context, {'success': false}),
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
                    SelectableText(
                      widget.currentTranslation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      selectionControls: MaterialTextSelectionControls(),
                      onSelectionChanged: (selection, cause) {
                        if (selection.isValid && !selection.isCollapsed) {
                          final selected = widget.currentTranslation.substring(
                            selection.start,
                            selection.end,
                          );
                          setState(() {
                            _selectedText = selected.trim();
                          });
                        } else {
                          setState(() {
                            _selectedText = null;
                            _selectedTextTranslationController.clear();
                          });
                        }
                      },
                    ),
                    if (_selectedText != null && _selectedText!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.highlight,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Texte sélectionné:',
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
                              '"$_selectedText"',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurface,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _selectedTextTranslationController,
                              decoration: InputDecoration(
                                labelText: 'Traduction alternative pour ce mot/groupe de mots',
                                hintText: 'Ex: si "cuire" devrait être "faire cuire"...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                prefixIcon: const Icon(Icons.translate),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '💡 Cette traduction sera apprise pour ce mot/groupe de mots dans toutes les recettes',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      maxLines: null,
                      minLines: 3,
                      textInputAction: TextInputAction.newline,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Suggestion IA générée',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  _aiSuggestion!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Boutons sur deux lignes
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ligne 1 : Utiliser la suggestion
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _suggestionController.text = _aiSuggestion!;
                                _aiSuggestionRejected = false;
                              });
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Utiliser cette suggestion'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Ligne 2 : Rejeter la suggestion
                          OutlinedButton.icon(
                            onPressed: _aiSuggestionRejected ? null : () async {
                              setState(() {
                                _aiSuggestionRejected = true;
                              });
                              
                              // Enregistrer le feedback que la suggestion IA était incorrecte
                              await _submitAISuggestionFeedback(rejected: true);
                            },
                            icon: Icon(
                              _aiSuggestionRejected ? Icons.close : Icons.thumb_down_outlined,
                              size: 18,
                            ),
                            label: Text(_aiSuggestionRejected ? 'Suggestion rejetée' : 'Rejeter cette suggestion'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              foregroundColor: _aiSuggestionRejected 
                                  ? Colors.grey 
                                  : Theme.of(context).colorScheme.error,
                              side: BorderSide(
                                color: _aiSuggestionRejected 
                                    ? Colors.grey 
                                    : Theme.of(context).colorScheme.error,
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Options rapides : La traduction actuelle est correcte ou garder l'original
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Option 1 : La traduction actuelle est correcte
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _submitCurrentTranslationAsCorrect(),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('La traduction actuelle est correcte'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      foregroundColor: Colors.green[700],
                      side: BorderSide(
                        color: Colors.green[700]!,
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Option 2 : Garder le texte original (même si autre langue)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _submitOriginalAsTranslation(),
                    icon: const Icon(Icons.language, size: 18),
                    label: const Text('Garder le texte original (pas de traduction)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context, {'success': false}),
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

