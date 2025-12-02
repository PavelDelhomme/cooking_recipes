# Configuration de l'API Backend

## Structure recommandée

Pour mettre en place l'API backend avec base de données et système d'abonnement, voici une structure recommandée :

### Technologies suggérées

- **Backend**: Node.js avec Express ou Python avec FastAPI
- **Base de données**: PostgreSQL ou MongoDB
- **Authentification**: JWT (JSON Web Tokens)
- **Paiement**: Stripe ou PayPal pour les abonnements

### Endpoints API nécessaires

#### Authentification
- `POST /api/auth/signup` - Inscription
- `POST /api/auth/signin` - Connexion
- `POST /api/auth/signout` - Déconnexion
- `GET /api/auth/me` - Obtenir l'utilisateur actuel

#### Utilisateurs
- `GET /api/users/:id` - Obtenir un utilisateur
- `PUT /api/users/:id` - Mettre à jour un utilisateur
- `DELETE /api/users/:id` - Supprimer un utilisateur

#### Abonnements
- `GET /api/subscriptions/plans` - Obtenir les plans d'abonnement
- `POST /api/subscriptions/subscribe` - S'abonner
- `GET /api/subscriptions/status` - Statut de l'abonnement
- `POST /api/subscriptions/cancel` - Annuler l'abonnement

#### Données utilisateur (synchronisation)
- `GET /api/pantry` - Obtenir le placard
- `POST /api/pantry` - Ajouter un ingrédient
- `PUT /api/pantry/:id` - Modifier un ingrédient
- `DELETE /api/pantry/:id` - Supprimer un ingrédient

- `GET /api/meal-plans` - Obtenir les plannings
- `POST /api/meal-plans` - Ajouter un planning
- `PUT /api/meal-plans/:id` - Modifier un planning
- `DELETE /api/meal-plans/:id` - Supprimer un planning

- `GET /api/shopping-list` - Obtenir la liste de courses
- `POST /api/shopping-list` - Ajouter un élément
- `PUT /api/shopping-list/:id` - Modifier un élément
- `DELETE /api/shopping-list/:id` - Supprimer un élément

### Configuration dans Flutter

Modifier l'URL de base dans `lib/services/auth_service.dart` :

```dart
static const String _baseUrl = 'https://votre-api.com/api';
```

### Exemple de structure backend (Node.js/Express)

```
backend/
├── src/
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── user.controller.js
│   │   └── subscription.controller.js
│   ├── models/
│   │   ├── User.js
│   │   └── Subscription.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── user.routes.js
│   │   └── subscription.routes.js
│   ├── middleware/
│   │   └── auth.middleware.js
│   └── app.js
├── package.json
└── .env
```

### Variables d'environnement

```env
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/cooking_recipes
JWT_SECRET=your-secret-key
STRIPE_SECRET_KEY=sk_test_...
```

### Pour démarrer rapidement

1. Créer un nouveau projet backend
2. Configurer la base de données
3. Implémenter les endpoints d'authentification
4. Ajouter la gestion des abonnements
5. Mettre à jour l'URL dans `auth_service.dart`

