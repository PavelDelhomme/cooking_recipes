#!/bin/bash

# Script pour lancer le backend et le frontend en développement

# Obtenir le répertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Détecter Flutter
FLUTTER_CMD=""
if command -v flutter &> /dev/null; then
  FLUTTER_CMD="flutter"
elif [ -f "/home/pactivisme/flutter/bin/flutter" ]; then
  FLUTTER_CMD="/home/pactivisme/flutter/bin/flutter"
elif [ -f "/opt/flutter/bin/flutter" ]; then
  FLUTTER_CMD="/opt/flutter/bin/flutter"
else
  echo -e "${RED}❌ Flutter n'est pas installé${NC}"
  echo -e "${YELLOW}Veuillez installer Flutter avec: installman flutter${NC}"
  exit 1
fi

# Vérifier que Flutter fonctionne
if ! $FLUTTER_CMD --version &> /dev/null; then
  echo -e "${RED}❌ Flutter n'est pas accessible${NC}"
  exit 1
fi

# Vérifier que npm est installé
if ! command -v npm &> /dev/null; then
  echo -e "${RED}❌ npm n'est pas installé${NC}"
  exit 1
fi

# Détecter l'IP de la machine
echo -e "${GREEN}Détection de l'IP de la machine...${NC}"
MACHINE_IP=$(hostname -I 2>/dev/null | awk '{print $1}' | head -1)
if [ -z "$MACHINE_IP" ] || [ "$MACHINE_IP" = "" ]; then
  MACHINE_IP=$(ip route get 1.1.1.1 2>/dev/null | awk -F'src ' '{print $2}' | awk '{print $1}' | head -1)
fi
if [ -z "$MACHINE_IP" ] || [ "$MACHINE_IP" = "" ]; then
  MACHINE_IP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d/ -f1)
fi
if [ -z "$MACHINE_IP" ] || [ "$MACHINE_IP" = "" ]; then
  echo -e "${YELLOW}⚠ Impossible de détecter l'IP, utilisation de localhost${NC}"
  MACHINE_IP="localhost"
fi

echo -e "${GREEN}✓ IP détectée: $MACHINE_IP${NC}"
echo ""

# Commit et push Git automatique
echo -e "${GREEN}Vérification des modifications Git...${NC}"
cd "$PROJECT_ROOT" || exit 1

# Vérifier s'il y a des modifications
if [ -d ".git" ]; then
  # Vérifier si git est configuré
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # Vérifier s'il y a des modifications non commitées
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
      echo -e "${YELLOW}Modifications détectées, commit et push en cours...${NC}"
      git add -A 2>/dev/null || true
      git commit -m "dev: configuration IP $MACHINE_IP - $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null || true
      # Essayer de push
      if git remote get-url origin > /dev/null 2>&1; then
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
        git push origin "$CURRENT_BRANCH" 2>/dev/null || echo -e "${YELLOW}⚠ Push échoué (vérifiez votre connexion)${NC}"
      else
        echo -e "${YELLOW}⚠ Pas de remote configuré, commit local uniquement${NC}"
      fi
      echo -e "${GREEN}✓ Modifications commitées${NC}"
    else
      echo -e "${GREEN}✓ Aucune modification à commiter${NC}"
    fi
  else
    echo -e "${YELLOW}⚠ Dépôt Git non initialisé${NC}"
  fi
else
  echo -e "${YELLOW}⚠ Pas de dépôt Git détecté${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Lancement en mode développement...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Backend API: http://$MACHINE_IP:7373/api${NC}"
echo -e "${YELLOW}Frontend Web (PC): http://localhost:4041${NC}"
echo -e "${YELLOW}Frontend Web (Mobile): http://$MACHINE_IP:4041${NC}"
echo ""

