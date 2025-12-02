class ShoppingListItem {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final bool isChecked;
  final DateTime? addedDate;

  ShoppingListItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.isChecked = false,
    this.addedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
      'addedDate': addedDate?.toIso8601String(),
    };
  }

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as double?,
      unit: json['unit'] as String?,
      isChecked: json['isChecked'] as bool? ?? false,
      addedDate: json['addedDate'] != null
          ? DateTime.parse(json['addedDate'] as String)
          : null,
    );
  }

  ShoppingListItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    bool? isChecked,
    DateTime? addedDate,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      addedDate: addedDate ?? this.addedDate,
    );
  }
}

