#!/bin/bash

# Menu interactif complet pour le système d'entraînement IA de traduction
# Usage: make train-ai

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_FILE="/tmp/recipe_test_results.txt"
TRANSLATION_DATA_DIR="$SCRIPT_DIR/../frontend/lib/services/translation_data"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Fonction pour afficher le header
show_header() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}🤖 Système d'Entraînement IA - Traductions Automatiques${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Fonction pour afficher les statistiques
show_stats() {
    echo -e "${YELLOW}📊 Statistiques actuelles:${NC}"
    echo ""
    
    if [ -f "$RESULTS_FILE" ]; then
        TOTAL_LINES=$(wc -l < "$RESULTS_FILE" 2>/dev/null || echo "0")
        TITLE_COUNT=$(grep -c "^RECIPE_TITLE|" "$RESULTS_FILE" 2>/dev/null || echo "0")
        INGREDIENT_COUNT=$((TOTAL_LINES - TITLE_COUNT))
        
        echo -e "   ${GREEN}•${NC} Fichier de résultats: ${BOLD}$RESULTS_FILE${NC}"
        echo -e "   ${GREEN}•${NC} Total d'enregistrements: ${BOLD}$TOTAL_LINES${NC}"
        echo -e "   ${GREEN}•${NC} Titres testés: ${BOLD}$TITLE_COUNT${NC}"
        echo -e "   ${GREEN}•${NC} Ingrédients testés: ${BOLD}$INGREDIENT_COUNT${NC}"
    else
        echo -e "   ${RED}•${NC} Aucun fichier de résultats trouvé"
    fi
    
    echo ""
    
    if [ -d "$TRANSLATION_DATA_DIR" ]; then
        CORRECTIONS_COUNT=$(find "$TRANSLATION_DATA_DIR" -name "*.jsonl" 2>/dev/null | wc -l)
        if [ "$CORRECTIONS_COUNT" -gt 0 ]; then
            echo -e "   ${GREEN}•${NC} Fichiers de corrections: ${BOLD}$CORRECTIONS_COUNT${NC}"
            if [ -f "$TRANSLATION_DATA_DIR/training_stats.json" ]; then
                LAST_TRAINING=$(jq -r '.last_training' "$TRANSLATION_DATA_DIR/training_stats.json" 2>/dev/null || echo "N/A")
                echo -e "   ${GREEN}•${NC} Dernier entraînement: ${BOLD}$LAST_TRAINING${NC}"
            fi
        else
            echo -e "   ${YELLOW}•${NC} Aucun fichier de corrections généré"
        fi
    else
        echo -e "   ${YELLOW}•${NC} Répertoire de données non créé"
    fi
    
    echo ""
}

# Fonction pour tester des recettes
test_recipes() {
    show_header
    echo -e "${YELLOW}🧪 Test de recettes pour entraînement${NC}"
    echo ""
    echo -e "Combien de recettes voulez-vous tester ?"
    echo -n "   Nombre [10]: "
    read -r num_recipes
    num_recipes=${num_recipes:-10}
    
    echo ""
    echo -e "${GREEN}Lancement du test interactif...${NC}"
    echo ""
    
    bash "$SCRIPT_DIR/test-recipes.sh" "$num_recipes"
    
    echo ""
    echo -e "${GREEN}✅ Test terminé !${NC}"
    echo ""
    echo -e "Appuyez sur Entrée pour continuer..."
    read -r
}

# Fonction pour entraîner le modèle
train_model() {
    show_header
    echo -e "${YELLOW}🎓 Entraînement du modèle de traduction${NC}"
    echo ""
    
    if [ ! -f "$RESULTS_FILE" ]; then
        echo -e "${RED}❌ Aucun fichier de résultats trouvé${NC}"
        echo -e "${YELLOW}   Lancez d'abord un test de recettes${NC}"
        echo ""
        echo -e "Appuyez sur Entrée pour continuer..."
        read -r
        return
    fi
    
    echo -e "${GREEN}Analyse des résultats de test...${NC}"
    echo ""
    
    bash "$SCRIPT_DIR/train-translation-model.sh"
    
    echo ""
    echo -e "${GREEN}✅ Entraînement terminé !${NC}"
    echo ""
    echo -e "Appuyez sur Entrée pour continuer..."
    read -r
}

