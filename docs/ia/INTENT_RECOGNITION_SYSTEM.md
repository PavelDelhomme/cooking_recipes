# 🧠 Système de Reconnaissance d'Intention (Intent Recognition)

## Vue d'ensemble

Le système de reconnaissance d'intention permet de comprendre l'intention de l'utilisateur dans ses recherches et requêtes, améliorant ainsi les résultats de recherche et l'entraînement du modèle ML.

## 🎯 Objectifs

1. **Comprendre l'intention de recherche** : Détecter ce que l'utilisateur cherche vraiment
2. **Améliorer les résultats** : Personnaliser les résultats selon l'intention
3. **Optimiser l'entraînement ML** : Utiliser l'intention pour améliorer l'apprentissage du modèle
4. **Apprentissage continu** : Le système s'améliore avec chaque requête

## 📋 Types d'Intentions Supportées

### Intentions de Recherche

- **SEARCH_BY_NAME** : Recherche par nom de recette
  - Exemple : "chicken curry", "pasta carbonara"
  
- **SEARCH_BY_INGREDIENTS** : Recherche par ingrédients disponibles
  - Exemple : "avec tomates et fromage", "ingrédients dans mon placard"
  
- **SEARCH_BY_TYPE** : Recherche par type de plat
  - Types : dessert, entrée, plat principal, petit-déjeuner, snack, boisson
  - Exemple : "dessert au chocolat", "entrée végétarienne"
  
- **SEARCH_BY_CONSTRAINTS** : Recherche avec contraintes
  - Contraintes : rapide, facile, végétarien, végan, sans gluten, sain, économique
  - Exemple : "recette rapide", "végétarien facile"
  
- **SEARCH_BY_DIFFICULTY** : Recherche par difficulté
  - Niveaux : facile, moyen, difficile
  - Exemple : "recette facile", "plat difficile"
  
- **SEARCH_BY_TIME** : Recherche par temps de préparation
  - Durées : court (15-30 min), moyen (45-60 min), long (2h+)
  - Exemple : "15 minutes", "recette rapide"

### Intentions de Feedback

- **TRANSLATION_FEEDBACK** : Feedback général sur une traduction
- **TRANSLATION_CORRECTION** : Correction d'une traduction incorrecte
- **TRANSLATION_IMPROVEMENT** : Amélioration d'une traduction correcte mais perfectible

## 🏗️ Architecture

### Composants Principaux

1. **IntentRecognitionService** (`backend/src/services/intent_recognition_service.js`)
   - Service principal de reconnaissance d'intention
   - Analyse les requêtes et détecte l'intention
   - Gère les modèles d'intention

2. **Modèles d'Intention**
   - Stockage en mémoire pour performance
   - Sauvegarde dans des fichiers JSON (`data/intent_models/`)
   - Synchronisation avec la base de données SQLite

3. **Base de données**
   - Table `search_intents` : Historique des intentions détectées
   - Permet l'apprentissage continu et l'amélioration du modèle

## 🔍 Fonctionnement

### 1. Reconnaissance d'Intention

```javascript
const intent = await intentRecognitionService.recognizeSearchIntent(
  "dessert rapide au chocolat",
  { availableIngredients: ["chocolate", "flour"] }
);

// Résultat :
{
  intent: "SEARCH_BY_CONSTRAINTS",
  confidence: 0.8,
  extracted: {
    type: "dessert",
    constraints: ["quick"],
    ingredients: ["chocolate"],
    name: null,
    difficulty: null,
    time: "short"
  }
}
```

### 2. Processus de Détection

1. **Vérification des patterns connus** : Recherche dans l'historique
2. **Analyse des mots-clés** : Détection des types, contraintes, difficulté, temps
3. **Extraction des ingrédients** : Identification des ingrédients dans la requête
4. **Utilisation du contexte** : Prise en compte des ingrédients disponibles
5. **Calcul de la confiance** : Score de confiance basé sur la correspondance

### 3. Apprentissage Continu

- Chaque requête est enregistrée avec son intention détectée
- Les patterns fréquents sont mémorisés
- Le modèle s'améliore avec le temps
- Possibilité de correction manuelle par l'utilisateur

## 🔌 Intégration

### Dans la Recherche de Recettes

```javascript
// Route POST /api/recipes/search
router.post('/search', authenticateToken, async (req, res) => {
  const { query, context } = req.body;
  const intent = await intentRecognitionService.recognizeSearchIntent(query, context);
  await intentRecognitionService.saveIntent(query, intent, req.user.id);
  // Utiliser l'intention pour améliorer les résultats de recherche
});
```

