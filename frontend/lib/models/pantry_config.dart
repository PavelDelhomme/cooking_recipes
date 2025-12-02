class PantryConfig {
  // Notifications et alertes
  final bool enableExpiryNotifications;
  final int daysBeforeExpiryNotification; // Nombre de jours avant expiration pour notifier
  final bool showExpiryWarnings;
  final bool autoSortByExpiry; // Trier automatiquement par date d'expiration

  // Affichage
  final bool showExpiryDates;
  final bool highlightExpiringItems;
  final bool showIngredientImages;

  // Suggestions et recommandations
  final bool suggestRecipesForExpiringItems;
  final bool autoAddToShoppingList; // Ajouter automatiquement à la liste de courses quand expiré

  // Gestion automatique
  final bool autoRemoveExpiredItems; // Supprimer automatiquement les items expirés
  final int daysToKeepExpiredItems; // Nombre de jours à garder les items expirés avant suppression

  // Historique
  final bool trackHistory;
  final bool showHistoryButton;

  PantryConfig({
    this.enableExpiryNotifications = true,
    this.daysBeforeExpiryNotification = 3,
    this.showExpiryWarnings = true,
    this.autoSortByExpiry = true,
    this.showExpiryDates = true,
    this.highlightExpiringItems = true,
    this.showIngredientImages = true,
    this.suggestRecipesForExpiringItems = true,
    this.autoAddToShoppingList = false,
    this.autoRemoveExpiredItems = false,
    this.daysToKeepExpiredItems = 7,
    this.trackHistory = true,
    this.showHistoryButton = true,
  });

  factory PantryConfig.fromJson(Map<String, dynamic> json) {
    return PantryConfig(
      enableExpiryNotifications: json['enableExpiryNotifications'] ?? true,
      daysBeforeExpiryNotification: json['daysBeforeExpiryNotification'] ?? 3,
      showExpiryWarnings: json['showExpiryWarnings'] ?? true,
      autoSortByExpiry: json['autoSortByExpiry'] ?? true,
      showExpiryDates: json['showExpiryDates'] ?? true,
      highlightExpiringItems: json['highlightExpiringItems'] ?? true,
      showIngredientImages: json['showIngredientImages'] ?? true,
      suggestRecipesForExpiringItems: json['suggestRecipesForExpiringItems'] ?? true,
      autoAddToShoppingList: json['autoAddToShoppingList'] ?? false,
      autoRemoveExpiredItems: json['autoRemoveExpiredItems'] ?? false,
      daysToKeepExpiredItems: json['daysToKeepExpiredItems'] ?? 7,
      trackHistory: json['trackHistory'] ?? true,
      showHistoryButton: json['showHistoryButton'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableExpiryNotifications': enableExpiryNotifications,
      'daysBeforeExpiryNotification': daysBeforeExpiryNotification,
      'showExpiryWarnings': showExpiryWarnings,
      'autoSortByExpiry': autoSortByExpiry,
      'showExpiryDates': showExpiryDates,
      'highlightExpiringItems': highlightExpiringItems,
      'showIngredientImages': showIngredientImages,
      'suggestRecipesForExpiringItems': suggestRecipesForExpiringItems,
      'autoAddToShoppingList': autoAddToShoppingList,
      'autoRemoveExpiredItems': autoRemoveExpiredItems,
      'daysToKeepExpiredItems': daysToKeepExpiredItems,
      'trackHistory': trackHistory,
      'showHistoryButton': showHistoryButton,
    };
  }

  PantryConfig copyWith({
    bool? enableExpiryNotifications,
    int? daysBeforeExpiryNotification,
    bool? showExpiryWarnings,
    bool? autoSortByExpiry,
    bool? showExpiryDates,
    bool? highlightExpiringItems,
    bool? showIngredientImages,
    bool? suggestRecipesForExpiringItems,
    bool? autoAddToShoppingList,
    bool? autoRemoveExpiredItems,
    int? daysToKeepExpiredItems,
    bool? trackHistory,
    bool? showHistoryButton,
  }) {
    return PantryConfig(
      enableExpiryNotifications: enableExpiryNotifications ?? this.enableExpiryNotifications,
      daysBeforeExpiryNotification: daysBeforeExpiryNotification ?? this.daysBeforeExpiryNotification,
      showExpiryWarnings: showExpiryWarnings ?? this.showExpiryWarnings,
      autoSortByExpiry: autoSortByExpiry ?? this.autoSortByExpiry,
      showExpiryDates: showExpiryDates ?? this.showExpiryDates,
      highlightExpiringItems: highlightExpiringItems ?? this.highlightExpiringItems,
      showIngredientImages: showIngredientImages ?? this.showIngredientImages,
      suggestRecipesForExpiringItems: suggestRecipesForExpiringItems ?? this.suggestRecipesForExpiringItems,
      autoAddToShoppingList: autoAddToShoppingList ?? this.autoAddToShoppingList,
      autoRemoveExpiredItems: autoRemoveExpiredItems ?? this.autoRemoveExpiredItems,
      daysToKeepExpiredItems: daysToKeepExpiredItems ?? this.daysToKeepExpiredItems,
      trackHistory: trackHistory ?? this.trackHistory,
      showHistoryButton: showHistoryButton ?? this.showHistoryButton,
    );
  }
}

