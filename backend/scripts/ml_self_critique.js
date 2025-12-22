/**
 * Script d'autocritique de l'IA de traduction
 * Analyse les performances et génère un rapport indiquant ce qui fonctionne bien et ce qui ne fonctionne pas
 * Usage: node backend/scripts/ml_self_critique.js
 */

const mlTranslationEngine = require('../src/services/ml_translation_engine');
const { getDatabase } = require('../src/database/db');
const fs = require('fs');
const path = require('path');

class MLSelfCritique {
  constructor() {
    this.db = getDatabase();
    this.reportsDir = path.join(__dirname, '../data/ml_reports');
    this.critiqueDir = path.join(__dirname, '../data/ml_critiques');
    this.logsDir = path.join(__dirname, '../logs');
    this.isRunning = false;
    this.intervalId = null;
    this.lastCritiqueTime = null;
    
    // Créer les dossiers nécessaires
    if (!fs.existsSync(this.critiqueDir)) {
      fs.mkdirSync(this.critiqueDir, { recursive: true });
    }
    if (!fs.existsSync(this.logsDir)) {
      fs.mkdirSync(this.logsDir, { recursive: true });
    }
  }

  /**
   * Enregistre un log d'activité
   */
  logActivity(level, message, data = null) {
    const timestamp = new Date().toISOString();
    const logEntry = {
      timestamp,
      level,
      message,
      data,
    };

    // Afficher dans la console
    const prefix = level === 'error' ? '❌' : level === 'warn' ? '⚠️' : 'ℹ️';
    console.log(`${prefix} [${timestamp}] ${message}`);

    // Sauvegarder dans un fichier de log
    try {
      const logFile = path.join(this.logsDir, `self_critique_${new Date().toISOString().split('T')[0]}.log`);
      const logLine = JSON.stringify(logEntry) + '\n';
      fs.appendFileSync(logFile, logLine, 'utf8');
    } catch (error) {
      // Ignorer les erreurs de log (non bloquant)
      console.warn('⚠️ Erreur écriture log:', error.message);
    }
  }

  /**
   * Génère un rapport d'autocritique complet
   */
  async generateCritique() {
    const startTime = Date.now();
    this.logActivity('info', 'Début de l\'analyse d\'autocritique');

    console.log('🤖 ========================================');
    console.log('🤖 AUTOCRITIQUE DE L\'IA DE TRADUCTION');
    console.log('🤖 ========================================');
    console.log('');

    // 1. Charger les modèles
    console.log('📥 Chargement des modèles...');
    try {
      await mlTranslationEngine.loadModels();
      console.log('✅ Modèles chargés\n');
      this.logActivity('info', 'Modèles ML chargés avec succès');
    } catch (error) {
      this.logActivity('error', 'Erreur lors du chargement des modèles', { error: error.message });
      throw error;
    }

    // 2. Analyser les rapports de test
    console.log('📊 Analyse des rapports de test...');
    const testAnalysis = await this.analyzeTestReports();
    console.log('✅ Analyse des tests terminée\n');

    // 3. Analyser les feedbacks utilisateur
    console.log('📝 Analyse des feedbacks utilisateur...');
    const feedbackAnalysis = await this.analyzeFeedbacks();
    console.log('✅ Analyse des feedbacks terminée\n');

    // 4. Analyser les performances par type
    console.log('🔍 Analyse des performances par type...');
    const typeAnalysis = await this.analyzeByType();
    console.log('✅ Analyse par type terminée\n');

    // 5. Analyser les patterns de traduction
    console.log('🔬 Analyse approfondie des patterns de traduction...');
    const patternAnalysis = await this.analyzeTranslationPatterns();
    console.log('✅ Analyse des patterns terminée\n');

    // 6. Générer le rapport d'autocritique
    console.log('✍️  Génération du rapport d\'autocritique...');
    const critique = this.generateCritiqueReport(testAnalysis, feedbackAnalysis, typeAnalysis, patternAnalysis);
    
    // 6. Afficher le rapport
    this.displayCritique(critique);

    // 7. Comparer avec les rapports précédents et générer des défis
    console.log('🔄 Comparaison avec les rapports précédents...');
    const comparison = await this.compareWithPreviousReports(critique);
    critique.comparison = comparison;
    critique.challenges = this.generateChallenges(critique, comparison);
    console.log('✅ Comparaison terminée\n');

    // 8. Sauvegarder le rapport
    this.saveCritique(critique);

    // 9. Enregistrer les statistiques
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    this.logActivity('info', 'Analyse d\'autocritique terminée', {
      duration: `${duration}s`,
      strengths: critique.strengths.length,
      weaknesses: critique.weaknesses.length,
      recommendations: critique.recommendations.length,
      challenges: critique.challenges?.length || 0,
      accuracy: critique.overall.accuracy,
      trend: comparison?.trend || 'stable',
    });

    return critique;
  }

  /**
   * Analyse les rapports de test existants
   */
  async analyzeTestReports() {
    const analysis = {
      totalReports: 0,
      totalTests: 0,
      totalCorrect: 0,
      totalIncorrect: 0,
      totalMissing: 0,
      averageAccuracy: 0,
      accuracyTrend: [],
      errorsByType: {
        ingredients: { count: 0, examples: [] },
        instructions: { count: 0, examples: [] },
        units: { count: 0, examples: [] },
        recipeNames: { count: 0, examples: [] },
      },
      recentReports: [],
    };

    if (!fs.existsSync(this.reportsDir)) {
      return analysis;
    }

    const reportFiles = fs.readdirSync(this.reportsDir)
      .filter(file => file.startsWith('test_report_') && file.endsWith('.json'))
      .sort()
      .reverse(); // Plus récents en premier

    analysis.totalReports = reportFiles.length;

    for (const file of reportFiles.slice(0, 10)) { // Analyser les 10 derniers rapports
      try {
        const reportPath = path.join(this.reportsDir, file);
        const reportData = JSON.parse(fs.readFileSync(reportPath, 'utf8'));

        if (reportData.results) {
          const results = reportData.results;
          analysis.totalTests += results.total || 0;
          analysis.totalCorrect += results.correct || 0;
          analysis.totalIncorrect += results.incorrect || 0;
          analysis.totalMissing += results.missing || 0;

          if (results.accuracy !== undefined) {
            analysis.accuracyTrend.push({
              date: reportData.timestamp,
              accuracy: results.accuracy,
            });
          }

          // Analyser les erreurs par type
          if (results.details && Array.isArray(results.details)) {
            for (const detail of results.details) {
              // Erreurs d'ingrédients
              if (detail.ingredients) {
                for (const ing of detail.ingredients) {
                  if (!ing.correct && !ing.missing && ing.original) {
                    analysis.errorsByType.ingredients.count++;
                    if (analysis.errorsByType.ingredients.examples.length < 10) {
                      analysis.errorsByType.ingredients.examples.push({
                        original: ing.original,
                        translated: ing.translated,
                        expected: ing.expected,
                      });
                    }
                  }
                }
              }

              // Erreurs d'instructions
              if (detail.instructions) {
                for (const inst of detail.instructions) {
                  if (!inst.correct && !inst.missing && inst.original) {
                    analysis.errorsByType.instructions.count++;
                    if (analysis.errorsByType.instructions.examples.length < 10) {
                      analysis.errorsByType.instructions.examples.push({
                        original: inst.original.substring(0, 100),
                        translated: inst.translated,
                        expected: inst.expected,
                      });
                    }
                  }
                }
              }

              // Erreurs d'unités
              if (detail.units) {
                for (const unit of detail.units) {
                  if (!unit.correct && !unit.missing && unit.original) {
                    analysis.errorsByType.units.count++;
                    if (analysis.errorsByType.units.examples.length < 10) {
                      analysis.errorsByType.units.examples.push({
                        original: unit.original,
                        translated: unit.translated,
                        expected: unit.expected,
                      });
                    }
                  }
                }
              }
            }
          }

          analysis.recentReports.push({
            date: reportData.timestamp,
            accuracy: results.accuracy || 0,
            total: results.total || 0,
            correct: results.correct || 0,
            incorrect: results.incorrect || 0,
          });
        }
      } catch (error) {
        console.warn(`⚠️  Erreur lecture rapport ${file}:`, error.message);
      }
    }

    // Calculer la précision moyenne
    if (analysis.totalTests > 0) {
      analysis.averageAccuracy = (analysis.totalCorrect / analysis.totalTests) * 100;
    }

    return analysis;
  }

