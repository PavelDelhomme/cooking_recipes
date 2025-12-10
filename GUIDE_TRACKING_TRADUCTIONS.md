# 📊 Guide du Système de Tracking et d'Entraînement des Traductions

Ce guide explique le système complet de tracking des modifications de traductions et d'entraînement de l'IA.

## 🎯 Vue d'ensemble

Le système permet de :
1. **Voir l'historique** de toutes vos modifications de traductions
2. **Tracker dans le backend** toutes les corrections proposées
3. **Entraîner l'IA** avec ces données pour améliorer continuellement les traductions

## 📱 Interface Utilisateur

### Accéder à l'historique

1. Ouvrir le **menu drawer** (icône hamburger en haut à gauche)
2. Cliquer sur **"Mes Traductions"** (icône `translate`)
3. Voir toutes vos modifications avec :
   - Le type d'élément modifié (instruction, ingrédient, nom)
   - La recette concernée
   - Le texte original (anglais)
   - La traduction actuelle (problématique)
   - Votre traduction améliorée
   - La date et l'heure de la modification

### Filtres disponibles

- **Tous** : Affiche toutes les modifications
- **Instructions** : Seulement les instructions
- **Ingrédients** : Seulement les ingrédients
- **Noms** : Seulement les noms de recettes

## 🔄 Synchronisation Backend

### Enregistrement automatique

Quand vous enregistrez une traduction améliorée :
1. ✅ **Stockage local** : Enregistré immédiatement dans l'application
2. ✅ **Envoi au backend** : Envoyé automatiquement au serveur (si connecté)
3. ✅ **Traduction apprise** : Utilisée immédiatement pour cette recette et les futures

### Synchronisation bidirectionnelle

- **Au chargement** : L'application récupère les feedbacks depuis le backend
- **En cas d'erreur** : Fallback sur le stockage local
- **Synchronisation** : Les données locales sont synchronisées avec le backend

## 🗄️ Base de données Backend

### Table `translation_feedbacks`

Stocke tous les feedbacks utilisateur avec :
- `id` : Identifiant unique
- `user_id` : ID de l'utilisateur
- `recipe_id` : ID de la recette
- `recipe_title` : Titre de la recette
- `type` : Type (instruction, ingredient, recipeName)
- `original_text` : Texte original (anglais)
- `current_translation` : Traduction actuelle (problématique)
- `suggested_translation` : Traduction améliorée proposée
- `target_language` : Langue cible (fr, es)
- `context` : Contexte (ex: "Instruction 3", "Ingrédient 2")
- `timestamp` : Date et heure

## 🔧 API Backend

### Endpoints disponibles

#### POST `/api/translation-feedback`
Enregistre un nouveau feedback

**Body:**
```json
{
  "recipeId": "123",
  "recipeTitle": "Chicken Curry",
  "type": "instruction",
  "originalText": "Heat the oil",
  "currentTranslation": "Chauffer l'huile",
  "suggestedTranslation": "Faites chauffer l'huile",
  "targetLanguage": "fr",
  "context": "Instruction 1"
}
```

#### GET `/api/translation-feedback`
Récupère les feedbacks de l'utilisateur connecté

**Query params:**
- `type` : Filtrer par type (instruction, ingredient, recipeName)
- `limit` : Nombre de résultats (défaut: 100)
- `offset` : Offset pour pagination (défaut: 0)

#### GET `/api/translation-feedback/stats`
Statistiques des feedbacks de l'utilisateur

#### GET `/api/translation-feedback/training-data`
Récupère les données pour l'entraînement (tous les utilisateurs)

## 🤖 Entraînement de l'IA

### Script d'entraînement

Le script `backend/scripts/train_translation_model.js` permet de :

#### 1. Exporter les données d'entraînement

```bash
make train-translation-model
# ou
cd backend && node scripts/train_translation_model.js --export-json
```

Crée un fichier `backend/data/training_data.json` avec :
- Toutes les traductions approuvées par les utilisateurs
- Organisées par type (instructions, ingredients, recipeNames)
- Organisées par langue (fr, es)
- Avec compteur d'utilisation

#### 2. Afficher les statistiques

