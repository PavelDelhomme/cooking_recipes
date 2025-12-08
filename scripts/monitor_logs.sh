#!/bin/bash

# Script pour surveiller les logs Android et API en parallèle (version optimisée)

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}📊 Surveillance des logs Android et API${NC}"
echo ""

# Vérifier le device Android
DEVICE=$(adb devices | grep "device$" | head -1 | awk '{print $1}')

if [ -z "$DEVICE" ]; then
  echo -e "${RED}❌ Aucun device Android connecté${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Device Android: $DEVICE${NC}"

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
  echo -e "${YELLOW}   Démarrez le backend avec: make dev (option 2)${NC}"
fi

echo ""
echo -e "${BLUE}📱 Logs Android (filtre: Flutter/Cooking uniquement)${NC}"
if [ "$BACKEND_ACCESSIBLE" = true ]; then
  echo -e "${GREEN}🌐 Logs API Backend${NC}"
fi
echo -e "${YELLOW}   Appuyez sur Ctrl+C pour arrêter${NC}"
echo ""

# Fonction de nettoyage
cleanup() {
  echo ""
  echo -e "${YELLOW}🛑 Arrêt de la surveillance...${NC}"
  kill $ANDROID_LOG_PID 2>/dev/null || true
  kill $API_LOG_PID 2>/dev/null || true
  rm -f /tmp/android_fifo /tmp/api_fifo 2>/dev/null || true
  exit 0
}

trap cleanup INT TERM

# Nettoyer les anciens fichiers
rm -f /tmp/android_logs.txt /tmp/api_logs.txt /tmp/android_fifo /tmp/api_fifo

# Lancer les logs Android en arrière-plan (filtrer les erreurs système)
adb -s "$DEVICE" logcat -c > /dev/null 2>&1
adb -s "$DEVICE" logcat 2>/dev/null | \
  grep -iE "flutter|cooking|com.delhomme" | \
  grep -vE "SimpleEventLog|PlayCommon|FlagRegistrar|GoogleApiManager|BluetoothPowerStatsCollector|ACDB-LOADER|libprotobuf|chromium|SurfaceFlinger|io_stats|BugleNetwork|CronetNetworkEngine|PdnController|MalformedInputException" | \
  grep -vE "^\s*$|^}$|^\{$" | \
  tr -d '\0' | \
  sed 's/[[:cntrl:]]//g' > /tmp/android_logs.txt &
ANDROID_LOG_PID=$!

# Lancer les logs API si disponible (filtrer le JSON brut)
if [ -f "/tmp/backend.log" ] && [ "$BACKEND_ACCESSIBLE" = true ]; then
  tail -f /tmp/backend.log 2>/dev/null | \
    grep -vE "^\s*$|^}$|^\{$|^\s*\}\s*$|^\s*,\s*$" | \
    grep -vE "^\s*\"[^\"]+\":\s*[^,}]+,?\s*$" | \
    grep -E "GET|POST|PUT|DELETE|ERROR|error|WARN|warn|statusCode|method|url|timestamp|severity" | \
    grep -vE "BUILD FAILED|Gradle task|Running Gradle|Try:|Run with|Error:|Execution failed" | \
    tr -d '\0' | \
    sed 's/[[:cntrl:]]//g' | \
    sed 's/^[[:space:]]*//' | \
    head -c 300 > /tmp/api_logs.txt &
  API_LOG_PID=$!
else
  API_LOG_PID=""
fi

# Afficher les logs de manière simple et efficace
if [ ! -z "$API_LOG_PID" ]; then
  # Mode avec API - affichage simple
  while true; do
    # Lire les logs Android
    if [ -f /tmp/android_logs.txt ] && [ -s /tmp/android_logs.txt ]; then
      ANDROID_LINE=$(tail -1 /tmp/android_logs.txt 2>/dev/null | head -c 200)
      if [ ! -z "$ANDROID_LINE" ] && [ "$ANDROID_LINE" != "$LAST_ANDROID_LINE" ]; then
        echo -e "${BLUE}[ANDROID]${NC} $ANDROID_LINE"
        LAST_ANDROID_LINE="$ANDROID_LINE"
      fi
    fi
    
    # Lire les logs API
    if [ -f /tmp/api_logs.txt ] && [ -s /tmp/api_logs.txt ]; then
      API_LINE=$(tail -1 /tmp/api_logs.txt 2>/dev/null | head -c 200 | tr -d '\0' | sed 's/[[:cntrl:]]//g')
      if [ ! -z "$API_LINE" ] && [ "$API_LINE" != "}" ] && [ "$API_LINE" != "{" ] && [ "$API_LINE" != "$LAST_API_LINE" ]; then
        echo -e "${GREEN}[API]${NC} $API_LINE"
        LAST_API_LINE="$API_LINE"
      fi
    fi
    
    sleep 0.5
  done
else
  # Mode Android uniquement
  tail -f /tmp/android_logs.txt 2>/dev/null | while IFS= read -r line; do
    if [ ! -z "$line" ]; then
      echo -e "${BLUE}[ANDROID]${NC} $line"
    fi
  done
fi
