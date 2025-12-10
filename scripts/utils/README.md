# Utilitaires

Scripts utilitaires généraux pour le projet.

## Scripts disponibles

### `memory_monitor.sh`
Monitoring de la mémoire pour détecter les fuites et analyser l'utilisation.

**Utilisation :**
```bash
make memory-report        # Rapport complet
make memory-monitor       # Monitoring en temps réel
make memory-leak         # Détection de fuites (5 min)
make memory-leak-extended # Détection étendue (15 min)
```

### `detect-language.sh`
Détection automatique de la langue d'un texte.

### `setup_libretranslate.sh`
Configuration et installation de LibreTranslate pour les traductions.

