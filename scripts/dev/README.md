# Scripts de Développement

Scripts pour le développement local et le débogage.

## Scripts disponibles

### `dev.sh`
Script principal de développement. Lance le backend Node.js et le frontend Flutter.

**Utilisation :**
```bash
make dev          # Lance tout (détecte automatiquement Android/Web)
make dev-web      # Force le mode Web uniquement
```

### `monitor_logs.sh`
Surveillance des logs en temps réel (backend, frontend, Android).

**Utilisation :**
```bash
make logs
```

### `install_android.sh`
Installation et lancement de l'application sur un appareil Android connecté.

**Utilisation :**
```bash
make install-android
```

### `logs_android.sh`
Affiche les logs Android filtrés (supprime le bruit système).

**Utilisation :**
```bash
make logs-android
```

