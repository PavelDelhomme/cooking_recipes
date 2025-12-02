# Cooking Recipes - Application Complète

Application de gestion de recettes de cuisine avec synchronisation cloud.

## Structure du Projet

```
flutter_cooking_recipe/
├── frontend/          # Application Flutter (Web + Mobile)
├── backend/           # API Node.js/Express avec SQLite
├── docker-compose.yml # Configuration Docker pour tout le projet
└── Makefile          # Commandes de gestion
```

## Démarrage Rapide

### Prérequis

- Docker et Docker Compose
- Flutter (pour développement local)
- Node.js (pour développement local backend)

### Mode Développement Local (Recommandé)

```bash
# Installer les dépendances
make install

# Lancer tout le projet (backend + frontend Flutter web)
make dev
```

L'application sera disponible sur :
- **Frontend Web (PC)**: http://localhost:4041
- **Frontend Web (Mobile/Réseau)**: http://[VOTRE_IP]:4041
- **Backend API**: http://[VOTRE_IP]:7373/api

> **Note**: Le backend écoute sur le port **7373** pour permettre l'accès depuis votre téléphone sur le même réseau. L'IP de votre machine sera détectée automatiquement.

### Avec Docker

```bash
# Lancer avec Docker Compose
docker-compose up --build
```

### Commandes Utiles

```bash
make help          # Affiche toutes les commandes
make dev           # Lance tout en mode développement
make down          # Arrête tous les conteneurs
make restart       # Redémarre tout
make logs          # Affiche les logs en temps réel
make status        # Affiche l'état des conteneurs
```

## Développement Local

### Backend seul

```bash
cd backend
npm install
PORT=7373 HOST=0.0.0.0 npm run dev
```

Ou utiliser le Makefile :
```bash
make backend-dev
```

Le backend sera disponible sur http://localhost:7373/api (et accessible depuis le réseau sur http://[VOTRE_IP]:7373/api)

### Frontend seul

```bash
cd frontend
flutter pub get
flutter run -d web-server --web-port=4041
```

## Build Mobile

### Android

```bash
make build-android
```

L'APK sera créé dans `frontend/build/app/outputs/flutter-apk/`

### iOS (nécessite macOS)

```bash
make build-ios
```

## Configuration

### Variables d'environnement Backend

Créer un fichier `backend/.env` (optionnel) :

```env
PORT=7373
HOST=0.0.0.0
JWT_SECRET=votre-secret-key-securise
```

### Configuration Frontend

L'URL de l'API est configurée automatiquement dans `frontend/lib/config/api_config.dart` :
- **Web** : Détecte automatiquement l'hostname et utilise le port 7373
- **Mobile** : Utilise localhost par défaut (configurable via `make configure-mobile-api`)

Pour configurer l'URL pour mobile (depuis votre téléphone) :
```bash
make configure-mobile-api  # Configure avec l'IP de votre machine
make build-android         # Build avec l'IP configurée
```

## API Endpoints

### Authentification
- `POST /api/auth/signup` - Inscription
- `POST /api/auth/signin` - Connexion
- `GET /api/auth/me` - Utilisateur actuel

### Placard
- `GET /api/pantry` - Liste des ingrédients
- `POST /api/pantry` - Ajouter un ingrédient
- `PUT /api/pantry/:id` - Modifier un ingrédient
- `DELETE /api/pantry/:id` - Supprimer un ingrédient

### Planning
- `GET /api/meal-plans` - Liste des plannings
- `POST /api/meal-plans` - Ajouter un planning
- `DELETE /api/meal-plans/:id` - Supprimer un planning

### Liste de courses
- `GET /api/shopping-list` - Liste des éléments
- `POST /api/shopping-list` - Ajouter un élément
- `PUT /api/shopping-list/:id` - Modifier un élément
- `DELETE /api/shopping-list/:id` - Supprimer un élément

## Architecture

- **Frontend**: Flutter (Web + Mobile)
- **Backend**: Node.js + Express + SQLite
- **Base de données**: SQLite (fichier dans `backend/data/`)
- **Authentification**: JWT (JSON Web Tokens)
- **Containerisation**: Docker + Docker Compose

## Notes

- La base de données SQLite est persistée dans `backend/data/`
- Les tokens JWT expirent après 30 jours
- Pas de système de paiement (comme demandé)
- Le backend est optimisé pour une exécution rapide

