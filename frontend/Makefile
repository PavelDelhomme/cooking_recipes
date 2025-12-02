.PHONY: help install clean test web run build analyze format stop down docker-build docker-up docker-down docker-dev docker-logs logs docker-shell restart up

# Variables
CHROME = chrome
DART = dart
FLUTTER = $(HOME)/flutter/bin/flutter
PORT = 7070
DOCKER_COMPOSE = docker-compose

# Couleurs pour les messages
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

help: ## Affiche cette aide
	@echo -e "$(GREEN)Commandes disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

install: ## Installe les dépendances Flutter
	@echo -e "$(GREEN)Installation des dépendances...$(NC)"
	$(FLUTTER) pub get
	@echo -e "$(GREEN)✓ Dépendances installées$(NC)"

clean: ## Nettoie le projet (supprime build/, .dart_tool/, etc.)
	@echo -e "$(GREEN)Nettoyage du projet...$(NC)"
	$(FLUTTER) clean
	$(FLUTTER) pub get
	@echo -e "$(GREEN)✓ Projet nettoyé$(NC)"

web: ## Lance l'application en mode web
	@echo -e "$(GREEN)Build de l'application pour le web...$(NC)"
	@$(FLUTTER) build web
	@echo -e "$(GREEN)✓ Build terminé$(NC)"
	@echo -e "$(GREEN)Serveur web démarré sur http://localhost:$(PORT)$(NC)"
	@echo -e "$(YELLOW)Ouvrez http://localhost:$(PORT) dans votre navigateur$(NC)"
	@echo -e "$(YELLOW)Appuyez sur Ctrl+C pour arrêter le serveur ou utilisez 'make stop'$(NC)"
	@if [ -d "build/web" ]; then \
		cd build/web && \
		if command -v python3 >/dev/null 2>&1; then \
			python3 -m http.server $(PORT); \
		elif command -v python >/dev/null 2>&1; then \
			python -m http.server $(PORT); \
		else \
			echo "$(YELLOW)Python non trouvé. Ouvrez build/web/index.html dans votre navigateur$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)Erreur: build/web n'existe pas$(NC)"; \
		exit 1; \
	fi

start: docker-dev ## Alias pour lancer l'application (Docker avec hot reload)

up: docker-dev ## Alias pour lancer l'application (Docker avec hot reload)

run: docker-dev ## Alias pour lancer l'application (Docker avec hot reload)

dev: docker-dev ## Lance en mode développement avec hot reload (Docker)

install-buildx: ## Installe Docker Buildx manuellement
	@./install-docker-buildx.sh

docker-check-buildx: ## Vérifie et installe Docker Buildx si nécessaire
	@echo -e "$(GREEN)Vérification de Docker Buildx...$(NC)"
	@if ! docker buildx version >/dev/null 2>&1; then \
		echo "$(YELLOW)Docker Buildx n'est pas installé. Installation...$(NC)"; \
		./install-docker-buildx.sh || \
		(mkdir -p ~/.docker/cli-plugins && \
		ARCH=$$(uname -m) && \
		if [ "$$ARCH" = "x86_64" ]; then \
			BUILDX_ARCH="linux-amd64"; \
		elif [ "$$ARCH" = "aarch64" ] || [ "$$ARCH" = "arm64" ]; then \
			BUILDX_ARCH="linux-arm64"; \
		else \
			echo "$(YELLOW)Architecture non supportée: $$ARCH$(NC)"; \
			exit 1; \
		fi && \
		curl -L https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.$$BUILDX_ARCH -o ~/.docker/cli-plugins/docker-buildx && \
		chmod +x ~/.docker/cli-plugins/docker-buildx && \
		docker buildx install && \
		docker buildx create --use --name builder 2>/dev/null || true && \
		echo "$(GREEN)✓ Docker Buildx installé$(NC)"); \
	else \
		echo "$(GREEN)✓ Docker Buildx est déjà installé$(NC)"; \
	fi

docker-build: docker-check-buildx ## Construit l'image Docker
	@echo -e "$(GREEN)Construction de l'image Docker...$(NC)"
	@$(DOCKER_COMPOSE) build
	@echo -e "$(GREEN)✓ Image Docker construite$(NC)"

