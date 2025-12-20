# 🐳 Système d'Autocritique dans Docker

## 📋 Configuration Docker

Le système d'autocritique fonctionne automatiquement dans les conteneurs Docker. Les rapports et logs sont persistés via les volumes Docker.

## 🔧 Configuration des Volumes

### docker-compose.yml (Développement)

```yaml
volumes:
  - ./backend/data:/app/data          # Données (modèles ML, rapports d'autocritique)
  - ./backend/src:/app/src            # Code source (hot reload)
  - ./backend/logs:/app/logs          # Logs (autocritique, sécurité)
```

### docker-compose.prod.yml (Production)

```yaml
volumes:
  - cookingrecipes_backend_data:/app/data    # Volume nommé pour les données
  - cookingrecipes_security_logs:/app/logs   # Volume nommé pour les logs
```

## 📁 Structure des Dossiers dans le Conteneur

```
/app/
├── data/
│   ├── ml_models/           # Modèles ML (ingrédients, instructions, etc.)
│   ├── ml_critiques/        # Rapports d'autocritique
│   │   ├── latest_self_critique.json
│   │   ├── self_critique_*.json
│   │   └── summary_history.json
│   └── ml_reports/          # Rapports de test
└── logs/
    ├── self_critique_*.log  # Logs d'autocritique
    └── security/            # Logs de sécurité
```

## 🚀 Démarrage avec Docker

### Développement

```bash
docker-compose up -d backend
```

### Production

```bash
docker-compose -f docker-compose.prod.yml up -d
```

## ✅ Vérification dans le Conteneur

### Vérifier que l'autocritique démarre

```bash
# Voir les logs du conteneur
docker logs cooking_recipes_backend

# Ou en temps réel
docker logs -f cooking_recipes_backend
```

Vous devriez voir :
```
✅ Système d'autocritique continu démarré (toutes les 120 minutes)
```

### Vérifier les rapports générés

```bash
# Accéder au conteneur
docker exec -it cooking_recipes_backend sh

# Dans le conteneur
ls -lh /app/data/ml_critiques/
cat /app/data/ml_critiques/latest_self_critique.json | jq
```

### Vérifier les logs

```bash
# Depuis l'hôte (si volume monté)
cat backend/logs/self_critique_$(date +%Y-%m-%d).log

# Ou depuis le conteneur
docker exec cooking_recipes_backend cat /app/logs/self_critique_$(date +%Y-%m-%d).log
```

## 📊 Accéder aux Rapports depuis l'Hôte

### Développement (volumes bind)

Les rapports sont directement accessibles sur l'hôte :

```bash
# Dernier rapport
cat backend/data/ml_critiques/latest_self_critique.json | jq

# Historique
cat backend/data/ml_critiques/summary_history.json | jq

# Logs
tail -f backend/logs/self_critique_$(date +%Y-%m-%d).log
```

### Production (volumes nommés)

Pour accéder aux volumes nommés :

```bash
# Lister les volumes
docker volume ls | grep cookingrecipes

# Inspecter un volume
docker volume inspect cookingrecipes_backend_data

# Accéder aux données via un conteneur temporaire
docker run --rm -v cookingrecipes_backend_data:/data alpine ls -lh /data/ml_critiques/
```

## 🔍 Commandes Utiles

### Voir les rapports d'autocritique

```bash
# Depuis l'hôte (développement)
docker exec cooking_recipes_backend cat /app/data/ml_critiques/latest_self_critique.json | jq

# Depuis l'hôte (production)
docker run --rm -v cookingrecipes_backend_data:/data alpine cat /data/ml_critiques/latest_self_critique.json | jq
```

### Voir l'historique

```bash
# Depuis l'hôte (développement)
docker exec cooking_recipes_backend cat /app/data/ml_critiques/summary_history.json | jq

# Depuis l'hôte (production)
docker run --rm -v cookingrecipes_backend_data:/data alpine cat /data/ml_critiques/summary_history.json | jq
```

### Voir les logs

```bash
# Depuis l'hôte (développement)
docker exec cooking_recipes_backend tail -f /app/logs/self_critique_$(date +%Y-%m-%d).log

# Depuis l'hôte (production)
docker exec cookingrecipes-api tail -f /app/logs/self_critique_$(date +%Y-%m-%d).log
```

### Forcer une analyse immédiate

```bash
# Exécuter le script d'autocritique dans le conteneur
docker exec cooking_recipes_backend node /app/scripts/ml_self_critique.js
```

## 🐛 Dépannage

### Les rapports ne sont pas générés

1. **Vérifier que le conteneur tourne** :
   ```bash
   docker ps | grep backend
   ```

2. **Vérifier les logs** :
   ```bash
   docker logs cooking_recipes_backend | grep autocritique
   ```

3. **Vérifier les permissions** :
   ```bash
   docker exec cooking_recipes_backend ls -la /app/data/ml_critiques/
   ```

4. **Vérifier que les dossiers existent** :
   ```bash
   docker exec cooking_recipes_backend mkdir -p /app/data/ml_critiques /app/logs
   ```

### Les logs ne sont pas sauvegardés

1. **Vérifier le volume** :
   ```bash
   docker volume inspect cookingrecipes_security_logs
   ```

2. **Vérifier les permissions** :
   ```bash
   docker exec cooking_recipes_backend ls -la /app/logs/
   ```

### Le système ne démarre pas

1. **Vérifier les variables d'environnement** :
   ```bash
   docker exec cooking_recipes_backend env | grep -E "NODE_ENV|PORT"
   ```

2. **Vérifier les logs de démarrage** :
   ```bash
   docker logs cooking_recipes_backend | head -50
   ```

## 📝 Notes Importantes

1. **Persistance des données** : Les rapports et logs sont persistés via les volumes Docker
2. **Permissions** : Les dossiers sont créés avec les bonnes permissions dans le Dockerfile
3. **Automatique** : Le système démarre automatiquement avec le serveur backend
4. **Intervalle** : Les rapports sont générés toutes les 2 heures par défaut

## 🔄 Mise à Jour

Lors d'une mise à jour du conteneur, les données sont préservées grâce aux volumes :

```bash
# Reconstruire et redémarrer
docker-compose build backend
docker-compose up -d backend

# Les rapports et logs sont toujours là
docker exec cooking_recipes_backend ls -lh /app/data/ml_critiques/
```

## 📚 Documentation Complémentaire

- [Système d'Autocritique](../ia/AUTOCRITIQUE_SYSTEM.md)
- [Guide de Démarrage](../../GUIDE_DEMARRAGE.md)

