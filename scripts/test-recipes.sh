#!/bin/bash

# Script interactif pour tester les portions et unités de mesure des recettes
# Usage: make test-recipes

# Ne pas utiliser set -e car cela peut causer des problèmes avec l'arithmétique et les commandes interactives
# set -e

# Charger les traductions d'ingrédients
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ingredient_translations.sh"

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
    local recipe_num="$2"  # Numéro de la recette (1, 2, 3...)
    local total_recipes="$3"  # Nombre total de recettes
    local recipe_id=$(echo "$recipe_json" | jq -r '.idMeal')
    local recipe_name=$(echo "$recipe_json" | jq -r '.strMeal')
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 $(get_label recipe) $recipe_num/$total_recipes: $recipe_name (ID: $recipe_id) [$TEST_LANG]"
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
    
    # Compter le nombre total d'ingrédients pour cette recette
    local total_ingredients=0
    for j in {1..20}; do
        local ing=$(echo "$recipe_json" | jq -r ".strIngredient$j // empty")
        if [ -n "$ing" ] && [ "$ing" != "null" ] && [ "$ing" != "" ]; then
            total_ingredients=$((total_ingredients + 1))
        fi
    done
    
    # Demander validation pour chaque ingrédient
    echo "🔍 Validation des ingrédients (appuyez sur Entrée pour passer, 'q' pour quitter):"
    echo ""
    
    local current_ingredient=0
    for i in {1..20}; do
        local ingredient=$(echo "$recipe_json" | jq -r ".strIngredient$i // empty")
        local measure=$(echo "$recipe_json" | jq -r ".strMeasure$i // empty")
        
        if [ -n "$ingredient" ] && [ "$ingredient" != "null" ] && [ "$ingredient" != "" ]; then
            current_ingredient=$((current_ingredient + 1))
            # Obtenir la traduction attendue
            local expected_translation=$(get_ingredient_translation "$ingredient" "$TEST_LANG")
            local is_translated="true"
            
            if [ -z "$expected_translation" ]; then
                expected_translation="[NON TRADUIT]"
                is_translated="false"
            fi
            
            echo "   ┌─ [Ingrédient $current_ingredient/$total_ingredients] $(get_label ingredient) original (EN): $ingredient"
            if [ "$TEST_LANG" != "en" ]; then
                if [ "$is_translated" = "true" ]; then
                    echo "   │  Traduction attendue ($TEST_LANG): $expected_translation"
                else
                    echo "   │  ⚠️  Traduction attendue ($TEST_LANG): $expected_translation"
                fi
            fi
            echo "   │  $(get_label measure): $measure"
            echo "   │  📊 Progression: Recette $recipe_num/$total_recipes | Ingrédient $current_ingredient/$total_ingredients"
            echo ""
            
            # Demander si la traduction est correcte (si ce n'est pas l'anglais)
            local translation_correct="true"
            if [ "$TEST_LANG" != "en" ]; then
                if [ "$is_translated" = "false" ]; then
                    echo -n "   ├─ ⚠️  Ingrédient non traduit - Correct? (o/n/q): "
                else
                    echo -n "   ├─ ✅ Traduction correcte? (o/n/q): "
                fi
                read -r translation_response
                
                if [ "$translation_response" = "q" ] || [ "$translation_response" = "Q" ]; then
                    echo ""
                    echo "👋 $(get_label quit)."
                    exit 0
                fi
                
                if [ "$translation_response" != "o" ] && [ "$translation_response" != "O" ] && [ -n "$translation_response" ]; then
                    translation_correct="false"
                fi
            fi
            
            # Demander si la mesure est correcte
            echo -n "   └─ ✅ $(get_label measure) correcte pour cet ingrédient? (o/n/q): "
            read -r measure_response
            
            if [ "$measure_response" = "q" ] || [ "$measure_response" = "Q" ]; then
                echo ""
                echo "👋 $(get_label quit)."
                exit 0
            fi
            
            local measure_correct="false"
            if [ "$measure_response" = "o" ] || [ "$measure_response" = "O" ] || [ "$measure_response" = "" ]; then
                measure_correct="true"
            fi
            
            # Stocker le résultat avec toutes les informations
            echo "$recipe_id|$ingredient|$expected_translation|$is_translated|$translation_correct|$measure|$measure_correct|$TEST_LANG" >> /tmp/recipe_test_results.txt
            echo ""
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Progression globale: 0/$NUM_RECIPES recettes testées"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for i in $(seq 1 $NUM_RECIPES); do
    echo "🔄 Récupération de la recette $i/$NUM_RECIPES..."
    RECIPE=$(curl -s "https://www.themealdb.com/api/json/v1/1/random.php" | jq -r '.meals[0]')
    
    if [ -n "$RECIPE" ] && [ "$RECIPE" != "null" ]; then
        test_recipe "$RECIPE" "$i" "$NUM_RECIPES"
        
        # Afficher la progression après chaque recette
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📊 Progression globale: $i/$NUM_RECIPES recettes testées"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
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
        
        # Statistiques de traduction
        if [ "$TEST_LANG" != "en" ]; then
            TRANSLATION_CORRECT=$(echo "$LANG_RESULTS" | grep -c "|true|true|" || echo "0")
            TRANSLATION_INCORRECT=$(echo "$LANG_RESULTS" | grep -c "|true|false|" || echo "0")
            NOT_TRANSLATED=$(echo "$LANG_RESULTS" | grep -c "|false|" || echo "0")
        else
            TRANSLATION_CORRECT=0
            TRANSLATION_INCORRECT=0
            NOT_TRANSLATED=0
        fi
        
        # Statistiques de mesure
        MEASURE_CORRECT=$(echo "$LANG_RESULTS" | awk -F'|' '{if ($7 == "true") print}' | wc -l)
        MEASURE_INCORRECT=$(echo "$LANG_RESULTS" | awk -F'|' '{if ($7 == "false") print}' | wc -l)
    else
        TOTAL=0
        TRANSLATION_CORRECT=0
        TRANSLATION_INCORRECT=0
        NOT_TRANSLATED=0
        MEASURE_CORRECT=0
        MEASURE_INCORRECT=0
    fi
