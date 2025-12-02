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

### Avec Docker (Recommandé)

```bash
# Installer les dépendances
make install

# Lancer tout le projet
make dev

# Ou simplement
make up
```

L'application sera disponible sur :
- **Frontend**: http://localhost:4041
- **Backend API**: http://localhost:4040

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
npm run dev
```

Le backend sera disponible sur http://localhost:4040

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

Créer un fichier `backend/.env` :

```env
PORT=4040
JWT_SECRET=votre-secret-key-securise
```

### Configuration Frontend

L'URL de l'API est configurée dans `frontend/lib/services/auth_service.dart` :

```dart
static const String _baseUrl = 'http://localhost:4040/api';
```

Pour Docker, utilisez `http://backend:4040/api` (géré automatiquement).

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

