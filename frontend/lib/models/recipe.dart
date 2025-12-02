import 'ingredient.dart';

class Recipe {
  final String id;
  final String title;
  final String? image;
  final String? summary;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int? readyInMinutes;
  final int? servings;

  Recipe({
    required this.id,
    required this.title,
    this.image,
    this.summary,
    required this.ingredients,
    required this.instructions,
    this.readyInMinutes,
    this.servings,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'summary': summary,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'].toString(),
      title: json['title'] as String,
      image: json['image'] as String?,
      summary: json['summary'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((i) => i.toString())
              .toList() ??
          [],
      readyInMinutes: json['readyInMinutes'] as int?,
      servings: json['servings'] as int?,
    );
  }
}

