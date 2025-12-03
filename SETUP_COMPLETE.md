# 🚀 Guide de Configuration Complète - Production

Ce guide vous accompagne étape par étape pour configurer :
1. ✅ GitHub Actions avec secrets
2. ✅ Docker Hub (token)
3. ✅ Portainer (stack + webhook)
4. ✅ Nginx Proxy Manager (proxys hosts)

---

## 📋 Étape 1 : Configuration Docker Hub

### 1.1 Créer un Access Token Docker Hub

1. Allez sur [hub.docker.com](https://hub.docker.com)
2. Connectez-vous avec votre compte
3. Cliquez sur votre **profil** (en haut à droite) → **Account Settings**
4. Allez dans **Security** → **New Access Token**
5. Créez un token :
   - **Description** : `Cooking Recipes CI/CD`
   - **Permissions** : `Read & Write`
6. **Copiez le token** (vous ne pourrez plus le voir après !)
   - Exemple : `dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## 📋 Étape 2 : Configuration GitHub Actions

### 2.1 Ajouter les Secrets GitHub

1. Allez sur votre repo GitHub : `https://github.com/PavelDelhomme/cooking_recipes`
2. Cliquez sur **Settings** (en haut du repo)
3. Dans le menu de gauche : **Secrets and variables** → **Actions**
4. Cliquez sur **New repository secret**

#### Secret 1 : DOCKER_HUB_USERNAME
- **Name** : `DOCKER_HUB_USERNAME`
- **Secret** : `paveldelhomme` (votre nom d'utilisateur Docker Hub)
- Cliquez sur **Add secret**

#### Secret 2 : DOCKER_HUB_TOKEN
- **Name** : `DOCKER_HUB_TOKEN`
- **Secret** : Collez le token Docker Hub créé à l'étape 1.1
- Cliquez sur **Add secret**

#### Secret 3 : PORTAINER_WEBHOOK_URL (optionnel, à faire après l'étape 3)
- **Name** : `PORTAINER_WEBHOOK_URL`
- **Secret** : L'URL du webhook (vous l'obtiendrez à l'étape 3.4)
- Cliquez sur **Add secret**

✅ **Vérification** : Vous devriez avoir 3 secrets dans la liste :
- `DOCKER_HUB_USERNAME`
- `DOCKER_HUB_TOKEN`
- `PORTAINER_WEBHOOK_URL` (optionnel)

---

## 📋 Étape 3 : Configuration Portainer

### 3.1 Créer le Réseau Docker `web`

1. **Portainer** → **Networks** (menu de gauche)
2. Cliquez sur **Add network**
3. Configuration :
   - **Name** : `web`
   - **Driver** : `bridge`
   - **Scope** : `Local` (ou `Swarm` si vous utilisez Swarm)
4. Cliquez sur **Create network**

✅ **Important** : Ce réseau doit exister avant de créer la stack !

### 3.2 Créer la Stack dans Portainer

1. **Portainer** → **Stacks** (menu de gauche)
2. Cliquez sur **Add stack**
3. Configuration :
   - **Name** : `cooking-recipes`
   - **Build method** : Sélectionnez **Web editor**
4. **Collez le contenu** de `docker-compose.prod.yml` dans l'éditeur

   > 💡 **Astuce** : Ouvrez le fichier `docker-compose.prod.yml` et copiez tout son contenu

5. **Variables d'environnement** :
   - Cliquez sur **Environment variables**
   - Ajoutez :
     - **Name** : `JWT_SECRET`
     - **Value** : `votre-secret-jwt-super-securise-changez-moi` (générez un secret fort !)
   - Cliquez sur **Add**

6. **Réseaux** :
   - Vérifiez que le réseau `web` est sélectionné
   - Si absent, créez-le d'abord (étape 3.1)

7. Cliquez sur **Deploy the stack**

✅ **Vérification** : 
- Allez dans **Stacks** → `cooking-recipes`
- Vous devriez voir 2 conteneurs :
  - `cookingrecipes-api` (État: Running)
  - `cookingrecipes-frontend` (État: Running)

### 3.3 Vérifier les Conteneurs

1. **Portainer** → **Containers**
2. Vérifiez que les conteneurs sont en cours d'exécution :
   - `cookingrecipes-api`
   - `cookingrecipes-frontend`
3. Si un conteneur est arrêté, cliquez dessus → **Start**

### 3.4 Créer le Webhook Portainer

1. **Portainer** → **Stacks** → `cooking-recipes`
2. Cliquez sur l'onglet **Webhooks** (ou le bouton **Webhooks**)
3. Cliquez sur **Add webhook**
4. Configuration :
   - **Name** : `cooking-recipes-auto-deploy`
   - **Stack** : `cooking-recipes` (sélectionné automatiquement)
5. Cliquez sur **Create webhook**
6. **Copiez l'URL du webhook** (ex: `https://portainer.delhomme.ovh/api/webhooks/xxxxx`)
   - ⚠️ **Important** : Gardez cette URL, vous en aurez besoin !

7. **Ajoutez cette URL dans GitHub** :
   - Retournez sur GitHub → **Settings** → **Secrets and variables** → **Actions**
   - Modifiez ou créez le secret `PORTAINER_WEBHOOK_URL`
   - Collez l'URL du webhook
   - Cliquez sur **Update secret**

✅ **Test du webhook** :
```bash
# Testez manuellement (remplacez par votre URL)
curl -X POST https://portainer.delhomme.ovh/api/webhooks/xxxxx
```

---

## 📋 Étape 4 : Configuration Nginx Proxy Manager

### 4.1 Configuration Frontend (cookingrecipes.delhomme.ovh)

1. **Nginx Proxy Manager** → **Proxy Hosts** (menu de gauche)
2. Cliquez sur **Add Proxy Host**
3. **Details** :
   - **Domain Names** : `cookingrecipes.delhomme.ovh`
   - **Scheme** : `http` (pas https ici, NPM gère le SSL)
   - **Forward Hostname/IP** : `cookingrecipes-frontend`
   - **Forward Port** : `8080`
   - ✅ **Block Common Exploits** : Cochez
   - ✅ **Websockets Support** : Cochez
   - ✅ **Cache Assets** : Cochez (pour améliorer les performances)
   - ❌ **Access List** : Laissez vide (ou configurez si vous voulez restreindre l'accès)

4. **SSL** :
   - Cliquez sur l'onglet **SSL**
   - ✅ **Request a new SSL Certificate** : Cochez
   - ✅ **Force SSL** : Cochez
   - ✅ **HTTP/2 Support** : Cochez
   - ✅ **HSTS Enabled** : Cochez
   - ✅ **HSTS Subdomains** : Cochez (optionnel)
   - **Email Address for Let's Encrypt** : Votre email (ex: `votre@email.com`)
   - Cliquez sur **Save**

5. **Advanced** (optionnel, pour optimiser le cache) :
   - Cliquez sur l'onglet **Advanced**
   - Collez ceci :
   ```nginx
   # Cache statique pour améliorer les performances
   location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|webp)$ {
       expires 1y;
       add_header Cache-Control "public, immutable";
   }
   ```
   - Cliquez sur **Save**

✅ **Vérification** :
- Attendez quelques minutes que Let's Encrypt génère le certificat
- Testez : `https://cookingrecipes.delhomme.ovh`

### 4.2 Configuration Backend API (cookingrecipes-api.delhomme.ovh)

1. **Nginx Proxy Manager** → **Proxy Hosts**
2. Cliquez sur **Add Proxy Host**
3. **Details** :
   - **Domain Names** : `cookingrecipes-api.delhomme.ovh`
   - **Scheme** : `http`
   - **Forward Hostname/IP** : `cookingrecipes-api`
   - **Forward Port** : `7272`
   - ✅ **Block Common Exploits** : Cochez
   - ✅ **Websockets Support** : Cochez
   - ❌ **Cache Assets** : **DÉCOCHEZ** (important pour l'API !)
   - ❌ **Access List** : Laissez vide

4. **SSL** :
   - Cliquez sur l'onglet **SSL**
   - ✅ **Request a new SSL Certificate** : Cochez
   - ✅ **Force SSL** : Cochez
   - ✅ **HTTP/2 Support** : Cochez
   - ✅ **HSTS Enabled** : Cochez
   - **Email Address for Let's Encrypt** : Votre email
   - Cliquez sur **Save**

5. **Advanced** (pour CORS si nécessaire) :
   - Cliquez sur l'onglet **Advanced**
   - Collez ceci :
   ```nginx
   # CORS Headers (si nécessaire pour les appels depuis le frontend)
   add_header 'Access-Control-Allow-Origin' '*' always;
   add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
   add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
   
   if ($request_method = 'OPTIONS') {
       return 204;
   }
   ```
   - Cliquez sur **Save**

✅ **Vérification** :
- Testez : `https://cookingrecipes-api.delhomme.ovh/health`
- Vous devriez voir : `{"status":"ok","message":"API is running"}`

---

## 📋 Étape 5 : Configuration DNS OVH

### 5.1 Ajouter les Enregistrements DNS

1. Allez sur [OVH Manager](https://www.ovh.com/manager/)
2. Connectez-vous
3. Allez dans **Web Cloud** → **Domaines** → `delhomme.ovh`
4. Cliquez sur **Zone DNS**
5. Ajoutez les enregistrements :

#### Enregistrement 1 : Frontend
- **Type** : `A`
- **Sous-domaine** : `cooking-recipe`
- **Cible** : `95.111.227.204`
- **TTL** : `3600` (ou laissez par défaut)
- Cliquez sur **Suivant** → **Confirmer**

#### Enregistrement 2 : Backend API
- **Type** : `A`
- **Sous-domaine** : `cookingrecipes-api`
- **Cible** : `95.111.227.204`
- **TTL** : `3600`
- Cliquez sur **Suivant** → **Confirmer**

✅ **Vérification** :
- Attendez quelques minutes pour la propagation DNS
- Testez : `ping cookingrecipes.delhomme.ovh` (devrait retourner `95.111.227.204`)
- Testez : `ping cookingrecipes-api.delhomme.ovh` (devrait retourner `95.111.227.204`)

---

## 📋 Étape 6 : Test Complet

### 6.1 Tester le Backend

```bash
# Test de santé
curl https://cookingrecipes-api.delhomme.ovh/health

# Devrait retourner :
# {"status":"ok","message":"API is running"}
```

### 6.2 Tester le Frontend

1. Ouvrez votre navigateur
2. Allez sur : `https://cookingrecipes.delhomme.ovh`
3. Vous devriez voir l'application Flutter
4. Testez la connexion :
   - Email : `admin@cookingrecipe.com`
   - Password : `admin123`

### 6.3 Tester GitHub Actions

1. Faites une petite modification dans le code
2. Commit et push :
   ```bash
   git add .
   git commit -m "test: test déploiement automatique"
   git push origin main
   ```
3. Allez sur GitHub → **Actions**
4. Vous devriez voir le workflow **Build and Push Docker Images** en cours
5. Attendez la fin (environ 5-10 minutes)
6. Vérifiez dans Portainer que la stack a été redéployée automatiquement

---

## 🐛 Dépannage

### Les conteneurs ne démarrent pas

1. **Portainer** → **Stacks** → `cooking-recipes` → **Logs**
2. Vérifiez les erreurs
3. Vérifiez que le réseau `web` existe
4. Vérifiez les variables d'environnement

### Erreur 502 Bad Gateway dans Nginx Proxy Manager

1. Vérifiez que les conteneurs sont en cours d'exécution dans Portainer
2. Vérifiez les noms des conteneurs :
   - Frontend : `cookingrecipes-frontend:8080`
   - Backend : `cookingrecipes-api:7272`
3. Vérifiez que les conteneurs sont sur le réseau `web`

### Le webhook ne fonctionne pas

1. Vérifiez l'URL du webhook dans Portainer
2. Testez manuellement :
   ```bash
   curl -X POST https://portainer.delhomme.ovh/api/webhooks/xxxxx
   ```
3. Vérifiez les logs GitHub Actions pour voir si le webhook a été appelé

### Erreur SSL dans Nginx Proxy Manager

1. Vérifiez que les DNS sont bien configurés
2. Attendez quelques minutes pour la propagation
3. Vérifiez que le port 80 et 443 sont ouverts sur votre serveur
4. Réessayez de demander le certificat SSL

### GitHub Actions échoue

1. Vérifiez les secrets GitHub (Settings → Secrets)
2. Vérifiez que le token Docker Hub est valide
3. Vérifiez les logs dans GitHub Actions pour voir l'erreur exacte

---

## ✅ Checklist Finale

- [ ] Docker Hub token créé et ajouté dans GitHub Secrets
- [ ] Secrets GitHub configurés (DOCKER_HUB_USERNAME, DOCKER_HUB_TOKEN, PORTAINER_WEBHOOK_URL)
- [ ] Réseau `web` créé dans Portainer
- [ ] Stack `cooking-recipes` créée dans Portainer
- [ ] Conteneurs en cours d'exécution
- [ ] Webhook Portainer créé et URL ajoutée dans GitHub
- [ ] Proxy Host frontend configuré dans Nginx Proxy Manager
- [ ] Proxy Host backend configuré dans Nginx Proxy Manager
- [ ] Certificats SSL générés pour les deux domaines
- [ ] DNS OVH configurés (cooking-recipe et cookingrecipes-api)
- [ ] Test du frontend réussi
- [ ] Test du backend réussi
- [ ] Test du déploiement automatique réussi

---

## 🎉 C'est Prêt !

Votre application est maintenant complètement configurée et automatisée ! 🚀

À chaque push sur `main`, l'application sera automatiquement :
1. ✅ Buildée par GitHub Actions
2. ✅ Poussée sur Docker Hub
3. ✅ Redéployée sur Portainer via webhook
4. ✅ Accessible sur `https://cookingrecipes.delhomme.ovh`

