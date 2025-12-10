#!/bin/bash

# Script interactif pour tester les portions et unités de mesure des recettes
# Usage: make test-recipes

# Ne pas utiliser set -e car cela peut causer des problèmes avec l'arithmétique et les commandes interactives
# set -e

# Charger les traductions d'ingrédients et la détection de langue
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_FILE="$PROJECT_ROOT/data/training_results/recipe_test_results.txt"
source "$SCRIPT_DIR/ingredient_translations.sh"
source "$SCRIPT_DIR/detect-language.sh"

# Créer le répertoire s'il n'existe pas
mkdir -p "$(dirname "$RESULTS_FILE")"

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

# Fonction pour simuler la traduction automatique du titre (comme TranslationService.translateRecipeName)
simulate_title_translation() {
    local title="$1"
    local lang="$2"
    
    if [ "$lang" = "en" ]; then
        echo "$title"
        return
    fi
    
    # Dictionnaires de traduction (simplifiés pour bash)
    local translated="$title"
    local translated_words=""
    local translation_steps=""
    
    if [ "$lang" = "fr" ]; then
        # Dictionnaire anglais -> français (termes courants)
        declare -A recipe_terms=(
            ["chicken"]="Poulet"
            ["beef"]="Bœuf"
            ["pork"]="Porc"
            ["fish"]="Poisson"
            ["salmon"]="Saumon"
            ["pasta"]="Pâtes"
            ["spaghetti"]="Spaghettis"
            ["lasagna"]="Lasagne"
            ["lasagne"]="Lasagne"
            ["rice"]="Riz"
            ["soup"]="Soupe"
            ["salad"]="Salade"
            ["sandwich"]="Sandwich"
            ["burger"]="Burger"
            ["pizza"]="Pizza"
            ["cake"]="Gâteau"
            ["pie"]="Tarte"
            ["bread"]="Pain"
            ["stew"]="Ragoût"
            ["curry"]="Curry"
            ["stir fry"]="Sauté"
            ["roast"]="Rôti"
            ["grilled"]="Grillé"
            ["baked"]="Cuit au four"
            ["fried"]="Frit"
            ["boiled"]="Bouilli"
            ["steamed"]="Cuit à la vapeur"
            ["vegan"]="Végétalien"
            ["vegetarian"]="Végétarien"
            ["vegetable"]="Légume"
            ["vegetables"]="Légumes"
        )
        
        # Traduire mot par mot (simplifié)
        local words=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -s ' ' | sed 's/^ *//;s/ *$//')
        local result_words=""
        local word_translations=""
        
        for word in $words; do
            # Nettoyer le mot (enlever ponctuation)
            local clean_word=$(echo "$word" | sed 's/[^a-z]//g')
            local translation="${recipe_terms[$clean_word]}"
            
            if [ -n "$translation" ]; then
                result_words="$result_words $translation"
                word_translations="$word_translations|$clean_word->$translation"
            else
                result_words="$result_words $word"
                word_translations="$word_translations|$clean_word->[NON_TRADUIT]"
            fi
        done
        
        # Nettoyer et capitaliser
        result_words=$(echo "$result_words" | sed 's/^ *//;s/ *$//' | sed 's/\([a-z]\)/\U\1/g' | sed 's/\([A-Z]\)\([A-Z]*\)/\1\L\2/g')
        translated="$result_words"
        translation_steps="${word_translations#|}"  # Enlever le premier |
    elif [ "$lang" = "es" ]; then
        # Pour l'espagnol, on peut faire quelque chose de similaire
        # Pour l'instant, on retourne juste le titre
        translated="$title"
        translation_steps="[TRADUCTION_ES_NON_IMPLÉMENTÉE]"
    fi
    
    # Retourner la traduction et les détails
    echo "$translated|$translation_steps"
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
    
    # Validation du titre de la recette (boucle pour permettre les modifications)
    while true; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📝 Validation du titre de la recette"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Détecter la langue originale du titre
        local original_lang=$(detect_language "$recipe_name")
        local lang_name=""
        case "$original_lang" in
            es) lang_name="Espagnol" ;;
            en) lang_name="Anglais" ;;
            *) lang_name="Inconnu" ;;
        esac
        
        echo "   📋 Titre original ($lang_name): $recipe_name"
        echo "   🌍 Langue détectée: $lang_name ($original_lang)"
        
        if [ "$TEST_LANG" != "en" ]; then
        # Simuler la traduction automatique du système
        local auto_translation_result=$(simulate_title_translation "$recipe_name" "$TEST_LANG")
        local auto_translated_title=$(echo "$auto_translation_result" | cut -d'|' -f1)
        local translation_details=$(echo "$auto_translation_result" | cut -d'|' -f2-)
        
        echo "   🤖 Traduction automatique ($TEST_LANG): $auto_translated_title"
        if [ -n "$translation_details" ] && [ "$translation_details" != "[TRADUCTION_ES_NON_IMPLÉMENTÉE]" ]; then
            echo "   📝 Détails de traduction (mots individuels):"
            # Parser les détails de traduction
            echo "$translation_details" | tr '|' '\n' | while IFS='->' read -r word trans || [ -n "$word" ]; do
                if [ -n "$word" ] && [ -n "$trans" ]; then
                    # Nettoyer les espaces
                    word=$(echo "$word" | sed 's/^ *//;s/ *$//')
                    trans=$(echo "$trans" | sed 's/^ *//;s/ *$//')
                    if [ -n "$word" ] && [ -n "$trans" ]; then
                        if [ "$trans" != "[NON_TRADUIT]" ]; then
                            echo "      • $word → $trans"
                        else
                            echo "      • $word → [NON TRADUIT]"
                        fi
                    fi
                fi
            done
        fi
        echo ""
        echo -n "   ✅ Traduction automatique correcte? (o/n/a/q) [a=annuler, q=quitter]: "
        read -r title_response
        
        if [ "$title_response" = "q" ] || [ "$title_response" = "Q" ]; then
            echo ""
            echo "👋 $(get_label quit)."
            exit 0
        fi
        
        # Si annulation, revenir au début de la validation du titre
        if [ "$title_response" = "a" ] || [ "$title_response" = "A" ]; then
            echo ""
            echo "   ↺ Annulation, retour à la validation du titre..."
            continue  # Retourner au début de la boucle de validation du titre
        fi
        
        local title_correct="true"
        local correct_title="$recipe_name"
        local title_comment=""
        
        if [ "$title_response" != "o" ] && [ "$title_response" != "O" ] && [ -n "$title_response" ]; then
            title_correct="false"
            echo ""
            echo -n "   │  📝 Quelle devrait être la traduction correcte ($TEST_LANG)? (a=annuler): "
            read -r correct_title
            
            # Annulation de la correction
            if [ "$correct_title" = "a" ] || [ "$correct_title" = "A" ]; then
                echo "   ↺ Annulation de la correction, retour à la validation..."
                title_correct="true"
                correct_title="$recipe_name"
            else
                if [ -z "$correct_title" ]; then
                    correct_title="$recipe_name"
                fi
                echo "   │  💬 Commentaire détaillé (optionnel, appuyez sur Entrée deux fois pour terminer, 'a' pour annuler):"
                title_comment=""
                local first_line=true
                while true; do
                    echo -n "   │     "
                    read -r line
                    if [ "$line" = "a" ] || [ "$line" = "A" ]; then
                        echo "   ↺ Annulation du commentaire"
                        title_comment=""
                        break
                    fi
                    if [ -z "$line" ]; then
                        if [ "$first_line" = "false" ]; then
                            break
                        fi
                        first_line=false
                        continue
                    fi
                    first_line=false
                    if [ -n "$title_comment" ]; then
                        title_comment="$title_comment|$line"
                    else
                        title_comment="$line"
                    fi
                done
            fi
        fi
        
        # Demander confirmation ou modification
        echo ""
        echo -n "   💾 Valider ce titre? (o/m/q) [o=valider, m=modifier, q=quitter]: "
        read -r title_confirm
        
        if [ "$title_confirm" = "q" ] || [ "$title_confirm" = "Q" ]; then
            echo ""
            echo "👋 $(get_label quit)."
            exit 0
        fi
        
        # Si modification demandée, recommencer la validation
        if [ "$title_confirm" = "m" ] || [ "$title_confirm" = "M" ]; then
            echo ""
            echo "   ↺ Modification du titre, retour à la validation..."
            continue
        fi
        
        # Stocker le résultat du titre avec la traduction automatique et la langue originale
        # Format: RECIPE_TITLE|recipe_id|recipe_name|original_lang|test_lang|auto_translated_title|translation_details|title_correct|correct_title|title_comment
        if [ "$TEST_LANG" != "en" ]; then
            echo "RECIPE_TITLE|$recipe_id|$recipe_name|$original_lang|$TEST_LANG|$auto_translated_title|$translation_details|$title_correct|$correct_title|$title_comment" >> "$RESULTS_FILE"
        fi
        fi  # Fin du if TEST_LANG != "en"
        break  # Sortir de la boucle de validation du titre
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
            local correct_translation="$expected_translation"
            local translation_comment=""
            
            if [ "$TEST_LANG" != "en" ]; then
                if [ "$is_translated" = "false" ]; then
                    echo -n "   ├─ ⚠️  Ingrédient non traduit - Correct? (o/n/b/a/q) [b=retour, a=annuler, q=quitter]: "
                else
                    echo -n "   ├─ ✅ Traduction correcte? (o/n/b/a/q) [b=retour, a=annuler, q=quitter]: "
                fi
                read -r translation_response
                
                if [ "$translation_response" = "q" ] || [ "$translation_response" = "Q" ]; then
                    echo ""
                    echo "👋 $(get_label quit)."
                    exit 0
                fi
                
                # Retour en arrière à l'ingrédient précédent
                if [ "$translation_response" = "b" ] || [ "$translation_response" = "B" ]; then
                    if [ $current_ingredient -gt 1 ]; then
                        echo ""
                        echo "   ↺ Retour à l'ingrédient précédent..."
                        # Revenir de 2 positions dans la boucle (on va revenir au début de cette itération)
                        current_ingredient=$((current_ingredient - 2))
                        # Trouver l'ingrédient précédent dans la liste
                        local prev_i=$((i - 1))
                        while [ $prev_i -gt 0 ]; do
                            local prev_ingredient=$(echo "$recipe_json" | jq -r ".strIngredient$prev_i // empty")
                            if [ -n "$prev_ingredient" ] && [ "$prev_ingredient" != "null" ] && [ "$prev_ingredient" != "" ]; then
                                i=$prev_i
                                break
                            fi
                            prev_i=$((prev_i - 1))
                        done
                        continue
                    else
                        echo "   ⚠️  Pas d'ingrédient précédent, retour au titre..."
                        # Retourner au titre
                        continue 2
                    fi
                fi
                
                # Annulation
                if [ "$translation_response" = "a" ] || [ "$translation_response" = "A" ]; then
                    echo ""
                    echo "   ↺ Annulation, passage à l'ingrédient suivant..."
                    translation_correct="true"
                    correct_translation="$expected_translation"
                    translation_comment=""
                elif [ "$translation_response" != "o" ] && [ "$translation_response" != "O" ] && [ -n "$translation_response" ]; then
                    translation_correct="false"
                    # Demander la traduction correcte
                    echo ""
                    echo -n "   │  📝 Quelle devrait être la traduction correcte ($TEST_LANG)? (a=annuler): "
                    read -r correct_translation
                    
                    # Annulation de la correction
                    if [ "$correct_translation" = "a" ] || [ "$correct_translation" = "A" ]; then
                        echo "   ↺ Annulation de la correction"
                        translation_correct="true"
                        correct_translation="$expected_translation"
                        translation_comment=""
                    else
                        if [ -z "$correct_translation" ]; then
                            correct_translation="$expected_translation"
                        fi
                        echo "   │  💬 Commentaire détaillé (optionnel, appuyez sur Entrée deux fois pour terminer, 'a' pour annuler):"
                        translation_comment=""
                        local first_line=true
                        while true; do
                            echo -n "   │     "
                            read -r line
                            if [ "$line" = "a" ] || [ "$line" = "A" ]; then
                                echo "   ↺ Annulation du commentaire"
                                translation_comment=""
                                break
                            fi
                            if [ -z "$line" ]; then
                                if [ "$first_line" = "false" ]; then
                                    break
                                fi
                                first_line=false
                                continue
                            fi
                            first_line=false
                            if [ -n "$translation_comment" ]; then
                                translation_comment="$translation_comment|$line"
                            else
                                translation_comment="$line"
                            fi
                        done
                    fi
                fi
            fi
            
            # Demander si la mesure est correcte
            echo -n "   └─ ✅ $(get_label measure) correcte pour cet ingrédient? (o/n/b/a/q) [b=retour traduction, a=annuler, q=quitter]: "
            read -r measure_response
            
            if [ "$measure_response" = "q" ] || [ "$measure_response" = "Q" ]; then
                echo ""
                echo "👋 $(get_label quit)."
                exit 0
            fi
            
            # Retour à la validation de la traduction
            if [ "$measure_response" = "b" ] || [ "$measure_response" = "B" ]; then
                echo ""
                echo "   ↺ Retour à la validation de la traduction..."
                # Revenir à la question de traduction
                if [ "$TEST_LANG" != "en" ]; then
                    if [ "$is_translated" = "false" ]; then
                        echo -n "   ├─ ⚠️  Ingrédient non traduit - Correct? (o/n/b/a/q): "
                    else
                        echo -n "   ├─ ✅ Traduction correcte? (o/n/b/a/q): "
                    fi
                    read -r translation_response_retry
                    # Traiter la réponse (simplifié pour l'exemple)
                    if [ "$translation_response_retry" = "a" ] || [ "$translation_response_retry" = "A" ]; then
                        translation_correct="true"
                        correct_translation="$expected_translation"
                        translation_comment=""
                    fi
                fi
                # Continuer avec la mesure
                echo -n "   └─ ✅ $(get_label measure) correcte pour cet ingrédient? (o/n/a/q): "
                read -r measure_response
            fi
            
            local measure_correct="false"
            local correct_measure="$measure"
            local measure_comment=""
            
            # Annulation
            if [ "$measure_response" = "a" ] || [ "$measure_response" = "A" ]; then
                echo ""
                echo "   ↺ Annulation, passage à l'ingrédient suivant..."
                measure_correct="true"
                correct_measure="$measure"
                measure_comment=""
            elif [ "$measure_response" != "o" ] && [ "$measure_response" != "O" ] && [ -n "$measure_response" ]; then
                measure_correct="false"
                # Demander la mesure correcte
                echo ""
                echo -n "   │  📏 Quelle devrait être la mesure correcte? (a=annuler): "
                read -r correct_measure
                
                # Annulation de la correction
                if [ "$correct_measure" = "a" ] || [ "$correct_measure" = "A" ]; then
                    echo "   ↺ Annulation de la correction"
                    measure_correct="true"
                    correct_measure="$measure"
                    measure_comment=""
                else
                    if [ -z "$correct_measure" ]; then
                        correct_measure="$measure"
                    fi
                    echo "   │  💬 Commentaire détaillé (optionnel, appuyez sur Entrée deux fois pour terminer, 'a' pour annuler):"
                    echo "   │     Exemple: '1 cup ≈ 240-250 ml. Équivalent: tasse. 1/2 cup ≈ 120 ml, 1/3 cup ≈ 80 ml, 1/4 cup ≈ 60 ml.'"
                    measure_comment=""
                    local first_line=true
                    while true; do
                        echo -n "   │     "
                        read -r line
                        if [ "$line" = "a" ] || [ "$line" = "A" ]; then
                            echo "   ↺ Annulation du commentaire"
                            measure_comment=""
                            break
                        fi
                        if [ -z "$line" ]; then
                            if [ "$first_line" = "false" ]; then
                                break
                            fi
                            first_line=false
                            continue
                        fi
                        first_line=false
                        if [ -n "$measure_comment" ]; then
                            measure_comment="$measure_comment|$line"
                        else
                            measure_comment="$line"
                        fi
                    done
                fi
            else
                measure_correct="true"
            fi
            
            # Stocker le résultat avec toutes les informations incluant la langue originale
            # Format: recipe_id|ingredient|ingredient_original_lang|expected_translation|is_translated|translation_correct|correct_translation|translation_comment|measure|measure_correct|correct_measure|measure_comment|test_lang
            echo "$recipe_id|$ingredient|$ingredient_original_lang|$expected_translation|$is_translated|$translation_correct|$correct_translation|$translation_comment|$measure|$measure_correct|$correct_measure|$measure_comment|$TEST_LANG" >> "$RESULTS_FILE"
            echo ""
        fi
    done
    
    echo ""
    echo "✅ $(get_label tested)"
    echo ""
}

