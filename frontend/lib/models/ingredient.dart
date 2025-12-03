class Ingredient {
  final String id;
  final String name;
  final String? originalName; // Nom anglais original (pour les images TheMealDB)
  final double? quantity;
  final String? unit;
  final String? preparation; // Terme de préparation (chopped, diced, sliced, etc.)

  Ingredient({
    required this.id,
    required this.name,
    this.originalName,
    this.quantity,
    this.unit,
    this.preparation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originalName': originalName,
      'quantity': quantity,
      'unit': unit,
      'preparation': preparation,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      originalName: json['originalName'] as String?,
      quantity: json['quantity'] as double?,
      unit: json['unit'] as String?,
      preparation: json['preparation'] as String?,
    );
  }

  Ingredient copyWith({
    String? id,
    String? name,
    String? originalName,
    double? quantity,
    String? unit,
    String? preparation,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      preparation: preparation ?? this.preparation,
    );
  }
}

