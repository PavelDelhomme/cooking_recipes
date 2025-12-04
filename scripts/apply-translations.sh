#!/bin/bash

# Script pour appliquer les traductions apprises au code source
# Usage: make apply-translations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSLATION_DATA_DIR="$SCRIPT_DIR/../frontend/lib/services/translation_data"
TRANSLATION_SERVICE="$SCRIPT_DIR/../frontend/lib/services/translation_service.dart"

echo "🔄 Application des traductions apprises"
echo "========================================"
echo ""

# Vérifier que les fichiers de corrections existent
if [ ! -f "$TRANSLATION_DATA_DIR/ingredient_corrections.jsonl" ] && [ ! -f "$TRANSLATION_DATA_DIR/title_corrections.jsonl" ]; then
    echo "❌ Aucun fichier de corrections trouvé"
    echo "   Lancez d'abord 'make train-translation' pour générer les corrections"
    exit 1
fi

echo "📝 Application des traductions d'ingrédients..."
INGREDIENT_COUNT=0

if [ -f "$TRANSLATION_DATA_DIR/ingredient_corrections.jsonl" ]; then
    # Lire les corrections et les appliquer
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            ingredient=$(echo "$line" | jq -r '.ingredient')
            translation=$(echo "$line" | jq -r '.translation')
            lang=$(echo "$line" | jq -r '.lang')
            
            if [ "$lang" = "fr" ] && [ -n "$ingredient" ] && [ -n "$translation" ]; then
                # Vérifier si la traduction existe déjà dans le code
                if ! grep -q "'$ingredient': '$translation'" "$TRANSLATION_SERVICE" 2>/dev/null; then
                    echo "   ➕ Ajout: '$ingredient' → '$translation'"
                    # Note: L'application automatique nécessiterait de modifier le fichier Dart
                    # Pour l'instant, on affiche juste les nouvelles traductions
                    INGREDIENT_COUNT=$((INGREDIENT_COUNT + 1))
                fi
            fi
        fi
    done < "$TRANSLATION_DATA_DIR/ingredient_corrections.jsonl"
fi

echo ""
echo "📝 Application des traductions de titres..."
TITLE_COUNT=0

if [ -f "$TRANSLATION_DATA_DIR/title_corrections.jsonl" ]; then
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            original=$(echo "$line" | jq -r '.original')
            translated=$(echo "$line" | jq -r '.translated')
            lang=$(echo "$line" | jq -r '.lang')
            
            if [ "$lang" = "fr" ] && [ -n "$original" ] && [ -n "$translated" ]; then
                echo "   ➕ Ajout: '$original' → '$translated'"
                TITLE_COUNT=$((TITLE_COUNT + 1))
            fi
        fi
    done < "$TRANSLATION_DATA_DIR/title_corrections.jsonl"
fi

echo ""
echo "✅ Application terminée !"
echo ""
echo "📊 Résumé:"
echo "   • $INGREDIENT_COUNT nouvelles traductions d'ingrédients"
echo "   • $TITLE_COUNT nouvelles traductions de titres"
echo ""
echo "💡 Les traductions doivent être ajoutées manuellement au code source"
echo "   ou via un script d'auto-génération plus avancé"

