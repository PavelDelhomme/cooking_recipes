# Système de Traduction - Cooking Recipes

Ce document explique comment fonctionne le système de traduction automatique dans l'application Cooking Recipes.

## Vue d'ensemble

Le système de traduction permet de convertir automatiquement les recettes, ingrédients, instructions et descriptions depuis l'anglais ou l'espagnol vers le français (ou d'autres langues) lorsque l'utilisateur sélectionne une langue dans l'application.

## Outils et Technologies Utilisés

### 1. **Flutter Localization**
- **Package**: `flutter_localizations` (intégré dans Flutter)
- **Usage**: Gestion de l'interface utilisateur (boutons, labels, messages)
- **Fichiers**: `lib/l10n/app_*.arb` (fichiers de traduction ARB)

### 2. **Service de Traduction Personnalisé**
- **Fichier**: `lib/services/translation_service.dart`
- **Type**: Singleton avec pattern `ChangeNotifier`
- **Fonction**: Traduction des données de recettes (noms, ingrédients, instructions)

### 3. **Service de Locale**
- **Fichier**: `lib/services/locale_service.dart`
- **Fonction**: Gestion de la langue sélectionnée par l'utilisateur (stockage persistant)

### 4. **Widget LocaleNotifier**
- **Fichier**: `lib/widgets/locale_notifier.dart`
- **Type**: `InheritedWidget`
- **Fonction**: Propagation des changements de langue dans l'arbre des widgets

## Architecture du Système

```
┌─────────────────────────────────────────────────────────┐
│                    Utilisateur                           │
│              (Sélectionne une langue)                   │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              LocaleService                               │
│  - Stocke la langue sélectionnée (SharedPreferences)    │
│  - Notifie TranslationService du changement             │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│          TranslationService (Singleton)                 │
│  - Dictionnaires de traduction (EN→FR, ES→FR)           │
│  - Méthodes de traduction                               │
│  - Notifie les widgets via ChangeNotifier               │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              LocaleNotifier                              │
│  - InheritedWidget pour propagation dans l'arbre         │
│  - Force la reconstruction des widgets enfants           │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│         Widgets de l'Application                        │
│  - Écoutent LocaleNotifier                              │
│  - Se reconstruisent automatiquement                    │
│  - Affichent les textes traduits                        │
└─────────────────────────────────────────────────────────┘
```

## Dictionnaires de Traduction

### 1. **Ingrédients (Anglais → Français)**
- **Variable**: `_ingredientTranslations`
- **Localisation**: `TranslationService` (ligne ~44)
- **Contenu**: Plus de 100 traductions d'ingrédients courants
- **Catégories**:
  - Viandes (chicken → Poulet, beef → Bœuf, etc.)
  - Poissons (salmon → Saumon, tuna → Thon, etc.)
  - Légumes (tomato → Tomate, onion → Oignon, etc.)
  - Fruits (apple → Pomme, banana → Banane, etc.)
  - Produits laitiers (milk → Lait, cheese → Fromage, etc.)
  - Céréales (rice → Riz, pasta → Pâtes, etc.)
  - Épices et herbes (salt → Sel, pepper → Poivre, etc.)
  - Huiles et vinaigres (oil → Huile, vinegar → Vinaigre, etc.)

### 2. **Ingrédients (Espagnol → Français)**
- **Variable**: `_spanishToFrenchIngredients`
- **Localisation**: `TranslationService` (ligne ~196)
- **Contenu**: Plus de 100 traductions d'ingrédients espagnols
- **Exemples**:
  - `pollo` → `Poulet`
  - `tomate` → `Tomate`
  - `aceite de oliva` → `Huile d'olive`
  - `caldo de pollo` → `Bouillon de poulet`

### 3. **Termes de Recettes (Anglais → Français)**
- **Variable**: `recipeTermTranslations` (dans `translateRecipeName`)
- **Contenu**: Termes courants dans les noms de recettes
- **Exemples**:
  - `chicken` → `Poulet`
  - `soup` → `Soupe`
  - `grilled` → `Grillé`
  - `baked` → `Cuit au four`

### 4. **Termes de Recettes (Espagnol → Français)**
- **Variable**: `spanishRecipeTermTranslations` (dans `translateRecipeName`)
- **Contenu**: Termes espagnols dans les noms de recettes
- **Exemples**:
  - `pollo` → `Poulet`
  - `sopa` → `Soupe`
  - `a la parrilla` → `Grillé`
  - `al horno` → `Cuit au four`
  - `paella` → `Paella`
  - `tapas` → `Tapas`
  - `gazpacho` → `Gaspacho`

### 5. **Unités de Mesure**
- **Variable**: `_unitTranslations`
- **Structure**: Map par langue (`fr`, `es`, `en`)
- **Exemples**:
  - `cup` → `tasse` (FR), `taza` (ES)
  - `tablespoon` → `cuillère à soupe` (FR), `cucharada` (ES)
  - `teaspoon` → `cuillère à café` (FR), `cucharadita` (ES)
  - `gram` → `gramme` (FR), `gramo` (ES)
  - `kilogram` → `kilogramme` (FR), `kilogramo` (ES)

## Méthodes de Traduction

### 1. **translateIngredient()**
```dart
static String translateIngredient(String ingredient)
```
- **Fonction**: Traduit un nom d'ingrédient
- **Logique**:
  1. Vérifie d'abord les traductions espagnol → français
  2. Puis vérifie les traductions anglais → français
  3. Recherche des correspondances partielles si aucune correspondance exacte
  4. Capitalise la première lettre si aucune traduction trouvée

### 2. **translateRecipeName()**
```dart
static String translateRecipeName(String recipeName)
```
- **Fonction**: Traduit le nom d'une recette
- **Logique**:
  1. Nettoie l'encodage (UTF-8)
  2. Traduit d'abord depuis l'espagnol
  3. Puis traduit depuis l'anglais
  4. Capitalise la première lettre

### 3. **cleanAndTranslate()**
```dart
static String cleanAndTranslate(String text)
```
- **Fonction**: Nettoie et traduit les instructions/descriptions
- **Logique**:
  1. Décode les entités HTML (`&amp;`, `&lt;`, etc.)
  2. Traduit les ingrédients dans le texte (espagnol puis anglais)
  3. Retourne le texte nettoyé et traduit

### 4. **translateUnit()**
```dart
static String translateUnit(String unit)
```
- **Fonction**: Traduit une unité de mesure
- **Logique**:
  1. Recherche dans le dictionnaire de la langue actuelle
  2. Cherche des correspondances partielles
  3. Retourne l'unité originale si aucune traduction trouvée

## Flux de Traduction

### Lors du Chargement d'une Recette

```
1. API TheMealDB retourne une recette (anglais ou espagnol)
   ↓
2. RecipeApiService._convertMealToRecipe()
   ↓
3. Pour chaque ingrédient:
   - TranslationService.fixEncoding() → Corrige l'encodage
   - TranslationService.translateIngredient() → Traduit le nom
   - TranslationService.translateUnit() → Traduit l'unité
   ↓
4. Pour les instructions:
   - Stocke le texte original dans originalInstructionsText
   - TranslationService.cleanAndTranslate() → Traduit pour l'affichage initial
   ↓
5. Pour le nom de la recette:
   - TranslationService.fixEncoding() → Corrige l'encodage
   - TranslationService.translateRecipeName() → Traduit le nom
   ↓
6. Recipe créée avec textes traduits ET originaux
```

### Lors du Changement de Langue

```
1. Utilisateur change la langue dans le drawer
   ↓
2. LocaleService.setLocale() → Stocke la nouvelle langue
   ↓
3. TranslationService.setLanguage() → Met à jour la langue
   ↓
4. TranslationService.notifyListeners() → Notifie les widgets
   ↓
5. LocaleNotifier.updateShouldNotify() → Retourne true
   ↓
6. Tous les widgets qui écoutent LocaleNotifier se reconstruisent
   ↓
7. Dans chaque widget:
   - Builder avec LocaleNotifier.of(context) → Écoute les changements
   - TranslationService.cleanAndTranslate(originalText) → Retraduit
   - Affiche le nouveau texte traduit
```

## Exemples d'Utilisation

### Dans un Widget

```dart
Builder(
  builder: (context) {
    // Écouter les changements de locale
    LocaleNotifier.of(context);
    
    // Retraduire dynamiquement
    final translatedText = TranslationService.cleanAndTranslate(
      widget.recipe.originalInstructionsText![index]
    );
    
    return Text(translatedText);
  },
)
```

### Traduction d'un Ingrédient

```dart
// Anglais → Français
TranslationService.translateIngredient('chicken'); // → 'Poulet'

// Espagnol → Français
TranslationService.translateIngredient('pollo'); // → 'Poulet'
```

### Traduction d'une Recette

```dart
// Anglais → Français
TranslationService.translateRecipeName('Chicken Soup'); 
// → 'Poulet Soup'

// Espagnol → Français
TranslationService.translateRecipeName('Sopa de Pollo'); 
// → 'Soupe de Poulet'
```

## Ajout de Nouvelles Traductions

### Ajouter un Ingrédient (Anglais → Français)

Éditez `lib/services/translation_service.dart` et ajoutez dans `_ingredientTranslations`:

```dart
'nouvel ingredient': 'Nouvel Ingrédient',
```

### Ajouter un Ingrédient (Espagnol → Français)

Ajoutez dans `_spanishToFrenchIngredients`:

```dart
'nuevo ingrediente': 'Nouvel Ingrédient',
```

### Ajouter un Terme de Recette

Ajoutez dans `recipeTermTranslations` ou `spanishRecipeTermTranslations`:

```dart
'new term': 'Nouveau Terme',
```

### Ajouter une Unité de Mesure

Ajoutez dans `_unitTranslations`:

```dart
'fr': {
  // ... existantes
  'nouvelle unite': 'Nouvelle Unité',
},
```

## Points Importants

### 1. **Stockage du Texte Original**
- Les recettes stockent **à la fois** le texte traduit ET le texte original
- Cela permet de retraduire dynamiquement lors du changement de langue
- Champs: `originalInstructionsText` et `originalSummaryText`

### 2. **Priorité de Traduction**
- **Espagnol d'abord**, puis **Anglais**
- Cela évite les conflits (ex: "pasta" existe en anglais et espagnol)

### 3. **Correspondances Partielles**
- Si aucune correspondance exacte, recherche des correspondances partielles
- Exemple: "chicken breast" → trouve "chicken" → traduit en "Poulet"

### 4. **Capitalisation**
- Si aucune traduction trouvée, capitalise la première lettre
- Exemple: "unknown" → "Unknown"

### 5. **Encodage UTF-8**
- `fixEncoding()` corrige les problèmes d'encodage courants
- Exemple: `Ã©` → `é`, `Ã¨` → `è`

## Limitations

1. **Traduction Mot-à-Mot**: Le système traduit mot par mot, pas phrase par phrase
2. **Pas de Traduction Contextuelle**: Ne comprend pas le contexte (ex: "bass" = poisson ou instrument ?)
3. **Dictionnaires Statiques**: Les traductions sont codées en dur, pas de service externe
4. **Langues Supportées**: Principalement FR, ES, EN (peut être étendu)

## Améliorations Possibles

1. **Service de Traduction Externe**: Intégrer Google Translate API ou DeepL
2. **Traduction Contextuelle**: Utiliser ML pour comprendre le contexte
3. **Cache de Traductions**: Mettre en cache les traductions fréquentes
4. **Détection Automatique**: Détecter automatiquement la langue source
5. **Traduction Phrase Complète**: Traduire les phrases entières, pas seulement les mots

## Fichiers Clés

- `lib/services/translation_service.dart` - Service principal de traduction
- `lib/services/locale_service.dart` - Gestion de la langue
- `lib/widgets/locale_notifier.dart` - Widget pour propagation des changements
- `lib/services/recipe_api_service.dart` - Utilise la traduction lors de la conversion
- `lib/screens/recipe_detail_screen.dart` - Affiche les textes traduits
- `lib/screens/pantry_screen.dart` - Affiche les ingrédients traduits
- `lib/screens/recipes_screen.dart` - Affiche les noms de recettes traduits

## Conclusion

Le système de traduction est basé sur des dictionnaires statiques et des méthodes de correspondance. Il fonctionne bien pour les ingrédients et termes courants, mais peut nécessiter des améliorations pour des traductions plus complexes ou contextuelles.

