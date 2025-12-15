# 📚 Comment l'IA Récupère et Utilise les Données d'Entraînement

## 🗄️ Sources de Données

L'IA de traduction utilise **3 sources de données** pour apprendre :

### 1. Base de Données SQLite (`backend/data/database.sqlite`)

**Table : `translation_feedbacks`**

Cette table contient **TOUS les feedbacks utilisateur** :

```sql
CREATE TABLE translation_feedbacks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  recipe_id TEXT NOT NULL,
  recipe_title TEXT NOT NULL,
  type TEXT NOT NULL,                    -- 'ingredient', 'instruction', 'recipeName', 'unit'
  original_text TEXT NOT NULL,            -- Texte original (anglais)
  current_translation TEXT NOT NULL,      -- Traduction actuelle (problématique)
  suggested_translation TEXT,             -- Traduction suggérée par l'utilisateur
  target_language TEXT NOT NULL,          -- 'fr' ou 'es'
  context TEXT,                           -- Contexte (optionnel)
  approved INTEGER DEFAULT 0,            -- 0=en attente, 1=approuvé, -1=rejeté
  approved_by TEXT,                       -- Email de l'admin qui a approuvé
  approved_at DATETIME,                   -- Date d'approbation
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

**Contenu :**
- Tous les feedbacks créés par les utilisateurs
- Feedbacks approuvés (utilisés pour l'entraînement)
- Feedbacks en attente (validation manuelle ou auto)
- Feedbacks rejetés (ignorés)

**Utilisation :**
- L'IA charge **uniquement les feedbacks approuvés** (`approved = 1`)
- Les feedbacks sont groupés par `original_text`, `suggested_translation`, `target_language`
- Le `usage_count` (nombre de fois qu'une traduction a été suggérée) est utilisé pour calculer les probabilités

### 2. Fichiers JSON (`backend/data/ml_models/`)

**Format : `{type}_{lang}.json`**

Exemples :
- `ingredients_fr.json` - Traductions d'ingrédients en français
- `ingredients_es.json` - Traductions d'ingrédients en espagnol
- `instructions_fr.json` - Traductions d'instructions en français
- `units_fr.json` - Traductions d'unités en français
- etc.

**Structure :**
```json
{
  "chicken": {
    "poulet": 5,
    "poulet entier": 2
  },
  "beef": {
    "boeuf": 8,
    "viande de boeuf": 1
  }
}
```

**Contenu :**
- Modèles ML sauvegardés après entraînement
- Format : `{ "original": { "translation": count, ... }, ... }`
- Le `count` représente le nombre de fois qu'une traduction a été approuvée

**Utilisation :**
- Chargement rapide au démarrage du serveur
- Permet de ne pas recharger toute la base de données à chaque fois
- Sauvegardé automatiquement après chaque entraînement

### 3. Modèles en Mémoire (Runtime)

**Format : Objets JavaScript avec probabilités**

**Structure :**
```javascript
{
  ingredients: {
    fr: {
      "chicken": { "poulet": 0.714, "poulet entier": 0.286 }
    },
    es: {
      "chicken": { "pollo": 1.0 }
    }
  },
  instructions: { ... },
  recipeNames: { ... },
  units: { ... }
}
```

**Contenu :**
- Modèles chargés depuis la DB + fichiers JSON
- Probabilités calculées à partir des fréquences
- Mis à jour en temps réel lors de l'apprentissage

**Utilisation :**
- Traduction en temps réel (très rapide)
- Recherche par correspondance exacte, similarité (Levenshtein), ou N-grammes
- Retourne la traduction avec la plus haute probabilité

## 🔄 Flux d'Apprentissage

### Étape 1 : Feedback Utilisateur
```
Utilisateur corrige "chicken" → "poulet"
↓
Feedback créé dans translation_feedbacks
approved = 0 (en attente)
```

### Étape 2 : Validation Automatique (toutes les heures)
```
Système compare avec traductions de référence
↓
Si "chicken" → "poulet" correspond à la référence
  → approved = 1 (approuvé automatiquement)