```bash
make translation-stats
# ou
cd backend && node scripts/train_translation_model.js --stats
```

Affiche :
- Nombre total de feedbacks
- Répartition par type
- Nombre d'utilisateurs uniques
- Nombre de recettes uniques

#### 3. Mettre à jour les dictionnaires

```bash
make update-translation-dict
# ou
cd backend && node scripts/train_translation_model.js --update-dict
```

Crée des dictionnaires JSON dans `backend/data/dictionaries/` :
- `instructions_fr.json` / `instructions_es.json`
- `ingredients_fr.json` / `ingredients_es.json`
- `recipeNames_fr.json` / `recipeNames_es.json`

**Critère d'inclusion** : Seules les traductions avec `usage_count >= 2` sont incluses (plus de confiance)

## 🔄 Workflow d'amélioration continue

### 1. Collecte des données
- Les utilisateurs proposent des traductions améliorées
- Les feedbacks sont stockés localement ET dans le backend

### 2. Analyse des données
- Le script d'entraînement analyse les patterns
- Identifie les traductions les plus utilisées
- Détecte les améliorations récurrentes

### 3. Entraînement
- Export des données d'entraînement
- Mise à jour des dictionnaires JSON
- Intégration dans le système de traduction

### 4. Amélioration
- Les nouvelles traductions sont utilisées automatiquement
- Le système devient plus intelligent avec le temps
- Les suggestions IA s'améliorent

## 📊 Format des données d'entraînement

### Structure JSON

```json
{
  "metadata": {
    "exportDate": "2025-12-10T00:00:00.000Z",
    "totalEntries": 150,
    "version": "1.0.0"
  },
  "instructions": {
    "fr": [
      {
        "original": "Heat the oil",
        "current": "Chauffer l'huile",
        "suggested": "Faites chauffer l'huile",
        "usageCount": 5,
        "recipes": ["Chicken Curry", "Beef Stew"]
      }
    ],
    "es": [...]
  },
  "ingredients": {
    "fr": [...],
    "es": [...]
  },
  "recipeNames": {
    "fr": [...],
    "es": [...]
  }
}
```

## 🎯 Utilisation pour l'entraînement d'un modèle IA

Les données exportées peuvent être utilisées pour :

1. **Entraîner un modèle de traduction** (ex: fine-tuning d'un modèle existant)
2. **Créer un système de règles** basé sur les patterns détectés
3. **Améliorer les suggestions IA** en utilisant les traductions approuvées
4. **Analyser les erreurs** récurrentes dans les traductions automatiques

## 🔐 Sécurité et Confidentialité

- ✅ Les feedbacks sont liés à l'utilisateur (authentification requise)
- ✅ Seuls les utilisateurs authentifiés peuvent voir leurs propres feedbacks
- ✅ Les données d'entraînement sont anonymisées (pas d'email, juste user_id)
- ✅ Les données sensibles ne sont pas incluses dans les exports

## 📈 Statistiques et Monitoring

### Dans l'application

L'écran "Mes Traductions" affiche :
- Tous vos feedbacks avec détails
- Filtres par type
- Dates et contextes

### Via l'API

```bash
# Statistiques personnelles
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:7272/api/translation-feedback/stats

# Données d'entraînement (admin)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:7272/api/translation-feedback/training-data
```

## 🚀 Commandes rapides

```bash
# Voir les stats
make translation-stats

# Exporter les données
make train-translation-model

# Mettre à jour les dictionnaires
make update-translation-dict
```

## 💡 Bonnes pratiques

1. **Proposer des traductions complètes** : Plus de contexte = meilleure qualité
2. **Être cohérent** : Utiliser les mêmes termes pour les mêmes actions
3. **Vérifier régulièrement** : Consulter l'historique pour voir vos contributions
4. **Entraîner régulièrement** : Exécuter le script d'entraînement périodiquement

## 🎉 Résultat

Un système qui :
- ✅ Track toutes vos modifications de traductions
- ✅ Les synchronise avec le backend
- ✅ Les utilise pour entraîner et améliorer l'IA
- ✅ Devient plus intelligent avec le temps
- ✅ Offre une meilleure expérience utilisateur