### Dans le Système ML d'Entraînement

```javascript
// Le système ML utilise l'intention pour améliorer l'apprentissage
async train(feedback) {
  const { intent } = feedback;
  if (intent) {
    await intentRecognitionService.recognizeFeedbackIntent(feedback);
  }
  // Entraînement normal avec contexte d'intention
}
```

## 📊 Statistiques

### Obtenir les Statistiques

```javascript
// Route GET /api/recipes/intent-stats
const stats = await intentRecognitionService.getIntentStatistics();

// Résultat :
{
  total: 1250,
  byType: {
    "SEARCH_BY_NAME": 450,
    "SEARCH_BY_INGREDIENTS": 320,
    "SEARCH_BY_TYPE": 280,
    "SEARCH_BY_CONSTRAINTS": 200
  }
}
```

## 🎓 Amélioration du Modèle

### Correction Manuelle

```javascript
// Route POST /api/recipes/improve-intent
router.post('/improve-intent', authenticateToken, async (req, res) => {
  const { query, correctIntent } = req.body;
  await intentRecognitionService.improveModel(query, correctIntent);
});
```

### Apprentissage Automatique

- Les patterns fréquents sont automatiquement mémorisés
- La confiance augmente avec la fréquence d'utilisation
- Les corrections utilisateur ont une confiance maximale

## 🔑 Mots-clés et Patterns

### Types de Plats

- **dessert** : dessert, sweet, cake, pie, cookie, chocolate, sugar
- **entree** : appetizer, starter, entrée, hors d'oeuvre
- **main** : main, dish, meal, dinner, lunch, plat principal
- **breakfast** : breakfast, morning, cereal, pancake, waffle
- **snack** : snack, bite, quick bite
- **drink** : drink, beverage, cocktail, smoothie

### Contraintes

- **quick** : quick, fast, rapid, speedy, 15 minutes, 30 minutes
- **easy** : easy, simple, basic, beginner, facile
- **vegetarian** : vegetarian, veggie, vegetable, végétarien
- **vegan** : vegan, plant-based
- **glutenFree** : gluten-free, gluten free, sans gluten
- **healthy** : healthy, light, low-calorie, diet, santé
- **cheap** : cheap, budget, affordable, économique

### Difficulté

- **easy** : easy, simple, beginner, facile
- **medium** : medium, moderate, intermediate, moyen
- **hard** : hard, difficult, advanced, complex, difficile

### Temps

- **short** : quick, fast, 15 min, 30 min, rapide
- **medium** : 1 hour, 45 min, moyen
- **long** : long, slow, 2 hours, 3 hours, long

## 📈 Avantages

1. **Meilleure compréhension** : Le système comprend mieux ce que l'utilisateur cherche
2. **Résultats personnalisés** : Les résultats sont adaptés à l'intention
3. **Apprentissage amélioré** : Le modèle ML apprend mieux avec le contexte d'intention
4. **Expérience utilisateur** : Recherche plus intuitive et efficace
5. **Amélioration continue** : Le système s'améliore avec chaque utilisation

## 🚀 Utilisation

### Pour les Développeurs

```javascript
const intentRecognitionService = require('./services/intent_recognition_service');

// Reconnaître l'intention d'une recherche
const intent = await intentRecognitionService.recognizeSearchIntent(
  "dessert rapide",
  { availableIngredients: ["chocolate"] }
);

// Utiliser l'intention pour améliorer les résultats
if (intent.intent === "SEARCH_BY_CONSTRAINTS") {
  // Filtrer les recettes rapides
  // Prioriser les desserts
}
```

### Pour les Utilisateurs

Le système fonctionne automatiquement en arrière-plan :
- Chaque recherche est analysée
- L'intention est détectée automatiquement
- Les résultats sont adaptés selon l'intention
- Le système apprend de vos préférences

## 🔮 Évolutions Futures

1. **Intention contextuelle** : Utiliser l'historique de l'utilisateur
2. **Intention multi-langue** : Support des intentions en plusieurs langues
3. **Intention prédictive** : Prédire l'intention avant que l'utilisateur termine sa requête
4. **Intention collaborative** : Apprendre des intentions d'autres utilisateurs similaires
5. **Intention émotionnelle** : Détecter l'état d'esprit de l'utilisateur

---

**💡 Note** : Le système de reconnaissance d'intention est conçu pour s'améliorer continuellement. Plus il est utilisé, plus il devient précis et utile.

