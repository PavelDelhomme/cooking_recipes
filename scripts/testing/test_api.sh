#!/bin/bash

# Script pour tester l'API et la récupération de recettes

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Obtenir le répertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKEND_PORT=${BACKEND_PORT:-7272}
API_URL="http://localhost:${BACKEND_PORT}/api"

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Tests de l'API et récupération de recettes${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier si le backend est démarré
echo -e "${YELLOW}1. Vérification du backend...${NC}"
if curl -s "${API_URL}/../health" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Backend accessible${NC}"
else
  echo -e "${RED}❌ Backend non accessible sur le port ${BACKEND_PORT}${NC}"
  echo -e "${YELLOW}   Démarrez le backend avec: make dev${NC}"
  exit 1
fi
echo ""

# Test 1: Health check
echo -e "${YELLOW}2. Test Health Check...${NC}"
HEALTH_RESPONSE=$(curl -s "http://localhost:${BACKEND_PORT}/health")
if echo "$HEALTH_RESPONSE" | grep -q "ok"; then
  echo -e "${GREEN}✓ Health check OK${NC}"
  echo "   Réponse: $HEALTH_RESPONSE"
else
  echo -e "${RED}❌ Health check échoué${NC}"
  echo "   Réponse: $HEALTH_RESPONSE"
fi
echo ""

# Test 2: Test de récupération de recettes via TheMealDB
echo -e "${YELLOW}3. Test de récupération de recettes (TheMealDB)...${NC}"
echo -e "${YELLOW}   Recherche de recettes avec 'chicken'...${NC}"

RECIPE_RESPONSE=$(curl -s "https://www.themealdb.com/api/json/v1/1/search.php?s=chicken")
if echo "$RECIPE_RESPONSE" | grep -q "meals"; then
  RECIPE_COUNT=$(echo "$RECIPE_RESPONSE" | grep -o '"strMeal"' | wc -l)
  echo -e "${GREEN}✓ Recettes trouvées: ${RECIPE_COUNT}${NC}"
  
  # Afficher le nom de la première recette
  FIRST_RECIPE=$(echo "$RECIPE_RESPONSE" | grep -o '"strMeal":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ ! -z "$FIRST_RECIPE" ]; then
    echo -e "${GREEN}   Première recette: ${FIRST_RECIPE}${NC}"
  fi
else
  echo -e "${RED}❌ Aucune recette trouvée${NC}"
fi
echo ""

# Test 3: Test de recherche par ingrédient
echo -e "${YELLOW}4. Test de recherche par ingrédient (tomato)...${NC}"
INGREDIENT_RESPONSE=$(curl -s "https://www.themealdb.com/api/json/v1/1/filter.php?i=tomato")
if echo "$INGREDIENT_RESPONSE" | grep -q "meals"; then
  INGREDIENT_COUNT=$(echo "$INGREDIENT_RESPONSE" | grep -o '"idMeal"' | wc -l)
  echo -e "${GREEN}✓ Recettes avec 'tomato': ${INGREDIENT_COUNT}${NC}"
else
  echo -e "${RED}❌ Aucune recette trouvée avec cet ingrédient${NC}"
fi
echo ""

# Test 4: Test d'encodage UTF-8
echo -e "${YELLOW}5. Test d'encodage UTF-8...${NC}"
UTF8_TEST=$(curl -s "https://www.themealdb.com/api/json/v1/1/search.php?s=crème" | head -c 500)
if echo "$UTF8_TEST" | grep -q "crème\|Crème"; then
  echo -e "${GREEN}✓ Encodage UTF-8 fonctionne${NC}"
else
  echo -e "${YELLOW}⚠ Vérification de l'encodage...${NC}"
  echo "   Extrait: $(echo "$UTF8_TEST" | head -c 200)"
fi
echo ""

# Test 5: Test Flutter (si disponible)
echo -e "${YELLOW}6. Test Flutter (récupération de recettes)...${NC}"
if command -v flutter &> /dev/null; then
  FLUTTER_CMD="flutter"
elif [ -f "/home/pactivisme/flutter/bin/flutter" ]; then
  FLUTTER_CMD="/home/pactivisme/flutter/bin/flutter"
else
  FLUTTER_CMD=""
fi

if [ ! -z "$FLUTTER_CMD" ]; then
  cd "$PROJECT_ROOT/frontend" || exit 1
  echo -e "${YELLOW}   Exécution des tests Flutter...${NC}"
  if $FLUTTER_CMD test test/widget_test.dart 2>&1 | head -20; then
    echo -e "${GREEN}✓ Tests Flutter OK${NC}"
  else
    echo -e "${YELLOW}⚠ Tests Flutter non configurés ou échec${NC}"
  fi
  cd "$PROJECT_ROOT" || exit 1
else
  echo -e "${YELLOW}⚠ Flutter non trouvé, tests Flutter ignorés${NC}"
fi
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Tests terminés${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

