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

# Fonction de nettoyage - ne tue QUE les processus de logs
cleanup() {
  echo ""
  echo -e "${YELLOW}🛑 Arrêt de la surveillance des logs${NC}"
  echo -e "${GREEN}✓ L'application continue de tourner${NC}"
  
  # Tuer uniquement les processus de logs que nous avons créés
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

# Vérifier qu'on a au moins une source de logs
if [ "$HAS_ANDROID" = false ] && [ "$BACKEND_ACCESSIBLE" = false ] && [ -z "$FRONTEND_LOG_FILE" ]; then
  echo -e "${RED}❌ Aucun log disponible${NC}"
  echo -e "${YELLOW}   Démarrez l'application avec: make dev-web${NC}"
  exit 1
fi

# Lancer les logs Android en arrière-plan (si disponible)
if [ "$HAS_ANDROID" = true ]; then
  adb -s "$DEVICE" logcat -c > /dev/null 2>&1
  (
    adb -s "$DEVICE" logcat 2>/dev/null | \
      while IFS= read -r line; do
        # Filtrer et afficher directement
        if echo "$line" | grep -qiE "flutter|cooking|com.delhomme"; then
          if ! echo "$line" | grep -qiE "SimpleEventLog|PlayCommon|FlagRegistrar|GoogleApiManager|BluetoothPowerStatsCollector|ACDB-LOADER|libprotobuf|chromium|SurfaceFlinger|io_stats|BugleNetwork|CronetNetworkEngine|PdnController|MalformedInputException"; then
            CLEAN_LINE=$(echo "$line" | tr -d '\0' | sed 's/[[:cntrl:]]//g' | head -c 200)
            if [ ! -z "$CLEAN_LINE" ]; then
              echo -e "${BLUE}[ANDROID]${NC} $CLEAN_LINE"
            fi
          fi
        fi
      done
  ) &
  ANDROID_LOG_PID=$!
fi

# Lancer les logs API en arrière-plan (si disponible)
if [ -f "/tmp/backend.log" ] && [ "$BACKEND_ACCESSIBLE" = true ]; then
  (
    tail -f /tmp/backend.log 2>/dev/null | \
      while IFS= read -r line; do
        # Filtrer le JSON brut et afficher les lignes importantes
        if echo "$line" | grep -qiE "GET|POST|PUT|DELETE|ERROR|error|WARN|warn|statusCode|method|url|timestamp|severity"; then
          if ! echo "$line" | grep -qiE "^\s*$|^}$|^\{$|^\s*\}\s*$|^\s*,\s*$|^\s*\"[^\"]+\":\s*[^,}]+,?\s*$|BUILD FAILED|Gradle task|Running Gradle|Try:|Run with|Error:|Execution failed"; then
            CLEAN_LINE=$(echo "$line" | tr -d '\0' | sed 's/[[:cntrl:]]//g' | sed 's/^[[:space:]]*//' | head -c 300)
            if [ ! -z "$CLEAN_LINE" ]; then
              echo -e "${GREEN}[API]${NC} $CLEAN_LINE"
            fi
          fi
        fi
      done
  ) &
  API_LOG_PID=$!
fi

# Lancer les logs frontend web en arrière-plan (si disponible)
if [ ! -z "$FRONTEND_LOG_FILE" ]; then
  (
    tail -f "$FRONTEND_LOG_FILE" 2>/dev/null | \
      while IFS= read -r line; do
        # Filtrer et afficher les lignes importantes
        if echo "$line" | grep -qiE "ERROR|WARN|error|warn|Exception|Failed|flutter|Compiling|Building"; then
          if ! echo "$line" | grep -qiE "^\s*$|^}$|^\{$|SimpleEventLog|PlayCommon|FlagRegistrar|GoogleApiManager|Waiting for connection from debug service"; then
            CLEAN_LINE=$(echo "$line" | tr -d '\0' | sed 's/[[:cntrl:]]//g' | head -c 300)
            if [ ! -z "$CLEAN_LINE" ]; then
              echo -e "${MAGENTA}[WEB]${NC} $CLEAN_LINE"
            fi
          fi
        fi
      done
  ) &
  FRONTEND_LOG_PID=$!
fi

# Attendre que les processus se terminent (ou Ctrl+C)
wait
