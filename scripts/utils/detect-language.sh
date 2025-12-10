#!/bin/bash

# Fonction pour détecter automatiquement la langue d'un texte
# Usage: detect_language "texte à analyser"

detect_language() {
    local text="$1"
    
    if [ -z "$text" ]; then
        echo "unknown"
        return
    fi
    
    # Normaliser le texte
    local lower_text=$(echo "$text" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')
    
    # Mots caractéristiques de l'espagnol
    local spanish_words=("pollo" "cerdo" "res" "pescado" "salmón" "arroz" "pasta" "sopa" "ensalada" "sándwich" "hamburguesa" "pastel" "tarta" "pan" "estofado" "salteado" "asado" "paella" "tortilla" "gazpacho" "tapas" "empanada" "flan" "churros" "con" "y" "de" "la" "el" "las" "los" "para" "con" "sin")
    
    # Mots caractéristiques de l'anglais
    local english_words=("chicken" "beef" "pork" "fish" "salmon" "rice" "pasta" "soup" "salad" "sandwich" "burger" "cake" "pie" "bread" "stew" "curry" "roast" "grilled" "baked" "fried" "boiled" "steamed" "vegan" "vegetarian" "with" "and" "of" "the" "for" "with" "without")
    
    # Compter les occurrences
    local spanish_count=0
    local english_count=0
    
    for word in "${spanish_words[@]}"; do
        if echo "$lower_text" | grep -q "\b$word\b"; then
            spanish_count=$((spanish_count + 1))
        fi
    done
    
    for word in "${english_words[@]}"; do
        if echo "$lower_text" | grep -q "\b$word\b"; then
            english_count=$((english_count + 1))
        fi
    done
    
    # Détecter la langue basée sur les occurrences
    if [ "$spanish_count" -gt "$english_count" ] && [ "$spanish_count" -gt 0 ]; then
        echo "es"
    elif [ "$english_count" -gt 0 ]; then
        echo "en"
    else
        # Si aucun mot caractéristique, analyser les caractères
        if echo "$text" | grep -qE "[áéíóúñÁÉÍÓÚÑ]"; then
            echo "es"
        else
            echo "en"  # Par défaut, on assume l'anglais pour TheMealDB
        fi
    fi
}

# Si appelé directement avec un argument
if [ $# -gt 0 ]; then
    detect_language "$1"
fi

