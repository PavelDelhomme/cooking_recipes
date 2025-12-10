#!/bin/bash

# Script pour installer et configurer LibreTranslate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 Installation de LibreTranslate${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker n'est pas installé${NC}"
    echo -e "${YELLOW}Veuillez installer Docker: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker détecté${NC}"

# Vérifier Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose n'est pas installé${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker Compose détecté${NC}"
echo ""

# Vérifier si LibreTranslate est déjà en cours d'exécution
if docker ps | grep -q libretranslate; then
    echo -e "${YELLOW}⚠️  LibreTranslate est déjà en cours d'exécution${NC}"
    echo -e "${BLUE}Voulez-vous le redémarrer ? (o/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([oO][uU][iI]|[oO])$ ]]; then
        echo -e "${YELLOW}Arrêt de LibreTranslate...${NC}"
        docker stop libretranslate 2>/dev/null || true
        docker rm libretranslate 2>/dev/null || true
    else
        echo -e "${GREEN}LibreTranslate est déjà démarré${NC}"
        exit 0
    fi
fi

# Démarrer LibreTranslate
echo -e "${YELLOW}📦 Démarrage de LibreTranslate...${NC}"
cd "$PROJECT_ROOT"

# Utiliser docker-compose ou docker compose selon ce qui est disponible
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

if $COMPOSE_CMD -f docker-compose.libretranslate.yml up -d; then
    echo -e "${GREEN}✓ LibreTranslate démarré${NC}"
    echo ""
    echo -e "${YELLOW}⏳ Attente du démarrage complet (peut prendre 1-2 minutes)...${NC}"
    echo -e "${BLUE}   (Les modèles de traduction sont téléchargés au premier démarrage)${NC}"
    echo ""
    
    # Attendre que le service soit prêt
    MAX_WAIT=180
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if curl -s http://localhost:7071/languages > /dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}✓ LibreTranslate est prêt !${NC}"
            echo ""
            echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}✅ LibreTranslate installé et démarré${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${YELLOW}📡 URL: http://localhost:7071${NC}"
            echo -e "${YELLOW}📚 Documentation: https://libretranslate.com/${NC}"
            echo ""
            echo -e "${GREEN}💡 Configuration:${NC}"
            echo -e "   - Langues: en, fr, es"
            echo -e "   - Port: 7071"
            echo -e "   - Le backend utilisera automatiquement ce service"
            echo ""
            
            # Tester la traduction
            echo -e "${BLUE}🧪 Test de traduction...${NC}"
            if curl -s -X POST http://localhost:7071/translate \
                -H "Content-Type: application/json" \
                -d '{"q":"Hello world","source":"en","target":"fr","format":"text"}' \
                | grep -q "Bonjour"; then
                echo -e "${GREEN}✓ Test de traduction réussi !${NC}"
            else
                echo -e "${YELLOW}⚠️  Test de traduction non concluant (peut être normal au premier démarrage)${NC}"
            fi
            echo ""
            
            exit 0
        fi
        
        # Afficher un point toutes les 10 secondes
        if [ $((WAIT_COUNT % 10)) -eq 0 ] && [ $WAIT_COUNT -gt 0 ]; then
            echo -e "${YELLOW}   En attente... (${WAIT_COUNT}s/${MAX_WAIT}s)${NC}"
        fi
        
        sleep 2
        WAIT_COUNT=$((WAIT_COUNT + 2))
    done
    
    echo ""
    echo -e "${YELLOW}⚠️  LibreTranslate prend plus de temps que prévu${NC}"
    echo -e "${YELLOW}   Vérifiez les logs: docker logs libretranslate${NC}"
    echo -e "${YELLOW}   Ou: $COMPOSE_CMD -f docker-compose.libretranslate.yml logs${NC}"
    echo ""
    echo -e "${BLUE}💡 Conseil: Au premier démarrage, les modèles peuvent prendre plusieurs minutes à télécharger${NC}"
    exit 1
else
    echo -e "${RED}❌ Erreur lors du démarrage de LibreTranslate${NC}"
    echo -e "${YELLOW}Vérifiez les logs: docker logs libretranslate${NC}"
    exit 1
fi
