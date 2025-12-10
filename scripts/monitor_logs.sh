#!/bin/bash

# Script pour surveiller les logs Android, Backend API et Frontend Web en temps réel
# Ctrl+C arrête uniquement l'affichage des logs, pas l'application

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}📊 Surveillance des logs en temps réel${NC}"
echo ""

# Vérifier le device Android (optionnel)
DEVICE=$(adb devices 2>/dev/null | grep "device$" | head -1 | awk '{print $1}')
HAS_ANDROID=false

if [ ! -z "$DEVICE" ]; then
  HAS_ANDROID=true
  echo -e "${GREEN}✓ Device Android: $DEVICE${NC}"
else
  echo -e "${YELLOW}⚠ Aucun device Android connecté (mode Web uniquement)${NC}"
fi

# Vérifier si le backend tourne
BACKEND_ACCESSIBLE=false
if curl -s http://localhost:7272/health > /dev/null 2>&1; then
  BACKEND_ACCESSIBLE=true
  echo -e "${GREEN}✓ Backend accessible sur localhost:7272${NC}"
elif curl -s http://192.168.1.134:7272/health > /dev/null 2>&1; then
  BACKEND_ACCESSIBLE=true
  echo -e "${GREEN}✓ Backend accessible sur 192.168.1.134:7272${NC}"
else
  echo -e "${YELLOW}⚠ Backend non accessible${NC}"
fi

# Vérifier les logs frontend web
FRONTEND_LOG_FILE=""
if [ -f "/tmp/frontend_web.log" ]; then
  FRONTEND_LOG_FILE="/tmp/frontend_web.log"
  echo -e "${GREEN}✓ Logs Frontend Web détectés${NC}"
elif [ -f "/tmp/frontend.log" ]; then
  FRONTEND_LOG_FILE="/tmp/frontend.log"
  echo -e "${GREEN}✓ Logs Frontend Web détectés${NC}"
else
  echo -e "${YELLOW}⚠ Aucun log Frontend Web détecté${NC}"
fi

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}   Appuyez sur Ctrl+C pour arrêter l'affichage des logs${NC}"
echo -e "${YELLOW}   (l'application continue de tourner)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Fonction de nettoyage
cleanup() {
  echo ""
  echo -e "${YELLOW}🛑 Arrêt de la surveillance des logs${NC}"
  echo -e "${GREEN}✓ L'application continue de tourner${NC}"
  
  # Tuer uniquement les processus de logs
  if [ ! -z "$ANDROID_LOG_PID" ]; then
    kill $ANDROID_LOG_PID 2>/dev/null || true
    pkill -P $ANDROID_LOG_PID 2>/dev/null || true
  fi
  if [ ! -z "$API_LOG_PID" ]; then
    kill $API_LOG_PID 2>/dev/null || true
    pkill -P $API_LOG_PID 2>/dev/null || true
  fi
  if [ ! -z "$FRONTEND_LOG_PID" ]; then
    kill $FRONTEND_LOG_PID 2>/dev/null || true
    pkill -P $FRONTEND_LOG_PID 2>/dev/null || true
  fi
  
  exit 0
}

trap cleanup INT TERM

# Fonction pour obtenir le timestamp actuel
get_timestamp() {
  date +"%H:%M:%S"
}

# Vérifier qu'on a au moins une source de logs
if [ "$HAS_ANDROID" = false ] && [ "$BACKEND_ACCESSIBLE" = false ] && [ -z "$FRONTEND_LOG_FILE" ]; then
  echo -e "${RED}❌ Aucun log disponible${NC}"
  echo -e "${YELLOW}   Démarrez l'application avec: make dev-web${NC}"
  exit 1
fi

