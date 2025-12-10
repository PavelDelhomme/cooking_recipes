/**
 * Système d'apprentissage continu pour l'IA de traduction
 * S'entraîne automatiquement avec tous les nouveaux feedbacks approuvés
 */

const mlTranslationEngine = require('../src/services/ml_translation_engine');
const { getDatabase } = require('../src/database/db');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class MLContinuousLearning {
  constructor() {
    this.dbPath = path.join(__dirname, '../../data/database.sqlite');
    this.lastProcessedId = null;
  }

  /**
   * Traite les nouveaux feedbacks approuvés et entraîne le modèle
   */
  async processNewFeedbacks() {
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }

        // Récupérer les nouveaux feedbacks approuvés depuis le dernier traitement
        let query = `SELECT * FROM translation_feedbacks 
                     WHERE approved = 1 
                       AND suggested_translation IS NOT NULL 
                       AND suggested_translation != ''`;
        
        const params = [];
        if (this.lastProcessedId) {
          query += ' AND id > ?';
          params.push(this.lastProcessedId);
        }

        query += ' ORDER BY approved_at ASC LIMIT 100';

        db.all(query, params, async (err, feedbacks) => {
          if (err) {
            db.close();
            return reject(err);
          }

          if (feedbacks.length === 0) {
            db.close();
            return resolve({ processed: 0 });
          }

          console.log(`📚 Traitement de ${feedbacks.length} nouveaux feedbacks approuvés...`);

          let processed = 0;
          for (const feedback of feedbacks) {
            try {
              await mlTranslationEngine.train({
                type: feedback.type,
                originalText: feedback.original_text,
                suggestedTranslation: feedback.suggested_translation,
                targetLanguage: feedback.target_language,
              });
              processed++;
              this.lastProcessedId = feedback.id;
            } catch (error) {
              console.error(`❌ Erreur entraînement feedback ${feedback.id}:`, error.message);
            }
          }

          db.close();
          console.log(`✅ ${processed} feedbacks traités et intégrés au modèle`);
          resolve({ processed });
        });
      });
    });
  }

  /**
   * Lance le cycle d'apprentissage continu
   */
  async startContinuousLearning(intervalMinutes = 30) {
    console.log(`🤖 Démarrage de l'apprentissage continu (intervalle: ${intervalMinutes} min)`);
    
    // Traiter immédiatement
    await this.processNewFeedbacks();

    // Puis toutes les X minutes
    setInterval(async () => {
      try {
        await this.processNewFeedbacks();
      } catch (error) {
        console.error('❌ Erreur apprentissage continu:', error);
      }
    }, intervalMinutes * 60 * 1000);
  }
}

// Exécution si appelé directement
if (require.main === module) {
  const learning = new MLContinuousLearning();
  const interval = parseInt(process.argv[2]) || 30;
  
  learning.startContinuousLearning(interval)
    .then(() => {
      console.log('✅ Apprentissage continu démarré');
      // Garder le processus actif
      process.on('SIGINT', () => {
        console.log('\n🛑 Arrêt de l\'apprentissage continu');
        process.exit(0);
      });
    })
    .catch(error => {
      console.error('❌ Erreur:', error);
      process.exit(1);
    });
}

module.exports = MLContinuousLearning;