docker-up: docker-build ## Démarre le conteneur Docker
	@echo -e "$(GREEN)Démarrage du conteneur Docker...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@echo -e "$(GREEN)✓ Conteneur démarré$(NC)"
	@echo -e "$(YELLOW)Application disponible sur http://localhost:$(PORT)$(NC)"
	@echo -e "$(YELLOW)Hot reload activé - Modifiez vos fichiers et ils seront rechargés automatiquement$(NC)"

docker-dev: docker-check-buildx docker-build ## Lance en mode développement avec hot reload (Docker)
	@echo -e "$(GREEN)Lancement en mode développement avec Docker...$(NC)"
	@echo -e "$(YELLOW)Hot reload activé - Les modifications dans lib/ seront rechargées automatiquement$(NC)"
	@echo -e "$(YELLOW)Application disponible sur http://localhost:$(PORT)$(NC)"
	@echo -e "$(YELLOW)Logs en direct - Appuyez sur Ctrl+C pour arrêter proprement$(NC)"
	@echo ""
	@bash -c 'trap "echo \"\"; echo \"$(GREEN)Arrêt des conteneurs...$(NC)\"; $(DOCKER_COMPOSE) down --remove-orphans; exit 0" INT TERM; $(DOCKER_COMPOSE) up --remove-orphans' || \
	(echo ""; echo "$(YELLOW)Arrêt des conteneurs...$(NC)"; $(DOCKER_COMPOSE) down --remove-orphans; exit 0)

docker-down: ## Arrête le conteneur Docker
	@echo -e "$(GREEN)Arrêt du conteneur Docker...$(NC)"
	@$(DOCKER_COMPOSE) down --remove-orphans
	@echo -e "$(GREEN)✓ Conteneur arrêté$(NC)"

docker-status: ## Affiche l'état des conteneurs Docker du projet
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)État des conteneurs Flutter Cooking Recipe$(NC)"
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@if docker ps --filter "name=flutter_cooking_recipe" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q flutter_cooking_recipe; then \
		echo -e "$(GREEN)Conteneurs en cours d'exécution:$(NC)"; \
		docker ps --filter "name=flutter_cooking_recipe" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"; \
		echo ""; \
		echo -e "$(GREEN)✓ Application disponible sur http://localhost:$(PORT)$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠ Aucun conteneur en cours d'exécution$(NC)"; \
		if docker ps -a --filter "name=flutter_cooking_recipe" --format "table {{.Names}}\t{{.Status}}" | grep -q flutter_cooking_recipe; then \
			echo ""; \
			echo -e "$(YELLOW)Conteneurs arrêtés:$(NC)"; \
			docker ps -a --filter "name=flutter_cooking_recipe" --format "table {{.Names}}\t{{.Status}}"; \
			echo ""; \
			echo -e "$(YELLOW)Pour démarrer: make dev$(NC)"; \
		else \
			echo ""; \
			echo -e "$(YELLOW)Aucun conteneur trouvé pour ce projet$(NC)"; \
			echo -e "$(YELLOW)Pour démarrer: make dev$(NC)"; \
		fi; \
	fi
	@echo ""

docker-logs: ## Affiche les logs du conteneur Docker
	@echo -e "$(GREEN)Affichage des logs Docker...$(NC)"
	@echo -e "$(YELLOW)Appuyez sur Ctrl+C pour quitter$(NC)"
	@echo ""
	@$(DOCKER_COMPOSE) logs -f

logs: docker-logs ## Alias pour afficher les logs Docker

docker-shell: ## Ouvre un shell dans le conteneur Docker
	@$(DOCKER_COMPOSE) exec flutter-web /bin/bash

docker-restart: docker-down docker-up ## Redémarre le conteneur Docker

restart: stop docker-dev ## Arrête et relance l'application en mode développement

test: ## Lance les tests unitaires
	@echo -e "$(GREEN)Lancement des tests...$(NC)"
	$(FLUTTER) test
	@echo -e "$(GREEN)✓ Tests terminés$(NC)"

test-watch: ## Lance les tests en mode watch
	@echo -e "$(GREEN)Lancement des tests en mode watch...$(NC)"
	$(FLUTTER) test --watch

analyze: ## Analyse le code pour détecter les problèmes
	@echo -e "$(GREEN)Analyse du code...$(NC)"
	$(FLUTTER) analyze
	@echo -e "$(GREEN)✓ Analyse terminée$(NC)"

format: ## Formate le code Dart
	@echo -e "$(GREEN)Formatage du code...$(NC)"
	$(FLUTTER) format lib/
	@echo -e "$(GREEN)✓ Code formaté$(NC)"