  /**
   * Analyse les feedbacks utilisateur pour identifier les patterns d'erreurs
   */
  async analyzeFeedbacks() {
    const analysis = {
      total: 0,
      approved: 0,
      pending: 0,
      rejected: 0,
      errorsByType: {
        ingredients: 0,
        instructions: 0,
        recipeNames: 0,
        units: 0,
        summaries: 0,
      },
      commonErrors: [],
      languages: { fr: 0, es: 0 },
      recentErrors: [],
    };

    return new Promise((resolve, reject) => {
      // Statistiques générales
      this.db.get(
        `SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN approved = 1 THEN 1 END) as approved,
          COUNT(CASE WHEN approved = 0 THEN 1 END) as pending,
          COUNT(CASE WHEN approved = -1 THEN 1 END) as rejected,
          COUNT(CASE WHEN type = 'ingredient' THEN 1 END) as ingredients,
          COUNT(CASE WHEN type = 'instruction' THEN 1 END) as instructions,
          COUNT(CASE WHEN type = 'recipeName' THEN 1 END) as recipeNames,
          COUNT(CASE WHEN type = 'unit' THEN 1 END) as units,
          COUNT(CASE WHEN type = 'summary' THEN 1 END) as summaries
         FROM translation_feedbacks`,
        [],
        (err, row) => {
          if (err) return reject(err);

          if (row) {
            analysis.total = row.total || 0;
            analysis.approved = row.approved || 0;
            analysis.pending = row.pending || 0;
            analysis.rejected = row.rejected || 0;
            analysis.errorsByType.ingredients = row.ingredients || 0;
            analysis.errorsByType.instructions = row.instructions || 0;
            analysis.errorsByType.recipeNames = row.recipeNames || 0;
            analysis.errorsByType.units = row.units || 0;
            analysis.errorsByType.summaries = row.summaries || 0;
          }

          // Erreurs les plus fréquentes (original_text qui apparaît souvent)
          this.db.all(
            `SELECT 
              original_text,
              type,
              target_language,
              COUNT(*) as error_count,
              GROUP_CONCAT(DISTINCT current_translation) as wrong_translations,
              GROUP_CONCAT(DISTINCT suggested_translation) as correct_translations
             FROM translation_feedbacks
             WHERE approved = 1 OR approved = 0
             GROUP BY original_text, type, target_language
             ORDER BY error_count DESC
             LIMIT 20`,
            [],
            (err, rows) => {
              if (!err && rows) {
                analysis.commonErrors = rows.map(row => ({
                  original: row.original_text,
                  type: row.type,
                  language: row.target_language,
                  count: row.error_count,
                  wrongTranslations: row.wrong_translations ? row.wrong_translations.split(',') : [],
                  correctTranslations: row.correct_translations ? row.correct_translations.split(',') : [],
                }));
              }

              // Langues les plus problématiques
              this.db.all(
                `SELECT 
                  target_language,
                  COUNT(*) as count
                 FROM translation_feedbacks
                 WHERE approved = 1 OR approved = 0
                 GROUP BY target_language`,
                [],
                (err, langRows) => {
                  if (!err && langRows) {
                    for (const row of langRows) {
                      if (row.target_language === 'fr' || row.target_language === 'es') {
                        analysis.languages[row.target_language] = row.count || 0;
                      }
                    }
                  }

                  // Erreurs récentes
                  this.db.all(
                    `SELECT 
                      original_text,
                      current_translation,
                      suggested_translation,
                      type,
                      target_language,
                      timestamp
                     FROM translation_feedbacks
                     WHERE (approved = 1 OR approved = 0)
                       AND suggested_translation IS NOT NULL
                     ORDER BY timestamp DESC
                     LIMIT 10`,
                    [],
                    (err, recentRows) => {
                      if (!err && recentRows) {
                        analysis.recentErrors = recentRows.map(row => ({
                          original: row.original_text,
                          wrong: row.current_translation,
                          correct: row.suggested_translation,
                          type: row.type,
                          language: row.target_language,
                          date: row.timestamp,
                        }));
                      }
                      resolve(analysis);
                    }
                  );
                }
              );
            }
          );
        }
      );
    });
  }

  /**
   * Analyse les performances par type de traduction
   */
  async analyzeByType() {
    const modelStats = mlTranslationEngine.getStats();
    const analysis = {
      types: {},
      strengths: [],
      weaknesses: [],
    };

    // Analyser chaque type
    for (const [type, langs] of Object.entries(modelStats)) {
      if (!langs || typeof langs !== 'object') continue;
      
      const totalTranslations = Object.values(langs).reduce((sum, count) => sum + (count || 0), 0);
      const frCount = langs.fr || 0;
      const esCount = langs.es || 0;

      analysis.types[type] = {
        total: totalTranslations,
        fr: frCount,
        es: esCount,
        coverage: totalTranslations > 0 ? 'good' : 'poor',
      };

      // Identifier les forces et faiblesses
      if (totalTranslations >= 100) {
        analysis.strengths.push({
          type,
          reason: `Bien couvert avec ${totalTranslations} traductions apprises`,
          count: totalTranslations,
        });
      } else if (totalTranslations < 50) {
        analysis.weaknesses.push({
          type,
          reason: `Peu couvert avec seulement ${totalTranslations} traductions apprises`,
          count: totalTranslations,
        });
      }
    }

    return analysis;
  }

