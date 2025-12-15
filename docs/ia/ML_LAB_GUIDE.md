# 🧪 Guide du Lab de Test IA de Traduction

Ce guide explique comment utiliser le système de test automatisé pour valider que l'IA de traduction fonctionne correctement et s'améliore continuellement.

## 🎯 Objectif

Le lab de test permet de :
- Tester l'IA sur 100 recettes (ou plus)
- Valider automatiquement les traductions contre des références
- Mesurer la précision de l'IA
- Identifier les erreurs et les zones d'amélioration
- Vérifier que l'apprentissage continu fonctionne

## 🚀 Utilisation

### Test basique (100 recettes)

```bash
make test-ml-lab
```

### Test personnalisé

```bash
make test-ml-lab NUM_RECIPES=50   # Test sur 50 recettes
make test-ml-lab NUM_RECIPES=200  # Test sur 200 recettes
```

### Test direct avec Node.js

```bash
cd backend
node scripts/ml_test_lab.js 100
```

## 📊 Résultats

Le lab génère :
1. **Affichage en temps réel** : Progression et résultats par recette
2. **Rapport JSON** : Sauvegardé dans `backend/data/ml_reports/test_report_YYYY-MM-DDTHH-MM-SS.json`

### Métriques calculées

- **Précision globale** : Pourcentage de traductions correctes
- **Correctes** : Nombre de traductions validées
- **Incorrectes** : Nombre de traductions erronées
- **Manquantes** : Nombre de traductions non trouvées dans les références

### Exemple de rapport

```json
{
  "timestamp": "2025-12-10T23:30:00.000Z",
  "results": {
    "total": 500,
    "correct": 420,
    "incorrect": 60,
    "missing": 20,
    "accuracy": 84.0,
    "details": [...]
  }
}
```

## 🔄 Système d'Apprentissage Continu

L'IA s'entraîne automatiquement de plusieurs façons :

### 1. Validation Automatique (toutes les heures)

Valide automatiquement les feedbacks qui correspondent aux traductions de référence :

```bash
make validate-ml-auto
```

**Fonctionnalités :**
- Compare les feedbacks avec des traductions de référence
- Approuve automatiquement les traductions correctes
- Laisse les autres en attente pour validation manuelle

### 2. Apprentissage Continu (toutes les 30 minutes)

Traite les nouveaux feedbacks approuvés et entraîne le modèle en temps réel :

```bash
make ml-continuous-learning              # Intervalle: 30 min
make ml-continuous-learning INTERVAL=15  # Intervalle: 15 min
```

**Fonctionnalités :**
- Surveille les nouveaux feedbacks approuvés
- Entraîne le modèle immédiatement
- S'exécute en continu (processus long)

### 3. Réentraînement Complet (toutes les 6 heures)

Réentraîne le modèle avec tous les feedbacks approuvés :

```bash
make retrain-ml
```

**Fonctionnalités :**
- Recharge tous les modèles
- Réentraîne avec tous les feedbacks approuvés
- Recalcule les probabilités

## 🎓 Traductions de Référence

Le système utilise des traductions de référence pour valider automatiquement :

### Ingrédients
- `chicken` → `poulet` (fr), `pollo` (es)
- `beef` → `boeuf` (fr), `carne de res` (es)
- `tomato` → `tomate` (fr), `tomate` (es)
- ... (20+ ingrédients de base)

### Unités
- `cup` → `tasse` (fr), `taza` (es)
- `tablespoon` → `cuillère à soupe` (fr), `cucharada` (es)
- `gram` → `gramme` (fr), `gramo` (es)
- ... (10+ unités de base)

### Instructions
- `chop` → `hacher` (fr), `picar` (es)
- `cook` → `cuire` (fr), `cocinar` (es)
- `mix` → `mélanger` (fr), `mezclar` (es)
- ... (15+ verbes de cuisine)

## 🔍 Vérification du Fonctionnement

### Vérifier que l'entraînement automatique fonctionne

1. **Vérifier les logs du serveur** :
   ```bash
   make logs
   ```
   Vous devriez voir :
   - `✅ Validation automatique programmée (toutes les heures)`
   - `✅ Entraînement automatique programmé (toutes les 6 heures)`

2. **Vérifier les feedbacks approuvés** :
   - Connectez-vous avec un compte admin
   - Allez dans "Validation Traductions"
   - Vérifiez que certains feedbacks sont automatiquement approuvés

3. **Vérifier les modèles ML** :
   ```bash
   ls -la backend/data/ml_models/
   ```
   Vous devriez voir des fichiers JSON pour chaque type/langue.

### Tester l'amélioration

1. **Lancer un test initial** :
   ```bash
   make test-ml-lab NUM_RECIPES=50
   ```
   Notez la précision.

2. **Ajouter des feedbacks** :
   - Utilisez l'application
   - Corrigez quelques traductions
   - Attendez la validation automatique (ou validez manuellement)

3. **Relancer le test** :
   ```bash
   make test-ml-lab NUM_RECIPES=50
   ```
   La précision devrait s'améliorer !

## 🛠️ Configuration Avancée

### Utiliser l'API Spoonacular pour des recettes réelles

```bash
export SPOONACULAR_API_KEY="votre_cle_api"
make test-ml-lab
```

Sans clé API, le lab utilise des recettes de test générées.

### Modifier les traductions de référence

Éditez `backend/scripts/ml_test_lab.js` et `backend/scripts/ml_auto_validator.js` pour ajouter/modifier les traductions de référence.

## 📈 Amélioration Continue

L'IA s'améliore automatiquement grâce à :

1. **Feedback utilisateur** : Chaque correction améliore le modèle
2. **Validation automatique** : Les traductions correctes sont approuvées automatiquement
3. **Apprentissage continu** : Le modèle s'entraîne en temps réel
4. **Réentraînement périodique** : Le modèle est réentraîné toutes les 6 heures

## 🐛 Dépannage

### L'IA ne s'améliore pas

1. Vérifiez que les feedbacks sont approuvés (admin)
2. Vérifiez les logs : `make logs`
3. Vérifiez que les modèles sont sauvegardés : `ls backend/data/ml_models/`
4. Lancez un réentraînement manuel : `make retrain-ml`

### Les tests échouent

1. Vérifiez que le backend est démarré : `make dev`
2. Vérifiez les erreurs dans les logs
3. Vérifiez que la base de données existe : `ls backend/data/database.sqlite`

## 📚 Ressources

- `backend/scripts/ml_test_lab.js` - Lab de test
- `backend/scripts/ml_auto_validator.js` - Validation automatique
- `backend/scripts/ml_continuous_learning.js` - Apprentissage continu
- `backend/src/services/ml_translation_engine.js` - Moteur ML
- `backend/ML_TRANSLATION_SYSTEM.md` - Documentation technique

