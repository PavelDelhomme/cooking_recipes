# 📱 Guide de Développement Android - Cooking Recipes

## 🚀 Installation et Lancement Rapide

### Méthode 1 : Installation Manuelle (Recommandée)

1. **Connectez votre téléphone via USB**
   ```bash
   adb devices
   ```
   Vous devriez voir : `R5CT7263YJL    device`

2. **Assurez-vous que le backend est démarré**
   ```bash
   make dev
   # Choisir l'option 2 (Web uniquement) pour démarrer juste le backend
   # OU laissez tourner le backend dans un autre terminal
   ```

3. **Build l'APK** (si pas déjà fait)
   ```bash
   cd frontend
   flutter build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=192.168.1.134
   ```

4. **Installez et lancez l'application**
   ```bash
   make install-android
   ```
   
   OU directement :
   ```bash
   bash scripts/install_android.sh
   ```

### Méthode 2 : Via `make dev` (Option 1 ou 3)

1. **Connectez votre téléphone via USB**

2. **Lancez le projet**
   ```bash
   make dev
   ```

3. **Choisissez l'option 1** (Android uniquement) ou **3** (Android + Web)

4. **Si l'application ne démarre pas automatiquement**, utilisez la méthode 1 ci-dessus

---

## 🔍 Diagnostic des Problèmes

### L'application ne se lance pas

#### 1. Vérifier que le device est connecté
```bash
adb devices
```
**Résultat attendu** : `R5CT7263YJL    device`

**Si vide** :
- Vérifiez que le câble USB est bien branché
- Vérifiez que le débogage USB est activé sur votre téléphone
- Autorisez l'ordinateur sur votre téléphone (popup de confirmation)

#### 2. Vérifier que Flutter détecte le device
```bash
flutter devices
```
**Résultat attendu** : Vous devriez voir votre device Samsung listé

**Si pas de device** :
- Vérifiez que `adb` est dans le PATH : `which adb`
- Redémarrez ADB : `adb kill-server && adb start-server`
- Vérifiez `flutter doctor` pour les problèmes de configuration

#### 3. Vérifier que l'APK est bien créé
```bash
ls -lh frontend/build/app/outputs/flutter-apk/app-debug.apk
```
**Résultat attendu** : Fichier de ~89MB

**Si l'APK n'existe pas** :
```bash
cd frontend
flutter build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=192.168.1.134
```

#### 4. Vérifier que l'application est installée
```bash
adb -s R5CT7263YJL shell pm list packages | grep cooking
```
**Résultat attendu** : `package:com.delhomme.cooking_recipe.cookingrecipe`

**Si pas installée** :
```bash
make install-android
```

#### 5. Vérifier les logs de l'application
```bash
adb -s R5CT7263YJL logcat | grep -i "flutter\|cooking\|error\|exception"
```

**Logs utiles** :
- Erreurs de compilation
- Erreurs de connexion API
- Crashes de l'application

#### 6. Lancer l'application manuellement
```bash
adb -s R5CT7263YJL shell am start -n com.delhomme.cooking_recipe.cookingrecipe/.MainActivity
```

---

## 🐛 Problèmes Courants

### Problème 1 : "Device not found"
**Solution** :
```bash
adb kill-server
adb start-server
adb devices
```

### Problème 2 : "Application not installed"
**Solution** :
```bash
# Désinstaller l'ancienne version
adb -s R5CT7263YJL uninstall com.delhomme.cooking_recipe.cookingrecipe

# Réinstaller
make install-android
```

### Problème 3 : "Cannot connect to API"
**Vérifications** :
1. Le backend est-il démarré ? `curl http://192.168.1.134:7272/health`
2. Le téléphone et le PC sont-ils sur le même réseau WiFi ?
3. L'IP dans l'APK est-elle correcte ? (192.168.1.134)

**Solution** :
- Rebuild l'APK avec la bonne IP :
  ```bash
  cd frontend
  flutter build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=192.168.1.134
  ```
- Réinstaller : `make install-android`

### Problème 4 : "Application crashes au démarrage"
**Vérifier les logs** :
```bash
adb -s R5CT7263YJL logcat -d | tail -100
```

**Causes possibles** :
- Erreur de compilation (vérifier avec `flutter analyze`)
- Problème de permissions Android
- Erreur de connexion API

---

## 📊 Commandes Utiles

### Voir les logs en temps réel
```bash
adb -s R5CT7263YJL logcat | grep -i flutter
```

### Voir tous les logs
```bash
adb -s R5CT7263YJL logcat
```

### Désinstaller l'application
```bash
adb -s R5CT7263YJL uninstall com.delhomme.cooking_recipe.cookingrecipe
```

### Redémarrer l'application
```bash
adb -s R5CT7263YJL shell am force-stop com.delhomme.cooking_recipe.cookingrecipe
adb -s R5CT7263YJL shell am start -n com.delhomme.cooking_recipe.cookingrecipe/.MainActivity
```

### Vérifier la version installée
```bash
adb -s R5CT7263YJL shell dumpsys package com.delhomme.cooking_recipe.cookingrecipe | grep versionName
```

### Prendre une capture d'écran
```bash
adb -s R5CT7263YJL shell screencap -p /sdcard/screenshot.png
adb -s R5CT7263YJL pull /sdcard/screenshot.png
```

---

## 🔧 Configuration

### IP de l'API

L'IP de l'API est passée lors du build via `--dart-define=DEV_API_IP=192.168.1.134`.

**Pour changer l'IP** :
1. Trouvez votre IP : `hostname -I | awk '{print $1}'`
2. Rebuild l'APK avec la nouvelle IP :
   ```bash
   cd frontend
   flutter build apk --debug --target-platform android-arm64 --dart-define=DEV_API_IP=VOTRE_IP
   ```
3. Réinstaller : `make install-android`

### Permissions Android

L'application nécessite :
- **Internet** : Pour accéder à l'API backend
- **Network State** : Pour vérifier la connexion réseau

Ces permissions sont déjà configurées dans `AndroidManifest.xml`.

---

## ✅ Checklist de Vérification

Avant de lancer l'application, vérifiez :

- [ ] Téléphone connecté via USB
- [ ] Débogage USB activé
- [ ] Device détecté par ADB : `adb devices`
- [ ] Device détecté par Flutter : `flutter devices`
- [ ] Backend démarré et accessible : `curl http://192.168.1.134:7272/health`
- [ ] APK buildé avec la bonne IP
- [ ] Téléphone et PC sur le même réseau WiFi (pour l'API)

---

## 🎯 Prochaines Étapes

Une fois l'application lancée :

1. **Testez la connexion** : Essayez de vous connecter/inscrire
2. **Vérifiez les logs** : Regardez s'il y a des erreurs
3. **Testez les fonctionnalités** : Recherche de recettes, favoris, etc.
4. **Notez les bugs** : Dans `TESTS_ET_AMELIORATIONS.md`

---

**Besoin d'aide ?** Vérifiez les logs avec `adb logcat` et cherchez les erreurs !

