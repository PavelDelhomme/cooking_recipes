#!/bin/bash
# Script pour déployer automatiquement sur Portainer
# Usage: ./scripts/deploy-portainer.sh

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PORTAINER_URL="${PORTAINER_URL:-http://localhost:9000}"
PORTAINER_USERNAME="${PORTAINER_USERNAME:-admin}"
PORTAINER_PASSWORD="${PORTAINER_PASSWORD:-}"
STACK_NAME="${STACK_NAME:-cooking-recipes}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

echo -e "${GREEN}🚀 Déploiement automatique sur Portainer${NC}"
echo ""

# Vérifier les prérequis
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq n'est pas installé. Installez-le: sudo apt install jq${NC}"
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Fichier $COMPOSE_FILE non trouvé${NC}"
    exit 1
fi

# Demander le mot de passe si non fourni
if [ -z "$PORTAINER_PASSWORD" ]; then
    read -sp "Mot de passe Portainer: " PORTAINER_PASSWORD
    echo ""
fi

# Authentification
echo -e "${YELLOW}🔐 Authentification...${NC}"
AUTH_RESPONSE=$(curl -s -X POST "$PORTAINER_URL/api/auth" \
    -H "Content-Type: application/json" \
    -d "{\"Username\":\"$PORTAINER_USERNAME\",\"Password\":\"$PORTAINER_PASSWORD\"}")

JWT=$(echo $AUTH_RESPONSE | jq -r '.jwt')

if [ "$JWT" == "null" ] || [ -z "$JWT" ]; then
    echo -e "${RED}❌ Erreur d'authentification${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authentifié${NC}"

# Obtenir l'endpoint ID
echo -e "${YELLOW}📡 Récupération de l'endpoint...${NC}"
ENDPOINTS=$(curl -s -X GET "$PORTAINER_URL/api/endpoints" \
    -H "Authorization: Bearer $JWT")

ENDPOINT_ID=$(echo $ENDPOINTS | jq -r '.[0].Id')

if [ -z "$ENDPOINT_ID" ] || [ "$ENDPOINT_ID" == "null" ]; then
    echo -e "${RED}❌ Aucun endpoint trouvé${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Endpoint ID: $ENDPOINT_ID${NC}"

# Vérifier si la stack existe
echo -e "${YELLOW}🔍 Vérification de la stack...${NC}"
STACKS=$(curl -s -X GET \
    "$PORTAINER_URL/api/stacks?filters={\"EndpointID\":$ENDPOINT_ID}" \
    -H "Authorization: Bearer $JWT")

STACK_ID=$(echo $STACKS | jq -r ".[] | select(.Name==\"$STACK_NAME\") | .Id")

# Lire le fichier compose
COMPOSE_CONTENT=$(cat "$COMPOSE_FILE" | jq -Rs .)

# Variables d'environnement
ENV_VARS="[]"
if [ -f .env.prod ]; then
    ENV_VARS=$(cat .env.prod | grep -v '^#' | grep -v '^$' | while IFS='=' read -r key value; do
        if [ -n "$key" ]; then
            echo "{\"name\":\"$key\",\"value\":\"$value\"}"
        fi
    done | jq -s '.')
fi

if [ -n "$STACK_ID" ] && [ "$STACK_ID" != "null" ]; then
    # Mettre à jour la stack existante
    echo -e "${YELLOW}🔄 Mise à jour de la stack existante...${NC}"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
        "$PORTAINER_URL/api/stacks/$STACK_ID?endpointId=$ENDPOINT_ID" \
        -H "Authorization: Bearer $JWT" \
        -H "Content-Type: application/json" \
        -d "{
            \"StackFileContent\": $COMPOSE_CONTENT,
            \"Prune\": true,
            \"PullImage\": true
        }")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✅ Stack mise à jour avec succès${NC}"
    else
        echo -e "${RED}❌ Erreur lors de la mise à jour (HTTP $HTTP_CODE)${NC}"
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
        exit 1
    fi
else
    # Créer une nouvelle stack
    echo -e "${YELLOW}🆕 Création d'une nouvelle stack...${NC}"
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        "$PORTAINER_URL/api/stacks?endpointId=$ENDPOINT_ID&method=compose" \
        -H "Authorization: Bearer $JWT" \
        -H "Content-Type: application/json" \
        -d "{
            \"Name\": \"$STACK_NAME\",
            \"StackFileContent\": $COMPOSE_CONTENT,
            \"Env\": $ENV_VARS
        }")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
        echo -e "${GREEN}✅ Stack créée avec succès${NC}"
    else
        echo -e "${RED}❌ Erreur lors de la création (HTTP $HTTP_CODE)${NC}"
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}🎉 Déploiement terminé!${NC}"
echo -e "${YELLOW}Vérifiez dans Portainer: Stacks → $STACK_NAME${NC}"

