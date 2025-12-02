# Docker - Flutter Web avec Hot Reload

## Installation

1. Assurez-vous d'avoir Docker et Docker Compose installés :
```bash
docker --version
docker-compose --version
```

## Utilisation

### Lancer l'application avec hot reload
```bash
make dev
# ou
make docker-dev
# ou
make start
```

L'application sera disponible sur http://localhost:8080

### Commandes disponibles

- `make docker-build` - Construire l'image Docker
- `make docker-up` - Démarrer le conteneur en arrière-plan
- `make docker-dev` - Lancer avec hot reload (recommandé)
- `make docker-down` - Arrêter le conteneur
- `make docker-logs` - Voir les logs
- `make docker-shell` - Ouvrir un shell dans le conteneur
- `make docker-restart` - Redémarrer le conteneur

### Hot Reload

Le hot reload fonctionne automatiquement :
- Modifiez les fichiers dans `lib/`
- Flutter détecte les changements et recharge automatiquement
- Ouvrez http://localhost:8080 dans votre navigateur

### Notes

- Les modifications dans `lib/` sont montées en volume, donc les changements sont immédiats
- Le cache Flutter est conservé dans des volumes Docker pour accélérer les builds
- Pour forcer un rebuild complet : `make docker-down && make docker-build && make docker-dev`

