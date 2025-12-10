.PHONY: help install clean test build dev up down restart logs status backend frontend configure-mobile-api restore-api-url _get-ip run-android run-ios build-android build-ios db-reset db-clear prod-build prod-up prod-down prod-logs prod-restart

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

improve-translations: ## [DEV] Améliore les traductions des recettes (instructions, ingrédients)
	@python3 scripts/improve_translations.py

export-translation-data: ## [DEV] Exporte les données de feedback pour l'entraînement du modèle
	@python3 scripts/export_translation_training_data.py

train-translation-model: ## [BACKEND] Entraîne le modèle de traduction avec les feedbacks utilisateur
	@cd backend && node scripts/train_translation_model.js --export-json

translation-stats: ## [BACKEND] Affiche les statistiques des feedbacks de traduction
	@cd backend && node scripts/train_translation_model.js --stats

update-translation-dict: ## [BACKEND] Met à jour les dictionnaires JSON avec les traductions approuvées
	@cd backend && node scripts/train_translation_model.js --update-dict

retrain-ml: ## [AI] Réentraîne le modèle ML de traduction avec tous les feedbacks
	@echo "🔄 Réentraînement du modèle ML..."
	@curl -X POST http://localhost:7272/api/translation/retrain 2>/dev/null || \
		node -e "const ml = require('./backend/src/services/ml_translation_engine'); ml.retrain().then(() => { console.log('✅ Réentraînement terminé'); process.exit(0); }).catch(e => { console.error('❌ Erreur:', e); process.exit(1); })"

help: ## Affiche cette aide
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo -e "$(GREEN)🍳 Cooking Recipes - Aide des commandes Make$(NC)"
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo -e "$(YELLOW)📦 Installation et Configuration$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[INSTALL\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[INSTALL\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)🚀 Développement$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[DEV\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[DEV\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)🔧 Services Individuels$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[SERVICE\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[SERVICE\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)📱 Build et Déploiement Mobile$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[MOBILE\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[MOBILE\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)🐳 Production Docker$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[PROD\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[PROD\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)🗄️  Base de Données$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[DB\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[DB\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)🧪 Tests$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[TEST\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[TEST\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)💾 Monitoring Mémoire$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[MEMORY\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[MEMORY\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)🤖 Système d'Entraînement IA$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[AI\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[AI\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(YELLOW)🧹 Utilitaires$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## \[UTIL\].*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## \\[UTIL\\] "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

install: ## [INSTALL] Installe les dépendances (backend + frontend)
	@echo -e "$(GREEN)Installation des dépendances...$(NC)"
	@echo -e "$(YELLOW)Installation backend...$(NC)"
	@cd backend && npm install --silent 2>&1 | grep -v "deprecated\|warn" || npm install
	@echo -e "$(YELLOW)Installation frontend...$(NC)"
	@cd frontend && $(FLUTTER) pub get
	@echo -e "$(GREEN)✓ Dépendances installées$(NC)"

dev: _get-ip ## [DEV] Lance tout en mode développement (local)
	@bash scripts/dev.sh

dev-web: _get-ip ## [DEV] Lance uniquement le frontend web (PC) sans détecter les appareils Android
	@FORCE_WEB_ONLY=true bash scripts/dev.sh

dev-stacktrace: _get-ip ## [DEV] Lance en mode développement avec stacktrace détaillée
	@STACKTRACE=true bash scripts/dev.sh

up: dev ## [DEV] Alias pour dev

start: dev ## [DEV] Alias pour dev

