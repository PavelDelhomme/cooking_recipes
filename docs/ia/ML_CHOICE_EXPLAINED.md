# 🎯 Comment l'IA Choisit Entre Plusieurs Traductions

## 📋 Situation

Quand vous proposez **plusieurs traductions pour un même mot**, l'IA doit choisir la meilleure.

**Exemple :**
- "chicken" → "poulet" (approuvé 5 fois)
- "chicken" → "poulet entier" (approuvé 2 fois)
- "chicken" → "poulet rôti" (approuvé 1 fois)

## ✅ Solution : L'IA Choisit Celle Avec le Plus de Points

### 🔢 Calcul des Points

Chaque traduction a un **compteur** qui augmente à chaque approbation :

```javascript
{
  "chicken": {
    "poulet": 5,           // 5 points
    "poulet entier": 2,    // 2 points
    "poulet rôti": 1       // 1 point
  }
}
```

### 📊 Calcul des Probabilités

Les probabilités sont calculées à partir des points :

```javascript
Total = 5 + 2 + 1 = 8 points

Probabilités :
- "poulet" : 5 / 8 = 0.625 (62.5%)
- "poulet entier" : 2 / 8 = 0.25 (25%)
- "poulet rôti" : 1 / 8 = 0.125 (12.5%)
```

### 🎯 Choix de l'IA

L'IA choisit **TOUJOURS** la traduction avec la **plus haute probabilité** (le plus de points) :

```javascript
✅ Choisi : "poulet" (62.5% - le plus de points)
```

## 🔍 Processus de Sélection

### Étape 1 : Recherche Exacte

```javascript
_getExactMatch("chicken", "ingredients", "fr")
↓
Trouve toutes les traductions possibles
↓
Calcule les probabilités
↓
Choisit celle avec le plus de points
↓
Retourne "poulet" (62.5%)
```

### Étape 2 : Si Plusieurs Traductions Existent

L'IA **log** toutes les options pour debug :

```
🔍 Plusieurs traductions pour "chicken": 
   poulet (62.5%), poulet entier (25.0%), poulet rôti (12.5%)
   → Choisi: "poulet" (62.5%)
```

### Étape 3 : Mise à Jour Dynamique

Quand vous ajoutez un nouveau feedback :

```javascript
Nouveau feedback : "chicken" → "poulet" (approuvé)
↓
Compteur mis à jour : "poulet" : 5 + 1 = 6 points
↓
Probabilités recalculées :
- "poulet" : 6 / 9 = 0.667 (66.7%) ← Augmente !
- "poulet entier" : 2 / 9 = 0.222 (22.2%)
- "poulet rôti" : 1 / 9 = 0.111 (11.1%)
↓
L'IA choisit toujours "poulet" (maintenant 66.7%)
```

## 📈 Exemple Concret

### Situation Initiale

```javascript
"chicken" → {
  "poulet": 3 points,
  "poulet entier": 2 points
}
```

**Probabilités :**
- "poulet" : 60%
- "poulet entier" : 40%

**Choix de l'IA :** "poulet" (60%)

### Après 2 Nouveaux Feedbacks pour "poulet"

```javascript
"chicken" → {
  "poulet": 5 points (3 + 2),
  "poulet entier": 2 points
}
```

**Probabilités :**
- "poulet" : 71.4% ← Augmente !
- "poulet entier" : 28.6%

**Choix de l'IA :** "poulet" (71.4%)

### Après 3 Nouveaux Feedbacks pour "poulet entier"

```javascript
"chicken" → {
  "poulet": 5 points,
  "poulet entier": 5 points (2 + 3)
}
```

**Probabilités :**
- "poulet" : 50%
- "poulet entier" : 50% ← Égalité !

**Choix de l'IA :** La première trouvée (ordre alphabétique ou d'ajout)

### Après 1 Feedback de Plus pour "poulet"

```javascript
"chicken" → {
  "poulet": 6 points,
  "poulet entier": 5 points
}
```

**Probabilités :**
- "poulet" : 54.5% ← Re-devient la meilleure
- "poulet entier" : 45.5%

**Choix de l'IA :** "poulet" (54.5%)

## 🎯 Règles de Choix

1. **Toujours choisir la traduction avec le plus de points**
   - Même si la probabilité est < 50%
   - Car c'est quand même la meilleure option disponible

2. **En cas d'égalité**
   - La première trouvée est choisie
   - (Ordre d'ajout dans le modèle)

3. **Mise à jour en temps réel**
   - Chaque nouveau feedback change les probabilités
   - L'IA choisit automatiquement la nouvelle meilleure

## 🔧 Code Implémenté

### Méthode `_getExactMatch()`

```javascript
_getExactMatch(text, modelType, targetLang) {
  // Récupère toutes les traductions possibles
  const probMap = probs.get(text);
  
  // Trouve celle avec le plus de points
  let bestTranslation = null;
  let bestProb = 0;
  
  for (const [translation, prob] of probMap.entries()) {
    if (prob > bestProb) {
      bestProb = prob;
      bestTranslation = translation;
    }
  }
  
  // Retourne TOUJOURS la meilleure (même si < 50%)
  return {
    translation: bestTranslation,
    confidence: bestProb,
  };
}
```

## ✅ Conclusion

**L'IA choisit TOUJOURS la traduction avec le plus de points**, même si plusieurs traductions existent pour le même mot.

Plus vous approuvez une traduction, plus elle a de chances d'être choisie ! 🎯

