#!/bin/bash

# Script pour voir uniquement les logs de l'application Flutter
# Ignore les erreurs système Android normales

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_NAME="com.delhomme.cooking_recipe.cookingrecipe"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}📱 Logs de l'application Cooking Recipes${NC}"
echo ""

# Détecter le device
DEVICE=$(adb devices | grep "device$" | head -1 | awk '{print $1}')

if [ -z "$DEVICE" ]; then
  echo -e "${YELLOW}❌ Aucun device Android connecté${NC}"
  echo -e "${YELLOW}   Connectez votre téléphone via USB${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Device: $DEVICE${NC}"
echo ""

# Options
MODE="${1:-realtime}"

case "$MODE" in
  "realtime"|"rt"|"")
    echo -e "${BLUE}📊 Logs en temps réel (app uniquement)${NC}"
    echo -e "${YELLOW}   Appuyez sur Ctrl+C pour arrêter${NC}"
    echo ""
    adb -s "$DEVICE" logcat | grep -iE "flutter|cooking|com.delhomme" --line-buffered
    ;;
  "errors"|"err"|"e")
    echo -e "${BLUE}❌ Erreurs uniquement${NC}"
    echo ""
    adb -s "$DEVICE" logcat -d *:E | grep -iE "flutter|cooking|com.delhomme" | tail -50
    ;;
  "all"|"a")
    echo -e "${BLUE}📋 Tous les logs (sans erreurs système)${NC}"
    echo ""
    adb -s "$DEVICE" logcat -d | grep -vE "Finsky|GoogleApiManager|SimpleEventLog|PlayCommon|BluetoothPowerStatsCollector|ACDB-LOADER|libprotobuf|chromium" | grep -iE "flutter|cooking|com.delhomme" | tail -100
    ;;
  "clear"|"c")
    echo -e "${BLUE}🧹 Nettoyage des logs${NC}"
    adb -s "$DEVICE" logcat -c
    echo -e "${GREEN}✓ Logs nettoyés${NC}"
    ;;
  "help"|"h"|"-h"|"--help")
    echo "Usage: $0 [mode]"
    echo ""
    echo "Modes disponibles:"
    echo "  realtime (rt)  - Logs en temps réel (défaut)"
    echo "  errors (err,e) - Erreurs uniquement"
    echo "  all (a)        - Tous les logs (sans erreurs système)"
    echo "  clear (c)      - Nettoyer les logs"
    echo "  help (h)       - Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0              # Logs en temps réel"
    echo "  $0 errors       # Voir les erreurs"
    echo "  $0 all          # Tous les logs"
    echo "  $0 clear        # Nettoyer"
    ;;
  *)
    echo -e "${YELLOW}⚠ Mode inconnu: $MODE${NC}"
    echo -e "${YELLOW}   Utilisez '$0 help' pour voir les modes disponibles${NC}"
    exit 1
    ;;
esac