down: ## [DEV] Arrête tous les conteneurs et processus
	@echo -e "$(GREEN)Arrêt des services...$(NC)"
	@echo -e "$(YELLOW)Arrêt des processus Node.js...$(NC)"
	@if [ -f /tmp/backend_pid.txt ]; then \
		BACKEND_PID=$$(cat /tmp/backend_pid.txt 2>/dev/null || echo ""); \
		if [ ! -z "$$BACKEND_PID" ] && kill -0 $$BACKEND_PID 2>/dev/null; then \
			kill -9 $$BACKEND_PID 2>/dev/null || true; \
		fi; \
		rm -f /tmp/backend_pid.txt 2>/dev/null || true; \
	fi
	@pkill -9 -f "node.*server.js" 2>/dev/null || true
	@pkill -9 -f "node.*backend" 2>/dev/null || true
	@pkill -9 -f "npm.*dev" 2>/dev/null || true
	@echo -e "$(YELLOW)Arrêt des processus Flutter...$(NC)"
	@if [ -f /tmp/frontend_pid.txt ]; then \
		FRONTEND_PID=$$(cat /tmp/frontend_pid.txt 2>/dev/null || echo ""); \
		if [ ! -z "$$FRONTEND_PID" ] && kill -0 $$FRONTEND_PID 2>/dev/null; then \
			kill -9 $$FRONTEND_PID 2>/dev/null || true; \
		fi; \
		rm -f /tmp/frontend_pid.txt 2>/dev/null || true; \
	fi
	@pkill -9 -f "flutter.*web-server" 2>/dev/null || true
	@pkill -9 -f "flutter.*android" 2>/dev/null || true
	@pkill -9 -f "flutter run" 2>/dev/null || true
	@pkill -9 -f "dart.*web" 2>/dev/null || true
	@echo -e "$(YELLOW)Libération des ports...$(NC)"
	@if command -v lsof >/dev/null 2>&1; then \
		PIDS_7272=$$(lsof -ti:7272 2>/dev/null || echo ""); \
		if [ ! -z "$$PIDS_7272" ]; then \
			echo $$PIDS_7272 | xargs kill -9 2>/dev/null || true; \
		fi; \
		PIDS_7070=$$(lsof -ti:7070 2>/dev/null || echo ""); \
		if [ ! -z "$$PIDS_7070" ]; then \
			echo $$PIDS_7070 | xargs kill -9 2>/dev/null || true; \
		fi; \
	fi
	@echo -e "$(YELLOW)Arrêt des conteneurs Docker...$(NC)"
	@$(DOCKER_COMPOSE) down --remove-orphans 2>/dev/null || true
	@echo -e "$(YELLOW)Nettoyage des fichiers temporaires...$(NC)"
	@rm -f /tmp/backend_pid.txt /tmp/frontend_pid.txt 2>/dev/null || true
	@echo -e "$(GREEN)✓ Tous les services ont été arrêtés$(NC)"

stop: down ## [DEV] Alias pour down

restart: _get-ip ## [DEV] Redémarre tous les services (down puis dev)
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)Redémarrage de l'application$(NC)"
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@$(MAKE) down || true
	@echo ""
	@echo -e "$(GREEN)Attente de 2 secondes avant le redémarrage...$(NC)"
	@sleep 2
	@echo ""
	@echo -e "$(GREEN)Redémarrage des services...$(NC)"
	@bash scripts/dev.sh

memory-report: ## [MEMORY] Génère un rapport mémoire complet
	@bash scripts/memory_monitor.sh report

memory-monitor: ## [MEMORY] Monitoring mémoire en temps réel (Ctrl+C pour arrêter)
	@bash scripts/memory_monitor.sh monitor

memory-leak: ## [MEMORY] Détecte les fuites mémoire (durée: 5 min par défaut)
	@echo -e "$(GREEN)Détection de fuites mémoire...$(NC)"
	@echo -e "$(YELLOW)Durée: 5 minutes (300 secondes)$(NC)"
	@bash scripts/memory_monitor.sh leak 300 10

memory-leak-extended: ## [MEMORY] Détection de fuites mémoire étendue (durée: 15 min)
	@echo -e "$(GREEN)Détection de fuites mémoire étendue...$(NC)"
	@echo -e "$(YELLOW)Durée: 15 minutes (900 secondes)$(NC)"
	@bash scripts/memory_monitor.sh leak 900 15

logs: ## [DEV] Affiche les logs en temps réel (filtrés et optimisés)
	@bash scripts/monitor_logs.sh

status: ## [DEV] Affiche l'état des conteneurs
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
backend-install: ## [SERVICE] Installe les dépendances du backend
	@cd backend && npm install

