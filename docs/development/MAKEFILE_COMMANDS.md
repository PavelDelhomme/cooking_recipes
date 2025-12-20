# 📋 Commandes Makefile - Guide Complet

## 🔧 Sécurité et Maintenance Backend

### Vérification et correction des vulnérabilités

```bash
# Vérifier les vulnérabilités npm
make backend-audit

# Corriger automatiquement les vulnérabilités
make backend-audit-fix

# Vérifier et corriger en une commande
make backend-security

# Afficher les informations de financement des packages
make backend-fund
```

## 🧪 Tests

### Tests généraux

```bash
# Tous les tests (frontend + backend)
make test

# Tests backend uniquement
make test-backend

# Tests du système d'autocritique
make test-autocritique
```

## 🤖 Système d'Autocritique IA

### Génération de rapports

```bash
# Générer un rapport d'autocritique unique
make ml-self-critique

# Démarrer le système en mode continu (arrière-plan)
# Par défaut: toutes les 120 minutes
make ml-self-critique-continuous

# Avec intervalle personnalisé (en minutes)
make ml-self-critique-continuous INTERVAL=60
```

### Consultation des rapports

```bash
# Voir le dernier rapport complet
make ml-self-critique-view

# Voir l'historique des résumés
make ml-self-critique-history

# Voir uniquement les défis générés
make ml-self-critique-challenges
```

## 🌐 Build Frontend Web

### Build et analyse

```bash
# Build web standard
make frontend-build

# Build web en mode release (optimisé)
make frontend-build-web

# Analyser le code Flutter pour détecter les erreurs
make frontend-analyze
```

## 📦 Installation

### Installation complète avec sécurité

```bash
# Installation standard
make install

# Installation + correction des vulnérabilités
make install-security
```

## 🚀 Développement

### Commandes principales

```bash
# Démarrer tout en mode développement
make dev

# Démarrer uniquement le web
make dev-web

# Arrêter tous les services
make down

# Redémarrer
make restart
```

## 📊 Autres commandes IA

```bash
# Réentraîner le modèle ML
make retrain-ml

# Valider automatiquement les feedbacks
make validate-ml-auto

# Afficher les métriques de performance
make ml-metrics

# Voir les données d'entraînement
make view-ml-data
```

## 💡 Exemples d'utilisation

### Workflow complet de test

```bash
# 1. Installer et sécuriser
make install-security

# 2. Lancer les tests
make test-autocritique

# 3. Générer un rapport
make ml-self-critique

# 4. Voir les défis
make ml-self-critique-challenges

# 5. Build web
make frontend-build-web
```

### Maintenance régulière

```bash
# Vérifier et corriger les vulnérabilités
make backend-security

# Générer un rapport d'autocritique
make ml-self-critique

# Voir l'historique
make ml-self-critique-history
```

## 📚 Voir toutes les commandes

```bash
make help
```

