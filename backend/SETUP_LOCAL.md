# 🚀 Guide de Configuration et Démarrage Local

## 📋 Prérequis

1. **Node.js** (v18 ou supérieur)
2. **npm** (v9 ou supérieur)
3. **Base de données SQLite** (créée automatiquement)

## ⚙️ Configuration

### 1. Créer le fichier `.env`

Le fichier `.env.example` est fourni comme modèle. Créez votre fichier `.env` :

```bash
cd backend
cp .env.example .env
```

### 2. Variables d'environnement

Le fichier `.env` doit contenir :

```env
PORT=7272
NODE_ENV=development
JWT_SECRET=dev-secret-key-change-in-production-2025
LIBRETRANSLATE_URL=http://localhost:5000
LIBRETRANSLATE_ENABLED=true
HOST=0.0.0.0
```

## 📦 Installation des dépendances

```bash
cd backend
npm install
```

## 🚀 Démarrage du serveur

### Mode développement (avec rechargement automatique)

```bash
npm run dev
```

### Mode production

```bash
npm start
```

## ✅ Vérification

Une fois le serveur démarré, vous devriez voir :

```
✅ Connexion à la base de données SQLite établie
✅ Modèles ML chargés avec succès
✅ Validation automatique programmée (toutes les heures)
✅ Entraînement automatique programmé (toutes les 6 heures)
✅ Système d'autocritique continu démarré (toutes les 120 minutes)
🚀 Server running on port 7272
📡 API available at http://localhost:7272/api
```

## 🧠 Interface IA Admin

### Accès

L'interface IA est accessible depuis le frontend Flutter :
1. Connectez-vous avec un compte admin (`dumb@delhomme.ovh` ou `dev@delhomme.ovh`)
2. Ouvrez le menu drawer
3. Cliquez sur "🧠 Gestion IA"

### Fonctionnalités disponibles

- **Statistiques** : Voir les statistiques des feedbacks
- **Approuver tous les feedbacks** : Approuve tous les feedbacks en attente
- **Réentraîner le modèle ML** : Lance un réentraînement du modèle
- **Réentraîner le réseau de neurones** : Lance un réentraînement du réseau de neurones

## 🤖 Système d'Autocritique

Le système d'autocritique tourne automatiquement en arrière-plan et génère des rapports toutes les 2 heures.

### Rapports générés

- **Emplacement** : `backend/data/ml_critiques/`
- **Format** : JSON
- **Dernier rapport** : `latest_self_critique.json`

### Voir le dernier rapport

```bash
cat backend/data/ml_critiques/latest_self_critique.json | jq
```

### Logs

Les logs sont enregistrés dans : `backend/logs/self_critique_YYYY-MM-DD.log`

## 🔍 Vérification du système

### 1. Vérifier que le serveur répond

```bash
curl http://localhost:7272/health
```

Réponse attendue :
```json
{"status":"ok","message":"API is running"}
```

### 2. Vérifier les modèles ML

```bash
curl http://localhost:7272/api/ml-admin/stats
```

(Nécessite une authentification admin)

### 3. Vérifier les logs d'autocritique

```bash
ls -lh backend/logs/self_critique_*.log
tail -f backend/logs/self_critique_$(date +%Y-%m-%d).log
```

## 🐛 Dépannage

### Erreur : "Cannot find module 'dotenv'"

```bash
cd backend
npm install dotenv
```

### Erreur : "Cannot find module 'sqlite3'"

```bash
cd backend
npm install sqlite3
```

### Le système d'autocritique ne démarre pas

Vérifiez les logs :
```bash
tail -f backend/logs/self_critique_$(date +%Y-%m-%d).log
```

### Port déjà utilisé

Modifiez le port dans `.env` :
```env
PORT=7273
```

## 📚 Documentation

- [Système d'Autocritique](../docs/ia/AUTOCRITIQUE_SYSTEM.md)
- [Interface IA Admin](../docs/ia/ADMIN_IA_EXPLAINED.md)
- [Système ML](../docs/ia/ML_SYSTEM_EXPLAINED.md)

