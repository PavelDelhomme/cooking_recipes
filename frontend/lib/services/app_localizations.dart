import 'package:flutter/material.dart';

/// Service de localisation pour les textes de l'interface
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  // Traductions
  String get appTitle => _localizedValues[locale.languageCode]?['appTitle'] ?? 'Cooking Recipes';
  String get recipes => _localizedValues[locale.languageCode]?['recipes'] ?? 'Recettes';
  String get pantry => _localizedValues[locale.languageCode]?['pantry'] ?? 'Placard';
  String get shoppingList => _localizedValues[locale.languageCode]?['shoppingList'] ?? 'Courses';
  String get mealPlan => _localizedValues[locale.languageCode]?['mealPlan'] ?? 'Planning';
  String get profile => _localizedValues[locale.languageCode]?['profile'] ?? 'Profil';
  String get ingredients => _localizedValues[locale.languageCode]?['ingredients'] ?? 'Ingrédients';
  String get instructions => _localizedValues[locale.languageCode]?['instructions'] ?? 'Instructions';
  String get description => _localizedValues[locale.languageCode]?['description'] ?? 'Description';
  String get addToMealPlan => _localizedValues[locale.languageCode]?['addToMealPlan'] ?? 'Ajouter au planning';
  String get addMissingIngredients => _localizedValues[locale.languageCode]?['addMissingIngredients'] ?? 'Ajouter manquants';
  String get servings => _localizedValues[locale.languageCode]?['servings'] ?? 'portions';
  String get person => _localizedValues[locale.languageCode]?['person'] ?? 'personne';
  String get people => _localizedValues[locale.languageCode]?['people'] ?? 'personnes';
  String get language => _localizedValues[locale.languageCode]?['language'] ?? 'Langue';
  String get darkMode => _localizedValues[locale.languageCode]?['darkMode'] ?? 'Mode sombre';
  String get lightMode => _localizedValues[locale.languageCode]?['lightMode'] ?? 'Mode clair';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Annuler';
  String get add => _localizedValues[locale.languageCode]?['add'] ?? 'Ajouter';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Supprimer';
  String get edit => _localizedValues[locale.languageCode]?['edit'] ?? 'Modifier';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Enregistrer';
  String get search => _localizedValues[locale.languageCode]?['search'] ?? 'Rechercher';
  String get noResults => _localizedValues[locale.languageCode]?['noResults'] ?? 'Aucun résultat';
  String get loading => _localizedValues[locale.languageCode]?['loading'] ?? 'Chargement...';
  
  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'appTitle': 'Cooking Recipes',
      'recipes': 'Recettes',
      'pantry': 'Placard',
      'shoppingList': 'Courses',
      'mealPlan': 'Planning',
      'profile': 'Profil',
      'ingredients': 'Ingrédients',
      'instructions': 'Instructions',
      'description': 'Description',
      'addToMealPlan': 'Ajouter au planning',
      'addMissingIngredients': 'Ajouter manquants',
      'servings': 'portions',
      'person': 'personne',
      'people': 'personnes',
      'language': 'Langue',
      'darkMode': 'Mode sombre',
      'lightMode': 'Mode clair',
      'cancel': 'Annuler',
      'add': 'Ajouter',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'save': 'Enregistrer',
      'search': 'Rechercher',
      'noResults': 'Aucun résultat',
      'loading': 'Chargement...',
    },
    'en': {
      'appTitle': 'Cooking Recipes',
      'recipes': 'Recipes',
      'pantry': 'Pantry',
      'shoppingList': 'Shopping List',
      'mealPlan': 'Meal Plan',
      'profile': 'Profile',
      'ingredients': 'Ingredients',
      'instructions': 'Instructions',
      'description': 'Description',
      'addToMealPlan': 'Add to Meal Plan',
      'addMissingIngredients': 'Add Missing',
      'servings': 'servings',
      'person': 'person',
      'people': 'people',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'cancel': 'Cancel',
      'add': 'Add',
      'delete': 'Delete',
      'edit': 'Edit',
      'save': 'Save',
      'search': 'Search',
      'noResults': 'No results',
      'loading': 'Loading...',
    },
    'es': {
      'appTitle': 'Recetas de Cocina',
      'recipes': 'Recetas',
      'pantry': 'Despensa',
      'shoppingList': 'Lista de Compras',
      'mealPlan': 'Plan de Comidas',
      'profile': 'Perfil',
      'ingredients': 'Ingredientes',
      'instructions': 'Instrucciones',
      'description': 'Descripción',
      'addToMealPlan': 'Añadir al Plan',
      'addMissingIngredients': 'Añadir Faltantes',
      'servings': 'porciones',
      'person': 'persona',
      'people': 'personas',
      'language': 'Idioma',
      'darkMode': 'Modo Oscuro',
      'lightMode': 'Modo Claro',
      'cancel': 'Cancelar',
      'add': 'Añadir',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'save': 'Guardar',
      'search': 'Buscar',
      'noResults': 'Sin resultados',
      'loading': 'Cargando...',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

