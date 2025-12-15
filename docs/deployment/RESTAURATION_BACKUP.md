# Guide de Restauration de la Sauvegarde Git

## 📦 Sauvegarde créée

Une sauvegarde complète de l'historique Git a été créée avant le nettoyage :
- **Fichier** : `../cooking-recipes-backup-20251203-172032.bundle`
- **Taille** : ~490KB
- **Date** : 3 décembre 2025, 17:20:32

## 🔄 Comment restaurer la sauvegarde

### Option 1 : Cloner la sauvegarde dans un nouveau répertoire

```bash
cd /home/pactivisme/Documents/Dev/Perso/cookingRecipes
git clone ../cooking-recipes-backup-20251203-172032.bundle cooking-recipes-restored
cd cooking-recipes-restored
```

### Option 2 : Restaurer dans le répertoire actuel (ATTENTION : écrase l'historique actuel)

```bash
cd /home/pactivisme/Documents/Dev/Perso/cookingRecipes/flutter_cooking_recipe
git remote remove origin  # Retirer le remote actuel
git clone ../cooking-recipes-backup-20251203-172032.bundle temp-restore
cd temp-restore
# Copier les fichiers si nécessaire
```

### Option 3 : Récupérer un commit spécifique depuis la sauvegarde

```bash
# Cloner la sauvegarde
git clone ../cooking-recipes-backup-20251203-172032.bundle temp-repo
cd temp-repo

# Lister les commits
git log --oneline

# Récupérer un fichier spécifique d'un commit
git show <commit-hash>:PORTAINER_DEPLOY.md > PORTAINER_DEPLOY.md
```

## ⚠️ Important

- La sauvegarde contient **tout l'historique** avant le nettoyage
- Le nettoyage a retiré `PORTAINER_DEPLOY.md` de l'historique Git
- Le fichier reste disponible localement mais n'est plus suivi par Git
- Les informations sensibles (IP, credentials) ont été nettoyées du fichier actuel

## 📍 Emplacement de la sauvegarde

```bash
ls -lh /home/pactivisme/Documents/Dev/Perso/cookingRecipes/cooking-recipes-backup-*.bundle
```

