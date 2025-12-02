#!/bin/bash
# Script d'installation de Docker Buildx

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installation de Docker Buildx...${NC}"

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker n'est pas installé. Veuillez installer Docker d'abord.${NC}"
    exit 1
fi

# Vérifier si Buildx est déjà installé
if docker buildx version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Buildx est déjà installé${NC}"
    docker buildx version
    exit 0
fi

# Créer le répertoire pour les plugins Docker
mkdir -p ~/.docker/cli-plugins

# Détecter l'architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        BUILDX_ARCH="linux-amd64"
        ;;
    aarch64|arm64)
        BUILDX_ARCH="linux-arm64"
        ;;
    *)
        echo -e "${YELLOW}Architecture non supportée: $ARCH${NC}"
        exit 1
        ;;
esac

# Télécharger Buildx
BUILDX_VERSION="v0.12.1"
BUILDX_URL="https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.${BUILDX_ARCH}"

echo -e "${GREEN}Téléchargement de Docker Buildx...${NC}"
curl -L "${BUILDX_URL}" -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

# Installer Buildx
echo -e "${GREEN}Installation de Docker Buildx...${NC}"
docker buildx install

# Créer un builder par défaut
echo -e "${GREEN}Création du builder par défaut...${NC}"
docker buildx create --use --name builder 2>/dev/null || docker buildx use builder 2>/dev/null || true

# Vérifier l'installation
if docker buildx version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Buildx installé avec succès !${NC}"
    docker buildx version
else
    echo -e "${YELLOW}⚠ Installation terminée, mais la vérification a échoué.${NC}"
    echo -e "${YELLOW}Essayez de redémarrer Docker ou votre session.${NC}"
fi

