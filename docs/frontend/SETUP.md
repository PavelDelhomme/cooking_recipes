# Guide d'installation et de configuration

## Installation de Flutter

Flutter a été installé dans `~/flutter/bin/flutter`.

### Ajouter Flutter au PATH de manière permanente

Pour que Flutter soit disponible dans tous vos terminaux, ajoutez cette ligne à votre fichier de configuration shell :

**Pour Zsh (recommandé sur Manjaro) :**
```bash
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Pour Bash :**
```bash
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Pour Fish :**
```bash
echo 'set -gx PATH $HOME/flutter/bin $PATH' >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

### Vérifier l'installation

```bash
flutter --version
flutter doctor
```

## Utilisation du Makefile

Le Makefile utilise automatiquement le chemin complet de Flutter (`~/flutter/bin/flutter`), donc vous n'avez pas besoin d'ajouter Flutter au PATH pour utiliser les commandes make.

### Commandes principales

```bash
# Installer les dépendances
make install

# Lancer l'application en mode web
make web

# Lancer les tests
make test

# Voir toutes les commandes
make help
```

## Première utilisation

1. Installez les dépendances :
```bash
make install
```

2. Lancez l'application :
```bash
make web
```

L'application devrait s'ouvrir dans Chrome automatiquement.

## Dépannage

### Flutter n'est pas trouvé

Si vous obtenez une erreur "flutter not found", utilisez le chemin complet :
```bash
~/flutter/bin/flutter --version
```

Ou ajoutez Flutter au PATH (voir section ci-dessus).

### Problèmes avec les dépendances

Si vous avez des problèmes avec les dépendances :
```bash
make clean
make install
```

### Vérifier la configuration Flutter

```bash
make doctor
```

Cela vous indiquera si des outils supplémentaires sont nécessaires (comme Chrome pour le développement web).