# Créer le fichier de résultats
rm -f "$RESULTS_FILE"
touch "$RESULTS_FILE"

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
if [ -f "$RESULTS_FILE" ]; then
    # Séparer les résultats de titre et d'ingrédients
    # Format titre: RECIPE_TITLE|recipe_id|recipe_name|original_lang|test_lang|...
    # Format ingrédient: recipe_id|ingredient|ingredient_original_lang|...|test_lang
    TITLE_RESULTS=$(grep "^RECIPE_TITLE|" "$RESULTS_FILE" | grep "|$TEST_LANG|" || echo "")
    INGREDIENT_RESULTS=$(grep -v "^RECIPE_TITLE|" "$RESULTS_FILE" | grep "|$TEST_LANG$" || echo "")
    
    # Filtrer les résultats pour la langue actuelle (ingrédients uniquement)
    LANG_RESULTS="$INGREDIENT_RESULTS"
    
    if [ -n "$LANG_RESULTS" ]; then
        TOTAL=$(echo "$LANG_RESULTS" | wc -l)
        
        # Statistiques de traduction
        # Format: recipe_id|ingredient|ingredient_original_lang|expected_translation|is_translated|translation_correct|correct_translation|translation_comment|measure|measure_correct|correct_measure|measure_comment|test_lang
        if [ "$TEST_LANG" != "en" ]; then
            TRANSLATION_CORRECT=$(echo "$LANG_RESULTS" | awk -F'|' '{if ($6 == "true") print}' | wc -l | tr -d ' ')
            TRANSLATION_INCORRECT=$(echo "$LANG_RESULTS" | awk -F'|' '{if ($6 == "false") print}' | wc -l | tr -d ' ')
            NOT_TRANSLATED=$(echo "$LANG_RESULTS" | awk -F'|' '{if ($5 == "false") print}' | wc -l | tr -d ' ')
            TRANSLATION_CORRECT=${TRANSLATION_CORRECT:-0}
            TRANSLATION_INCORRECT=${TRANSLATION_INCORRECT:-0}
            NOT_TRANSLATED=${NOT_TRANSLATED:-0}
        else
            TRANSLATION_CORRECT=0
            TRANSLATION_INCORRECT=0
            NOT_TRANSLATED=0
        fi
        
        # Statistiques de mesure
        MEASURE_CORRECT=$(echo "$LANG_RESULTS" | awk -F'|' '{if ($10 == "true") print}' | wc -l | tr -d ' ')
        MEASURE_INCORRECT=$(echo "$LANG_RESULTS" | awk -F'|' '{if ($10 == "false") print}' | wc -l | tr -d ' ')
        MEASURE_CORRECT=${MEASURE_CORRECT:-0}
        MEASURE_INCORRECT=${MEASURE_INCORRECT:-0}
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

    # Statistiques des titres
    # Format: RECIPE_TITLE|recipe_id|recipe_name|original_lang|test_lang|auto_translated_title|translation_details|title_correct|correct_title|title_comment
    if [ -n "$TITLE_RESULTS" ] && [ "$TEST_LANG" != "en" ]; then
        TITLE_TOTAL=$(echo "$TITLE_RESULTS" | wc -l | tr -d ' ')
        TITLE_CORRECT=$(echo "$TITLE_RESULTS" | awk -F'|' '{if ($8 == "true") print}' | wc -l | tr -d ' ')
        TITLE_INCORRECT=$(echo "$TITLE_RESULTS" | awk -F'|' '{if ($8 == "false") print}' | wc -l | tr -d ' ')
        TITLE_TOTAL=${TITLE_TOTAL:-0}
        TITLE_CORRECT=${TITLE_CORRECT:-0}
        TITLE_INCORRECT=${TITLE_INCORRECT:-0}
        
        echo ""
        echo "📈 Statistiques des titres de recettes ($TEST_LANG):"
        echo "   • Total de titres testés: $TITLE_TOTAL"
        echo "   • Titres corrects: $TITLE_CORRECT"
        echo "   • Titres incorrects: $TITLE_INCORRECT"
        if [ "$TITLE_TOTAL" -gt 0 ]; then
            TITLE_PERCENTAGE=$((TITLE_CORRECT * 100 / TITLE_TOTAL))
            echo "   • Taux de réussite: ${TITLE_PERCENTAGE}%"
        fi
        echo ""
    fi
    
    echo ""
    echo "📁 $(get_label saved): $RESULTS_FILE"
    echo "   Langue testée: $LANG_NAME ($TEST_LANG)"
    echo ""
    echo "📋 Format des résultats:"
    echo "   Titres: RECIPE_TITLE|recipe_id|recipe_name|original_lang|test_lang|auto_translated_title|translation_details|title_correct|correct_title|title_comment"
    echo "     - original_lang: Langue originale détectée automatiquement (en/es)"
    echo "     - auto_translated_title: Traduction automatique générée par le système"
    echo "     - translation_details: Détails des mots traduits (mot->traduction|mot->traduction|...)"
    echo "   Ingrédients: recipe_id|ingredient|ingredient_original_lang|expected_translation|is_translated|translation_correct|correct_translation|translation_comment|measure|measure_correct|correct_measure|measure_comment|test_lang"
    echo "     - ingredient_original_lang: Langue originale de l'ingrédient détectée automatiquement (en/es)"
    echo ""
    echo "💡 Les traductions et mesures correctes suggérées sont stockées pour analyse future"
    echo ""