Sinon
  → approved = 0 (reste en attente pour validation manuelle)
```

### Étape 3 : Apprentissage Continu (toutes les 30 min)
```
Nouveaux feedbacks approuvés détectés
↓
Pour chaque feedback approuvé:
  - Ajouter au modèle ML en mémoire
  - Incrémenter le count pour cette traduction
  - Recalculer les probabilités
↓
Modèle mis à jour immédiatement
```

### Étape 4 : Réentraînement Complet (toutes les 6 heures)
```
Recharger tous les feedbacks approuvés depuis la DB
↓
Recalculer toutes les probabilités
↓
Sauvegarder dans les fichiers JSON
```

### Étape 5 : Utilisation pour Traduire
```
Requête: Traduire "chicken" en français
↓
1. Recherche exacte dans modèles en mémoire
   → Trouvé: "chicken" → "poulet" (probabilité: 0.714)
↓
2. Retourne "poulet"
```

## 📊 Comment Voir les Données

### Afficher toutes les données d'entraînement

```bash
make view-ml-data
```

Affiche :
- Statistiques de la base de données
- Fichiers JSON disponibles
- Modèles chargés en mémoire
- Exemples de traductions apprises
- Flux d'apprentissage complet

### Voir la base de données directement

```bash
sqlite3 backend/data/database.sqlite
```

Commandes SQL utiles :
```sql
-- Voir tous les feedbacks
SELECT * FROM translation_feedbacks;

-- Voir les feedbacks approuvés
SELECT * FROM translation_feedbacks WHERE approved = 1;

-- Compter par type
SELECT type, COUNT(*) FROM translation_feedbacks WHERE approved = 1 GROUP BY type;

-- Voir les traductions les plus utilisées
SELECT original_text, suggested_translation, COUNT(*) as count
FROM translation_feedbacks
WHERE approved = 1
GROUP BY original_text, suggested_translation
ORDER BY count DESC
LIMIT 20;
```

### Voir les fichiers JSON

```bash
ls -la backend/data/ml_models/
cat backend/data/ml_models/ingredients_fr.json
```

## 🎯 Points Importants

1. **L'IA n'apprend QUE des feedbacks approuvés**
   - `approved = 1` → Utilisé pour l'entraînement
   - `approved = 0` → En attente, pas encore utilisé
   - `approved = -1` → Rejeté, jamais utilisé

2. **Les probabilités sont calculées à partir des fréquences**
   - Plus une traduction est approuvée, plus sa probabilité est élevée
   - Si plusieurs traductions existent, la plus fréquente est choisie

3. **L'apprentissage est continu**
   - Chaque nouveau feedback approuvé améliore immédiatement le modèle
   - Pas besoin d'attendre le réentraînement complet

4. **Les données sont persistantes**
   - Base de données SQLite : Tous les feedbacks (historique complet)
   - Fichiers JSON : Modèles sauvegardés (pour chargement rapide)
   - Modèles en mémoire : Pour traduction en temps réel

## 🔍 Vérification

Pour vérifier que l'IA apprend bien :

1. **Avant d'ajouter des feedbacks :**
   ```bash
   make view-ml-data
   # Notez le nombre de traductions : 0
   ```

2. **Ajoutez des feedbacks via l'application**
   - Corrigez quelques traductions
   - Validez-les (automatiquement ou manuellement)

3. **Après quelques feedbacks :**
   ```bash
   make view-ml-data
   # Le nombre de traductions devrait avoir augmenté
   ```

4. **Testez l'amélioration :**
   ```bash
   make test-ml-lab NUM_RECIPES=50
   # La précision devrait s'améliorer
   ```

## 📈 Exemple Concret

**Situation initiale :**
- Base de données : 0 feedbacks
- Fichiers JSON : Aucun
- Modèles en mémoire : Vides

**Après 10 feedbacks approuvés :**
- Base de données : 10 feedbacks avec `approved = 1`
- Fichiers JSON : Créés après le premier réentraînement (6h)
- Modèles en mémoire : 10 traductions chargées

**L'IA peut maintenant traduire ces 10 éléments correctement !**

