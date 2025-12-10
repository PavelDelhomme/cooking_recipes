# Système d'IA de Traduction - Documentation

## Vue d'ensemble

Le système d'IA de traduction est un moteur de machine learning qui apprend automatiquement des feedbacks utilisateur pour améliorer continuellement la qualité des traductions. Il utilise des modèles probabilistes, des N-grammes et des algorithmes de similarité pour prédire les meilleures traductions.

## Architecture

### Composants principaux

1. **MLTranslationEngine** (`src/services/ml_translation_engine.js`)
   - Moteur principal d'IA de traduction
   - Gère les modèles probabilistes
   - Calcule les similarités et probabilités
   - Apprend des feedbacks utilisateur

2. **Modèles de données**
   - Stockage en mémoire pour performance
   - Sauvegarde dans des fichiers JSON (`data/ml_models/`)
   - Synchronisation avec la base de données SQLite

3. **Intégration avec les routes**
   - `/api/translation/translate` - Utilise le ML en priorité
   - `/api/translation/ingredient` - Traduction d'ingrédients avec ML
   - `/api/translation/retrain` - Réentraînement du modèle

## Algorithmes utilisés

### 1. Modèles Probabilistes
- Calcule les probabilités de traduction basées sur la fréquence d'utilisation
- Plus un feedback est utilisé, plus sa probabilité augmente
- Sélectionne la traduction avec la plus haute probabilité

### 2. Distance de Levenshtein
- Calcule la similarité entre deux chaînes de caractères
- Permet de trouver des traductions pour des textes similaires
- Seuil de confiance : 0.8 (80% de similarité)

### 3. N-grammes
- Capture les patterns dans les phrases
- Génère des bigrammes (2 mots consécutifs)
- Compare les N-grammes pour trouver des correspondances

### 4. Recherche multi-niveaux
1. **Recherche exacte** : Correspondance parfaite
2. **Recherche similaire** : Distance de Levenshtein
3. **Recherche par N-grammes** : Patterns de mots
4. **Fallback** : LibreTranslate ou dictionnaires JSON

## Apprentissage continu

### Entraînement automatique
- Chaque feedback utilisateur entraîne immédiatement le modèle
- Les probabilités sont recalculées en temps réel
- Les modèles sont sauvegardés automatiquement

### Réentraînement complet
```bash
# Via l'API
POST /api/translation/retrain

# Via le script
node scripts/train_translation_model.js --retrain
```

## Utilisation

### Traduction avec ML (automatique)
Le système utilise automatiquement le ML en priorité :

```javascript
POST /api/translation/translate
{
  "text": "chicken breast",
  "source": "en",
  "target": "fr",
  "type": "ingredient"
}
```

Réponse :
```json
{
  "success": true,
  "translatedText": "blanc de poulet",
  "method": "ml"  // Indique que le ML a traduit
}
```

### Vérifier le statut
```javascript
GET /api/translation/status
```

Réponse :
```json
{
  "success": true,
  "libreTranslate": {
    "available": true,
    "baseURL": "http://localhost:7071"
  },
  "mlModel": {
    "loaded": true,
    "stats": {
      "ingredients": { "fr": 150, "es": 120 },
      "instructions": { "fr": 500, "es": 450 },
      "recipeNames": { "fr": 200, "es": 180 },
      "units": { "fr": 50, "es": 45 }
    }
  }
}
```

## Structure des fichiers

```
backend/
├── src/
│   └── services/
│       └── ml_translation_engine.js  # Moteur ML principal
├── data/
│   └── ml_models/                    # Modèles sauvegardés
│       ├── ingredients_fr.json
│       ├── ingredients_es.json
│       ├── instructions_fr.json
│       ├── instructions_es.json
│       ├── recipeNames_fr.json
│       ├── recipeNames_es.json
│       ├── units_fr.json
│       └── units_es.json
└── scripts/
    └── train_translation_model.js    # Scripts d'entraînement
```

## Performance

- **Temps de réponse** : < 10ms pour une recherche exacte
- **Temps de réponse** : < 50ms pour une recherche similaire
- **Mémoire** : ~10-50 MB selon la taille des modèles
- **Scalabilité** : Modèles en mémoire pour performance maximale

## Amélioration continue

Le système s'améliore automatiquement :
1. Chaque feedback utilisateur enrichit le modèle
2. Les traductions fréquentes gagnent en confiance
3. Les patterns sont détectés et réutilisés
4. Le modèle devient plus précis avec le temps

## Limitations actuelles

- Traduction uniquement depuis l'anglais (en) vers français (fr) et espagnol (es)
- Modèles probabilistes simples (pas de deep learning)
- Nécessite des données d'entraînement (feedbacks utilisateur)

## Évolutions futures possibles

- Support de plus de langues
- Deep learning avec TensorFlow.js
- Modèles de séquence à séquence (seq2seq)
- Attention mechanisms pour contexte
- Embeddings de mots pour similarité sémantique