format-check: ## Vérifie le formatage du code sans le modifier
	@echo -e "$(GREEN)Vérification du formatage...$(NC)"
	$(FLUTTER) format --set-exit-if-changed lib/
	@echo -e "$(GREEN)✓ Formatage correct$(NC)"

build-web: ## Build l'application pour le web
	@echo -e "$(GREEN)Build de l'application pour le web...$(NC)"
	$(FLUTTER) build web
	@echo -e "$(GREEN)✓ Build terminé dans build/web/$(NC)"

build-apk: ## Build l'application Android (APK)
	@echo -e "$(GREEN)Build de l'application Android...$(NC)"
	$(FLUTTER) build apk
	@echo -e "$(GREEN)✓ APK créé dans build/app/outputs/flutter-apk/$(NC)"

build-apk-release: ## Build l'application Android (APK Release)
	@echo -e "$(GREEN)Build de l'application Android (Release)...$(NC)"
	$(FLUTTER) build apk --release
	@echo -e "$(GREEN)✓ APK Release créé dans build/app/outputs/flutter-apk/$(NC)"

build-appbundle: ## Build l'application Android (App Bundle)
	@echo -e "$(GREEN)Build de l'application Android (App Bundle)...$(NC)"
	$(FLUTTER) build appbundle
	@echo -e "$(GREEN)✓ App Bundle créé$(NC)"

build-ios: ## Build l'application iOS (nécessite macOS et Xcode)
	@echo -e "$(GREEN)Build de l'application iOS...$(NC)"
	$(FLUTTER) build ios
	@echo -e "$(GREEN)✓ Build iOS terminé$(NC)"

build-ios-release: ## Build l'application iOS en mode Release
	@echo -e "$(GREEN)Build de l'application iOS (Release)...$(NC)"
	$(FLUTTER) build ios --release
	@echo -e "$(GREEN)✓ Build iOS Release terminé$(NC)"

run-android: ## Lance l'application sur un appareil/émulateur Android
	@echo -e "$(GREEN)Lancement sur Android...$(NC)"
	$(FLUTTER) run -d android

run-ios: ## Lance l'application sur un appareil/simulateur iOS (nécessite macOS)
	@echo -e "$(GREEN)Lancement sur iOS...$(NC)"
	$(FLUTTER) run -d ios

doctor: ## Vérifie la configuration Flutter
	@echo -e "$(GREEN)Vérification de la configuration Flutter...$(NC)"
	$(FLUTTER) doctor -v

devices: ## Liste les appareils disponibles
	@echo -e "$(GREEN)Appareils disponibles:$(NC)"
	$(FLUTTER) devices

upgrade: ## Met à jour Flutter et les dépendances
	@echo -e "$(GREEN)Mise à jour de Flutter...$(NC)"
	$(FLUTTER) upgrade
	@echo -e "$(GREEN)Mise à jour des dépendances...$(NC)"
	$(FLUTTER) pub upgrade
	@echo -e "$(GREEN)✓ Mise à jour terminée$(NC)"

check: ## Vérifie que tout est OK (format, analyse, tests)
	@echo -e "$(GREEN)Vérification complète du projet...$(NC)"
	@make format-check
	@make analyze
	@make test
	@echo -e "$(GREEN)✓ Toutes les vérifications sont passées$(NC)"

serve: build-web ## Build et sert l'application web localement
	@echo -e "$(GREEN)Servir l'application web sur http://localhost:$(PORT)$(NC)"
	@cd build/web && python3 -m http.server $(PORT) || python -m http.server $(PORT)

stop: ## Arrête le serveur (Docker ou local)
	@echo -e "$(GREEN)Arrêt du serveur...$(NC)"
	@$(DOCKER_COMPOSE) down --remove-orphans 2>/dev/null || true
	@if lsof -ti:$(PORT) >/dev/null 2>&1; then \
		kill -9 $$(lsof -ti:$(PORT)) 2>/dev/null && echo "$(GREEN)✓ Serveur local arrêté$(NC)" || true; \
	fi
	@echo -e "$(GREEN)✓ Serveur arrêté$(NC)"

down: docker-down ## Alias pour arrêter le serveur

status: docker-status ## Affiche l'état des conteneurs Docker

all: clean install check ## Nettoie, installe et vérifie tout

.DEFAULT_GOAL := help

