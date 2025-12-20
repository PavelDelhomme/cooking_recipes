/**
 * Script de test simplifié pour le système d'autocritique
 * Teste uniquement les fonctions de base sans dépendances lourdes
 * Usage: node backend/scripts/test_self_critique_simple.js
 */

const fs = require('fs');
const path = require('path');

console.log('🧪 ========================================');
console.log('🧪 TESTS SIMPLIFIÉS DU SYSTÈME D\'AUTOCRITIQUE');
console.log('🧪 ========================================\n');

let testsPassed = 0;
let testsFailed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`✅ ${name}`);
    testsPassed++;
  } catch (error) {
    console.error(`❌ ${name}: ${error.message}`);
    if (error.stack) {
      console.error(`   Stack: ${error.stack.split('\n')[1]}`);
    }
    testsFailed++;
  }
}

// Test 1: Vérifier que le fichier ml_self_critique.js existe
test('Fichier ml_self_critique.js existe', () => {
  const filePath = path.join(__dirname, 'ml_self_critique.js');
  if (!fs.existsSync(filePath)) {
    throw new Error(`Fichier non trouvé: ${filePath}`);
  }
});

// Test 2: Vérifier la structure du fichier
test('Structure du fichier ml_self_critique.js', () => {
  const filePath = path.join(__dirname, 'ml_self_critique.js');
  const content = fs.readFileSync(filePath, 'utf8');
  
  const requiredMethods = [
    'generateCritique',
    'compareWithPreviousReports',
    'generateChallenges',
    'saveCritique',
    'saveSummary',
    'startContinuousCritique',
    'stopContinuousCritique',
    'logActivity',
  ];

  for (const method of requiredMethods) {
    if (!content.includes(method)) {
      throw new Error(`Méthode ${method} non trouvée dans le fichier`);
    }
  }
});

// Test 3: Vérifier que les routes API existent
test('Routes API dans mlAdmin.js', () => {
  const filePath = path.join(__dirname, '../src/routes/mlAdmin.js');
  if (!fs.existsSync(filePath)) {
    throw new Error(`Fichier non trouvé: ${filePath}`);
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Vérifier que les routes critiques existent
  if (!content.includes('/critiques')) {
    throw new Error('Route /critiques non trouvée dans mlAdmin.js');
  }
  if (!content.includes('critiques/:id') && !content.includes('critiques/:')) {
    throw new Error('Route critiques/:id non trouvée dans mlAdmin.js');
  }
  if (!content.includes('summary/history')) {
    throw new Error('Route critiques/summary/history non trouvée dans mlAdmin.js');
  }
});

// Test 4: Vérifier que le service frontend a les méthodes
test('Service MLAdminService dans frontend', () => {
  const filePath = path.join(__dirname, '../../frontend/lib/services/ml_admin_service.dart');
  if (!fs.existsSync(filePath)) {
    throw new Error(`Fichier non trouvé: ${filePath}`);
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  const requiredMethods = [
    'getCritiques',
    'getCritique',
    'getCritiqueHistory',
  ];

  for (const method of requiredMethods) {
    if (!content.includes(method)) {
      throw new Error(`Méthode ${method} non trouvée dans ml_admin_service.dart`);
    }
  }
});

// Test 5: Vérifier que l'interface affiche les rapports (web uniquement)
test('Interface ML Admin avec onglet rapports (web uniquement)', () => {
  const filePath = path.join(__dirname, '../../frontend/lib/screens/ml_admin_screen.dart');
  if (!fs.existsSync(filePath)) {
    throw new Error(`Fichier non trouvé: ${filePath}`);
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  const requiredElements = [
    'kIsWeb',
    'Rapports Autocritique',
    '_buildCritiquesTab',
    '_loadCritiques',
  ];

  for (const element of requiredElements) {
    if (!content.includes(element)) {
      throw new Error(`Élément ${element} non trouvé dans ml_admin_screen.dart`);
    }
  }
});

// Test 6: Vérifier que les dossiers nécessaires sont documentés
test('Documentation Docker pour autocritique', () => {
  const filePath = path.join(__dirname, '../../docs/deployment/AUTOCRITIQUE_DOCKER.md');
  if (!fs.existsSync(filePath)) {
    throw new Error(`Documentation non trouvée: ${filePath}`);
  }
});

// Test 7: Vérifier la structure des dossiers de données
test('Structure des dossiers de données', () => {
  const dataDir = path.join(__dirname, '../data');
  if (!fs.existsSync(dataDir)) {
    // Créer le dossier si nécessaire
    fs.mkdirSync(dataDir, { recursive: true });
  }

  const requiredDirs = [
    'ml_critiques',
    'ml_reports',
  ];

  for (const dir of requiredDirs) {
    const dirPath = path.join(dataDir, dir);
    if (!fs.existsSync(dirPath)) {
      // Créer le dossier si nécessaire
      fs.mkdirSync(dirPath, { recursive: true });
      console.log(`   📁 Dossier créé: ${dirPath}`);
    }
  }
});

// Test 8: Vérifier que package.json a la commande de test
test('Commande test dans package.json', () => {
  const filePath = path.join(__dirname, '../package.json');
  if (!fs.existsSync(filePath)) {
    throw new Error(`Fichier non trouvé: ${filePath}`);
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  const packageJson = JSON.parse(content);
  
  if (!packageJson.scripts || !packageJson.scripts.test) {
    throw new Error('Commande test non trouvée dans package.json');
  }
});

// Résumé
console.log('\n📊 ========================================');
console.log('📊 RÉSUMÉ DES TESTS');
console.log('📊 ========================================');
console.log(`✅ Tests réussis: ${testsPassed}`);
console.log(`❌ Tests échoués: ${testsFailed}`);
console.log(`📈 Total: ${testsPassed + testsFailed}`);
console.log('');

if (testsFailed === 0) {
  console.log('🎉 Tous les tests de structure sont passés !');
  console.log('');
  console.log('ℹ️  Note: Pour exécuter les tests complets avec dépendances:');
  console.log('   1. Installer les dépendances: npm install');
  console.log('   2. Exécuter: npm test');
  process.exit(0);
} else {
  console.log('⚠️  Certains tests ont échoué');
  process.exit(1);
}

