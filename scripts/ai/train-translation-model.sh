#!/bin/bash

# Script pour entraîner le modèle de traduction à partir des résultats de test
# Usage: make train-translation

# Ne pas utiliser set -e car cela peut causer des problèmes avec les opérations conditionnelles
# set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_FILE="$PROJECT_ROOT/data/training_results/recipe_test_results.txt"
OUTPUT_DIR="$SCRIPT_DIR/../frontend/lib/services/translation_data"

echo "🤖 Entraînement du modèle de traduction"
echo "========================================"
echo ""

# Vérifier que le fichier de résultats existe
if [ ! -f "$RESULTS_FILE" ]; then
    echo "❌ Fichier de résultats introuvable: $RESULTS_FILE"
    echo "   Lancez d'abord 'make test-recipes' pour collecter des données"
    exit 1
fi

# Créer le répertoire de sortie
mkdir -p "$OUTPUT_DIR"

echo "📊 Analyse des résultats de test..."
echo ""

# Analyser les résultats de titre
TITLE_CORRECTIONS=$(grep "^RECIPE_TITLE|" "$RESULTS_FILE" 2>/dev/null || echo "")
INGREDIENT_CORRECTIONS=$(grep -v "^RECIPE_TITLE|" "$RESULTS_FILE" 2>/dev/null || echo "")

# Compter les corrections
TITLE_COUNT=$(echo "$TITLE_CORRECTIONS" | grep -c "|false|" 2>/dev/null | tr -d ' ' || echo "0")
INGREDIENT_COUNT=$(echo "$INGREDIENT_CORRECTIONS" | grep -c "|false|" 2>/dev/null | tr -d ' ' || echo "0")
# S'assurer que les valeurs sont numériques
TITLE_COUNT=${TITLE_COUNT:-0}
INGREDIENT_COUNT=${INGREDIENT_COUNT:-0}

echo "   • Corrections de titres: $TITLE_COUNT"
echo "   • Corrections d'ingrédients: $INGREDIENT_COUNT"
echo ""

# Extraire les nouvelles traductions des titres
echo "📝 Extraction des nouvelles traductions de titres..."
TITLE_TRANSLATIONS_FILE="$OUTPUT_DIR/title_translations.json"
TITLE_TRANSLATIONS="{}"

if [ "$TITLE_COUNT" -gt 0 ]; then
    echo "$TITLE_CORRECTIONS" | while IFS='|' read -r prefix recipe_id original lang auto_translated details correct translated_title comment; do
        if [ "$correct" = "false" ] && [ -n "$translated_title" ] && [ "$translated_title" != "$original" ]; then
            # Extraire les mots de l'original et de la traduction
            original_lower=$(echo "$original" | tr '[:upper:]' '[:lower:]')
            translated_lower=$(echo "$translated_title" | tr '[:upper:]' '[:lower:]')
            
            # Créer une entrée JSON pour cette traduction
            echo "{\"original\": \"$original_lower\", \"translated\": \"$translated_lower\", \"lang\": \"$lang\"}"
        fi
    done > "$OUTPUT_DIR/title_corrections.jsonl"
    
    echo "   ✅ $TITLE_COUNT corrections de titres extraites"
fi

# Extraire les nouvelles traductions d'ingrédients
echo "📝 Extraction des nouvelles traductions d'ingrédients..."
INGREDIENT_TRANSLATIONS_FILE="$OUTPUT_DIR/ingredient_translations.json"

if [ "$INGREDIENT_COUNT" -gt 0 ]; then
    echo "$INGREDIENT_CORRECTIONS" | while IFS='|' read -r recipe_id ingredient expected is_translated trans_correct correct_translation trans_comment measure measure_correct correct_measure measure_comment lang; do
        if [ "$trans_correct" = "false" ] && [ -n "$correct_translation" ] && [ "$correct_translation" != "$ingredient" ]; then
            # Normaliser les noms
            ingredient_lower=$(echo "$ingredient" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g')
            translation_lower=$(echo "$correct_translation" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g')
            
            if [ -n "$ingredient_lower" ] && [ -n "$translation_lower" ]; then
                echo "{\"ingredient\": \"$ingredient_lower\", \"translation\": \"$translation_lower\", \"lang\": \"$lang\"}"
            fi
        fi
    done > "$OUTPUT_DIR/ingredient_corrections.jsonl"
    
    echo "   ✅ $INGREDIENT_COUNT corrections d'ingrédients extraites"
fi

# Générer un fichier de statistiques
STATS_FILE="$OUTPUT_DIR/training_stats.json"
cat > "$STATS_FILE" << EOF
{
  "last_training": "$(date -Iseconds)",
  "title_corrections": $TITLE_COUNT,
  "ingredient_corrections": $INGREDIENT_COUNT,
  "total_corrections": $((TITLE_COUNT + INGREDIENT_COUNT))
}
EOF

echo ""
echo "✅ Entraînement terminé !"
echo ""
echo "📁 Fichiers générés:"
echo "   • $OUTPUT_DIR/title_corrections.jsonl"
echo "   • $OUTPUT_DIR/ingredient_corrections.jsonl"
echo "   • $STATS_FILE"
echo ""
echo "💡 Utilisez 'make apply-translations' pour appliquer les nouvelles traductions au code"

