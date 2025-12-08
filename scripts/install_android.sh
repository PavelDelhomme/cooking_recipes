#!/bin/bash

# Script pour installer et lancer l'application Android manuellement

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK_PATH="$PROJECT_ROOT/frontend/build/app/outputs/flutter-apk/app-debug.apk"
PACKAGE_NAME="com.delhomme.cooking_recipe.cookingrecipe"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}📱 Installation et lancement de l'application Android${NC}"
echo ""

# Vérifier que l'APK existe
if [ ! -f "$APK_PATH" ]; then
  echo -e "${RED}❌ APK non trouvé: $APK_PATH${NC}"
  echo -e "${YELLOW}   Build d'abord l'APK avec:${NC}"
  echo -e "${YELLOW}   cd frontend && flutter build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=192.168.1.134${NC}"
  exit 1
fi

# Détecter le device
DEVICE=$(adb devices | grep "device$" | head -1 | awk '{print $1}')

if [ -z "$DEVICE" ]; then
  echo -e "${RED}❌ Aucun device Android connecté${NC}"
  echo -e "${YELLOW}   Connectez votre téléphone via USB et activez le débogage USB${NC}"
  echo ""
  echo -e "${YELLOW}   Vérifiez avec: adb devices${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Device détecté: $DEVICE${NC}"

# Obtenir l'IP de la machine pour l'API
MACHINE_IP=$(hostname -I 2>/dev/null | awk '{print $1}' | head -1)
if [ -z "$MACHINE_IP" ]; then
  MACHINE_IP=$(ip route get 1.1.1.1 2>/dev/null | awk -F'src ' '{print $2}' | awk '{print $1}' | head -1)
fi

if [ -z "$MACHINE_IP" ]; then
  MACHINE_IP="192.168.1.134"  # Valeur par défaut
fi

echo -e "${GREEN}✓ IP de la machine: $MACHINE_IP${NC}"
echo ""

# Vérifier si l'application est déjà installée
if adb -s "$DEVICE" shell pm list packages | grep -q "$PACKAGE_NAME"; then
  echo -e "${YELLOW}⚠ Application déjà installée, désinstallation...${NC}"
  adb -s "$DEVICE" uninstall "$PACKAGE_NAME" > /dev/null 2>&1 || true
  sleep 1
fi

# Installer l'APK
echo -e "${GREEN}📦 Installation de l'APK...${NC}"
if adb -s "$DEVICE" install -r "$APK_PATH" > /tmp/adb_install.log 2>&1; then
  echo -e "${GREEN}✓ Application installée avec succès${NC}"
else
  echo -e "${RED}❌ Échec de l'installation${NC}"
  echo -e "${YELLOW}Logs:${NC}"
  cat /tmp/adb_install.log
  exit 1
fi

# Lancer l'application
echo ""
echo -e "${GREEN}🚀 Lancement de l'application...${NC}"
if adb -s "$DEVICE" shell am start -n "$PACKAGE_NAME/.MainActivity" > /tmp/adb_launch.log 2>&1; then
  echo -e "${GREEN}✓ Application lancée sur votre téléphone !${NC}"
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ Application Android démarrée${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${YELLOW}📊 Pour voir les logs en temps réel:${NC}"
  echo -e "${YELLOW}   adb -s $DEVICE logcat | grep -i flutter${NC}"
  echo ""
  echo -e "${YELLOW}🌐 Backend API: http://$MACHINE_IP:7272/api${NC}"
  echo -e "${YELLOW}   Assurez-vous que le backend est démarré !${NC}"
else
  echo -e "${YELLOW}⚠ L'application est installée mais le lancement a échoué${NC}"
  echo -e "${YELLOW}   Lancez-la manuellement depuis votre téléphone${NC}"
  echo -e "${YELLOW}   Ou vérifiez les logs:${NC}"
  cat /tmp/adb_launch.log
fi

