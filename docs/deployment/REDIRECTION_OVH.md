# Guide de Configuration de la Redirection OVH

## 🔄 Redirection de `cookingrecipe.example.com` vers `cookingrecipes.example.com`

### 📋 Situation Actuelle

Vous avez déjà configuré dans **Nginx Proxy Manager** :
- **Proxy Host principal** : `cookingrecipes.example.com` → `http://cookingrecipes-frontend:8080` (avec SSL)
- **Proxy Host API** : `api.cookingrecipes.example.com` → `http://cookingrecipes-api:7272` (avec SSL)

### ✅ Solution : Créer un Proxy Host de Redirection Simple

Vous devez créer **un nouveau Proxy Host** uniquement pour la redirection. C'est la méthode la plus simple et la plus propre.

---

## 🎯 Étape par Étape : Configuration dans Nginx Proxy Manager

### 1. Connectez-vous à Nginx Proxy Manager

- Accédez à `https://ngin.example.com` (ou votre URL NPM)
- Connectez-vous avec vos identifiants

### 2. Créer un Nouveau Proxy Host pour la Redirection

1. **Cliquez sur "Proxy Hosts"** dans le menu de gauche
2. **Cliquez sur "Add Proxy Host"** (bouton en haut à droite)

### 3. Configuration de Base (Onglet "Details")

Remplissez les champs suivants :

- **Domain Names** : `cookingrecipe.example.com`
  - ⚠️ **Important** : Entrez uniquement le domaine sans 's', pas besoin d'ajouter le domaine avec 's'
  
- **Scheme** : `https`
  - ⚠️ **Important** : Mettez `https` même si vous allez faire une redirection

- **Forward Hostname/IP** : `cookingrecipes.example.com`
  - ⚠️ **Important** : Mettez le domaine de destination (avec 's')

- **Forward Port** : `443`
  - ⚠️ **Important** : Port HTTPS standard

- **Cache Assets** : ✅ (optionnel, peut être activé)
- **Block Common Exploits** : ✅ (recommandé)
- **Websockets Support** : ❌ (pas nécessaire pour une redirection)

### 4. Configuration SSL (Onglet "SSL")

1. **Cliquez sur l'onglet "SSL"**

2. **Sélectionnez "Request a new SSL Certificate"**
   - ✅ **Force SSL** : Cochez cette case
   - ✅ **HTTP/2 Support** : Cochez cette case
   - ✅ **HSTS Enabled** : Cochez cette case (optionnel mais recommandé)
   - ✅ **I Agree to the Let's Encrypt Terms of Service** : Cochez cette case

3. **Cliquez sur "Save"** pour demander le certificat SSL
   - ⏳ Attendez quelques secondes que le certificat soit généré

### 5. Configuration de la Redirection 301 (Onglet "Advanced")

1. **Cliquez sur l'onglet "Advanced"**

2. **Dans la section "Custom Nginx Configuration"**, ajoutez exactement ce code :

```nginx
return 301 https://cookingrecipes.example.com$request_uri;
```

⚠️ **Important** :
- Cette ligne doit être la **seule** dans la section "Custom Nginx Configuration"
- Elle redirige **toutes** les requêtes vers le domaine principal
- Le `$request_uri` conserve le chemin et les paramètres de l'URL

### 6. Sauvegarder

1. **Cliquez sur "Save"** en bas de la page
2. La redirection devrait être **active immédiatement**

---

## ✅ Vérification - Tout est Configuré !

### 📋 Checklist de Configuration

Vérifiez que vous avez bien :

#### ✅ Dans Nginx Proxy Manager (3 Proxy Hosts) :
1. **Frontend** : `cookingrecipes.example.com` → `http://cookingrecipes-frontend:8080` (SSL ✅)
2. **API** : `api.cookingrecipes.example.com` → `http://cookingrecipes-api:7272` (SSL ✅)
3. **Redirection** : `cookingrecipe.example.com` → `https://cookingrecipes.example.com:443` (SSL ✅)
   - Avec dans Advanced : `return 301 https://cookingrecipes.example.com$request_uri;`

