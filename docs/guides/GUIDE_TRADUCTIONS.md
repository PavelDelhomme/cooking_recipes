# 🌍 Guide d'Amélioration des Traductions

Ce guide explique comment améliorer manuellement les traductions des recettes pour obtenir des traductions plus précises et naturelles.

## 🚀 Utilisation

### Lancer l'outil

```bash
make improve-translations
```

Ou directement :

```bash
python3 scripts/improve_translations.py
```

## 📋 Fonctionnalités

### 1. ➕ Ajouter/Modifier une traduction d'instruction

Permet d'ajouter ou de modifier la traduction d'une instruction de recette.

**Exemple :**
- Instruction originale (EN) : `"Heat the oil in a large pan"`
- Traduction FR : `"Faites chauffer l'huile dans une grande poêle"`
- Traduction ES : `"Calienta el aceite en una sartén grande"`

### 2. 🔍 Rechercher des instructions

Recherche des instructions existantes dans le dictionnaire. Supporte :
- Recherche exacte
- Recherche partielle
- Recherche similaire (basée sur les mots communs)

### 3. 📋 Lister toutes les instructions

Affiche toutes les instructions traduites avec leurs traductions en français et espagnol.

### 4. 🍅 Améliorer une traduction d'ingrédient

Permet d'améliorer les traductions d'ingrédients existants dans le dictionnaire.

### 5. 📊 Statistiques

Affiche le nombre total de traductions dans chaque dictionnaire :
- Instructions
- Ingrédients
- Noms de recettes

## 📁 Fichiers de dictionnaires

Les traductions sont stockées dans :

```
frontend/lib/data/culinary_dictionaries/
├── ingredients_fr_en_es.json      # Traductions d'ingrédients
├── recipe_names_fr_en_es.json     # Traductions de noms de recettes
└── instructions_fr_en_es.json     # Traductions d'instructions (créé automatiquement)
```

## 🔄 Comment ça fonctionne

1. **Priorité des traductions** :
   - Les traductions manuelles dans les fichiers JSON ont la **priorité absolue**
   - Si une instruction n'est pas trouvée dans le dictionnaire, le système utilise `AutoTranslator` comme fallback
   - En dernier recours, `LibreTranslate` peut être utilisé (avec rate limiting)

2. **Chargement automatique** :
   - Les dictionnaires sont chargés automatiquement au démarrage de l'application
   - Les modifications sont prises en compte après un redémarrage de l'application

3. **Format des fichiers JSON** :

```json
{
  "metadata": {
    "version": "1.0.0",
    "source": "Manual improvements",
    "languages": ["en", "fr", "es"],
    "total_terms": 10,
    "last_updated": "2025-12-09"
  },
  "instructions": {
    "heat the oil": {
      "en": "Heat the oil",
      "fr": "Faites chauffer l'huile",
      "es": "Calienta el aceite"
    }
  }
}
```

## 💡 Conseils pour améliorer les traductions

1. **Instructions complètes** : Traduisez des phrases complètes plutôt que des mots isolés
   - ✅ Bon : `"Heat the oil in a large pan"` → `"Faites chauffer l'huile dans une grande poêle"`
   - ❌ Moins bon : `"heat"` → `"chauffer"`

2. **Contexte culinaire** : Utilisez le vocabulaire culinaire approprié
   - `"pan"` → `"poêle"` (pas `"casserole"`)
   - `"stir"` → `"remuer"` (pas `"agiter"`)

3. **Cohérence** : Utilisez les mêmes termes pour les mêmes actions
   - `"chop"` → toujours `"hacher"` (pas `"couper"` parfois)
   - `"dice"` → toujours `"couper en dés"`

4. **Phrases naturelles** : Les traductions doivent sonner naturelles en français/espagnol
   - Évitez les traductions mot-à-mot
   - Adaptez la structure de la phrase si nécessaire

## 🔧 Intégration dans le code

Les traductions sont utilisées automatiquement via :

```dart
// Dans recipe_card_variants.dart et autres fichiers
TranslationService.translateInstructionSync(instruction)
```

Le système vérifie d'abord le dictionnaire JSON, puis utilise les fallbacks si nécessaire.

## 📝 Exemples de traductions courantes

### Instructions de base
- `"Preheat the oven"` → `"Préchauffez le four"` / `"Precalienta el horno"`
- `"Add salt and pepper"` → `"Ajoutez du sel et du poivre"` / `"Agrega sal y pimienta"`
- `"Cook for 10 minutes"` → `"Cuisez pendant 10 minutes"` / `"Cocina durante 10 minutos"`

### Techniques de cuisson
- `"Stir occasionally"` → `"Remuez de temps en temps"` / `"Revuelve ocasionalmente"`
- `"Bring to a boil"` → `"Portez à ébullition"` / `"Lleva a ebullición"`
- `"Simmer for 20 minutes"` → `"Laissez mijoter pendant 20 minutes"` / `"Cocina a fuego lento durante 20 minutos"`

## 🎯 Objectif

L'objectif est d'avoir un dictionnaire riche de traductions manuelles pour :
- ✅ Améliorer la qualité des traductions
- ✅ Réduire la dépendance aux services de traduction automatique
- ✅ Éviter les erreurs de traduction courantes
- ✅ Avoir des traductions cohérentes dans toute l'application

## 🔄 Sauvegarde

Toutes les modifications sont **immédiatement sauvegardées** dans les fichiers JSON et **persistent** dans le projet. Elles seront utilisées lors du prochain démarrage de l'application.

