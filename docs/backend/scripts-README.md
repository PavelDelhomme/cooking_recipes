# Scripts Backend - IA de Traduction

Scripts pour l'entraînement, le test et la validation de l'IA de traduction.

## Scripts disponibles

### `ml_test_lab.js`
Lab de test automatisé qui teste l'IA sur 100 recettes avec validation automatique.

**Utilisation :**
```bash
make test-ml-lab              # Test sur 100 recettes
make test-ml-lab NUM_RECIPES=50  # Test sur 50 recettes
```

**Fonctionnalités :**
- Récupère des recettes (API Spoonacular ou génère des recettes de test)
- Teste les traductions d'ingrédients, instructions et unités
- Compare avec des traductions de référence
- Génère un rapport détaillé avec précision, erreurs, etc.
- Sauvegarde les rapports dans `data/ml_reports/`

### `ml_auto_validator.js`
Système de validation automatique des feedbacks de traduction.

**Utilisation :**
```bash
make validate-ml-auto
```

**Fonctionnalités :**
- Valide automatiquement les feedbacks qui correspondent aux traductions de référence
- Approuve les traductions correctes sans intervention manuelle
- Laisse les autres en attente pour validation manuelle
- S'exécute automatiquement toutes les heures (configuré dans `server.js`)

### `ml_continuous_learning.js`
Système d'apprentissage continu qui s'entraîne automatiquement avec les nouveaux feedbacks.

**Utilisation :**
```bash
make ml-continuous-learning              # Intervalle par défaut: 30 min
make ml-continuous-learning INTERVAL=15  # Intervalle personnalisé: 15 min
```

**Fonctionnalités :**
- Traite automatiquement les nouveaux feedbacks approuvés
- Entraîne le modèle ML en temps réel
- S'exécute en continu (processus long)
- Peut être intégré dans le serveur pour un apprentissage continu

### `ml_self_critique.js`
Système d'autocritique qui analyse les performances de l'IA et génère des rapports.

**Utilisation :**
```bash
make ml-self-critique
```

**Fonctionnalités :**
- Analyse les rapports de test existants
- Analyse les feedbacks utilisateur pour identifier les patterns d'erreurs
- Identifie les points forts (ce qui fonctionne bien)
- Identifie les points faibles (ce qui ne fonctionne pas)
- Génère des recommandations prioritaires pour s'améliorer
- Sauvegarde les rapports dans `data/ml_critiques/`

**Voir aussi :** [Guide complet de l'autocritique](../ia/ML_SELF_CRITIQUE.md)

### `ml_metrics.js`
Affiche les métriques de performance de l'IA (précision, couverture, etc.).

**Utilisation :**
```bash
make ml-metrics
```

**Fonctionnalités :**
- Statistiques du modèle (nombre de traductions apprises)
- Statistiques des feedbacks (approuvés, en attente, rejetés)
- Métriques de performance (précision, couverture)
- Recommandations basiques

### `train_translation_model.js`
Script original d'entraînement du modèle (conservé pour compatibilité).

## Architecture

L'IA de traduction fonctionne en plusieurs couches :

1. **Validation automatique** (toutes les heures)
   - Valide les feedbacks corrects automatiquement
   - Utilise des traductions de référence

2. **Apprentissage continu** (toutes les 30 minutes)
   - Traite les nouveaux feedbacks approuvés
   - Entraîne le modèle en temps réel

3. **Réentraînement complet** (toutes les 6 heures)
   - Réentraîne le modèle avec tous les feedbacks approuvés
   - Recalcule les probabilités

4. **Tests automatisés**
   - Lab de test sur 100 recettes
   - Validation contre traductions de référence
   - Rapports détaillés

## Configuration

Les scripts utilisent les variables d'environnement suivantes :
- `SPOONACULAR_API_KEY` : Clé API pour récupérer des recettes réelles (optionnel)
- `API_URL` : URL de l'API backend (défaut: http://localhost:7272/api)

## Rapports

### Rapports de test
Les rapports de test sont sauvegardés dans `data/ml_reports/` avec le format :
```
test_report_YYYY-MM-DDTHH-MM-SS.json
```

Chaque rapport contient :
- Résultats détaillés par recette
- Précision globale
- Liste des erreurs
- Statistiques par type (ingrédients, instructions, unités)

### Rapports d'autocritique
Les rapports d'autocritique sont sauvegardés dans `data/ml_critiques/` avec le format :
```
self_critique_YYYY-MM-DDTHH-MM-SS.json
latest_self_critique.json
```

Chaque rapport contient :
- Vue d'ensemble des performances
- Points forts identifiés
- Points faibles identifiés
- Recommandations prioritaires avec étapes d'action

