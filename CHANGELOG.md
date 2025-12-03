# Changelog - Cooking Recipes

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [Non versionné] - 2024-12-03

### 🛡️ Sécurité et Rate Limiting

#### Ajouté
- **Système de rate limiting par IP** avec blacklist automatique
  - Rate limiting uniquement pour les routes d'authentification (`/api/auth/signin` et `/api/auth/signup`)
  - 10 tentatives de connexion par 5 minutes par IP → blacklist 1 heure
  - 5 tentatives d'inscription par 15 minutes par IP → blacklist 2 heures
  - Stockage dans SQLite avec expiration automatique
  - Table `ip_blacklist` ajoutée à la base de données

- **Pages d'erreur HTML professionnelles**
  - 401 (Authentification requise)
  - 403 (IP blacklistée / Accès refusé)
  - 404 (Page non trouvée)
  - 429 (Trop de requêtes)
  - 500 (Erreur serveur)
  - Détection automatique : JSON pour API, HTML pour navigateur

- **Détection d'IP améliorée**
  - Support des headers proxy (`x-forwarded-for`, `x-real-ip`)
  - Configuration `trust proxy` dans Express pour fonctionner derrière Nginx

#### Modifié
- **Rate limiting retiré des routes générales**
  - Le rate limiting global a été retiré
  - Appliqué uniquement aux routes d'authentification
  - Les autres routes ne sont plus limitées

- **Allowed origins corrigées**
  - Retrait des URLs API de `ALLOWED_ORIGINS`
  - Seuls les domaines frontend sont autorisés : `https://cookingrecipes.delhomme.ovh` et `https://cookingrecipe.delhomme.ovh`

#### Fichiers créés
- `backend/src/middleware/ipBlacklist.js` - Gestion de la blacklist IP
- `backend/src/middleware/errorHandler.js` - Pages d'erreur HTML

#### Fichiers modifiés
- `backend/src/middleware/rateLimiter.js` - Rate limiting par IP avec blacklist
- `backend/src/middleware/auth.js` - Utilisation des pages d'erreur
- `backend/src/server.js` - Retrait du rate limiting global, ajout de `trust proxy`
- `backend/src/database/db.js` - Ajout de la table `ip_blacklist`
- `PORTAINER_DEPLOY.md` - Documentation complète mise à jour

### 📚 Documentation

- **PORTAINER_DEPLOY.md** complètement mis à jour avec :
  - Domaines corrects (`cookingrecipes.delhomme.ovh` et `api.cookingrecipes.delhomme.ovh`)
  - Images Docker correctes (`paveldelhomme/cookingrecipes-api:latest` et `paveldelhomme/cookingrecipes-frontend:latest`)
  - Configuration complète de la stack
  - Instructions pour Nginx Proxy Manager
  - Section sécurité avec détails sur le rate limiting et la blacklist
  - Guide de dépannage complet

---

## Format

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/lang/fr/).

