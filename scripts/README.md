# Scripts - Organisation

Ce dossier contient tous les scripts utilitaires du projet, organisés par catégorie.

## 📁 Structure

```
scripts/
├── dev/              # Scripts de développement
├── translation/      # Scripts de traduction
├── testing/         # Scripts de test
├── deployment/      # Scripts de déploiement
├── utils/           # Utilitaires généraux
└── ai/              # Scripts d'entraînement IA
```

## 📂 Détails par catégorie

### 🚀 `dev/` - Développement
Scripts pour le développement local et le débogage.

- **`dev.sh`** - Script principal de développement (lance backend + frontend)
- **`monitor_logs.sh`** - Surveillance des logs en temps réel
- **`install_android.sh`** - Installation et lancement sur Android
- **`logs_android.sh`** - Logs Android filtrés

### 🌐 `translation/` - Traduction
Scripts pour gérer les traductions et les dictionnaires.

- **`improve_translations.py`** - Amélioration interactive des traductions
- **`export_translation_training_data.py`** - Export des données d'entraînement
- **`translate_all_ingredients.py`** - Traduction de tous les ingrédients
- **`translate_all_recipe_names.py`** - Traduction de tous les noms de recettes
- **`complete_translations.py`** - Complétion des traductions manquantes
- **`build_complete_dictionary.py`** - Construction du dictionnaire complet
- **`extract_ingredients_from_instructions.py`** - Extraction d'ingrédients
- **`apply-translations.sh`** - Application des traductions au code source
- **`download_culinary_dictionary.sh`** - Téléchargement du dictionnaire culinaire

### 🧪 `testing/` - Tests
Scripts pour tester l'application et l'API.

- **`test_api.sh`** - Tests de l'API backend
- **`test-recipes.sh`** - Tests interactifs des recettes

### 🚢 `deployment/` - Déploiement
Scripts pour le déploiement en production.

- **`deploy-portainer.sh`** - Déploiement via Portainer

### 🛠️ `utils/` - Utilitaires
Scripts utilitaires généraux.

- **`memory_monitor.sh`** - Monitoring de la mémoire
- **`detect-language.sh`** - Détection de la langue
- **`setup_libretranslate.sh`** - Configuration de LibreTranslate

### 🤖 `ai/` - Intelligence Artificielle
Scripts pour l'entraînement et la gestion des modèles IA.

- **`train-translation-model.sh`** - Entraînement du modèle de traduction
- **`ai-training-menu.sh`** - Menu interactif d'entraînement IA

## 📝 Utilisation

Tous les scripts sont accessibles via le `Makefile` à la racine du projet :

```bash
# Développement
make dev              # Lance le développement
make logs             # Affiche les logs
make install-android  # Installe sur Android

# Traduction
make improve-translations      # Améliore les traductions
make export-translation-data   # Exporte les données

# Tests
make test-api         # Teste l'API
make test-recipes     # Teste les recettes

# IA
make train-ai         # Menu d'entraînement IA
make retrain-ml       # Réentraîne le modèle ML

# Utilitaires
make memory-monitor   # Monitoring mémoire
```

## 🔧 Modification des scripts

Si vous modifiez un script, pensez à :
1. Mettre à jour le `Makefile` si le chemin change
2. Documenter les changements dans ce README
3. Tester le script avant de commiter

