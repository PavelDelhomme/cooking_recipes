# 🤖 Automatisation du Déploiement Portainer

Ce guide explique comment automatiser le déploiement de l'application sur Portainer.

## 📋 Options Disponibles

### Option 1 : GitHub Actions + Webhook Portainer (Recommandé)
### Option 2 : Portainer Stacks avec Git
### Option 3 : Script de déploiement local

---

## 🚀 Option 1 : GitHub Actions + Webhook Portainer

### Configuration

#### 1. Secrets GitHub

Dans votre repo GitHub → **Settings** → **Secrets and variables** → **Actions**, ajoutez :

- `DOCKER_HUB_USERNAME` : Votre nom d'utilisateur Docker Hub
- `DOCKER_HUB_TOKEN` : Votre token Docker Hub (Settings → Security → New Access Token)
- `PORTAINER_WEBHOOK_URL` : URL du webhook Portainer (optionnel)

#### 2. Webhook Portainer

1. **Portainer** → **Stacks** → `cooking-recipes` → **Webhook**
2. Cliquez sur **Add webhook**
3. Copiez l'URL du webhook (ex: `https://portainer.example.com/api/webhooks/xxx`)
4. Ajoutez-la dans les secrets GitHub comme `PORTAINER_WEBHOOK_URL`

#### 3. Workflow GitHub Actions

Le workflow `.github/workflows/docker-build-push.yml` :
- ✅ Build automatique des images à chaque push sur `main`
- ✅ Push sur Docker Hub
- ✅ Déclenchement automatique du webhook Portainer

**Déclenchement** :
- Automatique : à chaque push sur `main` (backend/frontend)
- Manuel : **Actions** → **Build and Push Docker Images** → **Run workflow**

---

## 🔄 Option 2 : Portainer Stacks avec Git

### Configuration dans Portainer

1. **Portainer** → **Stacks** → **Add Stack**
2. Sélectionnez **Repository**
3. Configuration :
   - **Name** : `cooking-recipes`
   - **Repository URL** : `https://github.com/YourUsername/cooking_recipes.git`
   - **Repository Reference** : `main` (ou votre branche)
   - **Compose Path** : `docker-compose.prod.yml`
   - **Auto-update** : ✅ Activé
   - **Webhook** : Créez un webhook et notez l'URL

### Déclenchement

Portainer surveille automatiquement le repo Git et redéploie lors des changements.

**Avantages** :
- ✅ Pas besoin de Docker Hub
- ✅ Déploiement direct depuis Git
- ✅ Auto-update activé

---

## 🛠️ Option 3 : Script de Déploiement Local

### Installation

```bash
chmod +x scripts/deploy-portainer.sh
```

### Configuration

Créez un fichier `.env.portainer` (optionnel) :

```bash
PORTAINER_URL=http://portainer.example.com:9000
PORTAINER_USERNAME=admin
PORTAINER_PASSWORD=votre-mot-de-passe
STACK_NAME=cooking-recipes
```

### Utilisation

```bash
# Avec variables d'environnement
export PORTAINER_URL=http://portainer.example.com:9000
export PORTAINER_USERNAME=admin
./scripts/deploy-portainer.sh

# Ou avec le fichier .env.portainer
source .env.portainer && ./scripts/deploy-portainer.sh
```

Le script :
- ✅ S'authentifie sur Portainer
- ✅ Vérifie si la stack existe
- ✅ Met à jour ou crée la stack
- ✅ Utilise les variables d'environnement de `.env.prod`

---

## 📝 Workflow Complet Recommandé

### 1. Développement Local

```bash
# Développement
make dev

# Test
make test-api
```

### 2. Commit et Push

```bash
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin main
```

### 3. Déploiement Automatique

**Avec GitHub Actions** :
- ✅ Build automatique des images
- ✅ Push sur Docker Hub
- ✅ Webhook Portainer déclenché
- ✅ Stack redéployée automatiquement

**Avec Portainer Git** :
- ✅ Portainer détecte le changement
- ✅ Redéploiement automatique

**Avec Script** :
```bash
make docker-build-push
./scripts/deploy-portainer.sh
```

---

## 🔐 Sécurité

### Secrets à protéger

- `JWT_SECRET` : Secret JWT pour l'API
- `PORTAINER_PASSWORD` : Mot de passe Portainer
- `DOCKER_HUB_TOKEN` : Token Docker Hub

**Ne jamais commiter ces secrets dans Git !**

### Bonnes pratiques

1. Utilisez les **Secrets GitHub** pour les tokens
2. Utilisez `.env.prod` pour les variables locales (dans `.gitignore`)
3. Activez **2FA** sur Docker Hub et GitHub
4. Limitez les permissions des tokens

---

## 🐛 Dépannage

### Les images ne sont pas mises à jour

1. Vérifiez que les images sont bien poussées sur Docker Hub
2. Dans Portainer, vérifiez **Pull & Redeploy**
3. Vérifiez les logs GitHub Actions

### Le webhook ne fonctionne pas

1. Vérifiez l'URL du webhook dans Portainer
2. Testez manuellement : `curl -X POST WEBHOOK_URL`
3. Vérifiez les logs Portainer

### Erreur d'authentification Portainer

1. Vérifiez les credentials dans les secrets GitHub
2. Vérifiez que l'utilisateur a les permissions nécessaires
3. Testez la connexion manuellement

---

## 📊 Monitoring

### GitHub Actions

- **Actions** → Voir l'historique des déploiements
- **Logs** : Détails de chaque étape

### Portainer

- **Stacks** → `cooking-recipes` → **Logs**
- **Events** : Historique des déploiements

---

## 🎯 Commandes Rapides

```bash
# Build et push manuel
make docker-build-push

# Déploiement manuel via script
./scripts/deploy-portainer.sh

# Vérifier les images Docker Hub
docker pull your-username/cookingrecipes-api:latest
docker pull your-username/cookingrecipes-frontend:latest
```

---

## ✅ Checklist de Déploiement

- [ ] Secrets GitHub configurés
- [ ] Webhook Portainer créé (si Option 1)
- [ ] Stack Portainer configurée
- [ ] DNS OVH configuré
- [ ] Nginx Proxy Manager configuré
- [ ] Test de déploiement réussi
- [ ] Monitoring activé

---

## 🎉 C'est Prêt !

Votre pipeline de déploiement est maintenant automatisé. À chaque push sur `main`, l'application sera automatiquement déployée sur Portainer ! 🚀

