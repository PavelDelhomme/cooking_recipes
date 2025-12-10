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

Les rapports de test sont sauvegardés dans `data/ml_reports/` avec le format :
```
test_report_YYYY-MM-DDTHH-MM-SS.json
```

Chaque rapport contient :
- Résultats détaillés par recette
- Précision globale
- Liste des erreurs
- Statistiques par type (ingrédients, instructions, unités)