backend-dev: ## [SERVICE] Lance le backend en mode développement (local)
	@echo -e "$(GREEN)Démarrage du backend sur le port $(BACKEND_PORT)...$(NC)"
	@cd backend && PORT=$(BACKEND_PORT) HOST=0.0.0.0 npm run dev

backend-logs: ## [SERVICE] Affiche les logs du backend
	@$(DOCKER_COMPOSE) logs -f backend

# Frontend
frontend-install: ## [SERVICE] Installe les dépendances du frontend
	@cd frontend && $(FLUTTER) pub get

frontend-dev: _get-ip ## [SERVICE] Lance le frontend en mode développement (local)
	@MACHINE_IP=$$(cat /tmp/machine_ip.txt 2>/dev/null || echo "localhost"); \
	echo -e "$(GREEN)Frontend accessible sur: http://$$MACHINE_IP:$(FRONTEND_PORT)$(NC)"; \
	cd frontend && $(FLUTTER) run -d web-server --web-port=$(FRONTEND_PORT) --web-hostname=0.0.0.0

frontend-build: ## [SERVICE] Build le frontend pour le web
	@cd frontend && $(FLUTTER) build web

frontend-logs: ## [SERVICE] Affiche les logs du frontend
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
configure-mobile-api: _get-ip ## [MOBILE] Configure l'URL de l'API avec l'IP de la machine
	@echo -e "$(GREEN)Configuration de l'URL API pour mobile...$(NC)"
	@MACHINE_IP=$$(cat /tmp/machine_ip.txt 2>/dev/null || echo "localhost"); \
	if [ -f "frontend/lib/services/auth_service.dart" ]; then \
		sed -i "s|static const String _baseUrl = 'http://[^']*';|static const String _baseUrl = 'http://$$MACHINE_IP:$(BACKEND_PORT)/api';|g" frontend/lib/services/auth_service.dart; \
		echo -e "$(GREEN)✓ URL API configurée: http://$$MACHINE_IP:$(BACKEND_PORT)/api$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠ Fichier auth_service.dart non trouvé$(NC)"; \
	fi

# Restaurer l'URL de l'API pour développement local
restore-api-url: ## [MOBILE] Restaure l'URL de l'API à localhost
	@echo -e "$(GREEN)Restauration de l'URL API...$(NC)"
	@if [ -f "frontend/lib/services/auth_service.dart" ]; then \
		sed -i "s|static const String _baseUrl = 'http://[^']*';|static const String _baseUrl = 'http://localhost:$(BACKEND_PORT)/api';|g" frontend/lib/services/auth_service.dart; \
		echo -e "$(GREEN)✓ URL API restaurée: http://localhost:$(BACKEND_PORT)/api$(NC)"; \
	fi

# Build mobile
build-android: configure-mobile-api ## [MOBILE] Build l'application Android (APK) avec IP configurée
	@echo -e "$(GREEN)Build de l'application Android...$(NC)"
	@cd frontend && $(FLUTTER) build apk --release
	@echo -e "$(GREEN)✓ APK créé dans frontend/build/app/outputs/flutter-apk/app-release.apk$(NC)"
	@echo -e "$(YELLOW)Pour installer: adb install frontend/build/app/outputs/flutter-apk/app-release.apk$(NC)"

build-ios: configure-mobile-api ## [MOBILE] Build l'application iOS (nécessite macOS) avec IP configurée
	@cd frontend && $(FLUTTER) build ios --release
	@echo -e "$(GREEN)✓ Build iOS terminé$(NC)"

# Run mobile
run-android: configure-mobile-api ## [MOBILE] Lance l'application sur Android (détecte automatiquement l'appareil)
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

install-android: configure-mobile-api ## [MOBILE] Installe et lance l'APK sur Android (nécessite APK déjà buildé)
	@bash scripts/install_android.sh

logs-android: ## [MOBILE] Affiche les logs de l'application Android (filtre les erreurs système)
	@bash scripts/logs_android.sh $(ARGS)

run-ios: configure-mobile-api ## [MOBILE] Lance l'application sur iOS (détecte automatiquement l'appareil)
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
clean: ## [UTIL] Nettoie les builds et dépendances
	@echo -e "$(GREEN)Nettoyage...$(NC)"
	@cd frontend && $(FLUTTER) clean
	@cd frontend/android && rm -rf .gradle build && cd ../..
	@cd backend && rm -rf node_modules
	@$(DOCKER_COMPOSE) down -v
	@echo -e "$(GREEN)✓ Nettoyage terminé$(NC)"