  /**
   * Génère le rapport d'autocritique
   */
  generateCritiqueReport(testAnalysis, feedbackAnalysis, typeAnalysis, patternAnalysis = null) {
    const critique = {
      timestamp: new Date().toISOString(),
      overall: {
        accuracy: testAnalysis.averageAccuracy,
        totalTests: testAnalysis.totalTests,
        totalFeedbacks: feedbackAnalysis.total,
      },
      strengths: [],
      weaknesses: [],
      recommendations: [],
      challenges: [], // Sera rempli après la comparaison
      comparison: null, // Sera rempli après la comparaison
      translationPatterns: patternAnalysis || {},
      details: {
        testAnalysis,
        feedbackAnalysis,
        typeAnalysis,
        patternAnalysis,
      },
    };

    // ===== POINTS FORTS =====
    
    // 1. Précision élevée
    if (testAnalysis.averageAccuracy >= 80) {
      critique.strengths.push({
        category: 'Précision',
        description: `Excellente précision de ${testAnalysis.averageAccuracy.toFixed(1)}%`,
        evidence: `${testAnalysis.totalCorrect} traductions correctes sur ${testAnalysis.totalTests} testées`,
      });
    } else if (testAnalysis.averageAccuracy >= 60) {
      critique.strengths.push({
        category: 'Précision',
        description: `Précision correcte de ${testAnalysis.averageAccuracy.toFixed(1)}%`,
        evidence: `${testAnalysis.totalCorrect} traductions correctes sur ${testAnalysis.totalTests} testées`,
      });
    }

    // 2. Beaucoup de traductions apprises
    const totalLearned = Object.values(typeAnalysis.types).reduce((sum, t) => sum + t.total, 0);
    if (totalLearned >= 500) {
      critique.strengths.push({
        category: 'Couverture',
        description: `Large base de connaissances avec ${totalLearned} traductions apprises`,
        evidence: 'Le modèle a appris de nombreux exemples',
      });
    }

    // 3. Types bien couverts
    for (const strength of typeAnalysis.strengths) {
      critique.strengths.push({
        category: 'Couverture par type',
        description: `${strength.type} est bien couvert`,
        evidence: strength.reason,
      });
    }

    // 4. Beaucoup de feedbacks approuvés
    if (feedbackAnalysis.approved >= 100) {
      critique.strengths.push({
        category: 'Apprentissage',
        description: `${feedbackAnalysis.approved} feedbacks approuvés utilisés pour l'entraînement`,
        evidence: 'L\'IA apprend continuellement des corrections utilisateur',
      });
    }

    // ===== POINTS FAIBLES =====

    // 1. Précision faible
    if (testAnalysis.averageAccuracy < 50 && testAnalysis.totalTests > 0) {
      critique.weaknesses.push({
        category: 'Précision',
        description: `Précision faible de ${testAnalysis.averageAccuracy.toFixed(1)}%`,
        evidence: `${testAnalysis.totalIncorrect} erreurs sur ${testAnalysis.totalTests} tests`,
        impact: 'Les utilisateurs reçoivent des traductions incorrectes',
      });
    }

    // 2. Beaucoup de traductions manquantes
    if (testAnalysis.totalMissing > testAnalysis.totalCorrect) {
      critique.weaknesses.push({
        category: 'Couverture',
        description: `Beaucoup de traductions manquantes (${testAnalysis.totalMissing})`,
        evidence: 'L\'IA ne trouve pas de traduction pour de nombreux mots',
        impact: 'Fallback vers LibreTranslate trop fréquent',
      });
    }

    // 3. Types mal couverts
    for (const weakness of typeAnalysis.weaknesses) {
      critique.weaknesses.push({
        category: 'Couverture par type',
        description: `${weakness.type} est mal couvert`,
        evidence: weakness.reason,
        impact: `Les traductions de ${weakness.type} sont souvent incorrectes ou manquantes`,
      });
    }

    // 4. Erreurs fréquentes par type
    const errorTypes = Object.entries(testAnalysis.errorsByType)
      .filter(([_, data]) => data.count > 0)
      .sort(([_, a], [__, b]) => b.count - a.count);

    for (const [type, data] of errorTypes.slice(0, 3)) {
      critique.weaknesses.push({
        category: 'Erreurs fréquentes',
        description: `${data.count} erreurs détectées pour les ${type}`,
        evidence: `Exemples: ${data.examples.slice(0, 3).map(e => e.original).join(', ')}`,
        impact: `Les ${type} sont souvent mal traduits`,
      });
    }

    // 5. Beaucoup de feedbacks en attente
    if (feedbackAnalysis.pending > feedbackAnalysis.approved) {
      critique.weaknesses.push({
        category: 'Validation',
        description: `${feedbackAnalysis.pending} feedbacks en attente de validation`,
        evidence: `Seulement ${feedbackAnalysis.approved} approuvés`,
        impact: 'L\'IA n\'apprend pas des nouvelles corrections rapidement',
      });
    }

    // 6. Erreurs communes non corrigées
    if (feedbackAnalysis.commonErrors.length > 0) {
      const topError = feedbackAnalysis.commonErrors[0];
      critique.weaknesses.push({
        category: 'Erreurs récurrentes',
        description: `"${topError.original}" est souvent mal traduit (${topError.count} fois)`,
        evidence: `Erreur fréquente pour les ${topError.type} en ${topError.language}`,
        impact: 'Les utilisateurs doivent corriger la même erreur plusieurs fois',
      });
    }

    // 7. Patterns d'erreurs identifiés
    if (patternAnalysis && patternAnalysis.errorPatterns) {
      if (patternAnalysis.errorPatterns.commonMistakes.length > 0) {
        const topMistake = patternAnalysis.errorPatterns.commonMistakes[0];
        critique.weaknesses.push({
          category: 'Pattern d\'erreur',
          description: `Erreur fréquente: "${topMistake.original}" → "${topMistake.wrong}" (devrait être "${topMistake.correct}")`,
          evidence: `Apparaît ${topMistake.frequency} fois dans les feedbacks`,
          impact: 'L\'IA fait systématiquement la même erreur',
        });
      }

      // Erreurs spécifiques par langue
      for (const [lang, errors] of Object.entries(patternAnalysis.errorPatterns.languageSpecificErrors)) {
        if (errors.length > 0) {
          critique.weaknesses.push({
            category: `Erreurs en ${lang.toUpperCase()}`,
            description: `${errors.length} patterns d'erreurs spécifiques identifiés`,
            evidence: `Exemple: "${errors[0].original}" mal traduit`,
            impact: `Les traductions en ${lang} nécessitent des améliorations`,
          });
        }
      }
    }

    // ===== RECOMMANDATIONS =====

    // 1. Améliorer la précision
    if (testAnalysis.averageAccuracy < 70) {
      critique.recommendations.push({
        priority: 'haute',
        action: 'Réentraîner le modèle avec plus de données',
        reason: `Précision actuelle: ${testAnalysis.averageAccuracy.toFixed(1)}%`,
        steps: [
          'Valider les feedbacks en attente',
          'Exécuter: make retrain-ml',
          'Ajouter plus de traductions de référence',
        ],
      });
    }

    // 2. Réduire les traductions manquantes
    if (testAnalysis.totalMissing > 100) {
      critique.recommendations.push({
        priority: 'haute',
        action: 'Enrichir le modèle avec plus de traductions',
        reason: `${testAnalysis.totalMissing} traductions manquantes détectées`,
        steps: [
          'Ajouter des traductions pour les mots les plus fréquents',
          'Valider les feedbacks utilisateur',
          'Utiliser les dictionnaires culinaires existants',
        ],
      });
    }

    // 3. Corriger les erreurs fréquentes
    if (errorTypes.length > 0) {
      const topErrorType = errorTypes[0];
      critique.recommendations.push({
        priority: 'moyenne',
        action: `Améliorer les traductions de ${topErrorType[0]}`,
        reason: `${topErrorType[1].count} erreurs détectées`,
        steps: [
          `Analyser les exemples d'erreurs pour ${topErrorType[0]}`,
          'Ajouter des traductions correctes au modèle',
          'Réentraîner le modèle',
        ],
      });
    }

    // 4. Valider les feedbacks en attente
    if (feedbackAnalysis.pending > 50) {
      critique.recommendations.push({
        priority: 'moyenne',
        action: 'Valider les feedbacks en attente',
        reason: `${feedbackAnalysis.pending} feedbacks non utilisés pour l'entraînement`,
        steps: [
          'Exécuter: make validate-ml-auto',
          'Valider manuellement les feedbacks importants',
          'Rejeter les feedbacks incorrects',
        ],
      });
    }

    // 5. Améliorer les types mal couverts
    for (const weakness of typeAnalysis.weaknesses) {
      critique.recommendations.push({
        priority: 'basse',
        action: `Enrichir le modèle pour ${weakness.type}`,
        reason: `Seulement ${weakness.count} traductions apprises`,
        steps: [
          `Ajouter plus de feedbacks pour ${weakness.type}`,
          'Utiliser des sources de données externes',
          'Réentraîner le modèle',
        ],
      });
    }

    // 6. Corriger les patterns d'erreurs identifiés
    if (patternAnalysis && patternAnalysis.improvementSuggestions.length > 0) {
      for (const suggestion of patternAnalysis.improvementSuggestions) {
        critique.recommendations.push({
          priority: suggestion.priority,
          action: suggestion.suggestion,
          reason: `${suggestion.count} erreurs détectées pour ce type`,
          steps: [
            'Analyser les exemples d\'erreurs dans le rapport',
            'Ajouter les traductions correctes au modèle',
            'Réentraîner le modèle avec les corrections',
          ],
        });
      }
    }

    return critique;
  }

