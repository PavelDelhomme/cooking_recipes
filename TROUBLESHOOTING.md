# 🔧 Guide de Dépannage - Cooking Recipes

## 📱 Problèmes de Connexion Android

### Symptômes
- L'application ne se connecte pas au backend
- Erreurs "ERR_NAME_NOT_RESOLVED"
- Logs Portainer vides

### Solutions

#### 1. Vérifier la Connectivité Réseau

**Test depuis votre téléphone :**
1. Ouvrez un navigateur sur votre téléphone
2. Allez sur : `http://192.168.1.134:7272/health`
3. Vous devriez voir : `{"status":"ok","message":"API is running"}`

**Si ça ne fonctionne pas :**
- Vérifiez que le téléphone et le PC sont sur le **même réseau WiFi**
- Vérifiez le firewall (port 7272 doit être ouvert)
- Vérifiez que le backend tourne : `curl http://192.168.1.134:7272/health`

#### 2. Vérifier que le Backend est Démarré

```bash
# Vérifier si le backend tourne
ps aux | grep "node.*server.js" | grep -v grep

# Démarrer le backend si nécessaire
make dev
# Choisir l'option 2 (Web uniquement) pour démarrer juste le backend
```

#### 3. Rebuild l'APK avec la Bonne IP

```bash
# Trouver votre IP
hostname -I | awk '{print $1}'

# Rebuild l'APK avec cette IP
cd frontend
flutter build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=VOTRE_IP

# Réinstaller
make install-android
```

#### 4. Vérifier les Logs Flutter

```bash
# Voir les logs Flutter uniquement
adb -s R5CT7263YJL logcat | grep -i flutter

# Voir les erreurs de connexion
adb -s R5CT7263YJL logcat | grep -iE "error|exception|network|http"
```

---

## 📊 Surveillance des Logs

### Script Optimisé

```bash
# Surveiller les logs Android et API
bash scripts/monitor_logs.sh
```

**Ce script :**
- ✅ Filtre les erreurs système Android (SimpleEventLog, PlayCommon, etc.)
- ✅ Supprime les octets nuls
- ✅ Affiche uniquement les logs pertinents
- ✅ Économe en mémoire

### Logs Séparés

```bash
# Logs Android uniquement
adb -s R5CT7263YJL logcat | grep -i flutter

# Logs API backend
tail -f /tmp/backend.log
```

---

## 🐛 Erreurs Courantes

### 1. "ERR_NAME_NOT_RESOLVED"

**Cause :** L'application essaie de se connecter à un hostname qui ne peut pas être résolu.

**Solution :**
- Vérifiez que l'APK a été buildé avec `--dart-define=DEV_API_IP=192.168.1.134`
- Vérifiez que le téléphone et le PC sont sur le même WiFi
- Testez la connexion depuis le navigateur du téléphone

### 2. "Octet nul ignoré" dans monitor_logs.sh

**Cause :** Les logs Android contiennent des caractères nuls.

**Solution :** ✅ Corrigé dans la nouvelle version du script (utilise `tr -d '\0'`)

### 3. Logs Portainer Vides

**Cause :** Les containers en production n'écrivent pas dans stdout/stderr.

**Solution :**
- Normal en production si les logs sont redirigés ailleurs
- En développement, les logs sont dans `/tmp/backend.log`

### 4. Application Ne Se Connecte Pas

**Vérifications :**
1. ✅ Backend démarré et accessible
2. ✅ Téléphone et PC sur le même WiFi
3. ✅ Firewall ouvert (port 7272)
4. ✅ APK buildé avec la bonne IP
5. ✅ Test de connectivité depuis le navigateur du téléphone

---

## 🔍 Diagnostic Complet

### Checklist de Vérification

- [ ] Backend accessible depuis le PC : `curl http://localhost:7272/health`
- [ ] Backend accessible depuis le réseau : `curl http://192.168.1.134:7272/health`
- [ ] Backend accessible depuis le téléphone (navigateur) : `http://192.168.1.134:7272/health`
- [ ] Téléphone et PC sur le même WiFi
- [ ] Firewall ouvert (port 7272)
- [ ] APK buildé avec `--dart-define=DEV_API_IP=192.168.1.134`
- [ ] Application installée et lancée
- [ ] Logs Flutter sans erreurs critiques

### Commandes Utiles

```bash
# Vérifier l'IP de la machine
hostname -I | awk '{print $1}'

# Vérifier que le backend tourne
curl http://192.168.1.134:7272/health

# Voir les processus backend
ps aux | grep "node.*server"

# Rebuild et installer l'APK
cd frontend
flutter build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=192.168.1.134
make install-android

# Surveiller les logs
bash scripts/monitor_logs.sh
```

---

## 📝 Notes Importantes

### Erreurs Système Android (NORMALES)

Ces erreurs sont **normales** et n'affectent **PAS** votre application :
- `SimpleEventLog: PdnController resize failed`
- `PlayCommon: Failed to connect to server`
- `GoogleApiManager: Unknown calling package`
- `BluetoothPowerStatsCollector: error: 9`
- `ACDB-LOADER: Error`

Le script `monitor_logs.sh` les filtre automatiquement.

### Performance et Mémoire

Le script `monitor_logs.sh` est optimisé pour :
- ✅ Filtrer les logs inutiles
- ✅ Éviter les fuites mémoire
- ✅ Afficher uniquement les informations pertinentes
- ✅ Gérer proprement les octets nuls

---

## 🆘 Besoin d'Aide ?

Si le problème persiste :
1. Vérifiez les logs Flutter : `adb -s R5CT7263YJL logcat | grep -i flutter`
2. Testez la connectivité depuis le navigateur du téléphone
3. Vérifiez la configuration réseau (WiFi, firewall)
4. Rebuild l'APK avec la bonne IP

