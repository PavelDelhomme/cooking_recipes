# Tests - Système d'Autocritique

## 📋 Tests disponibles

### Tests d'autocritique

```bash
npm run test:critique
```

Ou pour tous les tests :

```bash
npm test
```

## 🧪 Tests implémentés

### MLSelfCritique

- ✅ Génération de rapport d'autocritique
- ✅ Sauvegarde des rapports
- ✅ Comparaison avec les rapports précédents
- ✅ Génération de défis/challenges
- ✅ Sauvegarde des résumés
- ✅ Logging des activités
- ✅ Mode continu (start/stop)

## 📝 Notes

Les tests utilisent des dossiers temporaires pour ne pas affecter les données de production :
- `data/test_ml_critiques/` pour les rapports de test
- `data/test_logs/` pour les logs de test

Ces dossiers sont nettoyés après chaque test.

## ⚠️ Prérequis

Pour exécuter les tests, vous devez avoir installé les dépendances :

```bash
npm install
```

## 🔧 Configuration

Les tests utilisent Jest. Si Jest n'est pas installé, installez-le :

```bash
npm install --save-dev jest
```