  /**
   * Affiche le rapport d'autocritique
   */
  displayCritique(critique) {
    console.log('\n');
    console.log('🤖 ========================================');
    console.log('🤖 RAPPORT D\'AUTOCRITIQUE');
    console.log('🤖 ========================================');
    console.log('');

    // Vue d'ensemble
    console.log('📊 VUE D\'ENSEMBLE');
    console.log('─────────────────────────────────────────');
    console.log(`Précision moyenne: ${critique.overall.accuracy.toFixed(1)}%`);
    console.log(`Total de tests: ${critique.overall.totalTests}`);
    console.log(`Total de feedbacks: ${critique.overall.totalFeedbacks}`);
    console.log('');

    // Points forts
    console.log('✅ POINTS FORTS');
    console.log('─────────────────────────────────────────');
    if (critique.strengths.length === 0) {
      console.log('Aucun point fort identifié');
    } else {
      critique.strengths.forEach((strength, i) => {
        console.log(`\n${i + 1}. [${strength.category}] ${strength.description}`);
        console.log(`   → ${strength.evidence}`);
      });
    }
    console.log('');

    // Points faibles
    console.log('❌ POINTS FAIBLES');
    console.log('─────────────────────────────────────────');
    if (critique.weaknesses.length === 0) {
      console.log('Aucun point faible identifié');
    } else {
      critique.weaknesses.forEach((weakness, i) => {
        console.log(`\n${i + 1}. [${weakness.category}] ${weakness.description}`);
        console.log(`   → ${weakness.evidence}`);
        if (weakness.impact) {
          console.log(`   ⚠️  Impact: ${weakness.impact}`);
        }
      });
    }
    console.log('');

    // Recommandations
    console.log('💡 RECOMMANDATIONS');
    console.log('─────────────────────────────────────────');
    if (critique.recommendations.length === 0) {
      console.log('Aucune recommandation');
    } else {
      // Trier par priorité
      const byPriority = {
        haute: critique.recommendations.filter(r => r.priority === 'haute'),
        moyenne: critique.recommendations.filter(r => r.priority === 'moyenne'),
        basse: critique.recommendations.filter(r => r.priority === 'basse'),
      };

      let num = 1;
      for (const priority of ['haute', 'moyenne', 'basse']) {
        if (byPriority[priority].length > 0) {
          console.log(`\n📌 Priorité ${priority.toUpperCase()}:`);
          for (const rec of byPriority[priority]) {
            console.log(`\n${num}. ${rec.action}`);
            console.log(`   Raison: ${rec.reason}`);
            console.log(`   Étapes:`);
            rec.steps.forEach(step => console.log(`     - ${step}`));
            num++;
          }
        }
      }
    }
    console.log('');

    // Patterns de traduction identifiés
    if (critique.translationPatterns && Object.keys(critique.translationPatterns).length > 0) {
      console.log('🔬 PATTERNS DE TRADUCTION IDENTIFIÉS');
      console.log('─────────────────────────────────────────');
      
      if (critique.translationPatterns.errorPatterns) {
        const patterns = critique.translationPatterns.errorPatterns;
        
        if (patterns.commonMistakes && patterns.commonMistakes.length > 0) {
          console.log(`\n❌ Erreurs les plus fréquentes (${patterns.commonMistakes.length}):`);
          patterns.commonMistakes.slice(0, 5).forEach((mistake, i) => {
            console.log(`   ${i + 1}. "${mistake.original}" → "${mistake.wrong}" (devrait être "${mistake.correct}") [${mistake.frequency}x]`);
          });
        }

        if (patterns.languageSpecificErrors) {
          for (const [lang, errors] of Object.entries(patterns.languageSpecificErrors)) {
            if (errors.length > 0) {
              console.log(`\n🌐 Erreurs spécifiques en ${lang.toUpperCase()} (${errors.length}):`);
              errors.slice(0, 3).forEach((error, i) => {
                console.log(`   ${i + 1}. "${error.original}" → "${error.wrong}" (devrait être "${error.correct}") [${error.frequency}x]`);
              });
            }
          }
        }
      }

      if (critique.translationPatterns.improvementSuggestions && critique.translationPatterns.improvementSuggestions.length > 0) {
        console.log(`\n💡 Suggestions d'amélioration (${critique.translationPatterns.improvementSuggestions.length}):`);
        critique.translationPatterns.improvementSuggestions.forEach((suggestion, i) => {
          console.log(`   ${i + 1}. [${suggestion.priority}] ${suggestion.suggestion} (${suggestion.count} erreurs)`);
        });
      }
    }
    console.log('');

    // Comparaison avec les rapports précédents
    if (critique.comparison) {
      console.log('📊 COMPARAISON AVEC LES RAPPORTS PRÉCÉDENTS');
      console.log('─────────────────────────────────────────');
      const comp = critique.comparison;
      
      console.log(`Rapports précédents analysés: ${comp.previousReportsCount}`);
      console.log(`Tendance: ${comp.trend === 'improving' ? '📈 Amélioration' : comp.trend === 'degrading' ? '📉 Dégradation' : '➡️ Stable'}`);
      console.log('');

      if (comp.metrics.accuracy.previous !== null) {
        const accChange = comp.metrics.accuracy.change;
        const accIcon = accChange > 0 ? '📈' : accChange < 0 ? '📉' : '➡️';
        console.log(`${accIcon} Précision: ${comp.metrics.accuracy.previous.toFixed(1)}% → ${comp.metrics.accuracy.current.toFixed(1)}% (${accChange > 0 ? '+' : ''}${accChange.toFixed(1)}%)`);
      }

      if (comp.metrics.weaknesses.previous !== null) {
        const weakChange = comp.metrics.weaknesses.change;
        const weakIcon = weakChange < 0 ? '✅' : weakChange > 0 ? '⚠️' : '➡️';
        console.log(`${weakIcon} Points faibles: ${comp.metrics.weaknesses.previous} → ${comp.metrics.weaknesses.current} (${weakChange > 0 ? '+' : ''}${weakChange})`);
      }

      if (comp.improvements.length > 0) {
        console.log(`\n✅ Améliorations (${comp.improvements.length}):`);
        comp.improvements.forEach((imp, i) => {
          console.log(`   ${i + 1}. ${imp.metric}: ${imp.change} - ${imp.description}`);
        });
      }

      if (comp.degradations.length > 0) {
        console.log(`\n⚠️  Dégradations (${comp.degradations.length}):`);
        comp.degradations.forEach((deg, i) => {
          const severityIcon = deg.severity === 'haute' ? '🔴' : '🟡';
          console.log(`   ${i + 1}. ${severityIcon} ${deg.metric}: ${deg.change} - ${deg.description}`);
          if (deg.details && deg.details.length > 0) {
            deg.details.forEach(detail => {
              console.log(`      → ${detail}`);
            });
          }
        });
      }
      console.log('');
    }

    // Défis et challenges
    if (critique.challenges && critique.challenges.length > 0) {
      console.log('🎯 DÉFIS ET CHALLENGES');
      console.log('─────────────────────────────────────────');
      critique.challenges.forEach((challenge, i) => {
        const priorityIcon = challenge.priority === 'haute' ? '🔴' : challenge.priority === 'moyenne' ? '🟡' : '🟢';
        console.log(`\n${i + 1}. ${priorityIcon} ${challenge.title}`);
        console.log(`   ${challenge.description}`);
        console.log(`   📅 Deadline: ${challenge.deadline}`);
        console.log(`   📋 Actions:`);
        challenge.actions.forEach(action => {
          console.log(`      - ${action}`);
        });
        if (challenge.details && challenge.details.length > 0) {
          console.log(`   📝 Détails:`);
          challenge.details.forEach(detail => {
            console.log(`      → ${detail}`);
          });
        }
      });
      console.log('');
    }
  }