#### ✅ Dans OVH DNS (3 enregistrements A) :
1. `cookingrecipes.example.com.` → `YOUR_SERVER_IP`
2. `api.cookingrecipes.example.com.` → `YOUR_SERVER_IP`
3. `cookingrecipe.example.com.` → `YOUR_SERVER_IP`

**Si vous avez tout ça, vous êtes prêt !** 🎉

---

## 🧪 Tests de Vérification

### Test 1 : Vérifier le DNS

```bash
# Vérifier que le DNS pointe bien vers votre IP
nslookup cookingrecipe.example.com
# Devrait retourner : YOUR_SERVER_IP

nslookup cookingrecipes.example.com
# Devrait retourner : YOUR_SERVER_IP

nslookup api.cookingrecipes.example.com
# Devrait retourner : YOUR_SERVER_IP
```

### Test 2 : Vérifier la Redirection (Ligne de Commande)

```bash
# Tester la redirection HTTP
curl -I http://cookingrecipe.example.com

# Tester la redirection HTTPS
curl -I https://cookingrecipe.example.com

# Vous devriez voir :
# HTTP/1.1 301 Moved Permanently
# Location: https://cookingrecipes.example.com/
```

### Test 3 : Vérifier dans le Navigateur

1. **Ouvrez** `https://cookingrecipe.example.com` dans votre navigateur
2. **Vous devriez être automatiquement redirigé** vers `https://cookingrecipes.example.com`
3. **L'URL dans la barre d'adresse devrait changer** pour afficher le domaine avec 's'
4. **L'application devrait se charger normalement**

### Test 4 : Vérifier que l'Application Fonctionne

1. **Ouvrez** `https://cookingrecipes.example.com` directement
2. **L'application devrait se charger** normalement
3. **Testez la connexion/inscription** pour vérifier que l'API fonctionne

### Test 5 : Vérifier l'API

```bash
# Tester l'endpoint de santé de l'API
curl https://api.cookingrecipes.example.com/health

# Devrait retourner :
# {"status":"ok","message":"API is running"}
```

---

## 📝 Résumé de la Configuration

### Proxy Hosts dans Nginx Proxy Manager

Vous devriez maintenant avoir **3 Proxy Hosts** :

1. **Frontend Principal** :
   - Domain : `cookingrecipes.example.com`
   - Forward : `http://cookingrecipes-frontend:8080`
   - SSL : ✅ Activé

2. **API Backend** :
   - Domain : `api.cookingrecipes.example.com`
   - Forward : `http://cookingrecipes-api:7272`
   - SSL : ✅ Activé

3. **Redirection** (NOUVEAU) :
   - Domain : `cookingrecipe.example.com`
   - Forward : `https://cookingrecipes.example.com:443`
   - SSL : ✅ Activé
   - Custom Nginx : `return 301 https://cookingrecipes.example.com$request_uri;`

---

## 🔍 Pourquoi Créer un Nouveau Proxy Host ?

### ✅ Avantages

- **Séparation claire** : Chaque domaine a son propre proxy host
- **Gestion SSL facile** : Chaque domaine peut avoir son propre certificat SSL
- **Maintenance simple** : Modifier la redirection n'affecte pas le proxy principal
- **Logs séparés** : Vous pouvez voir les accès à l'ancien domaine séparément

### ❌ Pourquoi ne pas modifier le proxy existant ?

- Si vous ajoutez `cookingrecipe.example.com` dans les "Domain Names" du proxy principal, les deux domaines pointeront vers le même conteneur
- Vous ne pourrez pas faire de redirection 301 propre
- Les deux domaines seraient accessibles sans redirection

---

## 🛠️ Alternative : Redirection via DNS (Non Recommandé)

Si vous préférez gérer la redirection au niveau DNS :