# Détecter les appareils Android connectés via ADB
ANDROID_DEVICES=""
ANDROID_DEVICE_COUNT=0
if command -v adb &> /dev/null; then
  ANDROID_DEVICES=$(adb devices 2>/dev/null | grep -v "List" | grep "device$" | awk '{print $1}' | head -1)
  ANDROID_DEVICE_COUNT=$(adb devices 2>/dev/null | grep -v "List" | grep -c "device$" || echo "0")
fi

# Détecter les appareils via Flutter
FLUTTER_ANDROID_DEVICES=$($FLUTTER_CMD devices 2>/dev/null | grep -i "android" | head -1 || echo "")
FLUTTER_WEB_AVAILABLE=$($FLUTTER_CMD devices 2>/dev/null | grep -i "web-server" | head -1 || echo "")

# Menu de sélection
DEVICE_CHOICE=""
HAS_ANDROID=false

if [ ! -z "$ANDROID_DEVICES" ] || [ ! -z "$FLUTTER_ANDROID_DEVICES" ]; then
  HAS_ANDROID=true
fi

if [ "$HAS_ANDROID" = true ]; then
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}Appareils détectés:${NC}"
  if [ ! -z "$ANDROID_DEVICES" ]; then
    echo -e "  ${GREEN}✓ Android (ADB): $ANDROID_DEVICES${NC}"
  elif [ ! -z "$FLUTTER_ANDROID_DEVICES" ]; then
    echo -e "  ${GREEN}✓ Android (Flutter): détecté${NC}"
  fi
  echo -e "  ${GREEN}✓ Web (navigateur)${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${YELLOW}Choisissez où lancer l'application:${NC}"
  echo -e "  ${GREEN}1)${NC} Téléphone Android uniquement"
  echo -e "  ${GREEN}2)${NC} Navigateur Web uniquement"
  echo -e "  ${GREEN}3)${NC} Les deux (Android + Web)"
  echo ""
  read -p "Votre choix [1-3] (défaut: 2): " DEVICE_CHOICE
  DEVICE_CHOICE=${DEVICE_CHOICE:-2}
else
  echo -e "${YELLOW}⚠ Aucun appareil Android détecté${NC}"
  echo -e "${YELLOW}   Connectez votre téléphone via USB et activez le débogage USB${NC}"
  echo -e "${GREEN}Lancement sur le navigateur Web...${NC}"
  DEVICE_CHOICE="2"
fi

# Configurer l'URL API pour mobile si nécessaire
if [ "$DEVICE_CHOICE" = "1" ] || [ "$DEVICE_CHOICE" = "3" ]; then
  echo -e "${GREEN}Configuration de l'URL API pour mobile...${NC}"
  if [ -f "$PROJECT_ROOT/frontend/lib/services/auth_service.dart" ]; then
    # Sauvegarder la version originale
    cp "$PROJECT_ROOT/frontend/lib/services/auth_service.dart" "$PROJECT_ROOT/frontend/lib/services/auth_service.dart.bak" 2>/dev/null || true
    # Modifier l'URL pour mobile (mais on utilise déjà ApiConfig qui détecte automatiquement)
    echo -e "${GREEN}✓ URL API configurée pour mobile: http://$MACHINE_IP:7373/api${NC}"
  fi
fi

echo ""

# Fonction pour nettoyer les processus à l'arrêt
cleanup() {
  echo ""
  echo -e "${GREEN}Arrêt des services...${NC}"
  if [ ! -z "$BACKEND_PID" ]; then
    kill $BACKEND_PID 2>/dev/null || true
  fi
  if [ ! -z "$FRONTEND_PID" ]; then
    kill $FRONTEND_PID 2>/dev/null || true
  fi
  if [ ! -z "$FRONTEND_ANDROID_PID" ]; then
    kill $FRONTEND_ANDROID_PID 2>/dev/null || true
  fi
  if [ ! -z "$FRONTEND_WEB_PID" ]; then
    kill $FRONTEND_WEB_PID 2>/dev/null || true
  fi
  # Tuer aussi les processus enfants
  pkill -f "node.*server.js" 2>/dev/null || true
  pkill -f "flutter.*web-server" 2>/dev/null || true
  pkill -f "flutter.*android" 2>/dev/null || true
  # Restaurer le fichier auth_service.dart si modifié
  if [ -f "$PROJECT_ROOT/frontend/lib/services/auth_service.dart.bak" ]; then
    mv "$PROJECT_ROOT/frontend/lib/services/auth_service.dart.bak" "$PROJECT_ROOT/frontend/lib/services/auth_service.dart" 2>/dev/null || true
  fi
  exit 0
}

