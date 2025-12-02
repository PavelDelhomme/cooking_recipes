.PHONY: help install clean test build dev up down restart logs status backend frontend configure-mobile-api restore-api-url _get-ip run-android run-ios build-android build-ios

# Variables
# Détecter Flutter automatiquement
_FLUTTER_PATH = $(shell which flutter 2>/dev/null)
ifeq ($(_FLUTTER_PATH),)
  ifeq ($(shell test -f /home/pactivisme/flutter/bin/flutter && echo "ok"),ok)
    _FLUTTER_PATH = /home/pactivisme/flutter/bin/flutter
  else ifeq ($(shell test -f /opt/flutter/bin/flutter && echo "ok"),ok)
    _FLUTTER_PATH = /opt/flutter/bin/flutter
  else
    _FLUTTER_PATH = flutter
  endif
endif
FLUTTER = $(_FLUTTER_PATH)
DOCKER_COMPOSE = docker-compose
BACKEND_PORT = 7272
FRONTEND_PORT = 7070

# Couleurs
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m

help: ## Affiche cette aide
	@echo -e "$(GREEN)Commandes disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

install: ## Installe les dépendances (backend + frontend)
	@echo -e "$(GREEN)Installation des dépendances...$(NC)"
	@echo -e "$(YELLOW)Installation backend...$(NC)"
	@cd backend && npm install --silent 2>&1 | grep -v "deprecated\|warn" || npm install
	@echo -e "$(YELLOW)Installation frontend...$(NC)"
	@cd frontend && $(FLUTTER) pub get
	@echo -e "$(GREEN)✓ Dépendances installées$(NC)"

dev: _get-ip ## Lance tout en mode développement (local)
	@bash scripts/dev.sh

dev-stacktrace: _get-ip ## Lance en mode développement avec stacktrace détaillée
	@STACKTRACE=true bash scripts/dev.sh

up: dev ## Alias pour dev

start: dev ## Alias pour dev

down: ## Arrête tous les conteneurs et processus
	@echo -e "$(GREEN)Arrêt des services...$(NC)"
	@if [ -f /tmp/backend_pid.txt ]; then \
		kill $$(cat /tmp/backend_pid.txt) 2>/dev/null || true; \
		rm /tmp/backend_pid.txt; \
	fi; \
	if [ -f /tmp/frontend_pid.txt ]; then \
		kill $$(cat /tmp/frontend_pid.txt) 2>/dev/null || true; \
		rm /tmp/frontend_pid.txt; \
	fi; \
	$(DOCKER_COMPOSE) down 2>/dev/null || true; \
	echo -e "$(GREEN)✓ Services arrêtés$(NC)"

stop: down ## Alias pour down

restart: down dev ## Redémarre tous les conteneurs

logs: ## Affiche les logs en temps réel
	@$(DOCKER_COMPOSE) logs -f

status: ## Affiche l'état des conteneurs
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)État des conteneurs Cooking Recipes$(NC)"
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@if docker ps --filter "name=cooking_recipes" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q cooking_recipes; then \
		echo -e "$(GREEN)Conteneurs en cours d'exécution:$(NC)"; \
		docker ps --filter "name=cooking_recipes" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"; \
		echo ""; \
		echo -e "$(GREEN)✓ Backend disponible sur http://localhost:$(BACKEND_PORT)$(NC)"; \
		echo -e "$(GREEN)✓ Frontend disponible sur http://localhost:$(FRONTEND_PORT)$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠ Aucun conteneur en cours d'exécution$(NC)"; \
		echo -e "$(YELLOW)Pour démarrer: make dev$(NC)"; \
	fi
	@echo ""

# Backend
backend-install: ## Installe les dépendances du backend
	@cd backend && npm install

backend-dev: ## Lance le backend en mode développement (local)
	@echo -e "$(GREEN)Démarrage du backend sur le port $(BACKEND_PORT)...$(NC)"
	@cd backend && PORT=$(BACKEND_PORT) HOST=0.0.0.0 npm run dev

backend-logs: ## Affiche les logs du backend
	@$(DOCKER_COMPOSE) logs -f backend

# Frontend
frontend-install: ## Installe les dépendances du frontend
	@cd frontend && $(FLUTTER) pub get

frontend-dev: _get-ip ## Lance le frontend en mode développement (local)
	@MACHINE_IP=$$(cat /tmp/machine_ip.txt 2>/dev/null || echo "localhost"); \
	echo -e "$(GREEN)Frontend accessible sur: http://$$MACHINE_IP:$(FRONTEND_PORT)$(NC)"; \
	cd frontend && $(FLUTTER) run -d web-server --web-port=$(FRONTEND_PORT) --web-hostname=0.0.0.0

frontend-build: ## Build le frontend pour le web
	@cd frontend && $(FLUTTER) build web

frontend-logs: ## Affiche les logs du frontend
	@$(DOCKER_COMPOSE) logs -f frontend

