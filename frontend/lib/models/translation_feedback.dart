/// Modèle pour les retours utilisateur sur les traductions
class TranslationFeedback {
  final String id;
  final String recipeId;
  final String recipeTitle;
  final FeedbackType type; // instruction, ingredient, recipeName
  final String originalText; // Texte original (anglais)
  final String currentTranslation; // Traduction actuelle (qui pose problème)
  final String? suggestedTranslation; // Traduction suggérée par l'utilisateur
  final String targetLanguage; // Langue cible (fr, es)
  final DateTime timestamp;
  final String? context; // Contexte supplémentaire (ex: "instruction 3", "ingredient 2")

  TranslationFeedback({
    required this.id,
    required this.recipeId,
    required this.recipeTitle,
    required this.type,
    required this.originalText,
    required this.currentTranslation,
    this.suggestedTranslation,
    required this.targetLanguage,
    required this.timestamp,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'type': type.toString().split('.').last,
      'originalText': originalText,
      'currentTranslation': currentTranslation,
      'suggestedTranslation': suggestedTranslation,
      'targetLanguage': targetLanguage,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }

  factory TranslationFeedback.fromJson(Map<String, dynamic> json) {
    return TranslationFeedback(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      recipeTitle: json['recipeTitle'] as String,
      type: FeedbackType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FeedbackType.instruction,
      ),
      originalText: json['originalText'] as String,
      currentTranslation: json['currentTranslation'] as String,
      suggestedTranslation: json['suggestedTranslation'] as String?,
      targetLanguage: json['targetLanguage'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: json['context'] as String?,
    );
  }
}

enum FeedbackType {
  instruction,
  ingredient,
  recipeName,
}

