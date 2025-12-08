#!/bin/bash

# Script pour surveiller les logs Android et API en parallèle

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
if ! curl -s http://localhost:7272/health > /dev/null 2>&1 && ! curl -s http://192.168.1.134:7272/health > /dev/null 2>&1; then
  echo -e "${YELLOW}⚠ Backend non accessible sur localhost:7272 ou 192.168.1.134:7272${NC}"
  echo -e "${YELLOW}   Démarrez le backend avec: make dev (option 2)${NC}"
  echo ""
fi

echo -e "${BLUE}📱 Logs Android (gauche) | 🌐 Logs API Backend (droite)${NC}"
echo -e "${YELLOW}   Appuyez sur Ctrl+C pour arrêter${NC}"
echo ""

# Fonction de nettoyage
cleanup() {
  echo ""
  echo -e "${YELLOW}🛑 Arrêt de la surveillance...${NC}"
  kill $ANDROID_LOG_PID 2>/dev/null || true
  kill $API_LOG_PID 2>/dev/null || true
  exit 0
}

trap cleanup INT TERM

# Lancer les logs Android en arrière-plan
adb -s "$DEVICE" logcat -c > /dev/null 2>&1
adb -s "$DEVICE" logcat | grep -iE "flutter|cooking|com.delhomme|error|exception" --line-buffered > /tmp/android_logs.txt &
ANDROID_LOG_PID=$!

# Lancer les logs API si disponible
if [ -f "/tmp/backend.log" ]; then
  tail -f /tmp/backend.log 2>/dev/null > /tmp/api_logs.txt &
  API_LOG_PID=$!
else
  API_LOG_PID=""
fi

# Afficher les logs en parallèle
if [ ! -z "$API_LOG_PID" ]; then
  # Mode avec API
  while true; do
    if [ -f /tmp/android_logs.txt ]; then
      ANDROID_LINES=$(tail -5 /tmp/android_logs.txt 2>/dev/null | wc -l)
      if [ "$ANDROID_LINES" -gt 0 ]; then
        echo -e "${BLUE}[ANDROID]${NC} $(tail -1 /tmp/android_logs.txt 2>/dev/null)"
      fi
    fi
    if [ -f /tmp/api_logs.txt ]; then
      API_LINES=$(tail -5 /tmp/api_logs.txt 2>/dev/null | wc -l)
      if [ "$API_LINES" -gt 0 ]; then
        echo -e "${GREEN}[API]${NC} $(tail -1 /tmp/api_logs.txt 2>/dev/null)"
      fi
    fi
    sleep 0.5
  done
else
  # Mode Android uniquement
  tail -f /tmp/android_logs.txt 2>/dev/null
fi