  /**
   * Sauvegarde le rapport d'autocritique
   */
  saveCritique(critique) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const critiquePath = path.join(this.critiqueDir, `self_critique_${timestamp}.json`);

    // Ajouter des métadonnées pour le suivi
    critique.metadata = {
      version: '2.0',
      generatedAt: new Date().toISOString(),
      reportId: timestamp,
      previousReportsCount: critique.comparison?.previousReportsCount || 0,
    };

    fs.writeFileSync(critiquePath, JSON.stringify(critique, null, 2), 'utf8');
    console.log(`💾 Rapport d'autocritique sauvegardé: ${critiquePath}`);

    // Sauvegarder aussi comme "latest"
    const latestPath = path.join(this.critiqueDir, 'latest_self_critique.json');
    fs.writeFileSync(latestPath, JSON.stringify(critique, null, 2), 'utf8');
    console.log(`💾 Rapport d'autocritique (latest): ${latestPath}`);

    // Sauvegarder un résumé pour le suivi dans le temps
    this.saveSummary(critique);
  }

  /**
   * Sauvegarde un résumé pour le suivi dans le temps
   */
  saveSummary(critique) {
    const summaryPath = path.join(this.critiqueDir, 'summary_history.json');
    
    let summaries = [];
    if (fs.existsSync(summaryPath)) {
      try {
        summaries = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
      } catch (e) {
        summaries = [];
      }
    }

    const summary = {
      timestamp: critique.timestamp,
      accuracy: critique.overall.accuracy,
      totalTests: critique.overall.totalTests,
      totalFeedbacks: critique.overall.totalFeedbacks,
      strengthsCount: critique.strengths.length,
      weaknessesCount: critique.weaknesses.length,
      recommendationsCount: critique.recommendations.length,
      challengesCount: critique.challenges?.length || 0,
      trend: critique.comparison?.trend || 'unknown',
      accuracyChange: critique.comparison?.metrics?.accuracy?.change || 0,
    };

    summaries.push(summary);

    // Garder seulement les 100 derniers résumés
    if (summaries.length > 100) {
      summaries = summaries.slice(-100);
    }

    fs.writeFileSync(summaryPath, JSON.stringify(summaries, null, 2), 'utf8');
    this.logActivity('info', 'Résumé sauvegardé pour le suivi', { 
      totalSummaries: summaries.length,
      accuracy: summary.accuracy,
      trend: summary.trend,
    });
  }

  /**
   * Démarre le système d'autocritique en arrière-plan
   * @param {number} intervalMinutes - Intervalle en minutes entre chaque analyse (défaut: 60)
   */
  async startContinuousCritique(intervalMinutes = 60, onCompleteCallback = null) {
    if (this.isRunning) {
      this.logActivity('warn', 'Le système d\'autocritique est déjà en cours d\'exécution');
      return;
    }

    this.isRunning = true;
    this.logActivity('info', `Démarrage du système d'autocritique continu`, { intervalMinutes });
    console.log(`🤖 Démarrage du système d'autocritique continu (intervalle: ${intervalMinutes} min)`);
    
    // Générer un premier rapport immédiatement
    try {
      await this.generateCritique();
      this.lastCritiqueTime = new Date();
      this.logActivity('info', 'Première analyse d\'autocritique terminée avec succès');
      
      // Exécuter le callback si fourni
      if (onCompleteCallback && typeof onCompleteCallback === 'function') {
        try {
          await onCompleteCallback();
        } catch (error) {
          console.warn('⚠️ Erreur callback après autocritique:', error.message);
        }
      }
    } catch (error) {
      this.logActivity('error', 'Erreur lors de la première autocritique', { error: error.message });
      console.error('❌ Erreur lors de la première autocritique:', error);
    }

    // Puis toutes les X minutes
    const intervalMs = intervalMinutes * 60 * 1000;
    this.intervalId = setInterval(async () => {
      if (!this.isRunning) return;
      
      try {
        const now = new Date().toLocaleString('fr-FR');
        this.logActivity('info', `Démarrage d'une nouvelle analyse d'autocritique`, { time: now });
        console.log(`\n🔄 Nouvelle analyse d'autocritique (${now})...`);
        await this.generateCritique();
        this.lastCritiqueTime = new Date();
        
        // Exécuter le callback si fourni
        if (onCompleteCallback && typeof onCompleteCallback === 'function') {
          try {
            await onCompleteCallback();
          } catch (error) {
            console.warn('⚠️ Erreur callback après autocritique:', error.message);
          }
        }
        console.log(`✅ Analyse d'autocritique terminée. Prochaine analyse dans ${intervalMinutes} minutes.`);
      } catch (error) {
        this.logActivity('error', 'Erreur lors de l\'autocritique continue', { error: error.message });
        console.error('❌ Erreur lors de l\'autocritique continue:', error);
      }
    }, intervalMs);

    console.log(`✅ Système d'autocritique démarré. Prochaine analyse dans ${intervalMinutes} minutes.`);
  }

  /**
   * Arrête le système d'autocritique
   */
  stopContinuousCritique() {
    if (!this.isRunning) {
      this.logActivity('warn', 'Tentative d\'arrêt alors que le système n\'est pas en cours d\'exécution');
      return;
    }

    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }

    this.isRunning = false;
    this.logActivity('info', 'Système d\'autocritique arrêté', { 
      lastCritiqueTime: this.lastCritiqueTime ? this.lastCritiqueTime.toISOString() : null 
    });
    console.log('🛑 Système d\'autocritique arrêté');
  }

  /**
   * Compare le rapport actuel avec les rapports précédents
   */
  async compareWithPreviousReports(currentCritique) {
    const comparison = {
      previousReportsCount: 0,
      trend: 'stable', // 'improving', 'degrading', 'stable'
      accuracyChange: 0,
      feedbacksChange: 0,
      improvements: [],
      degradations: [],
      metrics: {
        accuracy: { current: currentCritique.overall.accuracy, previous: null, change: 0 },
        totalFeedbacks: { current: currentCritique.overall.totalFeedbacks, previous: null, change: 0 },
        strengths: { current: currentCritique.strengths.length, previous: null, change: 0 },
        weaknesses: { current: currentCritique.weaknesses.length, previous: null, change: 0 },
      },
    };

    if (!fs.existsSync(this.critiqueDir)) {
      return comparison;
    }

    // Charger les rapports précédents (derniers 5)
    const reportFiles = fs.readdirSync(this.critiqueDir)
      .filter(file => file.startsWith('self_critique_') && file.endsWith('.json') && file !== 'latest_self_critique.json')
      .sort()
      .reverse()
      .slice(0, 5); // Derniers 5 rapports

    comparison.previousReportsCount = reportFiles.length;

    if (reportFiles.length === 0) {
      return comparison;
    }

    // Charger le rapport le plus récent (avant celui-ci)
    try {
      const previousReportPath = path.join(this.critiqueDir, reportFiles[0]);
      const previousReport = JSON.parse(fs.readFileSync(previousReportPath, 'utf8'));

      // Comparer les métriques
      comparison.metrics.accuracy.previous = previousReport.overall?.accuracy || 0;
      comparison.metrics.accuracy.change = currentCritique.overall.accuracy - comparison.metrics.accuracy.previous;

      comparison.metrics.totalFeedbacks.previous = previousReport.overall?.totalFeedbacks || 0;
      comparison.metrics.totalFeedbacks.change = currentCritique.overall.totalFeedbacks - comparison.metrics.totalFeedbacks.previous;

      comparison.metrics.strengths.previous = previousReport.strengths?.length || 0;
      comparison.metrics.strengths.change = currentCritique.strengths.length - comparison.metrics.strengths.previous;

      comparison.metrics.weaknesses.previous = previousReport.weaknesses?.length || 0;
      comparison.metrics.weaknesses.change = currentCritique.weaknesses.length - comparison.metrics.weaknesses.previous;

      // Identifier les tendances
      const accuracyChange = comparison.metrics.accuracy.change;
      const weaknessesChange = comparison.metrics.weaknesses.change;
      const strengthsChange = comparison.metrics.strengths.change;

      if (accuracyChange > 2 && weaknessesChange < 0) {
        comparison.trend = 'improving';
      } else if (accuracyChange < -2 || weaknessesChange > 2) {
        comparison.trend = 'degrading';
      } else {
        comparison.trend = 'stable';
      }

      // Identifier les améliorations
      if (accuracyChange > 1) {
        comparison.improvements.push({
          metric: 'Précision',
          change: `+${accuracyChange.toFixed(1)}%`,
          description: `La précision a augmenté de ${accuracyChange.toFixed(1)}%`,
        });
      }

      if (weaknessesChange < 0) {
        comparison.improvements.push({
          metric: 'Points faibles',
          change: `${weaknessesChange}`,
          description: `Réduction de ${Math.abs(weaknessesChange)} point(s) faible(s)`,
        });
      }

      if (strengthsChange > 0) {
        comparison.improvements.push({
          metric: 'Points forts',
          change: `+${strengthsChange}`,
          description: `Ajout de ${strengthsChange} point(s) fort(s)`,
        });
      }

      // Identifier les dégradations
      if (accuracyChange < -1) {
        comparison.degradations.push({
          metric: 'Précision',
          change: `${accuracyChange.toFixed(1)}%`,
          description: `La précision a diminué de ${Math.abs(accuracyChange).toFixed(1)}%`,
          severity: Math.abs(accuracyChange) > 5 ? 'haute' : 'moyenne',
        });
      }

      if (weaknessesChange > 0) {
        comparison.degradations.push({
          metric: 'Points faibles',
          change: `+${weaknessesChange}`,
          description: `Augmentation de ${weaknessesChange} point(s) faible(s)`,
          severity: weaknessesChange > 2 ? 'haute' : 'moyenne',
        });
      }

      if (strengthsChange < 0) {
        comparison.degradations.push({
          metric: 'Points forts',
          change: `${strengthsChange}`,
          description: `Réduction de ${Math.abs(strengthsChange)} point(s) fort(s)`,
          severity: 'moyenne',
        });
      }

      // Comparer les erreurs récurrentes
      const currentErrors = currentCritique.translationPatterns?.errorPatterns?.commonMistakes || [];
      const previousErrors = previousReport.translationPatterns?.errorPatterns?.commonMistakes || [];

      // Erreurs qui persistent
      const persistentErrors = currentErrors.filter(current => 
        previousErrors.some(prev => 
          prev.original === current.original && 
          prev.wrong === current.wrong &&
          current.frequency >= prev.frequency
        )
      );

      if (persistentErrors.length > 0) {
        comparison.degradations.push({
          metric: 'Erreurs persistantes',
          change: `${persistentErrors.length}`,
          description: `${persistentErrors.length} erreur(s) persistent depuis le dernier rapport`,
          severity: 'haute',
          details: persistentErrors.slice(0, 3).map(e => `${e.original} → ${e.wrong}`),
        });
      }

      // Nouvelles erreurs
      const newErrors = currentErrors.filter(current => 
        !previousErrors.some(prev => 
          prev.original === current.original && prev.wrong === current.wrong
        )
      );

      if (newErrors.length > 0) {
        comparison.degradations.push({
          metric: 'Nouvelles erreurs',
          change: `${newErrors.length}`,
          description: `${newErrors.length} nouvelle(s) erreur(s) détectée(s)`,
          severity: 'moyenne',
          details: newErrors.slice(0, 3).map(e => `${e.original} → ${e.wrong}`),
        });
      }

      // Erreurs corrigées
      const fixedErrors = previousErrors.filter(prev => 
        !currentErrors.some(current => 
          current.original === prev.original && current.wrong === prev.wrong
        )
      );

      if (fixedErrors.length > 0) {
        comparison.improvements.push({
          metric: 'Erreurs corrigées',
          change: `${fixedErrors.length}`,
          description: `${fixedErrors.length} erreur(s) corrigée(s) depuis le dernier rapport`,
          details: fixedErrors.slice(0, 3).map(e => `${e.original} → ${e.wrong}`),
        });
      }

    } catch (error) {
      this.logActivity('warn', 'Erreur lors de la comparaison avec les rapports précédents', { error: error.message });
    }

    return comparison;
  }

  /**
   * Génère des défis/challenges basés sur la comparaison
   */
  generateChallenges(currentCritique, comparison) {
    const challenges = [];

    // Défi basé sur la tendance
    if (comparison.trend === 'degrading') {
      challenges.push({
        id: 'trend_recovery',
        title: '🚨 Récupération de la performance',
        description: 'Les performances se dégradent. Objectif : retrouver le niveau précédent.',
        target: {
          accuracy: comparison.metrics.accuracy.previous,
          weaknesses: comparison.metrics.weaknesses.previous,
        },
        current: {
          accuracy: currentCritique.overall.accuracy,
          weaknesses: currentCritique.weaknesses.length,
        },
        priority: 'haute',
        deadline: 'Prochain rapport (2h)',
        actions: [
          'Valider les feedbacks en attente',
          'Réentraîner le modèle ML',
          'Corriger les erreurs persistantes identifiées',
        ],
      });
    } else if (comparison.trend === 'stable') {
      challenges.push({
        id: 'improve_accuracy',
        title: '📈 Améliorer la précision',
        description: `Objectif : augmenter la précision de ${currentCritique.overall.accuracy.toFixed(1)}% à ${(currentCritique.overall.accuracy + 5).toFixed(1)}%`,
        target: {
          accuracy: currentCritique.overall.accuracy + 5,
        },
        current: {
          accuracy: currentCritique.overall.accuracy,
        },
        priority: 'moyenne',
        deadline: 'Prochain rapport (2h)',
        actions: [
          'Ajouter plus de feedbacks corrects',
          'Valider les feedbacks en attente',
          'Réentraîner le modèle',
        ],
      });
    } else if (comparison.trend === 'improving') {
      challenges.push({
        id: 'maintain_improvement',
        title: '✅ Maintenir l\'amélioration',
        description: 'Les performances s\'améliorent ! Objectif : maintenir cette tendance.',
        target: {
          accuracy: currentCritique.overall.accuracy + 2,
          weaknesses: Math.max(0, currentCritique.weaknesses.length - 1),
        },
        current: {
          accuracy: currentCritique.overall.accuracy,
          weaknesses: currentCritique.weaknesses.length,
        },
        priority: 'moyenne',
        deadline: 'Prochain rapport (2h)',
        actions: [
          'Continuer à valider les feedbacks',
          'Maintenir la qualité des traductions',
          'Surveiller les nouvelles erreurs',
        ],
      });
    }

    // Défi basé sur les erreurs persistantes
    if (comparison.degradations) {
      const persistentErrors = comparison.degradations.find(d => d.metric === 'Erreurs persistantes');
      if (persistentErrors && persistentErrors.change > 0) {
        challenges.push({
          id: 'fix_persistent_errors',
          title: '🔧 Corriger les erreurs persistantes',
          description: `${persistentErrors.change} erreur(s) persistent depuis plusieurs rapports. Il faut les corriger !`,
          target: {
            persistentErrors: 0,
          },
          current: {
            persistentErrors: parseInt(persistentErrors.change),
          },
          priority: 'haute',
          deadline: 'Prochain rapport (2h)',
          actions: [
            'Identifier les erreurs dans le rapport',
            'Ajouter les traductions correctes au modèle',
            'Réentraîner le modèle avec les corrections',
          ],
          details: persistentErrors.details || [],
        });
      }
    }

    // Défi basé sur les points faibles
    if (currentCritique.weaknesses.length > 5) {
      challenges.push({
        id: 'reduce_weaknesses',
        title: '🎯 Réduire les points faibles',
        description: `Objectif : réduire de ${currentCritique.weaknesses.length} à ${Math.max(0, currentCritique.weaknesses.length - 2)} point(s) faible(s)`,
        target: {
          weaknesses: Math.max(0, currentCritique.weaknesses.length - 2),
        },
        current: {
          weaknesses: currentCritique.weaknesses.length,
        },
        priority: 'moyenne',
        deadline: 'Prochain rapport (2h)',
        actions: [
          'Traiter les recommandations prioritaires',
          'Valider les feedbacks en attente',
          'Réentraîner le modèle',
        ],
      });
    }

    // Défi basé sur les feedbacks en attente
    const pendingFeedbacks = currentCritique.details?.feedbackAnalysis?.pending || 0;
    if (pendingFeedbacks > 10) {
      challenges.push({
        id: 'validate_pending',
        title: '✅ Valider les feedbacks en attente',
        description: `${pendingFeedbacks} feedback(s) en attente. Les valider améliorera le modèle.`,
        target: {
          pendingFeedbacks: 0,
        },
        current: {
          pendingFeedbacks: pendingFeedbacks,
        },
        priority: 'moyenne',
        deadline: 'Prochain rapport (2h)',
        actions: [
          'Exécuter la validation automatique',
          'Valider manuellement les feedbacks importants',
          'Rejeter les feedbacks incorrects',
        ],
      });
    }

    // Défi basé sur la précision
    if (currentCritique.overall.accuracy < 70 && currentCritique.overall.totalTests > 0) {
      challenges.push({
        id: 'reach_70_accuracy',
        title: '🎯 Atteindre 70% de précision',
        description: `Précision actuelle : ${currentCritique.overall.accuracy.toFixed(1)}%. Objectif : 70%`,
        target: {
          accuracy: 70,
        },
        current: {
          accuracy: currentCritique.overall.accuracy,
        },
        priority: 'haute',
        deadline: 'Prochain rapport (2h)',
        actions: [
          'Valider tous les feedbacks corrects',
          'Réentraîner le modèle',
          'Ajouter plus de traductions de référence',
        ],
      });
    }

    return challenges;
  }

  /**
   * Analyse approfondie des traductions pour identifier les patterns d'erreurs
   */
  async analyzeTranslationPatterns() {
    const analysis = {
      translationAccuracy: {
        ml: { correct: 0, incorrect: 0, total: 0 },
        fallback: { correct: 0, incorrect: 0, total: 0 },
      },
      errorPatterns: {
        commonMistakes: [],
        contextErrors: [],
        languageSpecificErrors: { fr: [], es: [] },
      },
      improvementSuggestions: [],
    };

    return new Promise((resolve, reject) => {
      // Analyser les feedbacks pour identifier les erreurs récurrentes
      this.db.all(
        `SELECT 
          original_text,
          current_translation,
          suggested_translation,
          type,
          target_language,
          COUNT(*) as frequency
         FROM translation_feedbacks
         WHERE (approved = 1 OR approved = 0)
           AND suggested_translation IS NOT NULL
           AND suggested_translation != current_translation
         GROUP BY original_text, current_translation, suggested_translation, type, target_language
         ORDER BY frequency DESC
         LIMIT 50`,
        [],
        (err, rows) => {
          if (err) return reject(err);

          if (rows && rows.length > 0) {
            // Identifier les erreurs les plus fréquentes
            analysis.errorPatterns.commonMistakes = rows.slice(0, 20).map(row => ({
              original: row.original_text,
              wrong: row.current_translation,
              correct: row.suggested_translation,
              type: row.type,
              language: row.target_language,
              frequency: row.frequency,
            }));

            // Grouper par langue
            for (const row of rows) {
              const lang = row.target_language;
              if (lang === 'fr' || lang === 'es') {
                if (analysis.errorPatterns.languageSpecificErrors[lang].length < 10) {
                  analysis.errorPatterns.languageSpecificErrors[lang].push({
                    original: row.original_text,
                    wrong: row.current_translation,
                    correct: row.suggested_translation,
                    type: row.type,
                    frequency: row.frequency,
                  });
                }
              }
            }

            // Générer des suggestions d'amélioration
            const typeErrors = {};
            for (const row of rows) {
              if (!typeErrors[row.type]) {
                typeErrors[row.type] = 0;
              }
              typeErrors[row.type] += row.frequency;
            }

            for (const [type, count] of Object.entries(typeErrors)) {
              if (count > 5) {
                analysis.improvementSuggestions.push({
                  type,
                  priority: count > 20 ? 'haute' : 'moyenne',
                  suggestion: `Améliorer les traductions de ${type} (${count} erreurs détectées)`,
                  count,
                });
              }
            }
          }

          resolve(analysis);
        }
      );
    });
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  const critique = new MLSelfCritique();
  
  // Vérifier si on doit démarrer en mode continu
  const args = process.argv.slice(2);
  const continuousMode = args.includes('--continuous') || args.includes('-c');
  const intervalArg = args.find(arg => arg.startsWith('--interval='));
  const intervalMinutes = intervalArg ? parseInt(intervalArg.split('=')[1]) : 60;

  if (continuousMode) {
    // Mode continu (arrière-plan)
    critique.startContinuousCritique(intervalMinutes)
      .then(() => {
        console.log('✅ Système d\'autocritique continu démarré');
        // Garder le processus actif
        process.on('SIGINT', () => {
          console.log('\n🛑 Arrêt du système d\'autocritique...');
          critique.stopContinuousCritique();
          process.exit(0);
        });
        process.on('SIGTERM', () => {
          console.log('\n🛑 Arrêt du système d\'autocritique...');
          critique.stopContinuousCritique();
          process.exit(0);
        });
      })
      .catch((error) => {
        console.error('❌ Erreur lors du démarrage:', error);
        process.exit(1);
      });
  } else {
    // Mode unique (une seule exécution)
    critique.generateCritique()
      .then(() => {
        console.log('\n✅ Autocritique terminée');
        process.exit(0);
      })
      .catch((error) => {
        console.error('\n❌ Erreur lors de l\'autocritique:', error);
        process.exit(1);
      });
  }
}

module.exports = MLSelfCritique;