else
    TOTAL=0
    TRANSLATION_CORRECT=0
    TRANSLATION_INCORRECT=0
    NOT_TRANSLATED=0
    MEASURE_CORRECT=0
    MEASURE_INCORRECT=0
fi

echo "📈 Statistiques [$TEST_LANG]:"
echo "   • $(get_label total): $TOTAL"
echo ""

if [ "$TEST_LANG" != "en" ]; then
    echo "   📝 Traductions:"
    echo "      • Correctes: $TRANSLATION_CORRECT"
    echo "      • Incorrectes: $TRANSLATION_INCORRECT"
    echo "      • Non traduites: $NOT_TRANSLATED"
    echo ""
    
    if [ $TOTAL -gt 0 ]; then
        TRANSLATION_PERCENTAGE=$((TRANSLATION_CORRECT * 100 / TOTAL))
        echo "      • Taux de réussite traduction: ${TRANSLATION_PERCENTAGE}%"
    fi
    echo ""
fi

echo "   📏 Mesures:"
echo "      • Correctes: $MEASURE_CORRECT"
echo "      • Incorrectes: $MEASURE_INCORRECT"
echo ""

if [ $TOTAL -gt 0 ]; then
    MEASURE_PERCENTAGE=$((MEASURE_CORRECT * 100 / TOTAL))
    echo "      • Taux de réussite mesure: ${MEASURE_PERCENTAGE}%"
fi

echo ""
echo "📁 $(get_label saved): /tmp/recipe_test_results.txt"
echo "   Langue testée: $LANG_NAME ($TEST_LANG)"
echo ""