# Lancer les logs Android en arrière-plan (si disponible)
if [ "$HAS_ANDROID" = true ]; then
  (
    adb -s "$DEVICE" logcat -c > /dev/null 2>&1
    stdbuf -oL -eL adb -s "$DEVICE" logcat 2>/dev/null | \
      stdbuf -oL -eL strings | \
      stdbuf -oL -eL grep -aiE "flutter|cooking|com.delhomme" | \
      stdbuf -oL -eL grep -aviE "SimpleEventLog|PlayCommon|FlagRegistrar|GoogleApiManager|BluetoothPowerStatsCollector|ACDB-LOADER|libprotobuf|chromium|SurfaceFlinger|io_stats|BugleNetwork|CronetNetworkEngine|PdnController|MalformedInputException" | \
      stdbuf -oL -eL tr -d '\0' | \
      stdbuf -oL -eL sed 's/[[:cntrl:]]//g' | \
      while IFS= read -r line; do
        if [ ! -z "$line" ]; then
          timestamp=$(get_timestamp)
          echo -e "${BLUE}[ANDROID]${NC} ${CYAN}${timestamp}${NC} | ${line:0:200}"
        fi
      done
  ) &
  ANDROID_LOG_PID=$!
fi

# Lancer les logs API en arrière-plan avec filtrage et regroupement
if [ -f "/tmp/backend.log" ] && [ "$BACKEND_ACCESSIBLE" = true ]; then
  (
    stdbuf -oL -eL tail -f /tmp/backend.log 2>/dev/null | \
      stdbuf -oL -eL strings | \
      stdbuf -oL -eL grep -aviE "^\s*$|^}$|^\{$|BUILD FAILED|Gradle task|Running Gradle|Try:|Run with|Error:|Execution failed" | \
      stdbuf -oL -eL tr -d '\0' | \
      stdbuf -oL -eL sed 's/[[:cntrl:]]//g' | \
      stdbuf -oL -eL sed 's/^[[:space:]]*//' | \
      awk -v green="\033[0;32m" -v yellow="\033[1;33m" -v red="\033[0;31m" -v cyan="\033[0;36m" -v nc="\033[0m" '
        BEGIN {
          method = ""
          url = ""
          status = ""
          severity = ""
          request_time = ""
        }
        
        # Ignorer les lignes qui sont juste des propriétés JSON isolées
        /^"[^"]+":\s*[^,}]+,?\s*$/ { next }
        
        # Extraire timestamp si présent
        /timestamp:/ {
          cmd = "date +\"%H:%M:%S\""
          cmd | getline request_time
          close(cmd)
          method = ""
          url = ""
          status = ""
          severity = ""
        }
        
        # Extraire method
        /method:/ {
          match($0, /method:\s*['"'"'"]?([A-Z]+)['"'"'"]?/, arr)
          if (arr[1]) method = arr[1]
        }
        
        # Extraire url
        /url:/ {
          match($0, /url:\s*['"'"'"]?([^'"'"'"]+)['"'"'"]?/, arr)
          if (arr[1]) url = substr(arr[1], 1, 70)
        }
        
        # Extraire statusCode
        /statusCode:/ {
          match($0, /statusCode:\s*([0-9]+)/, arr)
          if (arr[1]) status = arr[1]
        }
        
        # Extraire severity
        /severity:/ {
          match($0, /severity:\s*['"'"'"]?([^'"'"'"]+)['"'"'"]?/, arr)
          if (arr[1]) severity = arr[1]
        }
        
        # Si on a method et url, afficher le log regroupé
        (method != "" && url != "") {
          status_color = green
          if (status >= 400 && status < 500) status_color = yellow
          if (status >= 500) status_color = red
          
          icon = ""
          if (severity ~ /ERROR|error/) {
            icon = " ❌"
            status_color = red
          } else if (severity ~ /WARN|warn/) {
            icon = " ⚠️"
            status_color = yellow
          }
          
          timestamp = request_time
          if (timestamp == "") {
            cmd = "date +\"%H:%M:%S\""
            cmd | getline timestamp
            close(cmd)
          }
          
          printf "%s[API]%s %s%s%s | %s%s%s %s %s%s%s%s\n", 
            green, nc, cyan, timestamp, nc, status_color, method, nc, url, status_color, status, nc, icon
          
          # Réinitialiser
          method = ""
          url = ""
          status = ""
          severity = ""
          request_time = ""
          next
        }
        
        # Afficher les erreurs et warnings
        /ERROR|WARN|error|warn|Exception/ {
          cmd = "date +\"%H:%M:%S\""
          cmd | getline timestamp
          close(cmd)
          
          color = red
          if (/WARN|warn/) color = yellow
          
          printf "%s[API]%s %s%s%s | %s%s%s\n", 
            green, nc, cyan, timestamp, nc, color, substr($0, 1, 200), nc
        }
      '
  ) &
  API_LOG_PID=$!
