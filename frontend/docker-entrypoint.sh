#!/bin/bash
set -e

echo "🚀 Démarrage de Flutter Web avec hot reload..."

# Installer les dépendances
echo "📦 Installation des dépendances..."
flutter pub get

# Fonction pour surveiller et rebuild
watch_and_rebuild() {
    echo "👀 Surveillance des fichiers dans lib/..."
    echo "✨ Modifiez vos fichiers dans lib/ et ils seront recompilés automatiquement"
    echo ""
    
    while true; do
        # Surveiller les changements dans lib/
        if command -v inotifywait >/dev/null 2>&1; then
            inotifywait -r -e modify,create,delete,move lib/ 2>/dev/null && {
                echo "🔄 Changement détecté, recompilation en cours..."
                flutter build web --release 2>&1 | grep -E "(Built|Error)" || true
                echo "✅ Recompilation terminée - Rechargez la page dans votre navigateur"
            }
        else
            # Fallback: vérifier les timestamps toutes les 2 secondes
            sleep 2
            find lib/ -type f -newer /tmp/last_check 2>/dev/null && {
                touch /tmp/last_check
                echo "🔄 Changement détecté, recompilation en cours..."
                flutter build web --release 2>&1 | grep -E "(Built|Error)" || true
                echo "✅ Recompilation terminée - Rechargez la page dans votre navigateur"
            }
        fi
    done
}

# Initialiser le timestamp
touch /tmp/last_check

# Lancer la surveillance en arrière-plan
watch_and_rebuild &
WATCH_PID=$!

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt du serveur..."
    kill $WATCH_PID 2>/dev/null || true
    exit 0
}

trap cleanup INT TERM

# Build initial
echo "🔨 Build initial..."
flutter build web --release

# Lancer le serveur HTTP simple
echo "🔥 Serveur de développement démarré..."
echo "📱 Application disponible sur http://localhost:8080 (interne) ou http://localhost:7070 (externe)"
echo "✨ Hot reload activé - Modifiez vos fichiers dans lib/ et rechargez la page"
echo ""

# Servir les fichiers avec Python
cd build/web
exec python3 -m http.server 8080 --bind 0.0.0.0
