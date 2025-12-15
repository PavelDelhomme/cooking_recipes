# 📝 Référence Rapide - Configuration Production

## 🔑 Valeurs à Utiliser

### Docker Hub
- **Username** : `your-username`
- **Repository API** : `your-username/cookingrecipes-api:latest`
- **Repository Frontend** : `your-username/cookingrecipes-frontend:latest`

### GitHub Secrets
```
DOCKER_HUB_USERNAME = your-username
DOCKER_HUB_TOKEN = dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx (à créer)
PORTAINER_WEBHOOK_URL = https://portainer.example.com/api/webhooks/xxxxx (à créer)
```

### Portainer
- **Stack Name** : `cookingrecipes`
- **Network** : `web` (externe, doit exister)
- **Container API** : `cookingrecipes-api` (port interne: 7272)
- **Container Frontend** : `cookingrecipes-frontend` (port interne: 8080)
- **Variable d'environnement** : `JWT_SECRET` (générez un secret fort !)

### Nginx Proxy Manager

#### Frontend
- **Domain** : `cookingrecipes.example.com`
- **Forward to** : `cookingrecipes-frontend:8080`
- **Options** : ✅ Cache Assets, ✅ Websockets, ✅ Block Exploits

#### Backend API
- **Domain** : `api.cookingrecipes.example.com`
- **Forward to** : `cookingrecipes-api:7272`
- **Options** : ✅ Websockets, ✅ Block Exploits, ❌ Cache Assets

### DNS OVH
- **IP Serveur** : `YOUR_SERVER_IP`
- **A Record 1** : `cookingrecipes` → `YOUR_SERVER_IP`
- **A Record 2** : `api.cookingrecipes` → `YOUR_SERVER_IP` (ou `api` si sous-domaine)

### Compte par Défaut
- **Email** : `admin@cookingrecipes.com`
- **Password** : `CHANGE_ME_PASSWORD`
- ⚠️ **Changez ce mot de passe immédiatement !**

---

## 🚀 Commandes Utiles

### Local
```bash
# Build et push
make docker-build-push

# Déploiement Portainer
make deploy-portainer

# Tout en un
make deploy-full
```

### Test
```bash
# Backend health
curl https://api.cookingrecipes.example.com/health

# Frontend
https://cookingrecipes.example.com
```

---

## 📋 Checklist Rapide

1. [ ] Token Docker Hub créé → Ajouté dans GitHub Secrets
2. [ ] Secrets GitHub configurés (3 secrets)
3. [ ] Réseau `web` créé dans Portainer
4. [ ] Stack `cookingrecipes` créée dans Portainer
5. [ ] Webhook Portainer créé → URL dans GitHub Secrets
6. [ ] 2 Proxy Hosts créés dans Nginx Proxy Manager
7. [ ] 2 DNS A records créés dans OVH
8. [ ] Test frontend : https://cookingrecipes.example.com
9. [ ] Test backend : https://api.cookingrecipes.example.com/health

---

## 🔗 URLs Importantes

- **Frontend** : https://cookingrecipes.example.com
- **Backend API** : https://api.cookingrecipes.example.com/api
- **Backend Health** : https://api.cookingrecipes.example.com/health
- **Portainer** : https://portainer.example.com (ou votre URL)
- **Nginx Proxy Manager** : https://ngin.example.com (ou votre URL)

---

Pour le guide détaillé, consultez **SETUP_COMPLETE.md** 📖

