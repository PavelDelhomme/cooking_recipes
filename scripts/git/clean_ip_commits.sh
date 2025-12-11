#!/bin/bash

# Script pour réécrire les messages de commit contenant l'IP
# Remplace l'IP par un texte générique sans casser l'historique

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT" || exit 1

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔒 NETTOYAGE SÉCURISÉ DE L'HISTORIQUE GIT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Ce script va:${NC}"
echo -e "  • Créer une backup complète du dépôt Git"
echo -e "  • Réécrire les messages de commit contenant l'IP"
echo -e "  • Remplacer l'IP par un texte générique"
echo -e "  • Conserver toute la structure de l'historique"
echo ""
echo -e "${RED}⚠️  Si vous avez déjà pushé sur GitHub:${NC}"
echo -e "  • Vous devrez faire un 'git push --force-with-lease'"
echo -e "  • Cela peut affecter les autres contributeurs !"
echo ""
echo -e "${BLUE}Voulez-vous continuer ?${NC}"
echo -e "${YELLOW}  o = Oui, réécrire l'historique${NC}"
echo -e "${YELLOW}  N = Non, annuler${NC}"
read -p "Votre choix (o/N): " confirm

if [[ ! "$confirm" =~ ^[oO]$ ]]; then
  echo -e "${YELLOW}Opération annulée${NC}"
  exit 0
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Étape 0: Vérification de l'état du dépôt${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

# Supprimer les anciens dossiers de backup s'ils existent
echo -e "${YELLOW}Nettoyage des anciens dossiers de backup...${NC}"
rm -rf .git-backup-* 2>/dev/null || true

# Retirer les dossiers de backup de l'index Git s'ils y sont
git rm --cached -r .git-backup-* 2>/dev/null || true

# Vérifier que le working directory est propre (en ignorant les dossiers de backup et le script lui-même)
# Les dossiers .git-backup-* sont créés par ce script et doivent être ignorés
# Le script scripts/git/clean_ip_commits.sh peut être modifié pendant le développement
CHANGES=$(git status --porcelain 2>/dev/null | \
  grep -vE "^(\?\?| M| D|AM|MM|AD) \.git-backup-" | \
  grep -vE "^ M scripts/git/clean_ip_commits\.sh$")

if [ -n "$CHANGES" ]; then
  echo -e "${RED}❌ Erreur: Vous avez des modifications non indexées${NC}"
  echo -e "${YELLOW}Git filter-branch nécessite un working directory propre${NC}"
  echo ""
  echo -e "${YELLOW}Modifications détectées:${NC}"
  echo "$CHANGES" | head -10
  echo ""
  echo -e "${YELLOW}Options:${NC}"
  echo -e "  1. Commiter vos modifications: ${BLUE}git add -A && git commit -m 'WIP'${NC}"
  echo -e "  2. Stasher vos modifications: ${BLUE}git stash${NC}"
  echo -e "  3. Annuler cette opération et revenir plus tard"
  echo ""
  exit 1
fi

echo -e "${GREEN}✓ Working directory propre${NC}"

# Obtenir la branche actuelle
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
echo -e "${GREEN}Branche actuelle: $CURRENT_BRANCH${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Étape 1: Création de la backup${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

# Créer un timestamp pour la backup
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$PROJECT_ROOT/.git-backup-$BACKUP_TIMESTAMP"

echo -e "${YELLOW}Création d'une backup complète du dépôt Git...${NC}"
echo -e "${YELLOW}Backup dans: $BACKUP_DIR${NC}"

# Créer une copie complète du dépôt Git
mkdir -p "$BACKUP_DIR"
cp -r .git "$BACKUP_DIR/" 2>/dev/null || {
  echo -e "${RED}❌ Erreur lors de la création de la backup${NC}"
  exit 1
}

# Créer aussi une branche de sauvegarde
BACKUP_BRANCH="backup-before-clean-$BACKUP_TIMESTAMP"
echo -e "${YELLOW}Création d'une branche de sauvegarde: $BACKUP_BRANCH${NC}"
git branch "$BACKUP_BRANCH" 2>/dev/null || {
  echo -e "${RED}❌ Impossible de créer la branche de sauvegarde${NC}"
  exit 1
}

echo -e "${GREEN}✓ Backup complète créée: $BACKUP_DIR${NC}"
echo -e "${GREEN}✓ Branche de sauvegarde créée: $BACKUP_BRANCH${NC}"

