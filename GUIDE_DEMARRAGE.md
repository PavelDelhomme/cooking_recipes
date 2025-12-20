# 🚀 Guide de Démarrage Rapide - Système d'Autocritique IA

## ✅ Configuration effectuée

1. ✅ Fichier `.env` créé dans `backend/`
2. ✅ Support `dotenv` ajouté au serveur
3. ✅ Système d'autocritique intégré au serveur
4. ✅ Documentation créée

## 📋 Étapes pour démarrer

### 1. Installer les dépendances

```bash
cd backend
npm install
```

### 2. Vérifier le fichier `.env`

Le fichier `.env` devrait exister dans `backend/` avec :

```env
PORT=7272
NODE_ENV=development
JWT_SECRET=dev-secret-key-change-in-production-2025
LIBRETRANSLATE_URL=http://localhost:5000
LIBRETRANSLATE_ENABLED=true
HOST=0.0.0.0
```

### 3. Démarrer le serveur

```bash
cd backend
npm start
# ou en mode développement avec rechargement automatique :
npm run dev
```

### 4. Vérifier que tout fonctionne

Vous devriez voir dans les logs :

```
✅ Connexion à la base de données SQLite établie
✅ Modèles ML chargés avec succès
✅ Validation automatique programmée (toutes les heures)
✅ Entraînement automatique programmé (toutes les 6 heures)
✅ Système d'autocritique continu démarré (toutes les 120 minutes)
🚀 Server running on port 7272
```

## 🧠 Accéder à l'Interface IA

### Depuis le Frontend Flutter

1. **Lancer l'application Flutter**
2. **Se connecter avec un compte admin** :
   - Email : `dumb@delhomme.ovh` ou `dev@delhomme.ovh`
   - (Créer le compte si nécessaire)
3. **Ouvrir le menu drawer** (icône hamburger en haut à gauche)
4. **Cliquer sur "🧠 Gestion IA"**

### Fonctionnalités disponibles dans l'interface

- **📊 Statistiques** : Voir les statistiques des feedbacks
  - Total de feedbacks
  - Feedbacks approuvés
  - Feedbacks avec traduction
  - Répartition par type (ingrédients, instructions, etc.)

- **⚡ Actions rapides** :
  - **Approuver tous les feedbacks** : Approuve tous les feedbacks en attente
  - **Réentraîner le modèle ML** : Lance un réentraînement du modèle
  - **Réentraîner le réseau de neurones** : Lance un réentraînement du réseau de neurones

## 🤖 Système d'Autocritique

### Fonctionnement automatique

Le système d'autocritique tourne **automatiquement en arrière-plan** et génère des rapports toutes les **2 heures**.

### Voir les rapports

#### Dernier rapport

```bash
cat backend/data/ml_critiques/latest_self_critique.json | jq
```

#### Tous les rapports

```bash
ls -lh backend/data/ml_critiques/self_critique_*.json
```

#### Contenu d'un rapport

Chaque rapport contient :
- **Points forts** : Ce qui fonctionne bien
- **Points faibles** : Ce qui doit être amélioré
- **Recommandations** : Actions prioritaires
- **Patterns de traduction** : Erreurs identifiées

### Logs

Les logs sont enregistrés dans : `backend/logs/self_critique_YYYY-MM-DD.log`

```bash
# Voir les logs du jour
tail -f backend/logs/self_critique_$(date +%Y-%m-%d).log

# Voir tous les logs
ls -lh backend/logs/self_critique_*.log
```

### Exécution manuelle

Si vous voulez générer un rapport immédiatement :

```bash
# Une seule analyse
node backend/scripts/ml_self_critique.js

# Mode continu (toutes les 60 minutes)
node backend/scripts/ml_self_critique.js --continuous

# Mode continu avec intervalle personnalisé (120 minutes)
node backend/scripts/ml_self_critique.js --continuous --interval=120
```

## 🔍 Vérification du système

### 1. Vérifier que le serveur répond

```bash
curl http://localhost:7272/health
```

Réponse attendue :
```json
{"status":"ok","message":"API is running"}
```

### 2. Vérifier les modèles ML (nécessite authentification admin)

```bash
# Via l'interface Flutter ou via curl avec token
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:7272/api/ml-admin/stats
```

### 3. Vérifier que l'autocritique fonctionne

Attendez 2 heures ou exécutez manuellement :

```bash
node backend/scripts/ml_self_critique.js
```

Vérifiez ensuite qu'un rapport a été créé :

```bash
ls -lh backend/data/ml_critiques/
```

## 📁 Structure des fichiers

```
backend/
├── .env                          # Configuration (créé)
├── .env.example                  # Modèle de configuration
├── src/
│   └── server.js                 # Serveur avec autocritique intégré
├── scripts/
│   └── ml_self_critique.js       # Script d'autocritique
├── data/
│   ├── ml_critiques/             # Rapports d'autocritique
│   │   ├── latest_self_critique.json
│   │   └── self_critique_*.json
│   └── ml_models/                # Modèles ML
└── logs/
    └── self_critique_*.log       # Logs d'autocritique
```

## 🐛 Dépannage

### Le serveur ne démarre pas

1. Vérifier que les dépendances sont installées : `npm install`
2. Vérifier que le fichier `.env` existe
3. Vérifier les logs d'erreur dans la console

### L'interface IA n'apparaît pas

1. Vérifier que vous êtes connecté avec un compte admin
2. Emails admin autorisés : `dumb@delhomme.ovh` ou `dev@delhomme.ovh`
3. Vérifier que le serveur backend est démarré

### L'autocritique ne génère pas de rapports

1. Vérifier les logs : `tail -f backend/logs/self_critique_*.log`
2. Vérifier que la base de données contient des feedbacks
3. Exécuter manuellement : `node backend/scripts/ml_self_critique.js`

### Erreur "Cannot find module"

```bash
cd backend
npm install
```

## 📚 Documentation complète

- [Système d'Autocritique](docs/ia/AUTOCRITIQUE_SYSTEM.md)
- [Interface IA Admin](docs/ia/ADMIN_IA_EXPLAINED.md)
- [Configuration locale](backend/SETUP_LOCAL.md)

## 🎯 Prochaines étapes

1. ✅ Démarrer le serveur backend
2. ✅ Lancer l'application Flutter
3. ✅ Se connecter avec un compte admin
4. ✅ Accéder à l'interface IA
5. ✅ Attendre 2 heures pour voir le premier rapport d'autocritique
6. ✅ Ou exécuter manuellement : `node backend/scripts/ml_self_critique.js`

---

**Note** : Le système d'autocritique fonctionne en parallèle avec :
- **Validation automatique** : Toutes les heures
- **Apprentissage continu** : Toutes les 6 heures
- **Autocritique** : Toutes les 2 heures

Tous ces systèmes tournent automatiquement en arrière-plan ! 🚀

