# 📋 Types de Feedback Supportés

## ✅ Tous les Éléments de Recette sont Couverts !

Le système collaboratif de traduction supporte **5 types de feedback** pour couvrir tous les éléments d'une recette :

### 1. 📝 Instructions (`instruction`)
- **Où** : Dans l'écran de détail de la recette, section "Instructions"
- **Comment** : Cliquer sur l'icône de traduction à côté d'une instruction
- **Exemple** : "Bring a large saucepan of salted water to the boil" → "Porter une grande casserole d'eau salée à ébullition"

### 2. 🥕 Ingrédients (`ingredient`)
- **Où** : Dans l'écran de détail de la recette, section "Ingrédients"
- **Comment** : Cliquer sur l'icône de traduction à côté d'un ingrédient
- **Exemple** : "chicken" → "poulet"

### 3. 🍽️ Titre de Recette (`recipeName`)
- **Où** : Dans l'écran de détail de la recette, en haut (titre)
- **Comment** : Cliquer sur l'icône de traduction à côté du titre
- **Exemple** : "Chicken Curry" → "Curry de Poulet"

### 4. 📏 Unités de Mesure (`unit`)
- **Où** : Dans l'écran de détail de la recette, à côté des quantités d'ingrédients
- **Comment** : Cliquer sur l'icône de traduction à côté d'une unité
- **Exemple** : "cup" → "tasse", "tablespoon" → "cuillère à soupe"

### 5. 📄 Description/Résumé (`summary`)
- **Où** : Dans l'écran de détail de la recette, section "Description"
- **Comment** : Cliquer sur la carte de description ou l'icône de traduction
- **Exemple** : "A delicious chicken curry recipe..." → "Une délicieuse recette de curry de poulet..."

---

## 🔄 Partage et Entraînement

**Tous ces types de feedback sont partagés entre tous les utilisateurs !**

### Stockage
- Tous les feedbacks sont stockés dans `translation_feedbacks`
- Chaque feedback a un `type` qui indique de quel élément il s'agit
- Le `user_id` est enregistré pour l'historique personnel

### Entraînement de l'IA
- L'IA charge **tous les feedbacks approuvés** (tous types confondus)
- Les feedbacks sont regroupés par type, texte original, et traduction suggérée
- Le `usage_count` compte combien d'utilisateurs ont suggéré la même traduction

### Modèles ML
- **Instructions** : Modèle `instructions_fr.json` / `instructions_es.json`
- **Ingrédients** : Modèle `ingredients_fr.json` / `ingredients_es.json`
- **Noms de recettes** : Modèle `recipeNames_fr.json` / `recipeNames_es.json`
- **Unités** : Modèle `units_fr.json` / `units_es.json`
- **Résumés** : Utilise le modèle `instructions_*` (même logique de traduction)

---

## 📊 Statistiques par Type

Les statistiques sont disponibles pour chaque type :

```sql
SELECT 
  COUNT(CASE WHEN type = 'instruction' THEN 1 END) as instructions,
  COUNT(CASE WHEN type = 'ingredient' THEN 1 END) as ingredients,
  COUNT(CASE WHEN type = 'recipeName' THEN 1 END) as recipeNames,
  COUNT(CASE WHEN type = 'unit' THEN 1 END) as units,
  COUNT(CASE WHEN type = 'summary' THEN 1 END) as summaries
FROM translation_feedbacks 
WHERE approved = 1
```

---

## 🎯 Interface Utilisateur

### Écran de Détail de Recette

Chaque élément peut être corrigé :

1. **Titre** → Icône de traduction → Feedback `recipeName`
2. **Description** → Clic sur la carte ou icône → Feedback `summary`
3. **Ingrédients** → Icône de traduction → Feedback `ingredient`
4. **Unités** → Icône de traduction → Feedback `unit`
5. **Instructions** → Icône de traduction → Feedback `instruction`

### Widget de Feedback

Le widget `TranslationFeedbackWidget` supporte tous les types :
- Affiche le type correct dans l'en-tête
- Génère des suggestions IA adaptées au type
- Permet de rejeter les mauvaises suggestions
- Enregistre le feedback avec le bon type

---

## ✅ Checklist de Support

- [x] **Instructions** → Supporté et fonctionnel
- [x] **Ingrédients** → Supporté et fonctionnel
- [x] **Titre de recette** → Supporté et fonctionnel
- [x] **Unités de mesure** → Supporté et fonctionnel
- [x] **Description/Résumé** → Supporté et fonctionnel

**Tous les éléments d'une recette peuvent être corrigés et améliorés ! 🎉**

