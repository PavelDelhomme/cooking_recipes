# 🔒 Architecture de Sécurité - Cooking Recipes

## Vue d'ensemble

Ce document décrit l'architecture de sécurité complète de l'application Cooking Recipes, incluant le WAF (Web Application Firewall), la DMZ (Demilitarized Zone), et toutes les mesures de protection.

## 🛡️ Mesures de Sécurité Implémentées

### 1. Web Application Firewall (WAF)

#### Middleware WAF Express
- **Fichier**: `backend/src/middleware/waf.js`
- **Stack technique protégée**:
  - **Base de données**: SQLite
  - **Backend**: Node.js/Express
  - **Frontend**: Flutter Web
- **Protection contre**:
  - **SQL Injection** (SQLite spécifique) - Détection des commandes SQL dangereuses, patterns d'injection, commentaires SQL
  - **XSS (Cross-Site Scripting)** - Scripts inline, iframes, event handlers, JavaScript dans URLs, expressions CSS
  - **Path Traversal** - Navigation de répertoires, accès aux fichiers système sensibles
  - **Command Injection** - Exécution de commandes système, shells, outils réseau
  - **File Upload malveillants** - Extensions de scripts serveur, archives dangereuses

#### Nginx WAF
- **Fichier**: `nginx/waf.conf`
- **Fonctionnalités**:
  - Filtrage des user-agents suspects
  - Blocage des extensions de fichiers dangereuses
  - Détection de patterns d'attaque dans les URLs
  - Rate limiting par IP

### 2. Protection CSRF (Cross-Site Request Forgery)

- **Fichier**: `backend/src/middleware/csrf.js`
- **Fonctionnement**:
  - Génération de tokens CSRF pour les requêtes GET
  - Vérification obligatoire pour POST, PUT, DELETE, PATCH
  - Tokens valides 30 minutes
  - Nettoyage automatique des tokens expirés

### 3. Rate Limiting et Blacklist IP

- **Fichier**: `backend/src/middleware/rateLimiter.js`
- **Limites**:
  - Authentification: 10 tentatives / 5 minutes
  - Inscription: 5 tentatives / 30 minutes
  - API générale: 200 requêtes / 5 minutes
- **Blacklist automatique**:
  - IPs bloquées temporairement ou définitivement
  - Raison et expiration stockées en base

### 4. Logging de Sécurité

- **Fichier**: `backend/src/middleware/securityLogger.js`
- **Événements enregistrés**:
  - Tentatives d'authentification (succès/échec)
  - Attaques bloquées par le WAF
  - Violations CSRF
  - Activités suspectes
  - Actions administrateur
- **Stockage**:
  - Fichiers de log journaliers: `backend/logs/security/`
  - Base de données: table `security_logs`

### 5. Validation et Sanitization

- **Fichier**: `backend/src/utils/validation.js`
- **Validations**:
  - Email (format, domaine)
  - Mot de passe (force, caractères)
  - Noms et champs texte
- **Sanitization**:
  - Échappement des caractères HTML
  - Nettoyage des inputs avant traitement

### 6. Headers de Sécurité (Helmet)

- **Fichier**: `backend/src/server.js`
- **Headers configurés**:
  - Content-Security-Policy
  - X-Frame-Options
  - X-Content-Type-Options
  - X-XSS-Protection
  - Referrer-Policy
  - Permissions-Policy

### 7. Authentification JWT

- **Sécurité**:
  - Tokens signés avec secret fort
  - Expiration: 30 jours
  - Vérification sur chaque requête protégée
  - Protection contre les attaques de timing

## 🏗️ Architecture DMZ (Demilitarized Zone)

### Schéma d'Architecture

```
Internet
   │
   ▼
[Firewall/Routeur]
   │
   ▼
[DMZ - Zone Périphérique]
   │
   ├──► [Nginx Proxy Manager] (Reverse Proxy + SSL)
   │         │
   │         ├──► [Frontend Container] (Port 8080)
   │         │
   │         └──► [API Container] (Port 7272)
   │
   └──► [Portainer] (Gestion Docker)
   
[Zone Interne - Réseau Privé]
   │
   ├──► [Base de Données] (SQLite - Volume Docker)
   ├──► [Logs de Sécurité] (Volume Docker)
   └──► [Backup] (Volume Docker)
```

### Configuration DMZ avec Docker

#### Réseaux Docker

1. **Réseau `web`** (DMZ - Externe)
   - Accessible depuis Internet via Nginx Proxy Manager
   - Contient: Frontend, API (exposés uniquement sur ce réseau)

