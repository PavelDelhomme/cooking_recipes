class Ingredient {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;

  Ingredient({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as double?,
      unit: json['unit'] as String?,
    );
  }

  Ingredient copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}

