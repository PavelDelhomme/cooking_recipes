import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/translation_feedback.dart';
import '../services/translation_feedback_service.dart';
import '../services/translation_service.dart';
import '../services/http_client.dart';
import '../config/api_config.dart';
import 'dart:convert';

/// Widget pour améliorer la séparation et la traduction des instructions
class InstructionsSeparationDialog extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;
  final String originalInstructionsText;
  final List<String> currentInstructions;

  const InstructionsSeparationDialog({
    required this.recipeId,
    required this.recipeTitle,
    required this.originalInstructionsText,
    required this.currentInstructions,
  });

  @override
  State<InstructionsSeparationDialog> createState() => _InstructionsSeparationDialogState();
}

class _InstructionsSeparationDialogState extends State<InstructionsSeparationDialog> {
  final TranslationFeedbackService _feedbackService = TranslationFeedbackService();
  final TextEditingController _originalTextController = TextEditingController();
  final TextEditingController _separatedInstructionsController = TextEditingController();
  bool _isLoading = false;
  List<String> _separatedInstructions = [];
  List<TextEditingController> _translationControllers = [];

  @override
  void initState() {
    super.initState();
    _originalTextController.text = widget.originalInstructionsText;
    // Initialiser avec les instructions actuelles
    _separatedInstructionsController.text = widget.currentInstructions.join('\n\n');
    _separatedInstructions = List<String>.from(widget.currentInstructions);
    _translationControllers = _separatedInstructions.map((_) => TextEditingController()).toList();
    for (int i = 0; i < _separatedInstructions.length; i++) {
      _translationControllers[i].text = _separatedInstructions[i];
    }
  }

  @override
  void dispose() {
    _originalTextController.dispose();
    _separatedInstructionsController.dispose();
    for (var controller in _translationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _parseSeparatedInstructions() {
    final text = _separatedInstructionsController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _separatedInstructions = [];
        for (var controller in _translationControllers) {
          controller.dispose();
        }
        _translationControllers = [];
      });
      return;
    }

    // Diviser par lignes vides ou retours à la ligne doubles
    final instructions = text
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Si pas de lignes vides, diviser par simples retours à la ligne
    if (instructions.length == 1) {
      final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      setState(() {
        _separatedInstructions = lines;
        // Créer les controllers pour les traductions
        for (var controller in _translationControllers) {
          controller.dispose();
        }
        _translationControllers = _separatedInstructions.map((instruction) {
          final controller = TextEditingController();
          // Traduire automatiquement chaque instruction
          controller.text = TranslationService.translateInstructionSync(instruction);
          return controller;
        }).toList();
      });
    } else {
      setState(() {
        _separatedInstructions = instructions;
        // Créer les controllers pour les traductions
        for (var controller in _translationControllers) {
          controller.dispose();
        }
        _translationControllers = _separatedInstructions.map((instruction) {
          final controller = TextEditingController();
          // Traduire automatiquement chaque instruction
          controller.text = TranslationService.translateInstructionSync(instruction);
          return controller;
        }).toList();
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (_separatedInstructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez séparer les instructions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Enregistrer un feedback pour la séparation des instructions
      final separationFeedback = TranslationFeedback(
        id: '${DateTime.now().millisecondsSinceEpoch}_separation',
        recipeId: widget.recipeId,
        recipeTitle: widget.recipeTitle,
        type: FeedbackType.instructionSeparation,
        originalText: widget.originalInstructionsText,
        currentTranslation: widget.currentInstructions.join(' | '), // Séparateur pour distinguer
        suggestedTranslation: _separatedInstructions.join(' | '), // Nouvelle séparation proposée
        targetLanguage: TranslationService.currentLanguageStatic,
        timestamp: DateTime.now(),
        context: 'Séparation des instructions complètes',
      );

      await _feedbackService.submitFeedback(separationFeedback);

      // Enregistrer un feedback pour chaque instruction traduite
      for (int i = 0; i < _separatedInstructions.length; i++) {
        final originalInstruction = _separatedInstructions[i];
        final translatedInstruction = _translationControllers[i].text.trim();
        
        if (translatedInstruction.isNotEmpty && 
            translatedInstruction != originalInstruction) {
          final instructionFeedback = TranslationFeedback(
            id: '${DateTime.now().millisecondsSinceEpoch}_instruction_$i',
            recipeId: widget.recipeId,
            recipeTitle: widget.recipeTitle,
            type: FeedbackType.instruction,
            originalText: originalInstruction,
            currentTranslation: widget.currentInstructions.length > i 
                ? widget.currentInstructions[i] 
                : originalInstruction,
            suggestedTranslation: translatedInstruction,
            targetLanguage: TranslationService.currentLanguageStatic,
            timestamp: DateTime.now(),
            context: 'Instruction ${i + 1} (séparation améliorée)',
          );

          await _feedbackService.submitFeedback(instructionFeedback);
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, {'success': true});
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
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
                      Icons.tune,
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
                          'Améliorer les instructions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Séparer et traduire correctement',
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
              
              // Texte original complet
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
                          'Texte original complet (anglais)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.originalInstructionsText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Instructions séparées (une par ligne)
              Text(
                'Instructions séparées (une instruction par ligne) :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _separatedInstructionsController,
                maxLines: 8,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: 'Entrez les instructions séparées, une par ligne...\n\nExemple:\nMélanger les ingrédients\nCuire pendant 20 minutes\nServir chaud',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  prefixIcon: const Icon(Icons.list_alt),
                ),
                onChanged: (_) => _parseSeparatedInstructions(),
              ),
              const SizedBox(height: 8),
              Text(
                '💡 Séparez chaque instruction sur une nouvelle ligne. Les traductions seront générées automatiquement.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              // Traductions individuelles
              if (_separatedInstructions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Traductions individuelles (modifiez si nécessaire) :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_separatedInstructions.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _separatedInstructions[index],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _translationControllers[index],
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Traduction de l\'instruction ${index + 1}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                prefixIcon: const Icon(Icons.translate, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
              
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

