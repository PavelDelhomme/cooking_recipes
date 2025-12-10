#!/bin/bash

# Script de monitoring mémoire complet pour l'application Flutter
# Détecte les fuites mémoire et génère des rapports détaillés

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/reports/memory"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORTS_DIR/memory_report_${TIMESTAMP}.txt"
LEAK_REPORT="$REPORTS_DIR/leak_detection_${TIMESTAMP}.txt"

mkdir -p "$REPORTS_DIR"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔍 Monitoring Mémoire - Cooking Recipes${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Fonction pour obtenir l'utilisation mémoire d'un processus
get_process_memory() {
    local pid=$1
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
        echo "0"
        return
    fi
    
    # Utiliser /proc pour obtenir la mémoire (plus précis)
    if [ -f "/proc/$pid/status" ]; then
        # RSS (Resident Set Size) en KB
        local rss=$(grep "^VmRSS:" /proc/$pid/status 2>/dev/null | awk '{print $2}' || echo "0")
        echo "$rss"
    else
        # Fallback avec ps
        ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1}' || echo "0"
    fi
}

# Fonction pour convertir KB en MB
kb_to_mb() {
    local kb=$1
    echo "scale=2; $kb / 1024" | bc
}

# Fonction pour obtenir la mémoire totale du système
get_system_memory() {
    if [ -f /proc/meminfo ]; then
        grep "^MemTotal:" /proc/meminfo | awk '{print $2}'
    else
        echo "0"
    fi
}

# Fonction pour obtenir la mémoire disponible
get_available_memory() {
    if [ -f /proc/meminfo ]; then
        grep "^MemAvailable:" /proc/meminfo | awk '{print $2}'
    else
        echo "0"
    fi
}