1. **Connectez-vous à OVH Manager**
2. **Allez dans votre zone DNS**
3. **Trouvez l'enregistrement pour `cookingrecipe.example.com`**
4. **Modifiez l'enregistrement** :
   - Changez le type en **CNAME** (si ce n'est pas déjà le cas)
   - Pointez vers `cookingrecipes.example.com`

⚠️ **Note** : Cette méthode ne fait **pas** de redirection HTTP 301, elle pointe juste le DNS. Les moteurs de recherche ne comprendront pas que c'est une redirection permanente.

---

## 📋 Notes Importantes

### Redirection 301 vs Redirection JavaScript

- **Redirection 301 (Nginx)** : 
  - ✅ Plus rapide (côté serveur)
  - ✅ Meilleure pour le SEO (moteurs de recherche)
  - ✅ Fonctionne même si JavaScript est désactivé
  - ✅ C'est la méthode recommandée

- **Redirection JavaScript (Fallback)** :
  - ✅ Fonctionne si la redirection serveur n'est pas configurée
  - ❌ Plus lente (côté client)
  - ❌ Nécessite JavaScript activé
  - ⚠️ Déjà incluse dans le code de l'application comme fallback

### Backend CORS

Le backend accepte **déjà les deux domaines** dans `ALLOWED_ORIGINS` :
- `https://cookingrecipes.example.com`
- `https://cookingrecipe.example.com`

Vous n'avez **rien à modifier** dans le backend ou dans Portainer.

---

## 🐛 Dépannage

### La redirection ne fonctionne pas

1. **Vérifiez que le Proxy Host de redirection est bien créé**
2. **Vérifiez que le certificat SSL est bien généré** (onglet SSL)
3. **Vérifiez la configuration "Custom Nginx Configuration"** :
   - Doit contenir exactement : `return 301 https://cookingrecipes.example.com$request_uri;`
   - Pas d'autres lignes
4. **Vérifiez les logs** dans Nginx Proxy Manager → Logs

### Erreur SSL

1. **Attendez quelques minutes** après la création du Proxy Host
2. **Vérifiez que Let's Encrypt peut accéder à votre domaine** (port 80 ouvert)
3. **Réessayez de demander le certificat** dans l'onglet SSL

### Les deux domaines fonctionnent sans redirection

- Vérifiez que vous avez bien ajouté la ligne dans "Custom Nginx Configuration"
- Vérifiez que vous avez bien créé un **nouveau** Proxy Host (pas modifié l'existant)

---

## ✅ C'est Prêt !

Une fois configuré, tous les accès à `cookingrecipe.example.com` seront automatiquement redirigés vers `cookingrecipes.example.com` avec une redirection 301 permanente.

---

## 🎯 Résumé : Que Faire Maintenant ?

### Si vous avez déjà tout configuré (Nginx Proxy Manager + DNS OVH) :

1. **Attendez 1-2 minutes** pour la propagation DNS (si vous venez de créer l'enregistrement DNS)
2. **Testez la redirection** dans votre navigateur :
   - Ouvrez `https://cookingrecipe.example.com`
   - Vous devriez être redirigé vers `https://cookingrecipes.example.com`
3. **C'est tout !** 🎉

### Si la redirection ne fonctionne pas :

1. **Vérifiez les certificats SSL** dans Nginx Proxy Manager :
   - Allez dans chaque Proxy Host → Onglet SSL
   - Vérifiez que les certificats Let's Encrypt sont bien générés (statut vert)
   - Si un certificat est en erreur, supprimez-le et redemandez-le

2. **Vérifiez la configuration Advanced** du Proxy Host de redirection :
   - Doit contenir exactement : `return 301 https://cookingrecipes.example.com$request_uri;`
   - Pas d'autres lignes

3. **Vérifiez les logs** dans Nginx Proxy Manager :
   - Allez dans "Logs" → "Access Logs"
   - Regardez les requêtes vers `cookingrecipe.example.com`

4. **Vérifiez que le DNS est bien propagé** :
   ```bash
   nslookup cookingrecipe.example.com
   # Doit retourner : YOUR_SERVER_IP
   ```

### Rien d'autre à faire !

- ✅ Le backend accepte déjà les deux domaines (CORS configuré dans Portainer)
- ✅ Pas besoin de modifier Portainer ou la stack Docker
- ✅ La redirection JavaScript dans le code sert de fallback (déjà incluse)
- ✅ Tout est automatique maintenant
