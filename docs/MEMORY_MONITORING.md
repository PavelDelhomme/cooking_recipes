# 📊 Guide de Monitoring Mémoire

Ce guide explique comment utiliser le système complet de monitoring mémoire pour détecter les fuites mémoire et optimiser la consommation RAM.

## 🎯 Fonctionnalités

### 1. Redémarrage Automatique
- **Ctrl+C** : Redémarre automatiquement l'application
- **Shift+C** : Arrête définitivement (si nécessaire)

### 2. Monitoring Mémoire
- **Monitoring système** : Script bash qui surveille les processus Node.js et Flutter
- **Monitoring Flutter** : Service Dart intégré pour surveiller la mémoire de l'application
- **Détection de fuites** : Analyse automatique des tendances de croissance mémoire

### 3. Rapports Détaillés
- Rapports complets avec statistiques système
- Détection automatique de fuites mémoire
- Historique des snapshots mémoire

## 🚀 Utilisation

### Commandes Make

```bash
# Générer un rapport mémoire complet instantané
make memory-report

# Monitoring en temps réel (mise à jour toutes les 2 secondes)
make memory-monitor

# Détecter les fuites mémoire (5 minutes)
make memory-leak

# Détection étendue (15 minutes)
make memory-leak-extended
```

### Workflow Recommandé

1. **Lancer l'application** :
   ```bash
   make dev-web
   ```

2. **Dans un autre terminal, lancer le monitoring** :
   ```bash
   make memory-monitor
   ```
   Cela affichera en temps réel :
   - Mémoire Backend (Node.js)
   - Mémoire Frontend (Flutter)
   - Mémoire système totale

3. **Pour détecter les fuites** :
   ```bash
   make memory-leak
   ```
   Le script va :
   - Surveiller pendant 5 minutes
   - Prendre des échantillons toutes les 10 secondes
   - Analyser les tendances
   - Générer un rapport de détection

## 📄 Rapports Générés

Les rapports sont sauvegardés dans `reports/memory/` :

### `memory_report_TIMESTAMP.txt`
Rapport complet incluant :
- Mémoire système (totale, utilisée, disponible)
- Mémoire Backend (PID, RSS, threads, fichiers ouverts)
- Mémoire Frontend (PID, RSS, threads, fichiers ouverts)
- Top 10 processus par mémoire
- Fichiers ouverts par processus
- Cache système

### `leak_detection_TIMESTAMP.txt`
Rapport de détection de fuites incluant :
- Croissance mémoire Backend (%)
- Croissance mémoire Frontend (%)
- Détection automatique (⚠️ si croissance > 20%)
- Détails de tous les échantillons

## 🔍 Interprétation des Résultats

### Mémoire Normale
- **Backend** : 50-200 MB (selon le nombre de requêtes)
- **Frontend** : 100-300 MB (selon le nombre de widgets)
- **Croissance** : < 10% sur 5 minutes

### Fuite Mémoire Détectée
- **Croissance** : > 20% sur 5 minutes
- **Tendance** : Croissance constante sans stabilisation
- **Action** : Vérifier les listeners non supprimés, les streams non fermés, les images non libérées

### Exemple de Rapport

```
═══════════════════════════════════════════════════════════
RAPPORT DE DÉTECTION DE FUITES MÉMOIRE
═══════════════════════════════════════════════════════════
Date: 2024-01-15 14:30:00
Durée: 300s
Intervalle: 10s

--- Backend ---
Croissance mémoire: 15.5%
✓ Pas de fuite détectée

--- Frontend ---
Croissance mémoire: 25.3%
⚠️  FUITE MÉMOIRE DÉTECTÉE (croissance > 20%)
```

## 🛠️ Détails Techniques

### Script Bash (`scripts/memory_monitor.sh`)

Le script utilise :
- `/proc/PID/status` pour obtenir la mémoire RSS
- `ps` pour les statistiques processus
- `lsof` pour les fichiers ouverts
- Calculs avec `bc` pour les pourcentages

### Service Dart (`frontend/lib/services/memory_monitor.dart`)

Le service Flutter :
- Prend des snapshots périodiques
- Calcule les tendances de croissance
- Détecte automatiquement les fuites
- Génère des rapports détaillés

### Modes de Monitoring

1. **report** : Rapport instantané
2. **monitor** : Monitoring temps réel (mise à jour continue)
3. **leak** : Détection de fuites (surveillance sur durée)

## 📊 Métriques Surveillées

### Backend (Node.js)
- **RSS** : Resident Set Size (mémoire physique utilisée)
- **Threads** : Nombre de threads
- **Fichiers ouverts** : Nombre de descripteurs de fichiers

### Frontend (Flutter)
- **Heap Size** : Taille du tas mémoire
- **External Size** : Mémoire externe (images, etc.)
- **RSS** : Mémoire physique utilisée

### Système
- **Mémoire totale** : RAM totale disponible
- **Mémoire utilisée** : RAM actuellement utilisée
- **Mémoire disponible** : RAM libre
- **Cache** : Mémoire utilisée pour le cache

## 🔧 Dépannage

### Le monitoring ne détecte pas les processus
- Vérifier que l'application est lancée : `make dev-web`
- Vérifier les fichiers PID : `/tmp/backend_pid.txt` et `/tmp/frontend_pid.txt`

### Les rapports sont vides
- Attendre que l'application soit complètement démarrée
- Vérifier que les processus sont actifs : `ps aux | grep -E "node|flutter"`

### Erreur "bc: command not found"
- Installer `bc` : `sudo pacman -S bc` (Arch/Manjaro) ou `sudo apt install bc` (Debian/Ubuntu)

## 💡 Conseils d'Optimisation

1. **Images** : Utiliser `cacheWidth` et `cacheHeight` pour limiter la taille
2. **Listeners** : Toujours supprimer les listeners dans `dispose()`
3. **Streams** : Fermer les streams avec `.cancel()`
4. **Widgets** : Utiliser `const` pour éviter les reconstructions
5. **Dictionnaires** : Charger une seule fois et mettre en cache

## 📚 Références

- [Flutter Performance](https://docs.flutter.dev/perf)
- [Node.js Memory Management](https://nodejs.org/en/docs/guides/simple-profiling/)
- [Linux Memory Management](https://www.kernel.org/doc/html/latest/admin-guide/mm/)