# Fonction pour détecter les fuites mémoire
detect_memory_leaks() {
    local backend_pid=$1
    local frontend_pid=$2
    local duration=${3:-300}  # 5 minutes par défaut
    local interval=${4:-10}    # Vérifier toutes les 10 secondes
    
    echo -e "${BLUE}🔍 Détection de fuites mémoire (durée: ${duration}s, intervalle: ${interval}s)...${NC}"
    echo ""
    
    local samples=$((duration / interval))
    local backend_samples=()
    local frontend_samples=()
    local timestamps=()
    
    for ((i=0; i<samples; i++)); do
        local timestamp=$(date +%s)
        timestamps+=("$timestamp")
        
        if [ ! -z "$backend_pid" ] && kill -0 "$backend_pid" 2>/dev/null; then
            local backend_mem=$(get_process_memory "$backend_pid")
            backend_samples+=("$backend_mem")
        else
            backend_samples+=("0")
        fi
        
        if [ ! -z "$frontend_pid" ] && kill -0 "$frontend_pid" 2>/dev/null; then
            local frontend_mem=$(get_process_memory "$frontend_pid")
            frontend_samples+=("$frontend_mem")
        else
            frontend_samples+=("0")
        fi
        
        if [ $((i % 5)) -eq 0 ] && [ $i -gt 0 ]; then
            local backend_avg=$(IFS='+'; echo "scale=0; (${backend_samples[*]}) / ${#backend_samples[@]}" | bc 2>/dev/null || echo "0")
            local frontend_avg=$(IFS='+'; echo "scale=0; (${frontend_samples[*]}) / ${#frontend_samples[@]}" | bc 2>/dev/null || echo "0")
            echo -e "${YELLOW}   Échantillon $i/$samples - Backend: $(kb_to_mb $backend_avg) MB, Frontend: $(kb_to_mb $frontend_avg) MB${NC}"
        fi
        
        sleep "$interval"
    done
    
    # Analyser les tendances
    echo ""
    echo -e "${BLUE}📊 Analyse des tendances...${NC}"
    
    # Calculer la croissance moyenne
    local backend_growth=0
    local frontend_growth=0
    
    if [ ${#backend_samples[@]} -gt 1 ]; then
        local backend_start=${backend_samples[0]}
        local backend_end=${backend_samples[-1]}
        backend_growth=$(echo "scale=2; ($backend_end - $backend_start) / $backend_start * 100" | bc 2>/dev/null || echo "0")
    fi
    
    if [ ${#frontend_samples[@]} -gt 1 ]; then
        local frontend_start=${frontend_samples[0]}
        local frontend_end=${frontend_samples[-1]}
        frontend_growth=$(echo "scale=2; ($frontend_end - $frontend_start) / $frontend_start * 100" | bc 2>/dev/null || echo "0")
    fi
    
    # Détecter les fuites (croissance > 20%)
    {
        echo "═══════════════════════════════════════════════════════════"
        echo "RAPPORT DE DÉTECTION DE FUITES MÉMOIRE"
        echo "═══════════════════════════════════════════════════════════"
        echo "Date: $(date)"
        echo "Durée: ${duration}s"
        echo "Intervalle: ${interval}s"
        echo ""
        echo "--- Backend ---"
        echo "Croissance mémoire: ${backend_growth}%"
        if (( $(echo "$backend_growth > 20" | bc -l 2>/dev/null || echo "0") )); then
            echo "⚠️  FUITE MÉMOIRE DÉTECTÉE (croissance > 20%)"
        else
            echo "✓ Pas de fuite détectée"
        fi
        echo ""
        echo "--- Frontend ---"
        echo "Croissance mémoire: ${frontend_growth}%"
        if (( $(echo "$frontend_growth > 20" | bc -l 2>/dev/null || echo "0") )); then
            echo "⚠️  FUITE MÉMOIRE DÉTECTÉE (croissance > 20%)"
        else
            echo "✓ Pas de fuite détectée"
        fi
        echo ""
        echo "--- Détails des échantillons ---"
        echo "Backend (KB): ${backend_samples[*]}"
        echo "Frontend (KB): ${frontend_samples[*]}"
    } > "$LEAK_REPORT"
    
    echo -e "${GREEN}✓ Rapport de fuites sauvegardé: $LEAK_REPORT${NC}"
}

# Fonction pour générer un rapport complet
generate_full_report() {
    local backend_pid=$1
    local frontend_pid=$2
    
    echo -e "${BLUE}📝 Génération du rapport complet...${NC}"
    
    {
        echo "═══════════════════════════════════════════════════════════"
        echo "RAPPORT MÉMOIRE COMPLET - Cooking Recipes"
        echo "═══════════════════════════════════════════════════════════"
        echo "Date: $(date)"
        echo ""
        
        # Mémoire système
        echo "--- SYSTÈME ---"
        local total_mem=$(get_system_memory)
        local available_mem=$(get_available_memory)
        local used_mem=$((total_mem - available_mem))
        local mem_percent=$(echo "scale=2; $used_mem * 100 / $total_mem" | bc 2>/dev/null || echo "0")
        
        echo "Mémoire totale: $(kb_to_mb $total_mem) MB"
        echo "Mémoire utilisée: $(kb_to_mb $used_mem) MB ($mem_percent%)"
        echo "Mémoire disponible: $(kb_to_mb $available_mem) MB"
        echo ""
        
        # Backend
        echo "--- BACKEND (Node.js) ---"
        if [ ! -z "$backend_pid" ] && kill -0 "$backend_pid" 2>/dev/null; then
            local backend_mem=$(get_process_memory "$backend_pid")
            local backend_mem_mb=$(kb_to_mb "$backend_mem")
            echo "PID: $backend_pid"
            echo "Mémoire RSS: ${backend_mem_mb} MB"
            
            # Détails du processus
            if [ -f "/proc/$backend_pid/status" ]; then
                echo "État: $(grep "^State:" /proc/$backend_pid/status | awk '{print $2}')"
                echo "Threads: $(grep "^Threads:" /proc/$backend_pid/status | awk '{print $2}')"
                echo "Fichiers ouverts: $(lsof -p "$backend_pid" 2>/dev/null | wc -l)"
            fi
        else
            echo "⚠️  Backend non démarré"
        fi
        echo ""
        
        # Frontend
        echo "--- FRONTEND (Flutter) ---"
        if [ ! -z "$frontend_pid" ] && kill -0 "$frontend_pid" 2>/dev/null; then
            local frontend_mem=$(get_process_memory "$frontend_pid")
            local frontend_mem_mb=$(kb_to_mb "$frontend_mem")
            echo "PID: $frontend_pid"
            echo "Mémoire RSS: ${frontend_mem_mb} MB"
            
            # Détails du processus
            if [ -f "/proc/$frontend_pid/status" ]; then
                echo "État: $(grep "^State:" /proc/$frontend_pid/status | awk '{print $2}')"
                echo "Threads: $(grep "^Threads:" /proc/$frontend_pid/status | awk '{print $2}')"
                echo "Fichiers ouverts: $(lsof -p "$frontend_pid" 2>/dev/null | wc -l)"
            fi
        else
            echo "⚠️  Frontend non démarré"
        fi
        echo ""
        
        # Tous les processus liés
        echo "--- TOUS LES PROCESSUS LIÉS ---"
        echo "Backend (Node.js):"
        ps aux | grep -E "node.*server.js|node.*backend" | grep -v grep || echo "Aucun"
        echo ""
        echo "Frontend (Flutter/Dart):"
        ps aux | grep -E "flutter|dart.*web" | grep -v grep || echo "Aucun"
        echo ""
        
        # Utilisation mémoire par processus
        echo "--- TOP 10 PROCESSUS PAR MÉMOIRE ---"
        ps aux --sort=-%mem | head -11 | tail -10
        echo ""
        
        # Fichiers ouverts
        echo "--- FICHIERS OUVERTS (TOP 20) ---"
        if [ ! -z "$backend_pid" ] && kill -0 "$backend_pid" 2>/dev/null; then
            echo "Backend:"
            lsof -p "$backend_pid" 2>/dev/null | head -20 || echo "Aucun"
        fi
        if [ ! -z "$frontend_pid" ] && kill -0 "$frontend_pid" 2>/dev/null; then
            echo "Frontend:"
            lsof -p "$frontend_pid" 2>/dev/null | head -20 || echo "Aucun"
        fi
        echo ""
        
        # Cache et buffers
        echo "--- CACHE SYSTÈME ---"
        if [ -f /proc/meminfo ]; then
            grep -E "^(Cached|Buffers|SwapCached):" /proc/meminfo
        fi
        echo ""
        
    } > "$REPORT_FILE"
    
    echo -e "${GREEN}✓ Rapport complet sauvegardé: $REPORT_FILE${NC}"
}

# Fonction principale
main() {
    local mode=${1:-"report"}  # report, monitor, leak
    
    # Lire les PIDs depuis les fichiers
    local backend_pid=""
    local frontend_pid=""
    
    if [ -f /tmp/backend_pid.txt ]; then
        backend_pid=$(cat /tmp/backend_pid.txt 2>/dev/null || echo "")
    fi
    
    if [ -f /tmp/frontend_pid.txt ]; then
        frontend_pid=$(cat /tmp/frontend_pid.txt 2>/dev/null || echo "")
    fi
    
    # Si les PIDs ne sont pas dans les fichiers, chercher les processus
    if [ -z "$backend_pid" ] || ! kill -0 "$backend_pid" 2>/dev/null; then
        backend_pid=$(pgrep -f "node.*server.js" | head -1 || echo "")
    fi
    
    if [ -z "$frontend_pid" ] || ! kill -0 "$frontend_pid" 2>/dev/null; then
        frontend_pid=$(pgrep -f "flutter.*web-server" | head -1 || echo "")
    fi
    
    case "$mode" in
        "report")
            generate_full_report "$backend_pid" "$frontend_pid"
            echo ""
            echo -e "${GREEN}📄 Rapport disponible: $REPORT_FILE${NC}"
            ;;
        "monitor")
            echo -e "${BLUE}📊 Monitoring en temps réel (Ctrl+C pour arrêter)...${NC}"
            echo ""
            while true; do
                clear
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}Monitoring Mémoire - $(date '+%H:%M:%S')${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo ""
                
                if [ ! -z "$backend_pid" ] && kill -0 "$backend_pid" 2>/dev/null; then
                    local backend_mem=$(get_process_memory "$backend_pid")
                    echo -e "${YELLOW}Backend (PID $backend_pid): $(kb_to_mb $backend_mem) MB${NC}"
                else
                    echo -e "${RED}Backend: Non démarré${NC}"
                fi
                
                if [ ! -z "$frontend_pid" ] && kill -0 "$frontend_pid" 2>/dev/null; then
                    local frontend_mem=$(get_process_memory "$frontend_pid")
                    echo -e "${YELLOW}Frontend (PID $frontend_pid): $(kb_to_mb $frontend_mem) MB${NC}"
                else
                    echo -e "${RED}Frontend: Non démarré${NC}"
                fi
                
                echo ""
                local total_mem=$(get_system_memory)
                local available_mem=$(get_available_memory)
                local used_mem=$((total_mem - available_mem))
                echo -e "${BLUE}Système: $(kb_to_mb $used_mem) MB / $(kb_to_mb $total_mem) MB utilisés${NC}"
                
                sleep 2
            done
            ;;
        "leak")
            local duration=${2:-300}
            local interval=${3:-10}
            detect_memory_leaks "$backend_pid" "$frontend_pid" "$duration" "$interval"
            echo ""
            echo -e "${GREEN}📄 Rapport de fuites: $LEAK_REPORT${NC}"
            ;;
        *)
            echo -e "${RED}Mode inconnu: $mode${NC}"
            echo "Usage: $0 [report|monitor|leak] [duration] [interval]"
            exit 1
            ;;
    esac
}

main "$@"

