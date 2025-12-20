/**
 * Tests pour le système d'autocritique
 */

const MLSelfCritique = require('../scripts/ml_self_critique');
const fs = require('fs');
const path = require('path');

describe('MLSelfCritique', () => {
  let selfCritique;
  const testCritiqueDir = path.join(__dirname, '../data/test_ml_critiques');
  const testLogsDir = path.join(__dirname, '../data/test_logs');

  beforeAll(() => {
    // Créer les dossiers de test
    if (!fs.existsSync(testCritiqueDir)) {
      fs.mkdirSync(testCritiqueDir, { recursive: true });
    }
    if (!fs.existsSync(testLogsDir)) {
      fs.mkdirSync(testLogsDir, { recursive: true });
    }
  });

  beforeEach(() => {
    selfCritique = new MLSelfCritique();
    // Utiliser les dossiers de test
    selfCritique.critiqueDir = testCritiqueDir;
    selfCritique.logsDir = testLogsDir;
  });

  afterEach(() => {
    // Nettoyer les fichiers de test
    if (fs.existsSync(testCritiqueDir)) {
      const files = fs.readdirSync(testCritiqueDir);
      files.forEach(file => {
        fs.unlinkSync(path.join(testCritiqueDir, file));
      });
    }
  });

  describe('generateCritique', () => {
    test('devrait générer un rapport d\'autocritique', async () => {
      const critique = await selfCritique.generateCritique();
      
      expect(critique).toBeDefined();
      expect(critique.timestamp).toBeDefined();
      expect(critique.overall).toBeDefined();
      expect(critique.strengths).toBeInstanceOf(Array);
      expect(critique.weaknesses).toBeInstanceOf(Array);
      expect(critique.recommendations).toBeInstanceOf(Array);
    }, 30000);

    test('devrait sauvegarder le rapport', async () => {
      await selfCritique.generateCritique();
      
      const latestPath = path.join(testCritiqueDir, 'latest_self_critique.json');
      expect(fs.existsSync(latestPath)).toBe(true);
      
      const report = JSON.parse(fs.readFileSync(latestPath, 'utf8'));
      expect(report).toBeDefined();
      expect(report.timestamp).toBeDefined();
    }, 30000);
  });

  describe('compareWithPreviousReports', () => {
    test('devrait retourner une comparaison vide si aucun rapport précédent', async () => {
      const currentCritique = {
        overall: { accuracy: 75, totalTests: 100, totalFeedbacks: 50 },
        strengths: [],
        weaknesses: [],
      };

      const comparison = await selfCritique.compareWithPreviousReports(currentCritique);
      
      expect(comparison).toBeDefined();
      expect(comparison.previousReportsCount).toBe(0);
      expect(comparison.trend).toBe('stable');
    });

    test('devrait comparer avec un rapport précédent', async () => {
      // Créer un rapport précédent
      const previousReport = {
        timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
        overall: { accuracy: 70, totalTests: 100, totalFeedbacks: 40 },
        strengths: [{ category: 'Test', description: 'Test' }],
        weaknesses: [{ category: 'Test', description: 'Test' }],
        translationPatterns: {
          errorPatterns: {
            commonMistakes: [
              { original: 'chicken', wrong: 'poulet entier', correct: 'poulet', frequency: 5 }
            ],
          },
        },
      };

      const previousPath = path.join(
        testCritiqueDir,
        `self_critique_${previousReport.timestamp.replace(/[:.]/g, '-')}.json`
      );
      fs.writeFileSync(previousPath, JSON.stringify(previousReport, null, 2));

      // Rapport actuel (amélioration)
      const currentCritique = {
        overall: { accuracy: 75, totalTests: 100, totalFeedbacks: 50 },
        strengths: [{ category: 'Test', description: 'Test' }, { category: 'Test2', description: 'Test2' }],
        weaknesses: [{ category: 'Test', description: 'Test' }],
        translationPatterns: {
          errorPatterns: {
            commonMistakes: [],
          },
        },
      };

      const comparison = await selfCritique.compareWithPreviousReports(currentCritique);
      
      expect(comparison.previousReportsCount).toBeGreaterThan(0);
      expect(comparison.metrics.accuracy.previous).toBe(70);
      expect(comparison.metrics.accuracy.current).toBe(75);
      expect(comparison.metrics.accuracy.change).toBe(5);
      expect(comparison.trend).toBe('improving');
      expect(comparison.improvements.length).toBeGreaterThan(0);
    });
  });

  describe('generateChallenges', () => {
    test('devrait générer des défis pour une tendance en dégradation', () => {
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

      const challenges = selfCritique.generateChallenges(currentCritique, comparison);
      
      expect(challenges.length).toBeGreaterThan(0);
      const recoveryChallenge = challenges.find(c => c.id === 'trend_recovery');
      expect(recoveryChallenge).toBeDefined();
      expect(recoveryChallenge.priority).toBe('haute');
    });

    test('devrait générer des défis pour une tendance stable', () => {
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

      const challenges = selfCritique.generateChallenges(currentCritique, comparison);
      
      expect(challenges.length).toBeGreaterThan(0);
      const improveChallenge = challenges.find(c => c.id === 'improve_accuracy');
      expect(improveChallenge).toBeDefined();
    });

    test('devrait générer un défi pour les erreurs persistantes', () => {
      const currentCritique = {
        overall: { accuracy: 75, totalTests: 100, totalFeedbacks: 50 },
        weaknesses: [],
      };

      const comparison = {
        trend: 'stable',
        degradations: [
          {
            metric: 'Erreurs persistantes',
            change: '3',
            description: '3 erreurs persistent',
            severity: 'haute',
            details: ['chicken → poulet entier', 'beef → boeuf entier'],
          },
        ],
      };

      const challenges = selfCritique.generateChallenges(currentCritique, comparison);
      
      const persistentChallenge = challenges.find(c => c.id === 'fix_persistent_errors');
      expect(persistentChallenge).toBeDefined();
      expect(persistentChallenge.priority).toBe('haute');
    });
  });

  describe('saveSummary', () => {
    test('devrait sauvegarder un résumé', () => {
      const critique = {
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

      selfCritique.saveSummary(critique);

      const summaryPath = path.join(testCritiqueDir, 'summary_history.json');
      expect(fs.existsSync(summaryPath)).toBe(true);

      const summaries = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
      expect(summaries.length).toBe(1);
      expect(summaries[0].accuracy).toBe(75);
      expect(summaries[0].trend).toBe('improving');
    });
  });

  describe('logActivity', () => {
    test('devrait enregistrer une activité dans les logs', () => {
      const logFile = path.join(testLogsDir, `self_critique_${new Date().toISOString().split('T')[0]}.log`);
      
      selfCritique.logActivity('info', 'Test log', { test: 'data' });

      expect(fs.existsSync(logFile)).toBe(true);
      
      const logContent = fs.readFileSync(logFile, 'utf8');
      expect(logContent).toContain('Test log');
      expect(logContent).toContain('test');
    });
  });

  describe('startContinuousCritique', () => {
    test('devrait démarrer le système en mode continu', async () => {
      await selfCritique.startContinuousCritique(1); // 1 minute pour les tests
      
      expect(selfCritique.isRunning).toBe(true);
      expect(selfCritique.intervalId).toBeDefined();
      
      // Arrêter après le test
      selfCritique.stopContinuousCritique();
    }, 10000);

    test('ne devrait pas démarrer deux fois', async () => {
      await selfCritique.startContinuousCritique(1);
      const firstInterval = selfCritique.intervalId;
      
      await selfCritique.startContinuousCritique(1);
      expect(selfCritique.intervalId).toBe(firstInterval);
      
      selfCritique.stopContinuousCritique();
    });
  });

  describe('stopContinuousCritique', () => {
    test('devrait arrêter le système', async () => {
      await selfCritique.startContinuousCritique(1);
      expect(selfCritique.isRunning).toBe(true);
      
      selfCritique.stopContinuousCritique();
      expect(selfCritique.isRunning).toBe(false);
      expect(selfCritique.intervalId).toBeNull();
    });
  });
});