# Fonction pour appliquer les traductions
apply_translations() {
    show_header
    echo -e "${YELLOW}🔄 Application des traductions apprises${NC}"
    echo ""
    
    bash "$SCRIPT_DIR/apply-translations.sh"
    
    echo ""
    echo -e "Appuyez sur Entrée pour continuer..."
    read -r
}

# Fonction pour voir les résultats détaillés
view_results() {
    show_header
    echo -e "${YELLOW}📋 Résultats détaillés${NC}"
    echo ""
    
    if [ ! -f "$RESULTS_FILE" ]; then
        echo -e "${RED}❌ Aucun fichier de résultats trouvé${NC}"
        echo ""
        echo -e "Appuyez sur Entrée pour continuer..."
        read -r
        return
    fi
    
    echo -e "${CYAN}Emplacement: $RESULTS_FILE${NC}"
    echo ""
    echo -e "${YELLOW}Dernières 20 lignes:${NC}"
    echo ""
    tail -20 "$RESULTS_FILE" | head -20
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "   ${GREEN}1.${NC} Voir tout le fichier"
    echo -e "   ${GREEN}2.${NC} Voir uniquement les titres"
    echo -e "   ${GREEN}3.${NC} Voir uniquement les ingrédients"
    echo -e "   ${GREEN}4.${NC} Retour au menu"
    echo ""
    echo -n "Choix [4]: "
    read -r choice
    
    case "$choice" in
        1)
            less "$RESULTS_FILE"
            ;;
        2)
            grep "^RECIPE_TITLE|" "$RESULTS_FILE" | less
            ;;
        3)
            grep -v "^RECIPE_TITLE|" "$RESULTS_FILE" | less
            ;;
        *)
            ;;
    esac
}

# Fonction pour voir les corrections apprises
view_corrections() {
    show_header
    echo -e "${YELLOW}📚 Corrections apprises${NC}"
    echo ""
    
    if [ ! -d "$TRANSLATION_DATA_DIR" ]; then
        echo -e "${RED}❌ Répertoire de données non trouvé${NC}"
        echo -e "${YELLOW}   Lancez d'abord l'entraînement${NC}"
        echo ""
        echo -e "Appuyez sur Entrée pour continuer..."
        read -r
        return
    fi
    
    if [ -f "$TRANSLATION_DATA_DIR/title_corrections.jsonl" ]; then
        echo -e "${GREEN}📝 Corrections de titres:${NC}"
        echo ""
        jq -r '"   • \(.original) → \(.translated)"' "$TRANSLATION_DATA_DIR/title_corrections.jsonl" 2>/dev/null | head -20
        echo ""
    fi
    
    if [ -f "$TRANSLATION_DATA_DIR/ingredient_corrections.jsonl" ]; then
        echo -e "${GREEN}🥘 Corrections d'ingrédients:${NC}"
        echo ""
        jq -r '"   • \(.ingredient) → \(.translation)"' "$TRANSLATION_DATA_DIR/ingredient_corrections.jsonl" 2>/dev/null | head -20
        echo ""
    fi
    
    if [ -f "$TRANSLATION_DATA_DIR/training_stats.json" ]; then
        echo -e "${GREEN}📊 Statistiques d'entraînement:${NC}"
        echo ""
        jq '.' "$TRANSLATION_DATA_DIR/training_stats.json" 2>/dev/null
        echo ""
    fi
    
    echo -e "Appuyez sur Entrée pour continuer..."
    read -r
}

