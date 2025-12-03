# 📝 Référence Rapide - Configuration Production

## 🔑 Valeurs à Utiliser

### Docker Hub
- **Username** : `paveldelhomme`
- **Repository API** : `paveldelhomme/cookingrecipes-api:latest`
- **Repository Frontend** : `paveldelhomme/cookingrecipes-frontend:latest`

### GitHub Secrets
```
DOCKER_HUB_USERNAME = paveldelhomme
DOCKER_HUB_TOKEN = dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx (à créer)
PORTAINER_WEBHOOK_URL = https://portainer.delhomme.ovh/api/webhooks/xxxxx (à créer)
```

### Portainer
- **Stack Name** : `cooking-recipes`
- **Network** : `web` (externe, doit exister)
- **Container API** : `cookingrecipes-api` (port interne: 7272)
- **Container Frontend** : `cookingrecipes-frontend` (port interne: 8080)
- **Variable d'environnement** : `JWT_SECRET` (générez un secret fort !)

### Nginx Proxy Manager

#### Frontend
- **Domain** : `cookingrecipes.delhomme.ovh`
- **Forward to** : `cookingrecipes-frontend:8080`
- **Options** : ✅ Cache Assets, ✅ Websockets, ✅ Block Exploits

#### Backend API
- **Domain** : `cookingrecipes-api.delhomme.ovh`
- **Forward to** : `cookingrecipes-api:7272`
- **Options** : ✅ Websockets, ✅ Block Exploits, ❌ Cache Assets

### DNS OVH
- **IP Serveur** : `95.111.227.204`
- **A Record 1** : `cooking-recipe` → `95.111.227.204`
- **A Record 2** : `cookingrecipes-api` → `95.111.227.204`

### Compte par Défaut
- **Email** : `admin@cookingrecipe.com`
- **Password** : `admin123`
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
curl https://cookingrecipes-api.delhomme.ovh/health

# Frontend
https://cookingrecipes.delhomme.ovh
```

---

## 📋 Checklist Rapide

1. [ ] Token Docker Hub créé → Ajouté dans GitHub Secrets
2. [ ] Secrets GitHub configurés (3 secrets)
3. [ ] Réseau `web` créé dans Portainer
4. [ ] Stack `cooking-recipes` créée dans Portainer
5. [ ] Webhook Portainer créé → URL dans GitHub Secrets
6. [ ] 2 Proxy Hosts créés dans Nginx Proxy Manager
7. [ ] 2 DNS A records créés dans OVH
8. [ ] Test frontend : https://cookingrecipes.delhomme.ovh
9. [ ] Test backend : https://cookingrecipes-api.delhomme.ovh/health

---

## 🔗 URLs Importantes

- **Frontend** : https://cookingrecipes.delhomme.ovh
- **Backend API** : https://cookingrecipes-api.delhomme.ovh/api
- **Backend Health** : https://cookingrecipes-api.delhomme.ovh/health
- **Portainer** : https://portainer.delhomme.ovh (ou votre URL)
- **Nginx Proxy Manager** : https://ngin.delhomme.ovh (ou votre URL)

---

Pour le guide détaillé, consultez **SETUP_COMPLETE.md** 📖

