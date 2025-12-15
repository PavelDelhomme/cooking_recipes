# Origine des Recettes

## Source des Recettes

L'application **Cooking Recipes** récupère toutes les recettes depuis l'API **TheMealDB**.

### TheMealDB

- **URL de l'API** : `https://www.themealdb.com/api/json/v1/1`
- **Type** : API REST gratuite et publique
- **Clé API** : Aucune clé API nécessaire (gratuit)
- **Langue** : Les recettes sont principalement en anglais
- **Contenu** : Base de données de recettes du monde entier

### Fonctionnalités Utilisées

L'application utilise plusieurs endpoints de TheMealDB :

1. **Recherche par nom** : `/search.php?s={nom}`
   - Recherche des recettes par nom (ex: "chicken", "pasta")

2. **Recherche par ingrédient** : `/filter.php?i={ingrédient}`
   - Trouve toutes les recettes contenant un ingrédient spécifique

3. **Détails d'une recette** : `/lookup.php?i={id}`
   - Récupère les détails complets d'une recette (ingrédients, instructions, image)

4. **Recettes aléatoires** : `/random.php`
   - Obtient une recette aléatoire

5. **Images d'ingrédients** : `https://www.themealdb.com/images/ingredients/{nom}.png`
   - Images des ingrédients (utilise les noms anglais)

### Traduction

Comme TheMealDB fournit les recettes en anglais, l'application :

1. **Traduit automatiquement** :
   - Les noms de recettes
   - Les noms d'ingrédients
   - Les unités de mesure
   - Les instructions (nettoyage et traduction)

2. **Utilise le service de traduction** :
   - `TranslationService` pour convertir anglais → français
   - Dictionnaires de traduction pour ingrédients courants
   - Conversion des unités (cup → tasse, tablespoon → cuillère à soupe, etc.)

### Limitations

- TheMealDB ne supporte pas directement la recherche multi-ingrédients
- L'application fait une recherche par ingrédient et trouve l'intersection
- Les recettes sont principalement en anglais (traduites ensuite)
- Pas d'informations sur le nombre de portions (par défaut : 4 portions)

### Alternative Possible

Le code contient une référence à **Spoonacular** (commentée) :
- Nécessite une clé API gratuite
- Plus de fonctionnalités (nutrition, portions, etc.)
- Limite de requêtes gratuites par jour

## Code Source

Le service qui gère les recettes se trouve dans :
- `frontend/lib/services/recipe_api_service.dart`

