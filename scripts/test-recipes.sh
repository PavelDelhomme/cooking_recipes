#!/bin/bash

# Script interactif pour tester les portions et unités de mesure des recettes
# Usage: make test-recipes

set -e

echo "🧪 Test interactif des recettes - Portions et unités de mesure"
echo "================================================================"
echo ""

# Vérifier que le backend est démarré
if ! curl -s http://localhost:7272/health > /dev/null 2>&1; then
    echo "❌ Le backend n'est pas démarré. Lancez 'make backend-dev' d'abord."
    exit 1
fi

# Nombre de recettes à tester
NUM_RECIPES=${1:-10}

echo "📥 Récupération de $NUM_RECIPES recettes..."
echo ""

# Récupérer des recettes depuis TheMealDB
RECIPES=$(curl -s "https://www.themealdb.com/api/json/v1/1/random.php" | jq -r '.meals[0]')

if [ -z "$RECIPES" ] || [ "$RECIPES" = "null" ]; then
    echo "❌ Erreur lors de la récupération des recettes"
    exit 1
fi

# Fonction pour afficher une recette et demander validation
test_recipe() {
    local recipe_json="$1"
    local recipe_id=$(echo "$recipe_json" | jq -r '.idMeal')
    local recipe_name=$(echo "$recipe_json" | jq -r '.strMeal')
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Recette: $recipe_name (ID: $recipe_id)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Afficher les ingrédients
    echo "🥘 Ingrédients:"
    for i in {1..20}; do
        local ingredient=$(echo "$recipe_json" | jq -r ".strIngredient$i // empty")
        local measure=$(echo "$recipe_json" | jq -r ".strMeasure$i // empty")
        
        if [ -n "$ingredient" ] && [ "$ingredient" != "null" ] && [ "$ingredient" != "" ]; then
            echo "   • $ingredient: $measure"
        fi
    done
    
    echo ""
    echo "📝 Instructions:"
    local instructions=$(echo "$recipe_json" | jq -r '.strInstructions' | head -c 200)
    echo "   $instructions..."
    echo ""
    
    # Demander validation pour chaque ingrédient
    echo "🔍 Validation des ingrédients (appuyez sur Entrée pour passer, 'q' pour quitter):"
    echo ""
    
    for i in {1..20}; do
        local ingredient=$(echo "$recipe_json" | jq -r ".strIngredient$i // empty")
        local measure=$(echo "$recipe_json" | jq -r ".strMeasure$i // empty")
        
        if [ -n "$ingredient" ] && [ "$ingredient" != "null" ] && [ "$ingredient" != "" ]; then
            echo "   ┌─ Ingrédient: $ingredient"
            echo "   │  Mesure: $measure"
            echo -n "   └─ ✅ Correct? (o/n/q): "
            read -r response
            
            if [ "$response" = "q" ]; then
                echo ""
                echo "👋 Arrêt du test."
                exit 0
            fi
            
            local is_correct="false"
            if [ "$response" = "o" ] || [ "$response" = "O" ] || [ "$response" = "" ]; then
                is_correct="true"
            fi
            
            # Stocker le résultat
            echo "$recipe_id|$ingredient|$measure|$is_correct" >> /tmp/recipe_test_results.txt
        fi
    done
    
    echo ""
    echo "✅ Recette testée et enregistrée"
    echo ""
}

# Créer le fichier de résultats
rm -f /tmp/recipe_test_results.txt
touch /tmp/recipe_test_results.txt

# Tester plusieurs recettes
for i in $(seq 1 $NUM_RECIPES); do
    echo "🔄 Récupération de la recette $i/$NUM_RECIPES..."
    RECIPE=$(curl -s "https://www.themealdb.com/api/json/v1/1/random.php" | jq -r '.meals[0]')
    
    if [ -n "$RECIPE" ] && [ "$RECIPE" != "null" ]; then
        test_recipe "$RECIPE"
    else
        echo "⚠️  Erreur lors de la récupération de la recette $i"
    fi
    
    # Pause entre les recettes
    sleep 1
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résultats du test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Analyser les résultats
TOTAL=$(wc -l < /tmp/recipe_test_results.txt)
CORRECT=$(grep -c "|true$" /tmp/recipe_test_results.txt || echo "0")
INCORRECT=$(grep -c "|false$" /tmp/recipe_test_results.txt || echo "0")

echo "📈 Statistiques:"
echo "   • Total d'ingrédients testés: $TOTAL"
echo "   • Corrects: $CORRECT"
echo "   • Incorrects: $INCORRECT"
echo ""

if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$((CORRECT * 100 / TOTAL))
    echo "   • Taux de réussite: ${PERCENTAGE}%"
fi

echo ""
echo "📁 Résultats détaillés sauvegardés dans: /tmp/recipe_test_results.txt"
echo ""

