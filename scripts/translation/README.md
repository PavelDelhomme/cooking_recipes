# Scripts de Traduction

Scripts pour gérer les traductions, les dictionnaires et l'amélioration des traductions.

## Scripts disponibles

### Python

- **`improve_translations.py`** - Amélioration interactive des traductions
- **`export_translation_training_data.py`** - Export des données d'entraînement pour le ML
- **`translate_all_ingredients.py`** - Traduction de tous les ingrédients
- **`translate_all_recipe_names.py`** - Traduction de tous les noms de recettes
- **`complete_translations.py`** - Complétion des traductions manquantes
- **`build_complete_dictionary.py`** - Construction du dictionnaire complet
- **`extract_ingredients_from_instructions.py`** - Extraction d'ingrédients depuis les instructions

### Shell

- **`apply-translations.sh`** - Application des traductions apprises au code source
- **`ingredient_translations.sh`** - Script utilitaire pour les traductions d'ingrédients
- **`download_culinary_dictionary.sh`** - Téléchargement du dictionnaire culinaire

## Utilisation

```bash
# Améliorer les traductions
make improve-translations

# Exporter les données d'entraînement
make export-translation-data

# Appliquer les traductions
make apply-translations
```

