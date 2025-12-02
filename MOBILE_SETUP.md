# Guide pour Tester sur Mobile

## Android

### Prérequis
- Flutter installé
- Android Studio avec SDK Android
- Un appareil Android ou un émulateur

### Étapes

1. **Vérifier les appareils disponibles**
```bash
cd frontend
flutter devices
```

2. **Lancer sur Android**
```bash
# Avec Makefile (depuis la racine)
make run-android

# Ou directement
cd frontend
flutter run -d android
```

3. **Build APK pour installation**
```bash
# Avec Makefile
make build-android

# Le APK sera dans: frontend/build/app/outputs/flutter-apk/app-release.apk
```

4. **Installer l'APK sur votre appareil**
```bash
# Via ADB (si appareil connecté)
adb install frontend/build/app/outputs/flutter-apk/app-release.apk

# Ou transférez le fichier APK sur votre téléphone et installez-le manuellement
```

## iOS (macOS uniquement)

### Prérequis
- macOS
- Xcode installé
- CocoaPods installé (`sudo gem install cocoapods`)
- Un appareil iOS ou le simulateur

### Étapes

1. **Installer les dépendances iOS**
```bash
cd frontend/ios
pod install
cd ../..
```

2. **Lancer sur iOS**
```bash
# Avec Makefile
make run-ios

# Ou directement
cd frontend
flutter run -d ios
```

3. **Build pour iOS**
```bash
# Avec Makefile
make build-ios

# Le build sera dans: frontend/build/ios/
```

## Configuration pour le Backend

### En développement local

Si vous testez sur un appareil physique, vous devez configurer l'URL de l'API pour pointer vers votre machine locale :

1. Trouvez l'IP de votre machine :
```bash
# Linux/Mac
ip addr show | grep "inet " | grep -v 127.0.0.1

# Ou
hostname -I
```

2. Modifiez `frontend/lib/services/auth_service.dart` :
```dart
// Remplacez localhost par l'IP de votre machine
static const String _baseUrl = 'http://192.168.1.XXX:4040/api';
```

3. Assurez-vous que le backend est accessible depuis votre réseau local :
```bash
# Dans docker-compose.yml, le backend doit être accessible
# Vérifiez que le port 4040 est bien exposé
```

### Avec Docker

Si vous utilisez Docker, l'API est accessible via l'IP de votre machine Docker :

```dart
// Pour Docker Desktop
static const String _baseUrl = 'http://host.docker.internal:4040/api';

// Ou l'IP de votre machine
static const String _baseUrl = 'http://192.168.1.XXX:4040/api';
```

## Dépannage

### Erreur "No devices found"
- Vérifiez que votre appareil est connecté : `adb devices` (Android) ou vérifiez dans Xcode (iOS)
- Activez le mode développeur sur Android
- Autorisez le débogage USB sur Android

### Erreur de connexion à l'API
- Vérifiez que le backend est démarré : `make status`
- Vérifiez que l'IP est correcte dans `auth_service.dart`
- Vérifiez les permissions réseau sur votre appareil

### Build échoue
- Vérifiez que toutes les dépendances sont installées
- Pour Android : `flutter doctor` et installez les composants manquants
- Pour iOS : `cd ios && pod install`

