class Ingredient {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final String? preparation; // Terme de préparation (chopped, diced, sliced, etc.)

  Ingredient({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.preparation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'preparation': preparation,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as double?,
      unit: json['unit'] as String?,
      preparation: json['preparation'] as String?,
    );
  }

  Ingredient copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? preparation,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      preparation: preparation ?? this.preparation,
    );
  }
}