fi

# Lancer les logs frontend web en arrière-plan (filtre moins restrictif)
if [ ! -z "$FRONTEND_LOG_FILE" ]; then
  (
    stdbuf -oL -eL tail -f "$FRONTEND_LOG_FILE" 2>/dev/null | \
      stdbuf -oL -eL strings | \
      stdbuf -oL -eL grep -aviE "^\s*$|SimpleEventLog|PlayCommon|FlagRegistrar|GoogleApiManager|Waiting for connection from debug service" | \
      stdbuf -oL -eL grep -aiE "ERROR|WARN|error|warn|Exception|Failed|flutter|Compiling|Building|Launching|Hot reload|Hot restart|Reloaded|Restarted|Syncing|Performing|Running|Finished|Serving|Listening" | \
      stdbuf -oL -eL tr -d '\0' | \
      stdbuf -oL -eL sed 's/[[:cntrl:]]//g' | \
      while IFS= read -r line; do
        if [ ! -z "$line" ]; then
          timestamp=$(get_timestamp)
          color="${MAGENTA}"
          if echo "$line" | grep -qiE "ERROR|error|Exception|Failed"; then
            color="${RED}"
          elif echo "$line" | grep -qiE "WARN|warn"; then
            color="${YELLOW}"
          fi
          echo -e "${MAGENTA}[WEB]${NC} ${CYAN}${timestamp}${NC} | ${color}${line:0:300}${NC}"
        fi
      done
  ) &
  FRONTEND_LOG_PID=$!
fi

# Attendre que les processus se terminent (ou Ctrl+C)
# Utiliser wait pour attendre tous les processus en arrière-plan
# Leur sortie sera visible car ils écrivent directement dans stdout
if [ "$HAS_ANDROID" = true ] && [ "$BACKEND_ACCESSIBLE" = true ] && [ ! -z "$FRONTEND_LOG_FILE" ]; then
  # Tous les trois sont actifs
  wait $ANDROID_LOG_PID $API_LOG_PID $FRONTEND_LOG_PID 2>/dev/null || wait
elif [ "$HAS_ANDROID" = true ] && [ "$BACKEND_ACCESSIBLE" = true ]; then
  wait $ANDROID_LOG_PID $API_LOG_PID 2>/dev/null || wait
elif [ "$HAS_ANDROID" = true ] && [ ! -z "$FRONTEND_LOG_FILE" ]; then
  wait $ANDROID_LOG_PID $FRONTEND_LOG_PID 2>/dev/null || wait
elif [ "$BACKEND_ACCESSIBLE" = true ] && [ ! -z "$FRONTEND_LOG_FILE" ]; then
  wait $API_LOG_PID $FRONTEND_LOG_PID 2>/dev/null || wait
elif [ "$HAS_ANDROID" = true ]; then
  wait $ANDROID_LOG_PID 2>/dev/null || wait
elif [ "$BACKEND_ACCESSIBLE" = true ]; then
  wait $API_LOG_PID 2>/dev/null || wait
elif [ ! -z "$FRONTEND_LOG_FILE" ]; then
  wait $FRONTEND_LOG_PID 2>/dev/null || wait
fi