# Détecter l'IP de la machine
_get-ip:
	@echo -e "$(GREEN)Détection de l'IP de la machine...$(NC)"
	@MACHINE_IP=$$(hostname -I 2>/dev/null | awk '{print $$1}' | head -1); \
	if [ -z "$$MACHINE_IP" ] || [ "$$MACHINE_IP" = "" ]; then \
		MACHINE_IP=$$(ip route get 1.1.1.1 2>/dev/null | awk -F'src ' '{print $$2}' | awk '{print $$1}' | head -1); \
	fi; \
	if [ -z "$$MACHINE_IP" ] || [ "$$MACHINE_IP" = "" ]; then \
		MACHINE_IP=$$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $$2}' | cut -d/ -f1); \
	fi; \
	if [ -z "$$MACHINE_IP" ] || [ "$$MACHINE_IP" = "" ]; then \
		echo -e "$(YELLOW)⚠ Impossible de détecter l'IP, utilisation de localhost$(NC)"; \
		MACHINE_IP="localhost"; \
	fi; \
	echo "$$MACHINE_IP" > /tmp/machine_ip.txt; \
	echo -e "$(GREEN)✓ IP détectée: $$MACHINE_IP$(NC)"

# Configurer l'URL de l'API pour mobile
configure-mobile-api: _get-ip ## Configure l'URL de l'API avec l'IP de la machine
	@echo -e "$(GREEN)Configuration de l'URL API pour mobile...$(NC)"
	@MACHINE_IP=$$(cat /tmp/machine_ip.txt 2>/dev/null || echo "localhost"); \
	if [ -f "frontend/lib/services/auth_service.dart" ]; then \
		sed -i "s|static const String _baseUrl = 'http://[^']*';|static const String _baseUrl = 'http://$$MACHINE_IP:$(BACKEND_PORT)/api';|g" frontend/lib/services/auth_service.dart; \
		echo -e "$(GREEN)✓ URL API configurée: http://$$MACHINE_IP:$(BACKEND_PORT)/api$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠ Fichier auth_service.dart non trouvé$(NC)"; \
	fi

# Restaurer l'URL de l'API pour développement local
restore-api-url: ## Restaure l'URL de l'API à localhost
	@echo -e "$(GREEN)Restauration de l'URL API...$(NC)"
	@if [ -f "frontend/lib/services/auth_service.dart" ]; then \
		sed -i "s|static const String _baseUrl = 'http://[^']*';|static const String _baseUrl = 'http://localhost:$(BACKEND_PORT)/api';|g" frontend/lib/services/auth_service.dart; \
		echo -e "$(GREEN)✓ URL API restaurée: http://localhost:$(BACKEND_PORT)/api$(NC)"; \
	fi

# Build mobile
build-android: configure-mobile-api ## Build l'application Android (APK) avec IP configurée
	@echo -e "$(GREEN)Build de l'application Android...$(NC)"
	@cd frontend && $(FLUTTER) build apk --release
	@echo -e "$(GREEN)✓ APK créé dans frontend/build/app/outputs/flutter-apk/app-release.apk$(NC)"
	@echo -e "$(YELLOW)Pour installer: adb install frontend/build/app/outputs/flutter-apk/app-release.apk$(NC)"

build-ios: configure-mobile-api ## Build l'application iOS (nécessite macOS) avec IP configurée
	@cd frontend && $(FLUTTER) build ios --release
	@echo -e "$(GREEN)✓ Build iOS terminé$(NC)"

# Run mobile
run-android: configure-mobile-api ## Lance l'application sur Android (détecte automatiquement l'appareil)
	@echo -e "$(GREEN)Recherche d'appareils Android...$(NC)"
	@cd frontend && \
	DEVICE_ID=$$($(FLUTTER) devices | grep -E "android|chrome" | head -1 | awk '{print $$5}' || echo ""); \
	if [ -z "$$DEVICE_ID" ]; then \
		echo -e "$(YELLOW)⚠ Aucun appareil Android détecté$(NC)"; \
		echo -e "$(YELLOW)Connectez un appareil ou lancez un émulateur$(NC)"; \
		$(FLUTTER) devices; \
		exit 1; \
	fi; \
	echo -e "$(GREEN)Lancement sur Android ($$DEVICE_ID)...$(NC)"; \
	$(FLUTTER) run -d android

run-ios: configure-mobile-api ## Lance l'application sur iOS (détecte automatiquement l'appareil)
	@echo -e "$(GREEN)Recherche d'appareils iOS...$(NC)"
	@cd frontend && \
	DEVICE_ID=$$($(FLUTTER) devices | grep -E "ios|iPhone|iPad" | head -1 | awk '{print $$5}' || echo ""); \
	if [ -z "$$DEVICE_ID" ]; then \
		echo -e "$(YELLOW)⚠ Aucun appareil iOS détecté$(NC)"; \
		echo -e "$(YELLOW)Connectez un appareil ou lancez un simulateur$(NC)"; \
		$(FLUTTER) devices; \
		exit 1; \
	fi; \
	echo -e "$(GREEN)Lancement sur iOS ($$DEVICE_ID)...$(NC)"; \
	$(FLUTTER) run -d ios

# Utilitaires
clean: ## Nettoie les builds et dépendances
	@echo -e "$(GREEN)Nettoyage...$(NC)"
	@cd frontend && $(FLUTTER) clean
	@cd frontend/android && rm -rf .gradle build && cd ../..
	@cd backend && rm -rf node_modules
	@$(DOCKER_COMPOSE) down -v
	@echo -e "$(GREEN)✓ Nettoyage terminé$(NC)"

test: ## Lance les tests
	@cd frontend && $(FLUTTER) test
	@cd backend && npm test || echo "Pas de tests configurés"

.DEFAULT_GOAL := help

