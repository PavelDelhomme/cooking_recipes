/**
 * Script pour calculer et afficher les métriques de performance de l'IA
 * Usage: node backend/scripts/ml_metrics.js
 */

const mlTranslationEngine = require('../src/services/ml_translation_engine');
const { getDatabase } = require('../src/database/db');
const fs = require('fs');
const path = require('path');

class MLMetrics {
  constructor() {
    this.db = getDatabase();
  }

  /**
   * Calcule toutes les métriques
   */
  async calculateAllMetrics() {
    console.log('📊 ========================================');
    console.log('📊 MÉTRIQUES DE PERFORMANCE DE L\'IA');
    console.log('📊 ========================================');
    console.log('');

    // 1. Charger les modèles
    await mlTranslationEngine.loadModels();

    // 2. Statistiques du modèle
    const modelStats = mlTranslationEngine.getStats();
    console.log('🤖 STATISTIQUES DU MODÈLE');
    console.log('─────────────────────────────────────────');
    for (const [type, langs] of Object.entries(modelStats)) {
      console.log(`\n${type.toUpperCase()}:`);
      for (const [lang, count] of Object.entries(langs)) {
        console.log(`  ${lang.toUpperCase()}: ${count} traductions apprises`);
      }
    }

    // 3. Statistiques des feedbacks
    const feedbackStats = await this.getFeedbackStats();
    console.log('\n\n📝 STATISTIQUES DES FEEDBACKS');
    console.log('─────────────────────────────────────────');
    console.log(`Total: ${feedbackStats.total}`);
    console.log(`✅ Approuvés: ${feedbackStats.approved} (${((feedbackStats.approved / feedbackStats.total) * 100).toFixed(1)}%)`);
    console.log(`⏳ En attente: ${feedbackStats.pending} (${((feedbackStats.pending / feedbackStats.total) * 100).toFixed(1)}%)`);
    console.log(`❌ Rejetés: ${feedbackStats.rejected} (${((feedbackStats.rejected / feedbackStats.total) * 100).toFixed(1)}%)`);
    console.log('\nPar type:');
    console.log(`  Ingrédients: ${feedbackStats.ingredients}`);
    console.log(`  Instructions: ${feedbackStats.instructions}`);
    console.log(`  Noms de recettes: ${feedbackStats.recipeNames}`);
    console.log(`  Unités: ${feedbackStats.units}`);
    console.log(`  Résumés: ${feedbackStats.summaries}`);

    // 4. Métriques de performance (si disponibles)
    const performanceMetrics = await this.getPerformanceMetrics();
    if (performanceMetrics) {
      console.log('\n\n🎯 MÉTRIQUES DE PERFORMANCE');
      console.log('─────────────────────────────────────────');
      console.log(`Précision: ${(performanceMetrics.accuracy * 100).toFixed(2)}%`);
      console.log(`Couverture: ${(performanceMetrics.coverage * 100).toFixed(2)}%`);
      console.log(`Total testé: ${performanceMetrics.totalTested}`);
      console.log(`✅ Correct: ${performanceMetrics.correct}`);
      console.log(`❌ Incorrect: ${performanceMetrics.incorrect}`);
      console.log(`⚠️  Manquant: ${performanceMetrics.missing}`);
      if (performanceMetrics.lastTestDate) {
        console.log(`Dernier test: ${performanceMetrics.lastTestDate}`);
      }
    } else {
      console.log('\n\n⚠️  Aucune métrique de performance disponible');
      console.log('   Exécutez "make test-ml-lab" pour générer des métriques');
    }

    // 5. Recommandations
    console.log('\n\n💡 RECOMMANDATIONS');
    console.log('─────────────────────────────────────────');
    this.printRecommendations(modelStats, feedbackStats, performanceMetrics);

    // 6. Sauvegarder dans un fichier JSON
    await this.saveMetrics({
      modelStats,
      feedbackStats,
      performanceMetrics,
      timestamp: new Date().toISOString(),
    });

    console.log('\n\n✅ Métriques sauvegardées dans backend/data/ml_metrics.json');
  }

  /**
   * Récupère les statistiques des feedbacks
   */
  async getFeedbackStats() {
    return new Promise((resolve, reject) => {
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
          resolve(row || {
            total: 0,
            approved: 0,
            pending: 0,
            rejected: 0,
            ingredients: 0,
            instructions: 0,
            recipeNames: 0,
            units: 0,
            summaries: 0,
          });
        }
      );
    });
  }

  /**
   * Récupère les métriques de performance
   */
  async getPerformanceMetrics() {
    try {
      const reportPath = path.join(__dirname, '../data/training_results/latest_test_results.json');
      if (fs.existsSync(reportPath)) {
        const reportData = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
        return {
          accuracy: reportData.accuracy || 0,
          coverage: reportData.coverage || 0,
          totalTested: reportData.total || 0,
          correct: reportData.correct || 0,
          incorrect: reportData.incorrect || 0,
          missing: reportData.missing || 0,
          lastTestDate: reportData.testDate || null,
        };
      }
    } catch (e) {
      // Ignorer
    }
    return null;
  }

  /**
   * Affiche les recommandations
   */
  printRecommendations(modelStats, feedbackStats, performanceMetrics) {
    const totalLearned = Object.values(modelStats).reduce((sum, langs) => {
      return sum + Object.values(langs).reduce((s, count) => s + count, 0);
    }, 0);

    if (totalLearned < 100) {
      console.log('⚠️  Peu de traductions apprises (< 100)');
      console.log('   → Ajoutez plus de feedbacks pour améliorer l\'IA');
    }

    if (feedbackStats.pending > feedbackStats.approved) {
      console.log('⚠️  Beaucoup de feedbacks en attente');
      console.log('   → Validez les feedbacks pour entraîner l\'IA');
    }

    if (performanceMetrics && performanceMetrics.accuracy < 0.7) {
      console.log('⚠️  Précision faible (< 70%)');
      console.log('   → Réentraînez le modèle: make retrain-ml');
      console.log('   → Ajoutez plus de feedbacks corrects');
    }

    if (performanceMetrics && performanceMetrics.coverage < 0.5) {
      console.log('⚠️  Couverture faible (< 50%)');
      console.log('   → L\'IA ne traduit pas beaucoup de mots');
      console.log('   → Ajoutez plus de traductions dans le modèle');
    }

    if (!performanceMetrics) {
      console.log('ℹ️  Aucun test de performance effectué');
      console.log('   → Exécutez "make test-ml-lab" pour tester l\'IA');
    }

    if (totalLearned >= 100 && feedbackStats.approved > 50 && (!performanceMetrics || performanceMetrics.accuracy >= 0.7)) {
      console.log('✅ L\'IA fonctionne bien !');
      console.log('   → Continuez à ajouter des feedbacks pour maintenir la qualité');
    }
  }

  /**
   * Sauvegarde les métriques dans un fichier JSON
   */
  async saveMetrics(metrics) {
    const metricsPath = path.join(__dirname, '../data/ml_metrics.json');
    const metricsDir = path.dirname(metricsPath);
    
    if (!fs.existsSync(metricsDir)) {
      fs.mkdirSync(metricsDir, { recursive: true });
    }

    fs.writeFileSync(metricsPath, JSON.stringify(metrics, null, 2), 'utf8');
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  const metrics = new MLMetrics();
  metrics.calculateAllMetrics()
    .then(() => {
      console.log('\n✅ Terminé');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Erreur:', error);
      process.exit(1);
    });
}

module.exports = MLMetrics;