test: ## [TEST] Lance les tests
	@cd frontend && $(FLUTTER) test
	@cd backend && npm test || echo "Pas de tests configurés"

test-api: ## [TEST] Teste l'API et la récupération de recettes
	@bash scripts/test_api.sh

test-recipes: ## [AI] Test interactif des recettes pour entraîner le modèle de traduction
	@bash scripts/test-recipes.sh $(NUM_RECIPES)

train-translation: ## [AI] Entraîner le modèle de traduction à partir des résultats de test
	@bash scripts/train-translation-model.sh

apply-translations: ## [AI] Appliquer les traductions apprises au code source
	@bash scripts/apply-translations.sh

train-ai: ## [AI] Menu interactif complet pour le système d'entraînement IA
	@bash scripts/ai-training-menu.sh

test-data: ## [DB] Ajoute des données de test (ingrédients dans le placard) - nécessite d'être connecté
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)Ajout de données de test dans le placard$(NC)"
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo -e "$(YELLOW)⚠️  Vous devez être connecté pour ajouter des données de test$(NC)"
	@echo -e "$(YELLOW)⚠️  Récupérez votre token JWT depuis l'application web$(NC)"
	@echo ""
	@read -p "Token JWT (ou appuyez sur Entrée pour utiliser admin@cookingrecipe.com): " token; \
	if [ -z "$$token" ]; then \
		echo -e "$(YELLOW)Connexion avec le compte admin par défaut...$(NC)"; \
		LOGIN_RESPONSE=$$(curl -s -X POST http://localhost:$(BACKEND_PORT)/api/auth/signin \
			-H "Content-Type: application/json" \
			-d '{"email":"admin@cookingrecipe.com","password":"admin123"}'); \
		token=$$(echo $$LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4); \
		if [ -z "$$token" ]; then \
			echo -e "$(RED)❌ Erreur de connexion. Vérifiez que le backend est démarré et que le compte admin existe.$(NC)"; \
			echo -e "$(YELLOW)Astuce: Lancez 'make db-reset' pour créer le compte admin$(NC)"; \
			exit 1; \
		fi; \
		echo -e "$(GREEN)✓ Connexion réussie$(NC)"; \
	fi; \
	echo ""; \
	echo -e "$(YELLOW)Ajout des données de test...$(NC)"; \
	RESPONSE=$$(curl -s -X POST http://localhost:$(BACKEND_PORT)/api/admin/seed-test-data \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $$token"); \
	if echo "$$RESPONSE" | grep -q "Données de test ajoutées"; then \
		INSERTED=$$(echo $$RESPONSE | grep -o '"inserted":[0-9]*' | cut -d':' -f2); \
		TOTAL=$$(echo $$RESPONSE | grep -o '"total":[0-9]*' | cut -d':' -f2); \
		echo -e "$(GREEN)✓ Données de test ajoutées avec succès$(NC)"; \
		echo -e "$(GREEN)✓ $$INSERTED ingrédients ajoutés sur $$TOTAL$(NC)"; \
		echo ""; \
		echo -e "$(YELLOW)Vous pouvez maintenant voir les ingrédients dans votre placard !$(NC)"; \
	else \
		echo -e "$(RED)❌ Erreur lors de l'ajout des données de test$(NC)"; \
		echo "$$RESPONSE"; \
		exit 1; \
	fi

# Gestion de la base de données
db-reset: ## [DB] Réinitialise complètement la base de données (supprime et recrée les tables)
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)Réinitialisation de la base de données$(NC)"
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo -e "$(YELLOW)⚠️  ATTENTION: Cette opération va supprimer toutes les données!$(NC)"
	@read -p "Êtes-vous sûr ? (oui/non): " confirm; \
	if [ "$$confirm" != "oui" ]; then \
		echo -e "$(YELLOW)Opération annulée$(NC)"; \
		exit 0; \
	fi
	@echo ""
	@echo -e "$(YELLOW)Envoi de la requête de réinitialisation...$(NC)"
	@RESPONSE=$$(curl -s -X POST http://localhost:$(BACKEND_PORT)/api/admin/reset-database 2>/dev/null); \
	if [ $$? -eq 0 ]; then \
		echo -e "$(GREEN)✓ Base de données réinitialisée avec succès$(NC)"; \
		echo -e "$(GREEN)✓ Un compte admin par défaut sera créé au prochain démarrage$(NC)"; \
		echo ""; \
		echo -e "$(YELLOW)Identifiants par défaut:$(NC)"; \
		echo -e "  Email: $(YELLOW)admin@cookingrecipe.com$(NC)"; \
		echo -e "  Mot de passe: $(YELLOW)admin123$(NC)"; \
	else \
		echo -e "$(RED)❌ Erreur lors de la réinitialisation$(NC)"; \
		echo -e "$(YELLOW)Vérifiez que le backend est démarré: make dev ou make dev-web$(NC)"; \
		exit 1; \
	fi

db-clear: ## [DB] Vide tous les comptes utilisateurs (garde les tables)
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)Vidage de tous les comptes utilisateurs$(NC)"
	@echo -e "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo -e "$(YELLOW)⚠️  ATTENTION: Cette opération va supprimer tous les comptes!$(NC)"
	@read -p "Êtes-vous sûr ? (oui/non): " confirm; \
	if [ "$$confirm" != "oui" ]; then \
		echo -e "$(YELLOW)Opération annulée$(NC)"; \
		exit 0; \
	fi
	@echo ""
	@echo -e "$(YELLOW)Envoi de la requête de suppression...$(NC)"
	@RESPONSE=$$(curl -s -X POST http://localhost:$(BACKEND_PORT)/api/admin/clear-users 2>/dev/null); \
	if [ $$? -eq 0 ]; then \
		echo -e "$(GREEN)✓ Tous les comptes utilisateurs ont été supprimés$(NC)"; \
		echo -e "$(GREEN)✓ Un compte admin par défaut sera créé au prochain démarrage$(NC)"; \
		echo ""; \
		echo -e "$(YELLOW)Identifiants par défaut:$(NC)"; \
		echo -e "  Email: $(YELLOW)admin@cookingrecipe.com$(NC)"; \
		echo -e "  Mot de passe: $(YELLOW)admin123$(NC)"; \
	else \
		echo -e "$(RED)❌ Erreur lors de la suppression$(NC)"; \
		echo -e "$(YELLOW)Vérifiez que le backend est démarré: make dev ou make dev-web$(NC)"; \
		exit 1; \
	fi

# Production avec Docker
prod-build: ## [PROD] Build les images Docker pour la production
	@echo -e "$(GREEN)Construction des images Docker pour la production...$(NC)"
	@docker-compose -f docker-compose.prod.yml build
	@echo -e "$(GREEN)✓ Images construites$(NC)"

prod-up: ## [PROD] Démarre les conteneurs en production
	@echo -e "$(GREEN)Démarrage des conteneurs en production...$(NC)"
	@if [ ! -f .env.prod ]; then \
		echo -e "$(YELLOW)⚠ Fichier .env.prod non trouvé$(NC)"; \
		echo -e "$(YELLOW)Création depuis .env.prod.example...$(NC)"; \
		cp .env.prod.example .env.prod 2>/dev/null || true; \
		echo -e "$(YELLOW)⚠ Modifiez .env.prod avec vos valeurs avant de continuer!$(NC)"; \
	fi
	@echo -e "$(YELLOW)Vérification du réseau 'web'...$(NC)"
	@if ! docker network ls | grep -q " web "; then \
		echo -e "$(YELLOW)Création du réseau 'web'...$(NC)"; \
		docker network create web 2>/dev/null || echo -e "$(YELLOW)⚠ Réseau 'web' existe déjà ou erreur$(NC)"; \
	fi
	@docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
	@echo -e "$(GREEN)✓ Conteneurs démarrés$(NC)"
	@echo -e "$(YELLOW)Backend: http://localhost:7272/api$(NC)"
	@echo -e "$(YELLOW)Frontend: http://localhost:7070$(NC)"

prod-down: ## [PROD] Arrête les conteneurs en production
	@echo -e "$(GREEN)Arrêt des conteneurs en production...$(NC)"
	@docker-compose -f docker-compose.prod.yml down
	@echo -e "$(GREEN)✓ Conteneurs arrêtés$(NC)"

prod-restart: ## [PROD] Redémarre les conteneurs en production
	@echo -e "$(GREEN)Redémarrage des conteneurs en production...$(NC)"
	@docker-compose -f docker-compose.prod.yml restart
	@echo -e "$(GREEN)✓ Conteneurs redémarrés$(NC)"

prod-logs: ## [PROD] Affiche les logs en production
	@docker-compose -f docker-compose.prod.yml logs -f

prod-status: ## [PROD] Affiche l'état des conteneurs en production
	@echo -e "$(GREEN)État des conteneurs en production:$(NC)"
	@docker-compose -f docker-compose.prod.yml ps

# Docker Hub
DOCKER_HUB_USER=paveldelhomme
API_IMAGE=$(DOCKER_HUB_USER)/cookingrecipes-api:latest
FRONTEND_IMAGE=$(DOCKER_HUB_USER)/cookingrecipes-frontend:latest

docker-build-prod: ## [PROD] Build les images pour production (PRODUCTION_API_URL optionnel)
	@echo -e "$(GREEN)Construction des images Docker pour production...$(NC)"
	@echo -e "$(YELLOW)Build de l'image backend...$(NC)"
	@docker buildx build --load -f backend/Dockerfile.prod -t $(API_IMAGE) ./backend
	@echo -e "$(YELLOW)Build de l'image frontend...$(NC)"
	@if [ -z "$$PRODUCTION_API_URL" ]; then \
		echo -e "$(YELLOW)⚠️  PRODUCTION_API_URL non définie, utilisation de la valeur par défaut$(NC)"; \
		docker buildx build --load -f frontend/Dockerfile.prod --build-arg PRODUCTION_API_URL=https://api.cookingrecipes.delhomme.ovh/api -t $(FRONTEND_IMAGE) ./frontend; \
	else \
		echo -e "$(GREEN)Utilisation de PRODUCTION_API_URL=$$PRODUCTION_API_URL$(NC)"; \
		docker buildx build --load -f frontend/Dockerfile.prod --build-arg PRODUCTION_API_URL=$$PRODUCTION_API_URL -t $(FRONTEND_IMAGE) ./frontend; \
	fi
	@echo -e "$(GREEN)✓ Images construites$(NC)"

docker-tag: docker-build-prod ## [PROD] Tag les images pour Docker Hub (déjà taguées lors du build)
	@echo -e "$(GREEN)✓ Images déjà taguées pour Docker Hub$(NC)"

docker-push: docker-tag ## [PROD] Push les images sur Docker Hub
	@echo -e "$(GREEN)Push des images sur Docker Hub...$(NC)"
	@echo -e "$(YELLOW)Assurez-vous d'être connecté: docker login$(NC)"
	@docker push $(API_IMAGE)
	@docker push $(FRONTEND_IMAGE)
	@echo -e "$(GREEN)✓ Images poussées sur Docker Hub$(NC)"
	@echo -e "$(YELLOW)Images disponibles:$(NC)"
	@echo -e "  - $(API_IMAGE)"
	@echo -e "  - $(FRONTEND_IMAGE)"

docker-build-push: docker-build-prod docker-push ## [PROD] Build et push les images sur Docker Hub

# Déploiement Portainer
deploy-portainer: ## [PROD] Déploie automatiquement sur Portainer
	@echo -e "$(GREEN)Déploiement sur Portainer...$(NC)"
	@if [ ! -f scripts/deploy-portainer.sh ]; then \
		echo -e "$(RED)❌ Script deploy-portainer.sh non trouvé$(NC)"; \
		exit 1; \
	fi
	@chmod +x scripts/deploy-portainer.sh
	@./scripts/deploy-portainer.sh

deploy-full: docker-build-push deploy-portainer ## [PROD] Build, push et déploie sur Portainer

.DEFAULT_GOAL := help