# Compter les commits à modifier
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Étape 2: Analyse des commits${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

COMMIT_COUNT=$(git log --oneline --all --grep="dev: configuration IP" 2>/dev/null | wc -l | tr -d ' ')
echo -e "${YELLOW}$COMMIT_COUNT commits contenant l'IP trouvés${NC}"

if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo -e "${GREEN}✓ Aucun commit à modifier${NC}"
  echo -e "${YELLOW}Suppression de la backup...${NC}"
  rm -rf "$BACKUP_DIR"
  git branch -D "$BACKUP_BRANCH" 2>/dev/null || true
  exit 0
fi

# Afficher quelques exemples
echo -e "${YELLOW}Exemples de commits à modifier:${NC}"
git log --oneline --all --grep="dev: configuration IP" | head -5 | while read line; do
  echo -e "  ${BLUE}$line${NC}"
done

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Étape 3: Réécriture des messages de commit${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}(Cela peut prendre quelques minutes)${NC}"
echo ""

# Créer un script temporaire pour le filter
# IMPORTANT: --msg-filter lit depuis stdin, pas via argument
FILTER_SCRIPT=$(mktemp)
cat > "$FILTER_SCRIPT" << 'EOF'
#!/bin/bash
# Lire le message de commit depuis stdin
COMMIT_MSG=$(cat)
if echo "$COMMIT_MSG" | grep -q "dev: configuration IP"; then
  # Remplacer "dev: configuration IP XXX.XXX.XXX.XXX - ..." par "dev: configuration mise à jour"
  echo "$COMMIT_MSG" | sed 's/dev: configuration IP.*/dev: configuration mise à jour/'
else
  # Garder le message tel quel
  echo "$COMMIT_MSG"
fi
EOF
chmod +x "$FILTER_SCRIPT"

# Utiliser git filter-branch avec le script temporaire
# Supprimer l'avertissement de git filter-branch
export FILTER_BRANCH_SQUELCH_WARNING=1

# --msg-filter lit depuis stdin, donc on passe juste le script
git filter-branch --force --msg-filter "$FILTER_SCRIPT" --prune-empty --tag-name-filter cat -- --all 2>&1 | grep -v "WARNING:" || true

FILTER_RESULT=${PIPESTATUS[0]}

# Nettoyer le script temporaire
rm -f "$FILTER_SCRIPT"

if [ $FILTER_RESULT -eq 0 ]; then
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ Réécriture terminée avec succès !${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  
  # Vérifier le résultat
  NEW_COMMIT_COUNT=$(git log --oneline --all --grep="dev: configuration IP" 2>/dev/null | wc -l | tr -d ' ')
  echo -e "${GREEN}Commits avec IP restants: $NEW_COMMIT_COUNT${NC}"
  
  if [ "$NEW_COMMIT_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les commits ont été réécrits${NC}"
  else
    echo -e "${YELLOW}⚠️  Il reste $NEW_COMMIT_COUNT commits avec IP${NC}"
  fi
  
  echo ""
  echo -e "${YELLOW}Exemples de commits modifiés:${NC}"
  git log --oneline --all --grep="dev: configuration mise à jour" | head -5 | while read line; do
    echo -e "  ${GREEN}$line${NC}"
  done
  
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}Prochaines étapes:${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "1. ${BLUE}Vérifiez l'historique:${NC}"
  echo -e "   ${YELLOW}git log --oneline${NC}"
  echo ""
  echo -e "2. ${BLUE}Si tout est correct, force push:${NC}"
  echo -e "   ${YELLOW}git push --force-with-lease origin $CURRENT_BRANCH${NC}"
  echo ""
  echo -e "3. ${BLUE}Si problème, restaurer depuis la backup:${NC}"
  echo -e "   ${YELLOW}rm -rf .git && cp -r $BACKUP_DIR/.git . && git reset --hard HEAD${NC}"
  echo -e "   ${YELLOW}OU restaurer la branche: git reset --hard $BACKUP_BRANCH${NC}"
  echo ""
  echo -e "4. ${BLUE}Nettoyer les refs backup (après vérification):${NC}"
  echo -e "   ${YELLOW}git for-each-ref --format='%(refname)' refs/original/ | xargs -n 1 git update-ref -d${NC}"
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}Backup sauvegardée dans:${NC}"
  echo -e "${YELLOW}  • Dossier: $BACKUP_DIR${NC}"
  echo -e "${YELLOW}  • Branche: $BACKUP_BRANCH${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
else
  echo ""
  echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${RED}❌ Erreur lors de la réécriture${NC}"
  echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${YELLOW}Restauration depuis la backup...${NC}"
  echo -e "${YELLOW}Option 1: Restaurer depuis le dossier backup${NC}"
  echo -e "  ${BLUE}rm -rf .git && cp -r $BACKUP_DIR/.git . && git reset --hard HEAD${NC}"
  echo ""
  echo -e "${YELLOW}Option 2: Restaurer depuis la branche backup${NC}"
  echo -e "  ${BLUE}git reset --hard $BACKUP_BRANCH${NC}"
  echo ""
  exit 1
fi
