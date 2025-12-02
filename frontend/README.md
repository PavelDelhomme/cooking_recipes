# Cooking Recipes - Application Flutter Web

Application de gestion de recettes de cuisine avec planification automatique basée sur le placard. - Application de Recettes de Cuisine

Une application Flutter pour gérer vos recettes de cuisine, votre placard et planifier vos repas.

## Fonctionnalités

- 🍳 **Récupération automatique de recettes** depuis internet (TheMealDB)
- 🥘 **Gestion du placard** : ajoutez, modifiez et suivez vos ingrédients
- 📅 **Planification de repas** : planifiez vos repas pour 1 jour, plusieurs jours ou une semaine
- 🔍 **Recherche de recettes** : recherchez des recettes par nom ou ingrédients
- 💡 **Suggestions intelligentes** : recevez des suggestions de recettes basées sur ce que vous avez dans votre placard
- 📱 **Sans compte** : tout est stocké localement, aucune inscription nécessaire

## Installation

### Option 1 : Avec Docker (Recommandé)

1. Assurez-vous d'avoir Docker et Docker Compose installés :
```bash
docker --version
docker-compose --version
```

2. Lancez l'application :
```bash
make dev
```

C'est tout ! L'application sera disponible sur http://localhost:8080 avec hot reload activé.

### Option 2 : Installation locale Flutter

1. Assurez-vous d'avoir Flutter installé sur votre machine
2. Clonez le projet
3. Installez les dépendances :
```bash
make install
# ou
flutter pub get
```

## Utilisation

### 🐳 Avec Docker (Recommandé - Hot Reload activé)

Le projet est containerisé avec Docker pour un développement facile avec hot reload :

```bash
# Lancer l'application avec hot reload (Docker)
make dev
# ou
make start
# ou
make docker-dev

# L'application sera disponible sur http://localhost:8080
# Modifiez les fichiers dans lib/ et ils seront rechargés automatiquement !
```

**Commandes Docker disponibles :**
```bash
make docker-build    # Construire l'image Docker
make docker-up       # Démarrer en arrière-plan
make docker-dev      # Lancer avec hot reload (recommandé)
make docker-down     # Arrêter le conteneur
make docker-logs     # Voir les logs
make docker-shell    # Ouvrir un shell dans le conteneur
make docker-restart  # Redémarrer le conteneur
```

### Avec Makefile (sans Docker)

Le projet inclut un Makefile pour faciliter les commandes courantes :

```bash
# Afficher toutes les commandes disponibles
make help

# Lancer l'application en mode web (build statique)
make web

# Installer les dépendances
make install

# Nettoyer le projet
make clean

# Lancer les tests
make test

# Analyser le code
make analyze

# Formater le code
make format

# Build pour le web
make build-web

# Vérification complète (format + analyse + tests)
make check
```

### Sans Makefile

#### Lancer l'application en mode web

```bash
flutter run -d chrome
```

#### Lancer l'application sur mobile

```bash
flutter run
```

## Structure du projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── models/                   # Modèles de données
│   ├── ingredient.dart
│   ├── recipe.dart
│   ├── pantry_item.dart
│   └── meal_plan.dart
├── services/                 # Services (API, stockage)
│   ├── recipe_api_service.dart
│   ├── pantry_service.dart
│   └── meal_plan_service.dart
└── screens/                  # Écrans de l'application
    ├── recipes_screen.dart
    ├── recipe_detail_screen.dart
    ├── pantry_screen.dart
    └── meal_plan_screen.dart
```

## Fonctionnalités détaillées

### Gestion du placard
- Ajoutez des ingrédients avec quantité et unité
- Suivez les dates d'expiration
- Marquez les ingrédients comme utilisés (diminue automatiquement la quantité)
- Supprimez ou modifiez les ingrédients

### Recherche de recettes
- Recherchez des recettes par nom
- Obtenez des suggestions basées sur vos ingrédients disponibles
- Consultez les détails complets des recettes (ingrédients, instructions, temps de préparation)

### Planification de repas
- Ajoutez des recettes à votre planning
- Organisez par type de repas (petit-déjeuner, déjeuner, dîner, collation)
- Consultez votre planning jour par jour
- Supprimez des repas planifiés

## API utilisée

L'application utilise [TheMealDB](https://www.themealdb.com/) qui est une API gratuite et open-source pour les recettes de cuisine. Aucune clé API n'est nécessaire.

## Stockage des données

Toutes les données (placard, planning) sont stockées localement sur votre appareil à l'aide de `shared_preferences`. Aucune donnée n'est envoyée sur internet, sauf pour la récupération des recettes.

## Dépendances principales

- `http` : Pour les requêtes API
- `shared_preferences` : Pour le stockage local
- `intl` : Pour le formatage des dates

## Développement

Le projet est actuellement sur la branche `features/base_functionnality` et est prêt pour les tests en mode web.

## Prochaines améliorations possibles

- Vue semaine pour le planning
- Génération automatique de planning basé sur les ingrédients disponibles
- Liste de courses générée depuis le planning
- Favoris de recettes
- Support d'autres APIs de recettes (Spoonacular, etc.)