trap cleanup INT TERM

# Vérifier que les dépendances sont installées
if [ ! -d "$PROJECT_ROOT/backend/node_modules" ]; then
  echo -e "${YELLOW}Installation des dépendances backend...${NC}"
  cd "$PROJECT_ROOT/backend" || exit 1
  npm install
fi

# Démarrer le backend
echo -e "${GREEN}Démarrage du backend sur le port 7373...${NC}"
cd "$PROJECT_ROOT/backend" || exit 1
PORT=7373 HOST=0.0.0.0 npm run dev > /tmp/backend.log 2>&1 &
BACKEND_PID=$!

# Attendre que le backend démarre
echo -e "${YELLOW}Attente du démarrage du backend...${NC}"
sleep 5

# Vérifier que le backend est démarré
if ! kill -0 $BACKEND_PID 2>/dev/null; then
  echo -e "${RED}❌ Le backend n'a pas démarré correctement${NC}"
  echo -e "${YELLOW}Logs:${NC}"
  cat /tmp/backend.log
  exit 1
fi

# Démarrer le frontend selon le choix
cd "$PROJECT_ROOT/frontend" || exit 1

case "$DEVICE_CHOICE" in
  1)
    # Android uniquement
    echo -e "${GREEN}Démarrage sur Android...${NC}"
    $FLUTTER_CMD run -d android > /tmp/frontend.log 2>&1 &
    FRONTEND_PID=$!
    ;;
  2)
    # Web uniquement
    echo -e "${GREEN}Démarrage sur le navigateur Web...${NC}"
    $FLUTTER_CMD run -d web-server --web-port=4041 --web-hostname=0.0.0.0 > /tmp/frontend.log 2>&1 &
    FRONTEND_PID=$!
    ;;
  3)
    # Les deux
    echo -e "${GREEN}Démarrage sur Android et Web...${NC}"
    $FLUTTER_CMD run -d android > /tmp/frontend_android.log 2>&1 &
    FRONTEND_ANDROID_PID=$!
    sleep 2
    $FLUTTER_CMD run -d web-server --web-port=4041 --web-hostname=0.0.0.0 > /tmp/frontend_web.log 2>&1 &
    FRONTEND_WEB_PID=$!
    FRONTEND_PID=$FRONTEND_WEB_PID
    ;;
  *)
    # Par défaut: Web
    echo -e "${GREEN}Démarrage sur le navigateur Web (par défaut)...${NC}"
    $FLUTTER_CMD run -d web-server --web-port=4041 --web-hostname=0.0.0.0 > /tmp/frontend.log 2>&1 &
    FRONTEND_PID=$!
    ;;
esac

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Services démarrés avec succès${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
if [ "$DEVICE_CHOICE" = "1" ]; then
  echo -e "${YELLOW}Application lancée sur votre téléphone Android${NC}"
elif [ "$DEVICE_CHOICE" = "3" ]; then
  echo -e "${YELLOW}Application lancée sur Android ET Web${NC}"
  echo -e "${YELLOW}Web: http://$MACHINE_IP:4041${NC}"
else
  echo -e "${YELLOW}Application lancée sur: http://$MACHINE_IP:4041${NC}"
fi
echo -e "${YELLOW}Appuyez sur Ctrl+C pour arrêter${NC}"
echo ""

# Attendre que les processus se terminent
wait

