class PantryHistoryItem {
  final String id;
  final String ingredientName;
  final double quantity;
  final String unit;
  final DateTime usedDate;
  final String? reason; // Optionnel : raison de l'utilisation (ex: "Recette: Pâtes carbonara")

  PantryHistoryItem({
    required this.id,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.usedDate,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'usedDate': usedDate.toIso8601String(),
      'reason': reason,
    };
  }

  factory PantryHistoryItem.fromJson(Map<String, dynamic> json) {
    return PantryHistoryItem(
      id: json['id'] as String,
      ingredientName: json['ingredientName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      usedDate: DateTime.parse(json['usedDate'] as String),
      reason: json['reason'] as String?,
    );
  }
}

