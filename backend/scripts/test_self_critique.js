/**
 * Script de test simple pour le système d'autocritique
 * Usage: node backend/scripts/test_self_critique.js
 */

const MLSelfCritique = require('./ml_self_critique');
const fs = require('fs');
const path = require('path');

async function runTests() {
  console.log('🧪 ========================================');
  console.log('🧪 TESTS DU SYSTÈME D\'AUTOCRITIQUE');
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
      testsFailed++;
    }
  }

  async function asyncTest(name, fn) {
    try {
      await fn();
      console.log(`✅ ${name}`);
      testsPassed++;
    } catch (error) {
      console.error(`❌ ${name}: ${error.message}`);
      testsFailed++;
    }
  }

  // Test 1: Création de l'instance
  test('Création de l\'instance MLSelfCritique', () => {
    const critique = new MLSelfCritique();
    if (!critique) throw new Error('Instance non créée');
    if (!critique.db) throw new Error('Base de données non initialisée');
  });

  // Test 2: Comparaison avec aucun rapport précédent
  asyncTest('Comparaison sans rapport précédent', async () => {
    const critique = new MLSelfCritique();
    const testCritique = {
      overall: { accuracy: 75, totalTests: 100, totalFeedbacks: 50 },
      strengths: [],
      weaknesses: [],
    };
    const comparison = await critique.compareWithPreviousReports(testCritique);
    if (comparison.previousReportsCount !== 0) {
      throw new Error('Devrait retourner 0 rapport précédent');
    }
    if (comparison.trend !== 'stable') {
      throw new Error('Devrait être stable');
    }
  });

  // Test 3: Génération de défis
  test('Génération de défis pour dégradation', () => {
    const critique = new MLSelfCritique();
    const currentCritique = {
      overall: { accuracy: 65, totalTests: 100, totalFeedbacks: 50 },
      weaknesses: [{}, {}, {}, {}, {}, {}],
      details: {
        feedbackAnalysis: { pending: 15 },
      },
    };
    const comparison = {
      trend: 'degrading',
      metrics: {
        accuracy: { previous: 70, current: 65, change: -5 },
        weaknesses: { previous: 3, current: 6, change: 3 },
      },
      degradations: [
        { metric: 'Précision', change: '-5%', description: 'Dégradation', severity: 'haute' },
      ],
    };
    const challenges = critique.generateChallenges(currentCritique, comparison);
    if (challenges.length === 0) {
      throw new Error('Devrait générer au moins un défi');
    }
    const recoveryChallenge = challenges.find(c => c.id === 'trend_recovery');
    if (!recoveryChallenge) {
      throw new Error('Devrait générer un défi de récupération');
    }
  });

  // Test 4: Génération de défis pour stabilité
  test('Génération de défis pour stabilité', () => {
    const critique = new MLSelfCritique();
    const currentCritique = {
      overall: { accuracy: 75, totalTests: 100, totalFeedbacks: 50 },
      weaknesses: [],
    };
    const comparison = {
      trend: 'stable',
      metrics: {
        accuracy: { previous: 75, current: 75, change: 0 },
      },
    };
    const challenges = critique.generateChallenges(currentCritique, comparison);
    if (challenges.length === 0) {
      throw new Error('Devrait générer au moins un défi');
    }
  });

  // Test 5: Sauvegarde de résumé
  test('Sauvegarde de résumé', () => {
    const critique = new MLSelfCritique();
    const testSummaryDir = path.join(__dirname, '../data/test_ml_critiques');
    if (!fs.existsSync(testSummaryDir)) {
      fs.mkdirSync(testSummaryDir, { recursive: true });
    }
    critique.critiqueDir = testSummaryDir;

    const testCritique = {
      timestamp: new Date().toISOString(),
      overall: { accuracy: 75, totalTests: 100, totalFeedbacks: 50 },
      strengths: [{}, {}],
      weaknesses: [{}, {}, {}],
      recommendations: [{}],
      challenges: [{}, {}],
      comparison: {
        trend: 'improving',
        metrics: {
          accuracy: { change: 2.5 },
        },
      },
    };

    critique.saveSummary(testCritique);

    const summaryPath = path.join(testSummaryDir, 'summary_history.json');
    if (!fs.existsSync(summaryPath)) {
      throw new Error('Le fichier de résumé n\'a pas été créé');
    }

    const summaries = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
    if (summaries.length === 0) {
      throw new Error('Le résumé n\'a pas été sauvegardé');
    }

    // Nettoyer
    if (fs.existsSync(summaryPath)) {
      fs.unlinkSync(summaryPath);
    }
  });

  // Test 6: Logging
  test('Logging d\'activité', () => {
    const critique = new MLSelfCritique();
    const testLogsDir = path.join(__dirname, '../data/test_logs');
    if (!fs.existsSync(testLogsDir)) {
      fs.mkdirSync(testLogsDir, { recursive: true });
    }
    critique.logsDir = testLogsDir;

    critique.logActivity('info', 'Test log', { test: 'data' });

    const logFile = path.join(testLogsDir, `self_critique_${new Date().toISOString().split('T')[0]}.log`);
    if (!fs.existsSync(logFile)) {
      throw new Error('Le fichier de log n\'a pas été créé');
    }

    const logContent = fs.readFileSync(logFile, 'utf8');
    if (!logContent.includes('Test log')) {
      throw new Error('Le log ne contient pas le message attendu');
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
    console.log('🎉 Tous les tests sont passés !');
    process.exit(0);
  } else {
    console.log('⚠️  Certains tests ont échoué');
    process.exit(1);
  }
}

// Exécuter les tests
runTests().catch(error => {
  console.error('❌ Erreur lors de l\'exécution des tests:', error);
  process.exit(1);
});

