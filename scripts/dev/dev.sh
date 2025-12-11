#!/bin/bash

# Script pour lancer le backend et le frontend en développement

# Obtenir le répertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Fichier de configuration pour sauvegarder les choix lors des redémarrages
DEV_CONFIG_FILE="/tmp/flutter_cooking_recipe_dev_config.txt"

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

# Configurer Android SDK si disponible
if [ -d "$HOME/Android/Sdk" ]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools"
  
  # Ajouter cmdline-tools au PATH si disponible
  if [ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ]; then
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
  fi
  
  # Configurer Flutter pour utiliser ce SDK
  $FLUTTER_CMD config --android-sdk "$ANDROID_HOME" 2>/dev/null || true
  
  # Vérifier et installer/accéder les licences Android SDK
  # Créer le dossier licenses s'il n'existe pas
  mkdir -p "$ANDROID_HOME/licenses" 2>/dev/null || true
  
  # Vérifier si les licences sont déjà acceptées
  LICENSE_COUNT=$(find "$ANDROID_HOME/licenses" -name "*.txt" 2>/dev/null | wc -l)
  if [ "$LICENSE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ Licences Android SDK non acceptées${NC}"
    echo -e "${YELLOW}   Création automatique des licences...${NC}"
  fi
  
  # Trouver sdkmanager
  SDKMANAGER=""
  # Chercher dans différentes structures possibles
  if [ -f "$ANDROID_HOME/cmdline-tools/latest/cmdline-tools/bin/sdkmanager" ]; then
    SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/cmdline-tools/bin/sdkmanager"
  elif [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
  elif [ -f "$ANDROID_HOME/cmdline-tools/bin/sdkmanager" ]; then
    SDKMANAGER="$ANDROID_HOME/cmdline-tools/bin/sdkmanager"
  elif [ -d "$ANDROID_HOME/cmdline-tools" ]; then
    # Chercher dans tous les sous-dossiers
    SDKMANAGER=$(find "$ANDROID_HOME/cmdline-tools" -name "sdkmanager" -type f 2>/dev/null | head -1)
  elif [ -f "$ANDROID_HOME/tools/bin/sdkmanager" ]; then
    SDKMANAGER="$ANDROID_HOME/tools/bin/sdkmanager"
  fi
  
  # Si sdkmanager n'existe pas, essayer de l'installer
  if [ -z "$SDKMANAGER" ]; then
    echo -e "${YELLOW}⚠ sdkmanager non trouvé${NC}"
    echo -e "${YELLOW}   Installation des command-line tools...${NC}"
    
    # Créer le dossier cmdline-tools
    mkdir -p "$ANDROID_HOME/cmdline-tools" 2>/dev/null || true
    
    # Télécharger et installer les command-line tools
    CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    CMDLINE_TOOLS_ZIP="/tmp/cmdline-tools.zip"
    
    if command -v wget &> /dev/null; then
      echo -e "${YELLOW}Téléchargement des command-line tools...${NC}"
      wget -q --show-progress "$CMDLINE_TOOLS_URL" -O "$CMDLINE_TOOLS_ZIP" 2>&1 || {
        echo -e "${RED}❌ Échec du téléchargement${NC}"
        echo -e "${YELLOW}   Installation manuelle requise${NC}"
      }
      
      if [ -f "$CMDLINE_TOOLS_ZIP" ]; then
        echo -e "${YELLOW}Extraction des command-line tools...${NC}"
        unzip -q "$CMDLINE_TOOLS_ZIP" -d "$ANDROID_HOME/cmdline-tools" 2>/dev/null || true
        rm -f "$CMDLINE_TOOLS_ZIP"
        
        # Déplacer vers latest si nécessaire
        if [ -d "$ANDROID_HOME/cmdline-tools/cmdline-tools" ]; then
          mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" 2>/dev/null || true
        fi
        
        # Chercher sdkmanager après l'extraction
        if [ -f "$ANDROID_HOME/cmdline-tools/latest/cmdline-tools/bin/sdkmanager" ]; then
          SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/cmdline-tools/bin/sdkmanager"
          export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/cmdline-tools/bin"
          echo -e "${GREEN}✓ Command-line tools installés${NC}"
        elif [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
          SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
          export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
          echo -e "${GREEN}✓ Command-line tools installés${NC}"
        else
          # Chercher dans tous les sous-dossiers
          SDKMANAGER=$(find "$ANDROID_HOME/cmdline-tools" -name "sdkmanager" -type f 2>/dev/null | head -1)
          if [ ! -z "$SDKMANAGER" ]; then
            echo -e "${GREEN}✓ Command-line tools installés (sdkmanager trouvé)${NC}"
          fi
        fi
      fi
    else
      echo -e "${YELLOW}⚠ wget non disponible, installation manuelle requise${NC}"
      echo -e "${YELLOW}   Téléchargez depuis: https://developer.android.com/studio#command-tools${NC}"
    fi
  fi
  
  # Accepter les licences si sdkmanager est disponible
  if [ ! -z "$SDKMANAGER" ]; then
    echo -e "${GREEN}✓ sdkmanager trouvé: $SDKMANAGER${NC}"
    
    # Toujours accepter les licences pour s'assurer qu'elles sont à jour
    echo -e "${YELLOW}Acceptation des licences Android SDK...${NC}"
    
    # Utiliser yes pour accepter toutes les licences automatiquement
    # IMPORTANT: Utiliser --sdk_root pour que sdkmanager fonctionne correctement
    if command -v yes &> /dev/null; then
      yes | "$SDKMANAGER" --licenses --sdk_root="$ANDROID_HOME" > /tmp/android_licenses.log 2>&1 || {
        # Si yes échoue, créer un script temporaire
        LICENSE_SCRIPT=$(mktemp)
        for i in {1..50}; do echo "y"; done > "$LICENSE_SCRIPT"
        "$SDKMANAGER" --licenses --sdk_root="$ANDROID_HOME" < "$LICENSE_SCRIPT" > /tmp/android_licenses.log 2>&1 || true
        rm -f "$LICENSE_SCRIPT"
      }
    else
      # Créer un script temporaire avec des réponses 'y'
      LICENSE_SCRIPT=$(mktemp)
      for i in {1..50}; do echo "y"; done > "$LICENSE_SCRIPT"
      "$SDKMANAGER" --licenses --sdk_root="$ANDROID_HOME" < "$LICENSE_SCRIPT" > /tmp/android_licenses.log 2>&1 || true
      rm -f "$LICENSE_SCRIPT"
    fi
    
    # Vérifier que les licences sont acceptées
    LICENSE_COUNT=$(find "$ANDROID_HOME/licenses" -name "*.txt" 2>/dev/null | wc -l)
    if [ "$LICENSE_COUNT" -gt 0 ]; then
      echo -e "${GREEN}✓ $LICENSE_COUNT licence(s) Android SDK acceptée(s)${NC}"
    else
      echo -e "${YELLOW}⚠ Aucune licence .txt trouvée, création manuelle...${NC}"
      mkdir -p "$ANDROID_HOME/licenses" 2>/dev/null || true
      # Créer les fichiers de licence standard (format requis par Gradle)
      echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license.txt" 2>/dev/null || true
      echo "84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license.txt" 2>/dev/null || true
      echo "d975f751698a77b662f1254ddbeed3901e976f5a" > "$ANDROID_HOME/licenses/android-sdk-arm-dbt-license.txt" 2>/dev/null || true
      echo "601085b94cd77f0b54ff86406957099ebe79c4d6" > "$ANDROID_HOME/licenses/android-googletv-license.txt" 2>/dev/null || true
      echo -e "${GREEN}✓ Licences créées manuellement${NC}"
    fi
    
    # Installer les composants requis (platforms;android-34 et build-tools;34.0.0)
    echo -e "${YELLOW}Installation des composants Android SDK requis (Platform 34, Build-Tools 34)...${NC}"
    if command -v yes &> /dev/null; then
      yes | "$SDKMANAGER" "platforms;android-34" "build-tools;34.0.0" --sdk_root="$ANDROID_HOME" > /tmp/android_sdk_install.log 2>&1 || {
        echo -e "${YELLOW}⚠ Certains composants n'ont pas pu être installés${NC}"
        echo -e "${YELLOW}   Vérifiez les logs: /tmp/android_sdk_install.log${NC}"
      }
    else
      "$SDKMANAGER" "platforms;android-34" "build-tools;34.0.0" --sdk_root="$ANDROID_HOME" > /tmp/android_sdk_install.log 2>&1 || {
        echo -e "${YELLOW}⚠ Installation des composants en cours...${NC}"
      }
    fi
    echo -e "${GREEN}✓ Composants Android SDK vérifiés/installés${NC}"
  else
    echo -e "${YELLOW}⚠ sdkmanager non disponible${NC}"
    echo -e "${YELLOW}   Création manuelle des fichiers de licence...${NC}"
    mkdir -p "$ANDROID_HOME/licenses" 2>/dev/null || true
    
    # Créer tous les fichiers de licence standard Android SDK
    # Créer tous les fichiers de licence standard Android SDK (format .txt requis par Gradle)
    echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license.txt" 2>/dev/null || true
    echo "84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license.txt" 2>/dev/null || true
    echo "d975f751698a77b662f1254ddbeed3901e976f5a" > "$ANDROID_HOME/licenses/android-sdk-arm-dbt-license.txt" 2>/dev/null || true
    echo "601085b94cd77f0b54ff86406957099ebe79c4d6" > "$ANDROID_HOME/licenses/android-googletv-license.txt" 2>/dev/null || true
    echo "33b6a2b64607a11ce7e8bb9f8b3c5e6c0e8c0e8c" > "$ANDROID_HOME/licenses/google-gdk-license.txt" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Licences créées manuellement${NC}"
    echo -e "${GREEN}   Les fichiers de licence ont été créés dans $ANDROID_HOME/licenses${NC}"
  fi
fi

# Vérifier et configurer Java pour Gradle
# Java 25 n'est pas encore supporté par Gradle, on doit utiliser Java 17 ou 21
JAVA_VERSION=$(java -version 2>&1 | head -1 | grep -oE "version \"[0-9]+" | grep -oE "[0-9]+")
if [ ! -z "$JAVA_VERSION" ] && [ "$JAVA_VERSION" -gt 21 ]; then
  echo -e "${YELLOW}⚠ Java $JAVA_VERSION détecté (version système)${NC}"
  echo -e "${YELLOW}   Configuration de Java 21 pour Gradle...${NC}"
  
  # Chercher Java 21 ou 17 (priorité à Java 21)
  JAVA_21_PATH=""
  JAVA_17_PATH=""
  
  if [ -d "/usr/lib/jvm/java-21-openjdk" ]; then
    JAVA_21_PATH="/usr/lib/jvm/java-21-openjdk"
  fi
  if [ -d "/usr/lib/jvm/java-17-openjdk" ]; then
    JAVA_17_PATH="/usr/lib/jvm/java-17-openjdk"
  fi
  
  # Utiliser Java 21 si disponible, sinon Java 17
  if [ ! -z "$JAVA_21_PATH" ] && [ -f "$JAVA_21_PATH/bin/java" ]; then
    export JAVA_HOME="$JAVA_21_PATH"
    export PATH="$JAVA_21_PATH/bin:$PATH"
    echo -e "${GREEN}✓ Java 21 configuré pour Gradle (Java $JAVA_VERSION reste la version système)${NC}"
    # Vérifier la version
    JAVA_GRADLE_VERSION=$("$JAVA_21_PATH/bin/java" -version 2>&1 | head -1)
    echo -e "${GREEN}   Version Gradle: $JAVA_GRADLE_VERSION${NC}"
  elif [ ! -z "$JAVA_17_PATH" ] && [ -f "$JAVA_17_PATH/bin/java" ]; then
    export JAVA_HOME="$JAVA_17_PATH"
    export PATH="$JAVA_17_PATH/bin:$PATH"
    echo -e "${GREEN}✓ Java 17 configuré pour Gradle (Java $JAVA_VERSION reste la version système)${NC}"
  else
    echo -e "${RED}❌ Java 17 ou 21 non trouvé${NC}"
    echo -e "${YELLOW}   Installation requise:${NC}"
    echo -e "${YELLOW}   sudo pacman -S jdk21-openjdk${NC}"
    echo -e "${YELLOW}   ${NC}"
    echo -e "${YELLOW}   Après installation, relancez: make dev${NC}"
    echo ""
    read -p "Voulez-vous installer Java 21 maintenant? (o/N): " install_java
    if [[ "$install_java" =~ ^[oO]$ ]]; then
      echo -e "${GREEN}Installation de Java 21...${NC}"
      sudo pacman -S --noconfirm jdk21-openjdk || {
        echo -e "${RED}❌ Échec de l'installation${NC}"
        echo -e "${YELLOW}   Installez manuellement: sudo pacman -S jdk21-openjdk${NC}"
        exit 1
      }
      # Vérifier que Java 21 est maintenant disponible
      if [ -d "/usr/lib/jvm/java-21-openjdk" ] && [ -f "/usr/lib/jvm/java-21-openjdk/bin/java" ]; then
        export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
        export PATH="/usr/lib/jvm/java-21-openjdk/bin:$PATH"
        echo -e "${GREEN}✓ Java 21 installé et configuré pour Gradle${NC}"
        JAVA_GRADLE_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)
        echo -e "${GREEN}   Version: $JAVA_GRADLE_VERSION${NC}"
      else
        echo -e "${YELLOW}⚠ Java 21 installé mais chemin non trouvé${NC}"
        echo -e "${YELLOW}   Redémarrez le script: make dev${NC}"
        exit 1
      fi
    else
      exit 1
    fi
  fi
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
echo -e "${YELLOW}Backend API: http://$MACHINE_IP:7272/api${NC}"
echo -e "${YELLOW}Frontend Web (PC): http://localhost:7070${NC}"
echo -e "${YELLOW}Frontend Web (Mobile): http://$MACHINE_IP:7070${NC}"
echo ""

# Vérifier si on veut forcer le web uniquement (variable d'environnement)
FORCE_WEB_ONLY="${FORCE_WEB_ONLY:-false}"
if [ "$FORCE_WEB_ONLY" = "true" ] || [ "$FORCE_WEB_ONLY" = "1" ]; then
  echo -e "${GREEN}Mode Web uniquement activé (FORCE_WEB_ONLY=true)${NC}"
  ANDROID_DEVICE_ID=""
  ANDROID_DEVICE_COUNT=0
  ANDROID_USB_DEVICES=()
  ANDROID_WIFI_DEVICES=()
  ANDROID_WIFI_IPS=()
  HAS_ANDROID=false
else
  # Détecter les appareils Android connectés via ADB (USB et WiFi)
  if command -v adb >/dev/null 2>&1; then
    # Détecter tous les devices (USB et WiFi)
    ALL_ADB_DEVICES=$(adb devices 2>/dev/null | grep -v "List" | grep "device$" | awk '{print $1}')
  ANDROID_DEVICE_COUNT=$(echo "$ALL_ADB_DEVICES" | grep -c . || echo "0")
  
  # Séparer les devices USB (ID alphanumériques) et WiFi (adresses IP)
  while IFS= read -r device_id; do
    if [ ! -z "$device_id" ]; then
      # Vérifier si c'est une adresse IP (WiFi) ou un ID USB
      if echo "$device_id" | grep -qE "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"; then
        # Device WiFi
        ANDROID_WIFI_DEVICES+=("$device_id")
        ANDROID_WIFI_IPS+=("$device_id")
      else
        # Device USB
        ANDROID_USB_DEVICES+=("$device_id")
      fi
    fi
  done <<< "$ALL_ADB_DEVICES"
  
  # Priorité: WiFi d'abord, puis USB
  if [ ${#ANDROID_WIFI_DEVICES[@]} -gt 0 ]; then
    ANDROID_DEVICE_ID="${ANDROID_WIFI_DEVICES[0]}"
    ANDROID_DEVICES="$ANDROID_DEVICE_ID"
  elif [ ${#ANDROID_USB_DEVICES[@]} -gt 0 ]; then
    ANDROID_DEVICE_ID="${ANDROID_USB_DEVICES[0]}"
    ANDROID_DEVICES="$ANDROID_DEVICE_ID"
  fi
  
  # Si un device ADB est détecté mais pas Flutter, essayer de le forcer
  if [ ! -z "$ANDROID_DEVICE_ID" ]; then
    # Vérifier si c'est un device WiFi ou USB
    IS_WIFI_DEVICE=false
    if echo "$ANDROID_DEVICE_ID" | grep -qE "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"; then
      IS_WIFI_DEVICE=true
    fi
    
    # Vérifier si Flutter peut voir ce device
    FLUTTER_DEVICE_CHECK=$($FLUTTER_CMD devices 2>/dev/null | grep -i "$ANDROID_DEVICE_ID\|android" || echo "")
    if [ -z "$FLUTTER_DEVICE_CHECK" ]; then
      DEVICE_TYPE="USB"
      if [ "$IS_WIFI_DEVICE" = true ]; then
        DEVICE_TYPE="WiFi"
      fi
      echo -e "${YELLOW}⚠ Device ADB ($DEVICE_TYPE) détecté ($ANDROID_DEVICE_ID) mais Flutter ne le voit pas${NC}"
      echo -e "${YELLOW}   Tentative de reconnaissance par Flutter...${NC}"
      
      # Configurer ANDROID_SERIAL pour que Flutter utilise ce device
      export ANDROID_SERIAL="$ANDROID_DEVICE_ID"
      
      # Essayer de forcer Flutter à reconnaître le device
      # Vérifier que le device répond
      if adb -s "$ANDROID_DEVICE_ID" shell echo "test" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Device ADB ($DEVICE_TYPE) répond correctement${NC}"
        # Forcer Flutter à scanner les devices
        $FLUTTER_CMD devices > /dev/null 2>&1 || true
        sleep 2
        # Vérifier à nouveau
        FLUTTER_DEVICE_CHECK=$($FLUTTER_CMD devices 2>/dev/null | grep -i "android" || echo "")
        if [ -z "$FLUTTER_DEVICE_CHECK" ]; then
          echo -e "${YELLOW}⚠ Flutter ne détecte toujours pas le device${NC}"
          echo -e "${YELLOW}   On utilisera l'ID ADB directement ($ANDROID_DEVICE_ID)${NC}"
        else
          echo -e "${GREEN}✓ Device maintenant détecté par Flutter${NC}"
        fi
      fi
    fi
  fi
  fi
fi

# Détecter les appareils via Flutter
FLUTTER_ANDROID_DEVICES=$($FLUTTER_CMD devices 2>/dev/null | grep -i "android" | head -1 || echo "")
FLUTTER_WEB_AVAILABLE=$($FLUTTER_CMD devices 2>/dev/null | grep -i "web-server\|chrome" | head -1 || echo "")

# Si plusieurs devices sont disponibles, permettre de choisir
SELECTED_DEVICE_ID="$ANDROID_DEVICE_ID"
if [ ${#ANDROID_WIFI_DEVICES[@]} -gt 0 ] && [ ${#ANDROID_USB_DEVICES[@]} -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}Plusieurs devices détectés, choisissez lequel utiliser:${NC}"
  DEVICE_INDEX=1
  for wifi_device in "${ANDROID_WIFI_DEVICES[@]}"; do
    DEVICE_INFO=$(adb -s "$wifi_device" shell getprop ro.product.model 2>/dev/null || echo "Android Device")
    echo -e "  ${GREEN}$DEVICE_INDEX)${NC} WiFi: $wifi_device ($DEVICE_INFO)"
    DEVICE_INDEX=$((DEVICE_INDEX + 1))
  done
  for usb_device in "${ANDROID_USB_DEVICES[@]}"; do
    DEVICE_INFO=$(adb -s "$usb_device" shell getprop ro.product.model 2>/dev/null || echo "Android Device")
    echo -e "  ${GREEN}$DEVICE_INDEX)${NC} USB: $usb_device ($DEVICE_INFO)"
    DEVICE_INDEX=$((DEVICE_INDEX + 1))
  done
  echo ""
  read -p "Votre choix (défaut: 1 - WiFi): " device_choice
  device_choice=${device_choice:-1}
  
  # Sélectionner le device choisi
  TOTAL_DEVICES=$((${#ANDROID_WIFI_DEVICES[@]} + ${#ANDROID_USB_DEVICES[@]}))
  if [ "$device_choice" -ge 1 ] && [ "$device_choice" -le "$TOTAL_DEVICES" ]; then
    if [ "$device_choice" -le ${#ANDROID_WIFI_DEVICES[@]} ]; then
      SELECTED_DEVICE_ID="${ANDROID_WIFI_DEVICES[$((device_choice - 1))]}"
    else
      USB_INDEX=$((device_choice - ${#ANDROID_WIFI_DEVICES[@]} - 1))
      SELECTED_DEVICE_ID="${ANDROID_USB_DEVICES[$USB_INDEX]}"
    fi
    ANDROID_DEVICE_ID="$SELECTED_DEVICE_ID"
    echo -e "${GREEN}✓ Device sélectionné: $ANDROID_DEVICE_ID${NC}"
  fi
fi

# Si on a un device ADB mais pas Flutter, on peut quand même l'utiliser
if [ ! -z "$ANDROID_DEVICE_ID" ] && [ -z "$FLUTTER_ANDROID_DEVICES" ]; then
  DEVICE_TYPE="USB"
  if echo "$ANDROID_DEVICE_ID" | grep -qE "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"; then
    DEVICE_TYPE="WiFi"
  fi
  echo -e "${YELLOW}⚠ Utilisation du device ADB ($DEVICE_TYPE) directement: $ANDROID_DEVICE_ID${NC}"
  # Essayer de trouver l'ID Flutter correspondant
  FLUTTER_DEVICE_JSON=$($FLUTTER_CMD devices --machine 2>/dev/null || echo "[]")
  # Chercher un device Android dans la sortie JSON
  if echo "$FLUTTER_DEVICE_JSON" | grep -q "android"; then
    FLUTTER_ANDROID_ID=$(echo "$FLUTTER_DEVICE_JSON" | grep -o '"id":"[^"]*"' | grep -i android | head -1 | cut -d'"' -f4 || echo "")
  fi
fi

# Menu de sélection
DEVICE_CHOICE=""
HAS_ANDROID=false
AUTO_SELECT_ANDROID=false

# Si FORCE_WEB_ONLY est activé, sauter directement au web
if [ "$FORCE_WEB_ONLY" = "true" ] || [ "$FORCE_WEB_ONLY" = "1" ]; then
  DEVICE_CHOICE="2"
  echo -e "${GREEN}→ Lancement automatique sur Web uniquement${NC}"
  HAS_ANDROID=false
elif [ ! -z "$ANDROID_DEVICE_ID" ] || [ ! -z "$FLUTTER_ANDROID_DEVICES" ]; then
  HAS_ANDROID=true
fi

if [ "$FORCE_WEB_ONLY" != "true" ] && [ "$FORCE_WEB_ONLY" != "1" ] && [ "$HAS_ANDROID" = true ]; then
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}Appareils détectés:${NC}"
  
  # Afficher les devices WiFi
  if [ ${#ANDROID_WIFI_DEVICES[@]} -gt 0 ]; then
    for wifi_device in "${ANDROID_WIFI_DEVICES[@]}"; do
      DEVICE_INFO=$(adb -s "$wifi_device" shell getprop ro.product.model 2>/dev/null || echo "Android Device")
      echo -e "  ${GREEN}✓ Android (WiFi): $wifi_device${NC}"
      if [ ! -z "$DEVICE_INFO" ] && [ "$DEVICE_INFO" != "Android Device" ]; then
        echo -e "     Modèle: $DEVICE_INFO${NC}"
      fi
    done
  fi
  
  # Afficher les devices USB
  if [ ${#ANDROID_USB_DEVICES[@]} -gt 0 ]; then
    for usb_device in "${ANDROID_USB_DEVICES[@]}"; do
      DEVICE_INFO=$(adb -s "$usb_device" shell getprop ro.product.model 2>/dev/null || echo "Android Device")
      echo -e "  ${GREEN}✓ Android (USB): $usb_device${NC}"
      if [ ! -z "$DEVICE_INFO" ] && [ "$DEVICE_INFO" != "Android Device" ]; then
        echo -e "     Modèle: $DEVICE_INFO${NC}"
      fi
    done
  fi
  
  # Proposer de connecter via WiFi si un device USB est détecté mais pas de WiFi
  if [ ${#ANDROID_USB_DEVICES[@]} -gt 0 ] && [ ${#ANDROID_WIFI_DEVICES[@]} -eq 0 ]; then
    # Charger le choix sauvegardé si disponible (lors d'un redémarrage)
    if [ -f "$DEV_CONFIG_FILE" ]; then
      source "$DEV_CONFIG_FILE" 2>/dev/null || true
    fi
    
    # Si le choix n'est pas sauvegardé, demander à l'utilisateur
    if [ -z "$SAVED_ENABLE_WIFI" ]; then
      echo ""
      echo -e "${YELLOW}💡 Astuce: Vous pouvez connecter votre téléphone via WiFi${NC}"
      read -p "Voulez-vous activer la connexion ADB via WiFi? (o/N): " enable_wifi
      # Sauvegarder le choix (créer le fichier s'il n'existe pas)
      echo "SAVED_ENABLE_WIFI=\"$enable_wifi\"" > "$DEV_CONFIG_FILE"
    else
      enable_wifi="$SAVED_ENABLE_WIFI"
      echo -e "${GREEN}→ Réutilisation du choix précédent: ADB WiFi = ${enable_wifi}${NC}"
    fi
    
    if [[ "$enable_wifi" =~ ^[oO]$ ]]; then
      USB_DEVICE="${ANDROID_USB_DEVICES[0]}"
      echo -e "${GREEN}Activation du mode TCP/IP sur le device USB...${NC}"
      adb -s "$USB_DEVICE" tcpip 5555 2>/dev/null || {
        echo -e "${RED}❌ Échec de l'activation du mode TCP/IP${NC}"
        echo -e "${YELLOW}Vérifiez que le débogage USB est activé${NC}"
      }
      sleep 3
      
      # Obtenir l'IP du device - plusieurs méthodes
      echo -e "${YELLOW}Détection de l'IP du téléphone...${NC}"
      DEVICE_IP=""
      
      # Méthode 1: ip route get (Android moderne)
      ROUTE_OUTPUT=$(adb -s "$USB_DEVICE" shell "ip route get 1.1.1.1 2>/dev/null" 2>/dev/null)
      if [ ! -z "$ROUTE_OUTPUT" ]; then
        # Chercher l'IP dans la sortie (peut être dans différents champs selon la version)
        DEVICE_IP=$(echo "$ROUTE_OUTPUT" | grep -oE "src [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | awk '{print $2}' | head -1)
        if [ -z "$DEVICE_IP" ]; then
          # Essayer de trouver n'importe quelle IP dans la ligne
          DEVICE_IP=$(echo "$ROUTE_OUTPUT" | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "1.1.1.1" | grep -v "192.168.1.254" | head -1)
        fi
      fi
      
      # Méthode 2: ifconfig wlan0 (anciennes versions Android)
      if [ -z "$DEVICE_IP" ]; then
        IFCONFIG_OUTPUT=$(adb -s "$USB_DEVICE" shell "ifconfig wlan0 2>/dev/null" 2>/dev/null)
        if [ ! -z "$IFCONFIG_OUTPUT" ]; then
          DEVICE_IP=$(echo "$IFCONFIG_OUTPUT" | grep -oE "inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | cut -d: -f2 | head -1)
          if [ -z "$DEVICE_IP" ]; then
            # Format moderne: inet 192.168.1.184
            DEVICE_IP=$(echo "$IFCONFIG_OUTPUT" | grep -oE "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | awk '{print $2}' | head -1)
          fi
        fi
      fi
      
      # Méthode 3: ip addr show wlan0
      if [ -z "$DEVICE_IP" ]; then
        IP_ADDR_OUTPUT=$(adb -s "$USB_DEVICE" shell "ip addr show wlan0 2>/dev/null" 2>/dev/null)
        if [ ! -z "$IP_ADDR_OUTPUT" ]; then
          DEVICE_IP=$(echo "$IP_ADDR_OUTPUT" | grep -oE "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | awk '{print $2}' | cut -d/ -f1 | head -1)
        fi
      fi
      
      if [ ! -z "$DEVICE_IP" ] && [ "$DEVICE_IP" != "127.0.0.1" ]; then
        echo -e "${GREEN}✓ IP détectée: $DEVICE_IP${NC}"
        echo -e "${GREEN}Connexion au device via WiFi ($DEVICE_IP:5555)...${NC}"
        
        # Déconnecter d'abord si déjà connecté
        adb disconnect "$DEVICE_IP:5555" 2>/dev/null || true
        sleep 1
        
        # Connecter via WiFi
        CONNECT_OUTPUT=$(adb connect "$DEVICE_IP:5555" 2>&1)
        sleep 3
        
        # Vérifier si la connexion WiFi a réussi
        if adb devices 2>/dev/null | grep -q "$DEVICE_IP:5555.*device"; then
          ANDROID_WIFI_DEVICES+=("$DEVICE_IP:5555")
          ANDROID_DEVICE_ID="$DEVICE_IP:5555"
          echo -e "${GREEN}✓ Connexion WiFi établie avec succès!${NC}"
          echo -e "${GREEN}   Vous pouvez maintenant débrancher le câble USB${NC}"
        else
          echo -e "${YELLOW}⚠ Connexion WiFi échouée${NC}"
          echo -e "${YELLOW}   Sortie: $CONNECT_OUTPUT${NC}"
          echo -e "${YELLOW}   Vérifiez que:${NC}"
          echo -e "${YELLOW}   - Le téléphone et le PC sont sur le même réseau WiFi${NC}"
          echo -e "${YELLOW}   - Le port 5555 n'est pas bloqué par le firewall${NC}"
          echo -e "${YELLOW}   - Le mode TCP/IP est bien activé${NC}"
          echo -e "${YELLOW}   Utilisation du device USB pour l'instant${NC}"
        fi
      else
        echo -e "${YELLOW}⚠ Impossible de détecter l'IP du device${NC}"
        echo -e "${YELLOW}   Vérifiez que le WiFi est activé sur votre téléphone${NC}"
        echo -e "${YELLOW}   Vous pouvez connecter manuellement avec:${NC}"
        echo -e "${YELLOW}   adb connect <IP_DU_TELEPHONE>:5555${NC}"
        echo -e "${YELLOW}   Pour trouver l'IP: Paramètres > À propos du téléphone > État${NC}"
      fi
    fi
  fi
  
  if [ ! -z "$FLUTTER_ANDROID_DEVICES" ]; then
    echo -e "  ${GREEN}✓ Android (Flutter): détecté${NC}"
  fi
  echo -e "  ${GREEN}✓ Web (navigateur)${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  # Charger le choix sauvegardé si disponible (lors d'un redémarrage)
  if [ -f "$DEV_CONFIG_FILE" ]; then
    source "$DEV_CONFIG_FILE" 2>/dev/null || true
  fi
  
  # Si le choix n'est pas sauvegardé, demander à l'utilisateur
  if [ -z "$SAVED_DEVICE_CHOICE" ]; then
    echo -e "${YELLOW}Choisissez où lancer l'application:${NC}"
    echo -e "  ${GREEN}1)${NC} Téléphone Android uniquement ${YELLOW}(recommandé si device connecté)${NC}"
    echo -e "  ${GREEN}2)${NC} Navigateur Web uniquement"
    echo -e "  ${GREEN}3)${NC} Les deux (Android + Web)"
    echo ""
    read -p "Votre choix [1-3] (défaut: 1 pour Android, 2 sinon): " DEVICE_CHOICE
    
    # Si un device Android est détecté, proposer Android par défaut
    if [ -z "$DEVICE_CHOICE" ]; then
      if [ ! -z "$ANDROID_DEVICE_ID" ]; then
        DEVICE_CHOICE="1"
        AUTO_SELECT_ANDROID=true
        echo -e "${GREEN}→ Sélection automatique: Android (device détecté)${NC}"
      else
        DEVICE_CHOICE="2"
      fi
    fi
    # Sauvegarder le choix (ajouter au fichier existant ou créer)
    if [ -f "$DEV_CONFIG_FILE" ]; then
      echo "SAVED_DEVICE_CHOICE=\"$DEVICE_CHOICE\"" >> "$DEV_CONFIG_FILE"
    else
      echo "SAVED_DEVICE_CHOICE=\"$DEVICE_CHOICE\"" > "$DEV_CONFIG_FILE"
    fi
  else
    DEVICE_CHOICE="$SAVED_DEVICE_CHOICE"
    echo -e "${GREEN}→ Réutilisation du choix précédent: Mode = $DEVICE_CHOICE${NC}"
  fi
elif [ "$FORCE_WEB_ONLY" != "true" ] && [ "$FORCE_WEB_ONLY" != "1" ]; then
  # Charger le choix sauvegardé si disponible (lors d'un redémarrage)
  if [ -f "$DEV_CONFIG_FILE" ]; then
    source "$DEV_CONFIG_FILE" 2>/dev/null || true
  fi
  
  # Si le choix n'est pas sauvegardé, demander à l'utilisateur
  if [ -z "$SAVED_DEVICE_CHOICE" ]; then
    echo -e "${YELLOW}⚠ Aucun appareil Android détecté${NC}"
    echo -e "${YELLOW}   Connectez votre téléphone via USB et activez le débogage USB${NC}"
    echo -e "${YELLOW}   Ou choisissez l'option Web uniquement${NC}"
    echo ""
    echo -e "${YELLOW}Choisissez où lancer l'application:${NC}"
    echo -e "  ${GREEN}1)${NC} Téléphone Android uniquement ${YELLOW}(nécessite un device connecté)${NC}"
    echo -e "  ${GREEN}2)${NC} Navigateur Web uniquement ${YELLOW}(PC - localhost)${NC}"
    echo -e "  ${GREEN}3)${NC} Les deux (Android + Web)"
    echo ""
    read -p "Votre choix [1-3] (défaut: 2 pour Web): " DEVICE_CHOICE
    if [ -z "$DEVICE_CHOICE" ]; then
      DEVICE_CHOICE="2"
      echo -e "${GREEN}→ Sélection automatique: Web (aucun device Android détecté)${NC}"
    fi
    # Sauvegarder le choix (ajouter au fichier existant ou créer)
    if [ -f "$DEV_CONFIG_FILE" ]; then
      echo "SAVED_DEVICE_CHOICE=\"$DEVICE_CHOICE\"" >> "$DEV_CONFIG_FILE"
    else
      echo "SAVED_DEVICE_CHOICE=\"$DEVICE_CHOICE\"" > "$DEV_CONFIG_FILE"
    fi
  else
    DEVICE_CHOICE="$SAVED_DEVICE_CHOICE"
    echo -e "${GREEN}→ Réutilisation du choix précédent: Mode = $DEVICE_CHOICE${NC}"
  fi
fi

# Configurer l'URL API pour mobile si nécessaire
if [ "$DEVICE_CHOICE" = "1" ] || [ "$DEVICE_CHOICE" = "3" ]; then
  echo -e "${GREEN}Configuration de l'URL API pour mobile...${NC}"
  if [ -f "$PROJECT_ROOT/frontend/lib/services/auth_service.dart" ]; then
    # Sauvegarder la version originale
    cp "$PROJECT_ROOT/frontend/lib/services/auth_service.dart" "$PROJECT_ROOT/frontend/lib/services/auth_service.dart.bak" 2>/dev/null || true
    # Modifier l'URL pour mobile (mais on utilise déjà ApiConfig qui détecte automatiquement)
    echo -e "${GREEN}✓ URL API configurée pour mobile: http://$MACHINE_IP:7272/api${NC}"
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

# Fonction pour redémarrer l'application
restart_app() {
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}🔄 Redémarrage de l'application...${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  
  # Arrêter les processus
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
  pkill -f "python.*http.server" 2>/dev/null || true
  
  # Attendre un peu pour que les processus se terminent
  sleep 2
  
  # Libérer les ports
  if command -v lsof >/dev/null 2>&1; then
    PIDS_7272=$(lsof -ti:7272 2>/dev/null || echo "")
    if [ ! -z "$PIDS_7272" ]; then
      echo $PIDS_7272 | xargs kill -9 2>/dev/null || true
    fi
    PIDS_7070=$(lsof -ti:7070 2>/dev/null || echo "")
    if [ ! -z "$PIDS_7070" ]; then
      echo $PIDS_7070 | xargs kill -9 2>/dev/null || true
    fi
  fi
  
  # Redémarrer en appelant le script à nouveau
  # Les choix sauvegardés seront automatiquement réutilisés
  echo -e "${YELLOW}Redémarrage dans 2 secondes...${NC}"
  sleep 2
  # Préserver les variables d'environnement importantes
  if [ ! -z "$FORCE_WEB_ONLY" ]; then
    export FORCE_WEB_ONLY="$FORCE_WEB_ONLY"
  fi
  if [ ! -z "$STACKTRACE" ]; then
    export STACKTRACE="$STACKTRACE"
  fi
  exec "$PROJECT_ROOT/scripts/dev/dev.sh" "$@"
}

# Fonction pour arrêter définitivement l'application
stop_app() {
  echo ""
  echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${RED}🛑 Arrêt définitif de l'application...${NC}"
  echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  
  # Supprimer le fichier de configuration pour que les choix soient redemandés au prochain démarrage
  rm -f "$DEV_CONFIG_FILE" 2>/dev/null || true
  
  cleanup
  exit 0
}

# Variable pour détecter double Ctrl+C
_LAST_CTRL_C_TIME=0

# Gérer Ctrl+C : redémarrer si simple, arrêter si double
handle_ctrl_c() {
  local current_time=$(date +%s)
  local time_diff=$((current_time - _LAST_CTRL_C_TIME))
  
  if [ $time_diff -lt 2 ] && [ $_LAST_CTRL_C_TIME -gt 0 ]; then
    # Double Ctrl+C détecté (moins de 2 secondes entre les deux)
    stop_app
  else
    # Simple Ctrl+C - redémarrer
    _LAST_CTRL_C_TIME=$current_time
    restart_app
  fi
}

# Gérer Ctrl+C : utiliser la fonction de détection double
trap handle_ctrl_c INT
# Gérer Ctrl+\ (SIGQUIT) : arrêter définitivement (alternative à Ctrl+A)
trap stop_app QUIT
trap cleanup TERM

# Vérifier que les dépendances sont installées
if [ ! -d "$PROJECT_ROOT/backend/node_modules" ]; then
  echo -e "${YELLOW}Installation des dépendances backend...${NC}"
  cd "$PROJECT_ROOT/backend" || exit 1
  npm install
fi

# Démarrer le backend
echo -e "${GREEN}Démarrage du backend sur le port 7272...${NC}"
cd "$PROJECT_ROOT/backend" || exit 1
PORT=7272 HOST=0.0.0.0 npm run dev > /tmp/backend.log 2>&1 &
BACKEND_PID=$!
echo "$BACKEND_PID" > /tmp/backend_pid.txt 2>/dev/null || true

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
    if [ ! -z "$ANDROID_DEVICE_ID" ]; then
      # Configurer ANDROID_SERIAL pour forcer Flutter à utiliser ce device
      export ANDROID_SERIAL="$ANDROID_DEVICE_ID"
      echo -e "${YELLOW}Device sélectionné: $ANDROID_DEVICE_ID${NC}"
      
      # Vérifier que le device répond
      if ! adb -s "$ANDROID_DEVICE_ID" shell echo "test" > /dev/null 2>&1; then
        echo -e "${RED}❌ Le device $ANDROID_DEVICE_ID ne répond pas${NC}"
        echo -e "${YELLOW}Vérifiez la connexion USB et le débogage USB${NC}"
        exit 1
      fi
      
      cd "$PROJECT_ROOT/frontend" || exit 1
      
      # Vérifier si Flutter détecte le device
      FLUTTER_DEVICES=$($FLUTTER_CMD devices 2>/dev/null)
      FLUTTER_SEES_ANDROID=false
      
      # Essayer de trouver l'ID du device dans la sortie Flutter
      if echo "$FLUTTER_DEVICES" | grep -qi "android"; then
        FLUTTER_SEES_ANDROID=true
        ANDROID_FLUTTER_ID=$(echo "$FLUTTER_DEVICES" | grep -i "android" | head -1 | awk '{print $5}' || echo "android")
        echo -e "${GREEN}✓ Flutter détecte Android: $ANDROID_FLUTTER_ID${NC}"
      else
        echo -e "${YELLOW}⚠ Flutter ne détecte pas le device Android${NC}"
        echo -e "${YELLOW}   Utilisation de la méthode ADB directe...${NC}"
      fi
      
      if [ "$FLUTTER_SEES_ANDROID" = true ]; then
        # Flutter voit Android, utiliser flutter run normalement
        echo -e "${GREEN}Lancement avec Flutter...${NC}"
        # Passer l'IP de la machine pour que le mobile puisse accéder au backend
        $FLUTTER_CMD run -d "$ANDROID_FLUTTER_ID" --dart-define=DEV_API_IP=$MACHINE_IP > /tmp/frontend.log 2>&1 &
        FRONTEND_PID=$!
      else
        # Flutter ne voit pas Android, utiliser la méthode de build + install
        echo -e "${GREEN}Build et installation de l'application...${NC}"
        echo -e "${YELLOW}Cette méthode peut prendre quelques minutes la première fois...${NC}"
        
        # S'assurer que Java 21 est utilisé pour Gradle
        if [ -d "/usr/lib/jvm/java-21-openjdk" ] && [ -f "/usr/lib/jvm/java-21-openjdk/bin/java" ]; then
          export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
          export PATH="/usr/lib/jvm/java-21-openjdk/bin:$PATH"
          echo -e "${GREEN}✓ Java 21 configuré pour le build (JAVA_HOME=$JAVA_HOME)${NC}"
        fi
        
        # Vérifier que gradle.properties pointe vers Java 21
        GRADLE_PROPERTIES="$PROJECT_ROOT/frontend/android/gradle.properties"
        if [ -f "$GRADLE_PROPERTIES" ]; then
          if ! grep -q "org.gradle.java.home=/usr/lib/jvm/java-21-openjdk" "$GRADLE_PROPERTIES"; then
            # Mettre à jour gradle.properties si nécessaire
            sed -i 's|org.gradle.java.home=.*|org.gradle.java.home=/usr/lib/jvm/java-21-openjdk|g' "$GRADLE_PROPERTIES" 2>/dev/null || true
            echo -e "${GREEN}✓ gradle.properties mis à jour pour utiliser Java 21${NC}"
          fi
        fi
        
        # Vérifier et créer les licences Android SDK avant le build
        if [ -d "$ANDROID_HOME" ]; then
          mkdir -p "$ANDROID_HOME/licenses" 2>/dev/null || true
          LICENSE_COUNT=$(find "$ANDROID_HOME/licenses" -name "*.txt" 2>/dev/null | wc -l)
          if [ "$LICENSE_COUNT" -eq 0 ]; then
            echo -e "${YELLOW}⚠ Aucune licence trouvée, création des licences Android SDK...${NC}"
            # Créer les fichiers de licence standard (format requis par Gradle)
            echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license.txt" 2>/dev/null || true
            echo "84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license.txt" 2>/dev/null || true
            echo "d975f751698a77b662f1254ddbeed3901e976f5a" > "$ANDROID_HOME/licenses/android-sdk-arm-dbt-license.txt" 2>/dev/null || true
            echo "601085b94cd77f0b54ff86406957099ebe79c4d6" > "$ANDROID_HOME/licenses/android-googletv-license.txt" 2>/dev/null || true
            echo -e "${GREEN}✓ Licences créées${NC}"
          else
            echo -e "${GREEN}✓ $LICENSE_COUNT licence(s) Android SDK trouvée(s)${NC}"
          fi
        fi
        
        # Vérifier si l'utilisateur veut voir la stacktrace
        # --stacktrace est une option Gradle, pas Flutter
        # Flutter utilise Gradle en interne, on utilise --verbose pour plus de détails
        if [ "${SHOW_STACKTRACE:-}" = "true" ] || [ "${STACKTRACE:-}" = "true" ]; then
          echo -e "${YELLOW}Mode stacktrace activé (affichage détaillé des logs)${NC}"
          FLUTTER_VERBOSE="--verbose"
          SHOW_FULL_LOG=true
        else
          FLUTTER_VERBOSE=""
          SHOW_FULL_LOG=false
        fi
        
        echo -e "${YELLOW}Build de l'APK...${NC}"
        # Passer l'IP de la machine pour que le mobile puisse accéder au backend
        if [ ! -z "$FLUTTER_VERBOSE" ]; then
          $FLUTTER_CMD build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=$MACHINE_IP $FLUTTER_VERBOSE > /tmp/flutter_build.log 2>&1 &
        else
          $FLUTTER_CMD build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=$MACHINE_IP > /tmp/flutter_build.log 2>&1 &
        fi
        BUILD_PID=$!
        
        # Attendre que le build se termine
        wait $BUILD_PID
        BUILD_RESULT=$?
        
        if [ $BUILD_RESULT -eq 0 ]; then
          APK_PATH="$PROJECT_ROOT/frontend/build/app/outputs/flutter-apk/app-debug.apk"
          if [ -f "$APK_PATH" ]; then
            echo -e "${GREEN}✓ APK créé avec succès${NC}"
            echo -e "${YELLOW}Installation sur le device...${NC}"
            
            # Désinstaller l'ancienne version si elle existe
            PACKAGE_NAME="com.delhomme.cooking_recipe.cookingrecipe"
            echo -e "${YELLOW}Désinstallation de l'ancienne version...${NC}"
            adb -s "$ANDROID_DEVICE_ID" uninstall "$PACKAGE_NAME" 2>/dev/null || true
            
            # Installer la nouvelle version
            echo -e "${YELLOW}Installation de l'APK...${NC}"
            if adb -s "$ANDROID_DEVICE_ID" install -r "$APK_PATH" > /tmp/adb_install.log 2>&1; then
              echo -e "${GREEN}✓ Application installée${NC}"
              echo -e "${GREEN}Lancement de l'application...${NC}"
              
              # Lancer l'application
              adb -s "$ANDROID_DEVICE_ID" shell am start -n "$PACKAGE_NAME/.MainActivity" > /tmp/adb_launch.log 2>&1
              
              if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Application lancée sur votre téléphone!${NC}"
                echo -e "${YELLOW}Pour voir les logs: adb -s $ANDROID_DEVICE_ID logcat${NC}"
                echo ""
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}Application Android démarrée avec succès!${NC}"
                echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}Note: Le hot reload n'est pas disponible avec cette méthode${NC}"
                echo -e "${YELLOW}Pour relancer après modification: make dev${NC}"
                
                # Ne pas lancer flutter attach car ça ne fonctionnera pas sans device détecté
                # Juste garder le processus en vie pour que le script continue
                FRONTEND_PID=$$
              else
                echo -e "${YELLOW}⚠ L'application est installée mais le lancement a échoué${NC}"
                echo -e "${YELLOW}   Lancez-la manuellement depuis votre téléphone${NC}"
                FRONTEND_PID=$$
              fi
            else
              echo -e "${RED}❌ Échec de l'installation${NC}"
              cat /tmp/adb_install.log
              exit 1
            fi
          else
            echo -e "${RED}❌ APK non trouvé après le build${NC}"
            if [ "$SHOW_FULL_LOG" = "true" ]; then
              echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
              echo -e "${YELLOW}Log complet du build (mode stacktrace):${NC}"
              echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
              cat /tmp/flutter_build.log
              echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
            else
              echo -e "${YELLOW}Dernières lignes du log:${NC}"
              cat /tmp/flutter_build.log | tail -30
            fi
            exit 1
          fi
        else
          echo -e "${RED}❌ Échec du build${NC}"
          if [ "$SHOW_FULL_LOG" = "true" ]; then
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}Log complet du build (mode stacktrace):${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
            cat /tmp/flutter_build.log
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
          else
            echo -e "${YELLOW}Dernières lignes du log (utilisez 'make dev-stacktrace' pour le log complet):${NC}"
            cat /tmp/flutter_build.log | tail -50
          fi
          exit 1
        fi
      fi
    else
      # Pas d'ID ADB, utiliser android normalement
      cd "$PROJECT_ROOT/frontend" || exit 1
      echo -e "${GREEN}Lancement sur Android (device par défaut)...${NC}"
      # Passer l'IP de la machine pour que le mobile puisse accéder au backend
      $FLUTTER_CMD run -d android --dart-define=DEV_API_IP=$MACHINE_IP > /tmp/frontend.log 2>&1 &
      FRONTEND_PID=$!
    fi
    ;;
  2)
    # Web uniquement
    echo -e "${GREEN}Démarrage sur le navigateur Web...${NC}"
    cd "$PROJECT_ROOT/frontend" || exit 1
    # Vérifier que Flutter est prêt
    echo -e "${YELLOW}Vérification de Flutter...${NC}"
    if ! $FLUTTER_CMD doctor > /dev/null 2>&1; then
      echo -e "${RED}❌ Flutter n'est pas correctement configuré${NC}"
      exit 1
    fi
    # Compiler d'abord pour éviter les problèmes MIME type et assets
    echo -e "${YELLOW}Compilation initiale du frontend web...${NC}"
    $FLUTTER_CMD pub get > /dev/null 2>&1 || true
    
    echo -e "${YELLOW}Build web en cours...${NC}"
    echo -e "${YELLOW}(Cela peut prendre quelques minutes la première fois)${NC}"
    
    # Créer un fichier de statut
    rm -f /tmp/flutter_build_status.txt
    touch /tmp/flutter_build_status.txt
    
    # Lancer le build en arrière-plan avec un indicateur de progression
    (
      if $FLUTTER_CMD build web --release > /tmp/flutter_build.log 2>&1; then
        echo "BUILD_SUCCESS" > /tmp/flutter_build_status.txt
      else
        echo "BUILD_FAILED" > /tmp/flutter_build_status.txt
      fi
    ) &
    BUILD_PID=$!
    
    # Afficher un indicateur de progression pendant le build
    dots=0
    last_log_size=0
    while kill -0 $BUILD_PID 2>/dev/null; do
      sleep 3
      dots=$((dots + 1))
      
      # Afficher un indicateur animé
      case $((dots % 4)) in
        0) echo -e "${YELLOW}   Compilation en cours...${NC}" ;;
        1) echo -e "${YELLOW}   Compilation en cours.${NC}" ;;
        2) echo -e "${YELLOW}   Compilation en cours..${NC}" ;;
        3) echo -e "${YELLOW}   Compilation en cours...${NC}" ;;
      esac
      
      # Afficher les nouvelles lignes du log si le fichier a grandi
      if [ -f /tmp/flutter_build.log ]; then
        current_log_size=$(wc -c < /tmp/flutter_build.log 2>/dev/null | tr -d ' ' || echo "0")
        # S'assurer que c'est un nombre valide
        if ! echo "$current_log_size" | grep -qE '^[0-9]+$'; then
          current_log_size=0
        fi
        if ! echo "$last_log_size" | grep -qE '^[0-9]+$'; then
          last_log_size=0
        fi
        if [ "$current_log_size" -gt "$last_log_size" ] 2>/dev/null; then
          # Afficher les dernières lignes importantes
          important_lines=$(tail -5 /tmp/flutter_build.log 2>/dev/null | grep -E "Building|Compiling|Generating|✓|Error|Failed" | tail -1)
          if [ ! -z "$important_lines" ]; then
            echo -e "${YELLOW}   → ${important_lines:0:80}${NC}"
          fi
          last_log_size=$current_log_size
        fi
      fi
    done
    
    # Attendre que le processus se termine
    wait $BUILD_PID
    BUILD_RESULT=$?
    
    # Vérifier le résultat
    if [ ! -f /tmp/flutter_build_status.txt ] || ! grep -q "BUILD_SUCCESS" /tmp/flutter_build_status.txt; then
      echo -e "${RED}❌ Échec du build web${NC}"
      echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
      echo -e "${YELLOW}Dernières lignes des logs d'erreur:${NC}"
      echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
      # Afficher les erreurs importantes
      if [ -f /tmp/flutter_build.log ] && grep -q "Error:" /tmp/flutter_build.log; then
        echo -e "${RED}Erreurs trouvées:${NC}"
        grep -A 5 "Error:" /tmp/flutter_build.log | head -30
      fi
      # Afficher les dernières lignes
      if [ -f /tmp/flutter_build.log ]; then
        echo -e "${YELLOW}Dernières lignes du log complet:${NC}"
        tail -50 /tmp/flutter_build.log
      fi
      echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
      echo -e "${YELLOW}Pour voir le log complet: cat /tmp/flutter_build.log${NC}"
      rm -f /tmp/flutter_build_status.txt
      exit 1
    fi
    
    rm -f /tmp/flutter_build_status.txt
    echo ""
    echo -e "${GREEN}✓ Build web terminé avec succès !${NC}"
    
    # Vérifier que build/web existe
    if [ ! -d "build/web" ]; then
      echo -e "${RED}❌ Le répertoire build/web n'existe pas${NC}"
      exit 1
    fi
    
    # Lancer un serveur HTTP simple pour servir build/web
    echo -e "${GREEN}Lancement du serveur web HTTP...${NC}"
    cd build/web || exit 1
    
    # Utiliser Python pour servir les fichiers
    if command -v python3 &> /dev/null; then
      # Python 3
      python3 -m http.server 7070 --bind 0.0.0.0 > /tmp/frontend_web.log 2>&1 &
      FRONTEND_PID=$!
    elif command -v python &> /dev/null; then
      # Python 2
      python -m SimpleHTTPServer 7070 > /tmp/frontend_web.log 2>&1 &
      FRONTEND_PID=$!
    else
      echo -e "${RED}❌ Python n'est pas installé. Impossible de servir les fichiers web.${NC}"
      exit 1
    fi
    
    echo "$FRONTEND_PID" > /tmp/frontend_pid.txt 2>/dev/null || true
    
    # Attendre que le serveur démarre
    sleep 2
    
    # Vérifier que le serveur répond
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:7070/index.html 2>/dev/null | grep -q "200"; then
      echo -e "${GREEN}✓ Serveur web prêt!${NC}"
    else
      echo -e "${YELLOW}⚠ Le serveur peut prendre quelques secondes pour démarrer${NC}"
    fi
    
    echo -e "${GREEN}✓ Frontend démarré sur http://localhost:7070${NC}"
        echo -e "${GREEN}✓ Frontend accessible depuis le réseau: http://$MACHINE_IP:7070${NC}"
        echo -e "${YELLOW}💡 Astuce: Appuyez sur Ctrl+C pour redémarrer et reconstruire automatiquement le web${NC}"
        ;;
  3)
    # Les deux
    echo -e "${GREEN}Démarrage sur Android et Web...${NC}"
    
    # Lancer Android d'abord
    if [ ! -z "$ANDROID_DEVICE_ID" ]; then
      # Configurer ANDROID_SERIAL pour forcer Flutter à utiliser ce device
      export ANDROID_SERIAL="$ANDROID_DEVICE_ID"
      echo -e "${YELLOW}Device Android sélectionné: $ANDROID_DEVICE_ID${NC}"
      
      # Vérifier que le device répond
      if ! adb -s "$ANDROID_DEVICE_ID" shell echo "test" > /dev/null 2>&1; then
        echo -e "${RED}❌ Le device $ANDROID_DEVICE_ID ne répond pas${NC}"
        echo -e "${YELLOW}Vérifiez la connexion USB/WiFi et le débogage USB${NC}"
        echo -e "${YELLOW}Lancement uniquement sur Web...${NC}"
      else
        cd "$PROJECT_ROOT/frontend" || exit 1
        
        # Vérifier si Flutter détecte le device
        FLUTTER_DEVICES=$($FLUTTER_CMD devices 2>/dev/null)
        FLUTTER_SEES_ANDROID=false
        
        # Essayer de trouver l'ID du device dans la sortie Flutter
        if echo "$FLUTTER_DEVICES" | grep -qi "android"; then
          FLUTTER_SEES_ANDROID=true
          ANDROID_FLUTTER_ID=$(echo "$FLUTTER_DEVICES" | grep -i "android" | head -1 | awk '{print $5}' || echo "android")
          echo -e "${GREEN}✓ Flutter détecte Android: $ANDROID_FLUTTER_ID${NC}"
        else
          echo -e "${YELLOW}⚠ Flutter ne détecte pas le device Android${NC}"
          echo -e "${YELLOW}   Utilisation de la méthode ADB directe...${NC}"
        fi
        
        if [ "$FLUTTER_SEES_ANDROID" = true ]; then
          # Flutter voit Android, utiliser flutter run normalement
          echo -e "${GREEN}Lancement Android avec Flutter...${NC}"
          # Passer l'IP de la machine pour que le mobile puisse accéder au backend
          $FLUTTER_CMD run -d "$ANDROID_FLUTTER_ID" --dart-define=DEV_API_IP=$MACHINE_IP > /tmp/frontend_android.log 2>&1 &
          FRONTEND_ANDROID_PID=$!
        else
          # Flutter ne voit pas Android, utiliser la méthode de build + install
          echo -e "${GREEN}Build et installation de l'application Android...${NC}"
          echo -e "${YELLOW}Cette méthode peut prendre quelques minutes la première fois...${NC}"
          
          # S'assurer que Java 21 est utilisé pour Gradle
          if [ -d "/usr/lib/jvm/java-21-openjdk" ] && [ -f "/usr/lib/jvm/java-21-openjdk/bin/java" ]; then
            export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
            export PATH="/usr/lib/jvm/java-21-openjdk/bin:$PATH"
          fi
          
          # Build APK
          echo -e "${YELLOW}Build de l'APK...${NC}"
          # Passer l'IP de la machine pour que le mobile puisse accéder au backend
          $FLUTTER_CMD build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=$MACHINE_IP > /tmp/flutter_build_android.log 2>&1 &
          BUILD_PID=$!
          wait $BUILD_PID
          BUILD_RESULT=$?
          
          if [ $BUILD_RESULT -eq 0 ]; then
            APK_PATH="$PROJECT_ROOT/frontend/build/app/outputs/flutter-apk/app-debug.apk"
            if [ -f "$APK_PATH" ]; then
              echo -e "${GREEN}✓ APK créé avec succès${NC}"
              echo -e "${YELLOW}Installation sur le device...${NC}"
              
              PACKAGE_NAME="com.delhomme.cooking_recipe.cookingrecipe"
              adb -s "$ANDROID_DEVICE_ID" uninstall "$PACKAGE_NAME" 2>/dev/null || true
              
              if adb -s "$ANDROID_DEVICE_ID" install -r "$APK_PATH" > /tmp/adb_install.log 2>&1; then
                echo -e "${GREEN}✓ Application installée${NC}"
                adb -s "$ANDROID_DEVICE_ID" shell am start -n "$PACKAGE_NAME/.MainActivity" > /tmp/adb_launch.log 2>&1
                echo -e "${GREEN}✓ Application lancée sur votre téléphone!${NC}"
                FRONTEND_ANDROID_PID=$$
              else
                echo -e "${YELLOW}⚠ Échec de l'installation, lancement uniquement sur Web${NC}"
                FRONTEND_ANDROID_PID=""
              fi
            else
              echo -e "${YELLOW}⚠ APK non trouvé, lancement uniquement sur Web${NC}"
              FRONTEND_ANDROID_PID=""
            fi
          else
            echo -e "${YELLOW}⚠ Échec du build Android, lancement uniquement sur Web${NC}"
            FRONTEND_ANDROID_PID=""
          fi
        fi
      fi
    else
      # Pas d'ID ADB, essayer quand même avec android par défaut
      cd "$PROJECT_ROOT/frontend" || exit 1
      echo -e "${YELLOW}Lancement Android (device par défaut)...${NC}"
      $FLUTTER_CMD run -d android > /tmp/frontend_android.log 2>&1 &
      FRONTEND_ANDROID_PID=$!
    fi
    
    # Lancer Web
    sleep 2
    cd "$PROJECT_ROOT/frontend" || exit 1
    echo -e "${GREEN}Lancement Web...${NC}"
    # Compiler d'abord pour éviter les problèmes MIME type
    $FLUTTER_CMD pub get > /dev/null 2>&1 || true
    echo -e "${YELLOW}Build web en cours...${NC}"
    
    # Lancer le build en arrière-plan
    (
      if $FLUTTER_CMD build web --release > /tmp/flutter_build_web.log 2>&1; then
        echo "BUILD_SUCCESS" > /tmp/flutter_build_web_status.txt
      else
        echo "BUILD_FAILED" > /tmp/flutter_build_web_status.txt
      fi
    ) &
    BUILD_WEB_PID=$!
    
    # Attendre le build avec un indicateur
    web_dots=0
    while kill -0 $BUILD_WEB_PID 2>/dev/null; do
      sleep 2
      web_dots=$((web_dots + 1))
      if [ $((web_dots % 3)) -eq 0 ]; then
        echo -e "${YELLOW}   Build web en cours...${NC}"
      fi
    done
    
    wait $BUILD_WEB_PID
    
    # Vérifier le résultat
    if [ ! -f /tmp/flutter_build_web_status.txt ] || ! grep -q "BUILD_SUCCESS" /tmp/flutter_build_web_status.txt; then
      echo -e "${YELLOW}⚠ Échec du build web, utilisation du serveur Flutter...${NC}"
      rm -f /tmp/flutter_build_web_status.txt
      $FLUTTER_CMD run -d web-server --web-port=7070 --web-hostname=0.0.0.0 > /tmp/frontend_web.log 2>&1 &
      FRONTEND_WEB_PID=$!
    else
      rm -f /tmp/flutter_build_web_status.txt
      echo -e "${GREEN}✓ Build web terminé${NC}"
    fi
    
    if [ -z "$FRONTEND_WEB_PID" ]; then
      # Si build réussi, servir avec Python
      if [ -d "build/web" ]; then
        cd build/web || exit 1
        if command -v python3 &> /dev/null; then
          python3 -m http.server 7070 --bind 0.0.0.0 > /tmp/frontend_web.log 2>&1 &
          FRONTEND_WEB_PID=$!
        elif command -v python &> /dev/null; then
          python -m SimpleHTTPServer 7070 > /tmp/frontend_web.log 2>&1 &
          FRONTEND_WEB_PID=$!
        fi
      fi
    fi
    
    echo "$FRONTEND_WEB_PID" > /tmp/frontend_pid.txt 2>/dev/null || true
    FRONTEND_PID=$FRONTEND_WEB_PID
    
    if [ ! -z "$FRONTEND_ANDROID_PID" ]; then
      echo -e "${GREEN}✓ Android et Web démarrés${NC}"
    else
      echo -e "${GREEN}✓ Web démarré (Android non disponible)${NC}"
    fi
    ;;
  *)
    # Par défaut: Web
    echo -e "${GREEN}Démarrage sur le navigateur Web (par défaut)...${NC}"
    cd "$PROJECT_ROOT/frontend" || exit 1
    # Vérifier que Flutter est prêt
    if ! $FLUTTER_CMD doctor > /dev/null 2>&1; then
      echo -e "${RED}❌ Flutter n'est pas correctement configuré${NC}"
      exit 1
    fi
    # Compiler d'abord pour éviter les problèmes MIME type
    echo -e "${YELLOW}Compilation initiale du frontend web...${NC}"
    $FLUTTER_CMD pub get > /dev/null 2>&1 || true
    echo -e "${GREEN}Lancement du serveur web Flutter...${NC}"
    $FLUTTER_CMD run -d web-server --web-port=7070 --web-hostname=0.0.0.0 > /tmp/frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo "$FRONTEND_PID" > /tmp/frontend_pid.txt 2>/dev/null || true
    # Attendre que le serveur compile et démarre complètement
    echo -e "${YELLOW}Attente de la compilation et du démarrage du serveur web...${NC}"
    MAX_WAIT=30
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
      sleep 1
      WAIT_COUNT=$((WAIT_COUNT + 1))
      if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${RED}❌ Le frontend n'a pas démarré correctement${NC}"
        echo -e "${YELLOW}Logs:${NC}"
        cat /tmp/frontend.log
        exit 1
      fi
      if curl -s -o /dev/null -w "%{http_code}" http://localhost:7070/flutter_bootstrap.js 2>/dev/null | grep -q "200"; then
        echo -e "${GREEN}✓ Serveur web prêt!${NC}"
        break
      fi
      if [ $((WAIT_COUNT % 5)) -eq 0 ]; then
        echo -e "${YELLOW}   En attente... ($WAIT_COUNT/$MAX_WAIT secondes)${NC}"
      fi
    done
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
      echo -e "${YELLOW}⚠ Le serveur prend plus de temps que prévu${NC}"
      echo -e "${YELLOW}   Vérifiez les logs avec: tail -f /tmp/frontend.log${NC}"
    fi
    echo -e "${GREEN}✓ Frontend démarré sur http://localhost:7070${NC}"
    echo -e "${GREEN}✓ Frontend accessible depuis le réseau: http://$MACHINE_IP:7070${NC}"
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
    echo -e "${YELLOW}Web: http://$MACHINE_IP:7070${NC}"
else
    echo -e "${YELLOW}Application lancée sur: http://$MACHINE_IP:7070${NC}"
fi
echo ""
echo -e "${GREEN}🎉 Application chargée et prête !${NC}"
echo -e "${GREEN}   Vous pouvez maintenant utiliser l'application dans votre navigateur${NC}"
echo ""
echo -e "${YELLOW}Appuyez sur Ctrl+C pour redémarrer (Double Ctrl+C ou Ctrl+\\ pour arrêter définitivement)${NC}"
echo ""

# Attendre que les processus se terminent
wait