# Fonction pour nettoyer les données
clean_data() {
    show_header
    echo -e "${YELLOW}🧹 Nettoyage des données${NC}"
    echo ""
    echo -e "${RED}⚠️  Attention: Cette action est irréversible !${NC}"
    echo ""
    echo -e "Que voulez-vous nettoyer ?"
    echo -e "   ${GREEN}1.${NC} Fichier de résultats uniquement"
    echo -e "   ${GREEN}2.${NC} Fichiers de corrections uniquement"
    echo -e "   ${GREEN}3.${NC} Tout (résultats + corrections)"
    echo -e "   ${GREEN}4.${NC} Annuler"
    echo ""
    echo -n "Choix [4]: "
    read -r choice
    
    case "$choice" in
        1)
            if [ -f "$RESULTS_FILE" ]; then
                rm -f "$RESULTS_FILE"
                echo -e "${GREEN}✅ Fichier de résultats supprimé${NC}"
            else
                echo -e "${YELLOW}⚠️  Fichier de résultats introuvable${NC}"
            fi
            ;;
        2)
            if [ -d "$TRANSLATION_DATA_DIR" ]; then
                rm -f "$TRANSLATION_DATA_DIR"/*.jsonl "$TRANSLATION_DATA_DIR"/*.json 2>/dev/null
                echo -e "${GREEN}✅ Fichiers de corrections supprimés${NC}"
            else
                echo -e "${YELLOW}⚠️  Répertoire de corrections introuvable${NC}"
            fi
            ;;
        3)
            if [ -f "$RESULTS_FILE" ]; then
                rm -f "$RESULTS_FILE"
                echo -e "${GREEN}✅ Fichier de résultats supprimé${NC}"
            fi
            if [ -d "$TRANSLATION_DATA_DIR" ]; then
                rm -rf "$TRANSLATION_DATA_DIR"
                echo -e "${GREEN}✅ Répertoire de corrections supprimé${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}Annulation${NC}"
            ;;
    esac
    
    echo ""
    echo -e "Appuyez sur Entrée pour continuer..."
    read -r
}

# Fonction pour exporter les données
export_data() {
    show_header
    echo -e "${YELLOW}📤 Export des données${NC}"
    echo ""
    
    EXPORT_DIR="$SCRIPT_DIR/../exports"
    mkdir -p "$EXPORT_DIR"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    EXPORT_FILE="$EXPORT_DIR/translation_training_$TIMESTAMP.tar.gz"
    
    echo -e "Création de l'archive d'export...${NC}"
    
    tar -czf "$EXPORT_FILE" \
        "$RESULTS_FILE" \
        "$TRANSLATION_DATA_DIR" 2>/dev/null || true
    
    if [ -f "$EXPORT_FILE" ]; then
        SIZE=$(du -h "$EXPORT_FILE" | cut -f1)
        echo -e "${GREEN}✅ Export créé: $EXPORT_FILE${NC}"
        echo -e "   Taille: $SIZE"
    else
        echo -e "${RED}❌ Erreur lors de la création de l'export${NC}"
    fi
    
    echo ""
    echo -e "Appuyez sur Entrée pour continuer..."
    read -r
}

# Menu principal
main_menu() {
    while true; do
        show_header
        show_stats
        
        echo -e "${BOLD}${CYAN}Menu Principal:${NC}"
        echo ""
        echo -e "   ${GREEN}1.${NC} ${BOLD}🧪 Tester des recettes${NC}          - Collecter des données pour l'entraînement"
        echo -e "   ${GREEN}2.${NC} ${BOLD}🎓 Entraîner le modèle${NC}           - Analyser les résultats et extraire les traductions"
        echo -e "   ${GREEN}3.${NC} ${BOLD}🔄 Appliquer les traductions${NC}    - Voir les traductions à intégrer au code"
        echo -e "   ${GREEN}4.${NC} ${BOLD}📋 Voir les résultats${NC}            - Consulter les données collectées"
        echo -e "   ${GREEN}5.${NC} ${BOLD}📚 Voir les corrections apprises${NC} - Consulter les traductions apprises"
        echo -e "   ${GREEN}6.${NC} ${BOLD}🧹 Nettoyer les données${NC}         - Supprimer les fichiers de test/corrections"
        echo -e "   ${GREEN}7.${NC} ${BOLD}📤 Exporter les données${NC}          - Créer une archive des données"
        echo -e "   ${GREEN}8.${NC} ${BOLD}❌ Quitter${NC}"
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -n "Votre choix [1-8]: "
        read -r choice
        
        case "$choice" in
            1)
                test_recipes
                ;;
            2)
                train_model
                ;;
            3)
                apply_translations
                ;;
            4)
                view_results
                ;;
            5)
                view_corrections
                ;;
            6)
                clean_data
                ;;
            7)
                export_data
                ;;
            8)
                echo ""
                echo -e "${GREEN}👋 Au revoir !${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Choix invalide${NC}"
                sleep 1
                ;;
        esac
    done
}

# Point d'entrée
main_menu

