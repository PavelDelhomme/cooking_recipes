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

# Demander la langue
echo "🌍 Sélection de la langue pour le test:"
echo "   1) Français (fr)"
echo "   2) English (en)"
echo "   3) Español (es)"
echo ""
echo -n "Choisissez la langue (1-3) [1]: "
read -r lang_choice

case "$lang_choice" in
    2)
        TEST_LANG="en"
        LANG_NAME="English"
        ;;
    3)
        TEST_LANG="es"
        LANG_NAME="Español"
        ;;
    *)
        TEST_LANG="fr"
        LANG_NAME="Français"
        ;;
esac

echo ""
echo "✅ Langue sélectionnée: $LANG_NAME ($TEST_LANG)"
echo ""

# Nombre de recettes à tester
NUM_RECIPES=${1:-10}

echo "📥 Récupération de $NUM_RECIPES recettes en $LANG_NAME..."
echo ""

# Récupérer des recettes depuis TheMealDB
RECIPES=$(curl -s "https://www.themealdb.com/api/json/v1/1/random.php" | jq -r '.meals[0]')

if [ -z "$RECIPES" ] || [ "$RECIPES" = "null" ]; then
    echo "❌ Erreur lors de la récupération des recettes"
    exit 1
fi

# Fonction pour traduire les labels selon la langue
get_label() {
    local key="$1"
    case "$TEST_LANG" in
        en)
            case "$key" in
                recipe) echo "Recipe" ;;
                ingredients) echo "Ingredients" ;;
                instructions) echo "Instructions" ;;
                ingredient) echo "Ingredient" ;;
                measure) echo "Measure" ;;
                correct) echo "Correct?" ;;
                tested) echo "Recipe tested and saved" ;;
                quit) echo "Quit test" ;;
                stats) echo "Test Results" ;;
                total) echo "Total ingredients tested" ;;
                correct_count) echo "Correct" ;;
                incorrect_count) echo "Incorrect" ;;
                success_rate) echo "Success rate" ;;
                saved) echo "Detailed results saved in" ;;
            esac
            ;;
        es)
            case "$key" in
                recipe) echo "Receta" ;;
                ingredients) echo "Ingredientes" ;;
                instructions) echo "Instrucciones" ;;
                ingredient) echo "Ingrediente" ;;
                measure) echo "Medida" ;;
                correct) echo "¿Correcto?" ;;
                tested) echo "Receta probada y guardada" ;;
                quit) echo "Salir del test" ;;
                stats) echo "Resultados del Test" ;;
                total) echo "Total de ingredientes probados" ;;
                correct_count) echo "Correctos" ;;
                incorrect_count) echo "Incorrectos" ;;
                success_rate) echo "Tasa de éxito" ;;
                saved) echo "Resultados detallados guardados en" ;;
            esac
            ;;
        *)
            case "$key" in
                recipe) echo "Recette" ;;
                ingredients) echo "Ingrédients" ;;
                instructions) echo "Instructions" ;;
                ingredient) echo "Ingrédient" ;;
                measure) echo "Mesure" ;;
                correct) echo "Correct?" ;;
                tested) echo "Recette testée et enregistrée" ;;
                quit) echo "Quitter le test" ;;
                stats) echo "Résultats du test" ;;
                total) echo "Total d'ingrédients testés" ;;
                correct_count) echo "Corrects" ;;
                incorrect_count) echo "Incorrects" ;;
                success_rate) echo "Taux de réussite" ;;
                saved) echo "Résultats détaillés sauvegardés dans" ;;
            esac
            ;;
    esac
}

# Fonction pour afficher une recette et demander validation
test_recipe() {
    local recipe_json="$1"
    local recipe_id=$(echo "$recipe_json" | jq -r '.idMeal')
    local recipe_name=$(echo "$recipe_json" | jq -r '.strMeal')
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 $(get_label recipe): $recipe_name (ID: $recipe_id) [$TEST_LANG]"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Afficher les ingrédients
    echo "🥘 $(get_label ingredients):"
    for i in {1..20}; do
        local ingredient=$(echo "$recipe_json" | jq -r ".strIngredient$i // empty")
        local measure=$(echo "$recipe_json" | jq -r ".strMeasure$i // empty")
        
        if [ -n "$ingredient" ] && [ "$ingredient" != "null" ] && [ "$ingredient" != "" ]; then
            echo "   • $ingredient: $measure"
        fi
    done
    
    echo ""
    echo "📝 $(get_label instructions):"
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
            echo "   ┌─ $(get_label ingredient): $ingredient"
            echo "   │  $(get_label measure): $measure"
            echo -n "   └─ ✅ $(get_label correct) (o/n/q): "
            read -r response
            
            if [ "$response" = "q" ] || [ "$response" = "Q" ]; then
                echo ""
                echo "👋 $(get_label quit)."
                exit 0
            fi
            
            local is_correct="false"
            if [ "$response" = "o" ] || [ "$response" = "O" ] || [ "$response" = "" ]; then
                is_correct="true"
            fi
            
            # Stocker le résultat avec la langue
            echo "$recipe_id|$ingredient|$measure|$is_correct|$TEST_LANG" >> /tmp/recipe_test_results.txt
        fi
    done
    
    echo ""
    echo "✅ $(get_label tested)"
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
echo "📊 $(get_label stats)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Analyser les résultats (filtrer par langue si nécessaire)
if [ -f /tmp/recipe_test_results.txt ]; then
    # Filtrer les résultats pour la langue actuelle
    LANG_RESULTS=$(grep "|$TEST_LANG$" /tmp/recipe_test_results.txt || echo "")
    
    if [ -n "$LANG_RESULTS" ]; then
        TOTAL=$(echo "$LANG_RESULTS" | wc -l)
        CORRECT=$(echo "$LANG_RESULTS" | grep -c "|true|" || echo "0")
        INCORRECT=$(echo "$LANG_RESULTS" | grep -c "|false|" || echo "0")
    else
        TOTAL=0
        CORRECT=0
        INCORRECT=0
    fi
else
    TOTAL=0
    CORRECT=0
    INCORRECT=0
fi

echo "📈 Statistiques [$TEST_LANG]:"
echo "   • $(get_label total): $TOTAL"
echo "   • $(get_label correct_count): $CORRECT"
echo "   • $(get_label incorrect_count): $INCORRECT"
echo ""

if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$((CORRECT * 100 / TOTAL))
    echo "   • $(get_label success_rate): ${PERCENTAGE}%"
fi

echo ""
echo "📁 $(get_label saved): /tmp/recipe_test_results.txt"
echo "   Langue testée: $LANG_NAME ($TEST_LANG)"
echo ""