2. **Réseau `cookingrecipes_network`** (Interne)
   - Réseau privé pour communication interne
   - Contient: API, Base de données, Logs

#### Isolation des Services

```yaml
# docker-compose.prod.yml
services:
  cookingrecipes-api:
    networks:
      - cookingrecipes_network  # Réseau interne
      - web                      # Réseau DMZ (via Nginx)
    expose:
      - "7272"                   # Non publié directement
      
  cookingrecipes-frontend:
    networks:
      - cookingrecipes_network   # Réseau interne
      - web                      # Réseau DMZ (via Nginx)
    expose:
      - "8080"                   # Non publié directement
```

### Configuration Nginx Proxy Manager (DMZ)

#### Proxy Host - Frontend
- **Domain**: `cookingrecipes.delhomme.ovh`
- **Forward Hostname/IP**: `cookingrecipes-frontend`
- **Forward Port**: `8080`
- **SSL**: Let's Encrypt (automatique)
- **Advanced**: Inclure `nginx/waf.conf`

#### Proxy Host - API
- **Domain**: `api.cookingrecipes.delhomme.ovh`
- **Forward Hostname/IP**: `cookingrecipes-api`
- **Forward Port**: `7272`
- **SSL**: Let's Encrypt (automatique)
- **Advanced**: Inclure `nginx/waf.conf`
- **Custom Locations**: Rate limiting renforcé

## 🔐 Bonnes Pratiques de Sécurité

### 1. Secrets Management

- **JWT_SECRET**: Généré avec `openssl rand -hex 32`
- **Variables d'environnement**: Stockées dans `.env.prod` (non commité)
- **Docker Secrets**: Utiliser Docker secrets en production

### 2. Base de Données

- **Chiffrement**: SQLite avec chiffrement optionnel
- **Backup**: Automatique quotidien
- **Isolation**: Volume Docker non exposé

### 3. Monitoring et Alertes

- **Logs de sécurité**: Analysés quotidiennement
- **Alertes**: Configurer des alertes pour:
  - Plus de 10 attaques WAF en 1 heure
  - Plus de 5 échecs d'authentification depuis une IP
  - Accès administrateur

### 4. Mises à jour de Sécurité

- **Dépendances**: `npm audit` régulièrement
- **Images Docker**: Mises à jour mensuelles
- **Système**: Mises à jour de sécurité automatiques

## 🚨 Réponse aux Incidents

### En cas d'attaque détectée

1. **Automatique**:
   - IP ajoutée à la blacklist
   - Requête bloquée (403)
   - Événement loggé

2. **Manuel**:
   - Vérifier les logs: `backend/logs/security/`
   - Analyser la base: `SELECT * FROM security_logs WHERE event_type = 'WAF_BLOCKED'`
   - Blacklist permanente si nécessaire

### Commandes Utiles

```bash
# Voir les logs de sécurité
tail -f backend/logs/security/security-$(date +%Y-%m-%d).log

# Analyser les attaques récentes
grep "WAF_BLOCKED" backend/logs/security/*.log

# Vérifier les IPs blacklistées
sqlite3 backend/data/database.sqlite "SELECT * FROM ip_blacklist;"
```

## 📋 Checklist de Sécurité

- [x] WAF middleware Express
- [x] Protection CSRF
- [x] Rate limiting par IP
- [x] Blacklist IP automatique
- [x] Logging de sécurité
- [x] Validation et sanitization
- [x] Headers de sécurité (Helmet)
- [x] Authentification JWT sécurisée
- [x] Architecture DMZ documentée
- [x] Configuration Nginx WAF
- [ ] ModSecurity installé (optionnel)
- [ ] Intrusion Detection System (IDS)
- [ ] Chiffrement base de données
- [ ] Backup automatique chiffré
- [ ] Monitoring temps réel
- [ ] Alertes automatiques

## 🔄 Améliorations Futures

1. **ModSecurity**: Installation et configuration complète
2. **Fail2Ban**: Intégration pour blacklist automatique
3. **Chiffrement**: Base de données chiffrée
4. **2FA**: Authentification à deux facteurs
5. **Audit**: Outils d'audit de sécurité automatisés
6. **Pentest**: Tests de pénétration réguliers

## 📚 Ressources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Nginx Security Best Practices](https://www.nginx.com/blog/security-hardening-nginx/)
- [Express Security Best Practices](https://expressjs.com/en/advanced/best-practice-security.html)

