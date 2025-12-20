# 🤖 Guide de l'Autocritique de l'IA

## Vue d'ensemble

Le système d'autocritique permet à l'IA de traduction d'analyser ses propres performances et de générer des rapports détaillés indiquant :
- ✅ **Ce qu'elle fait bien** (points forts)
- ❌ **Ce qu'elle fait mal** (points faibles)
- 💡 **Comment s'améliorer** (recommandations)

## 🚀 Utilisation

### Générer un rapport d'autocritique

```bash
make ml-self-critique
```

Ou directement :

```bash
cd backend
node scripts/ml_self_critique.js
```

## 📊 Ce que le rapport analyse

### 1. Rapports de test existants
- Analyse les 10 derniers rapports de test
- Calcule la précision moyenne
- Identifie les erreurs par type (ingrédients, instructions, unités)
- Détecte les tendances de performance

### 2. Feedbacks utilisateur
- Analyse tous les feedbacks enregistrés
- Identifie les erreurs les plus fréquentes
- Détecte les patterns d'erreurs récurrents
- Analyse les langues les plus problématiques

### 3. Performance par type
- Évalue la couverture de chaque type de traduction
- Identifie les types bien/mal couverts
- Compare les performances français/espagnol

## 📋 Structure du rapport

Le rapport d'autocritique contient :

### Vue d'ensemble
- Précision moyenne
- Nombre total de tests
- Nombre total de feedbacks

### Points forts ✅
- Précision élevée
- Large base de connaissances
- Types bien couverts
- Beaucoup de feedbacks approuvés

### Points faibles ❌
- Précision faible
- Traductions manquantes
- Types mal couverts
- Erreurs fréquentes
- Feedbacks en attente
- Erreurs récurrentes non corrigées

### Recommandations 💡
- Priorité haute : Actions urgentes à prendre
- Priorité moyenne : Améliorations importantes
- Priorité basse : Optimisations à long terme

## 📁 Fichiers générés

Les rapports sont sauvegardés dans `backend/data/ml_critiques/` :

- `self_critique_YYYY-MM-DDTHH-MM-SS.json` - Rapport avec timestamp
- `latest_self_critique.json` - Dernier rapport généré

## 🔍 Exemple de rapport

```json
{
  "timestamp": "2025-12-10T23:30:00.000Z",
  "overall": {
    "accuracy": 75.5,
    "totalTests": 1423,
    "totalFeedbacks": 250
  },
  "strengths": [
    {
      "category": "Précision",
      "description": "Précision correcte de 75.5%",
      "evidence": "1074 traductions correctes sur 1423 testées"
    }
  ],
  "weaknesses": [
    {
      "category": "Couverture",
      "description": "Beaucoup de traductions manquantes (698)",
      "evidence": "L'IA ne trouve pas de traduction pour de nombreux mots",
      "impact": "Fallback vers LibreTranslate trop fréquent"
    }
  ],
  "recommendations": [
    {
      "priority": "haute",
      "action": "Enrichir le modèle avec plus de traductions",
      "reason": "698 traductions manquantes détectées",
      "steps": [
        "Ajouter des traductions pour les mots les plus fréquents",
        "Valider les feedbacks utilisateur",
        "Utiliser les dictionnaires culinaires existants"
      ]
    }
  ]
}
```

## 💡 Utilisation recommandée

### Fréquence
- **Quotidienne** : Pour suivre l'évolution des performances
- **Après chaque test** : Pour analyser les résultats immédiatement
- **Avant un réentraînement** : Pour identifier les priorités

### Workflow suggéré

1. **Générer le rapport d'autocritique**
   ```bash
   make ml-self-critique
   ```

2. **Lire les recommandations prioritaires**
   - Commencer par les actions de priorité "haute"
   - Suivre les étapes suggérées

3. **Appliquer les corrections**
   - Valider les feedbacks en attente
   - Réentraîner le modèle si nécessaire
   - Ajouter des traductions manquantes

4. **Vérifier l'amélioration**
   - Relancer un test : `make test-ml-lab`
   - Regénérer l'autocritique pour voir les progrès

## 🎯 Interprétation des résultats

### Précision
- **≥ 80%** : Excellente performance ✅
- **60-80%** : Performance correcte ⚠️
- **< 60%** : Performance faible ❌

### Couverture
- **≥ 500 traductions** : Large base de connaissances ✅
- **100-500 traductions** : Base correcte ⚠️
- **< 100 traductions** : Base insuffisante ❌

### Feedbacks
- **Beaucoup d'approuvés** : L'IA apprend bien ✅
- **Beaucoup en attente** : Besoin de validation ⚠️
- **Beaucoup de rejetés** : Qualité des feedbacks à améliorer ❌

## 🔄 Intégration avec les autres outils

L'autocritique s'intègre avec :

- **`make test-ml-lab`** : Génère les données de test analysées
- **`make ml-metrics`** : Complète les métriques avec l'analyse critique
- **`make retrain-ml`** : Utilise les recommandations pour améliorer le modèle
- **`make validate-ml-auto`** : Valide les feedbacks identifiés comme importants

## 📝 Notes importantes

- Le rapport analyse les **10 derniers rapports de test** pour éviter de surcharger
- Les **feedbacks en attente** sont identifiés comme une faiblesse car ils ne sont pas utilisés pour l'entraînement
- Les **erreurs récurrentes** sont prioritaires car elles impactent plusieurs utilisateurs
- Le rapport est **objectif** et basé uniquement sur les données disponibles

## 🚨 Actions urgentes

Si le rapport indique :
- **Précision < 50%** : Réentraîner immédiatement le modèle
- **> 100 traductions manquantes** : Enrichir le modèle en priorité
- **Erreurs récurrentes** : Corriger les traductions problématiques
- **> 50 feedbacks en attente** : Valider les feedbacks rapidement

