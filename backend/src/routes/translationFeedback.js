const express = require('express');
const router = express.Router();
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const { authenticateToken } = require('../middleware/auth');
const { inputSanitizerMiddleware } = require('../middleware/inputSanitizer');
const { requestValidatorMiddleware } = require('../middleware/requestValidator');
const { adminCheck } = require('../middleware/adminCheck');
const mlTranslationEngine = require('../services/ml_translation_engine');

const dbPath = path.join(__dirname, '../../data/database.sqlite');

// Initialiser la table des feedbacks de traduction
function initTranslationFeedbackTable() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('Erreur connexion DB pour translation_feedbacks:', err);
        return reject(err);
      }
    });

    db.run(`
      CREATE TABLE IF NOT EXISTS translation_feedbacks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        recipe_title TEXT NOT NULL,
        type TEXT NOT NULL,
        original_text TEXT NOT NULL,
        current_translation TEXT NOT NULL,
        suggested_translation TEXT,
        target_language TEXT NOT NULL,
        context TEXT,
        approved INTEGER DEFAULT 0,
        approved_by TEXT,
        approved_at DATETIME,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table translation_feedbacks:', err);
        return reject(err);
      }
      
      // Migration : Si la table existe avec user_id INTEGER, la recréer avec TEXT
      db.all("PRAGMA table_info(translation_feedbacks)", (err, columns) => {
        if (!err && columns) {
          const userIdColumn = columns.find(col => col.name === 'user_id');
          if (userIdColumn && userIdColumn.type.toUpperCase() === 'INTEGER') {
            console.log('Migration: Correction du type user_id de INTEGER à TEXT');
            // Recréer la table avec le bon type
            db.run(`
              CREATE TABLE IF NOT EXISTS translation_feedbacks_new (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                recipe_id TEXT NOT NULL,
                recipe_title TEXT NOT NULL,
                type TEXT NOT NULL,
                original_text TEXT NOT NULL,
                current_translation TEXT NOT NULL,
                suggested_translation TEXT,
                target_language TEXT NOT NULL,
                context TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
              )
            `, (err) => {
              if (!err) {
                // Copier les données
                db.run(`
                  INSERT INTO translation_feedbacks_new 
                  SELECT * FROM translation_feedbacks
                `, (err) => {
                  if (!err) {
                    // Remplacer l'ancienne table
                    db.run(`DROP TABLE translation_feedbacks`, () => {
                      db.run(`ALTER TABLE translation_feedbacks_new RENAME TO translation_feedbacks`, () => {
                        console.log('✅ Migration terminée: user_id est maintenant TEXT');
                      });
                    });
                  }
                });
              }
            });
          }
        }
      });
      
      // Créer un index pour améliorer les performances
      db.run(`
        CREATE INDEX IF NOT EXISTS idx_translation_feedbacks_user_id 
        ON translation_feedbacks(user_id)
      `, (err) => {
        if (err) {
          console.error('Erreur création index:', err);
        }
        
        // Ajouter les colonnes approved si elles n'existent pas (migration)
        db.all("PRAGMA table_info(translation_feedbacks)", (err, columns) => {
          if (!err && columns) {
            const hasApproved = columns.some(col => col.name === 'approved');
            if (!hasApproved) {
              console.log('Migration: Ajout des colonnes approved, approved_by, approved_at');
              db.run(`ALTER TABLE translation_feedbacks ADD COLUMN approved INTEGER DEFAULT 0`, () => {});
              db.run(`ALTER TABLE translation_feedbacks ADD COLUMN approved_by TEXT`, () => {});
              db.run(`ALTER TABLE translation_feedbacks ADD COLUMN approved_at DATETIME`, () => {});
            }
          }
          db.close();
          resolve();
        });
      });
    });
  });
}

// Initialiser la table au démarrage
initTranslationFeedbackTable().catch(err => {
  console.error('Erreur initialisation table translation_feedbacks:', err);
});

// POST /api/translation-feedback - Enregistrer un feedback
router.post(
  '/',
  authenticateToken,
  inputSanitizerMiddleware,
  requestValidatorMiddleware,
  async (req, res) => {
    try {
      const {
        recipeId,
        recipeTitle,
        type,
        originalText,
        currentTranslation,
        suggestedTranslation,
        targetLanguage,
        context,
      } = req.body;

      // Validation
      if (!recipeId || !recipeTitle || !type || !originalText || !currentTranslation || !targetLanguage) {
        return res.status(400).json({
          error: 'Champs requis manquants',
          required: ['recipeId', 'recipeTitle', 'type', 'originalText', 'currentTranslation', 'targetLanguage'],
        });
      }

      if (!['instruction', 'ingredient', 'recipeName'].includes(type)) {
        return res.status(400).json({
          error: 'Type invalide. Doit être: instruction, ingredient, ou recipeName',
        });
      }

      const userId = req.user?.userId || req.user?.id;
      if (!userId) {
        console.error('userId manquant dans req.user:', req.user);
        return res.status(401).json({ error: 'Utilisateur non authentifié' });
      }
      
      const id = `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      const db = new sqlite3.Database(dbPath);
      
      db.run(
        `INSERT INTO translation_feedbacks 
         (id, user_id, recipe_id, recipe_title, type, original_text, current_translation, 
          suggested_translation, target_language, context, timestamp)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))`,
        [
          id,
          userId,
          recipeId,
          recipeTitle,
          type,
          originalText,
          currentTranslation,
          suggestedTranslation || null,
          targetLanguage,
          context || null,
        ],
        function(err) {
          if (err) {
            db.close();
            console.error('Erreur insertion feedback:', err);
            console.error('Détails:', {
              userId,
              recipeId,
              type,
              originalText: originalText?.substring(0, 50),
              currentTranslation: currentTranslation?.substring(0, 50),
            });
            return res.status(500).json({ 
              error: 'Erreur lors de l\'enregistrement du feedback',
              details: err.message 
            });
          }

          // Note: L'entraînement ML se fera après validation par l'admin
          // Les feedbacks non approuvés ne sont pas utilisés pour l'entraînement

          res.status(201).json({
            success: true,
            id,
            message: 'Feedback enregistré avec succès. En attente de validation.',
          });
          db.close();
        }
      );
    } catch (error) {
      console.error('Erreur POST /api/translation-feedback:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

// GET /api/translation-feedback - Récupérer les feedbacks de l'utilisateur
router.get(
  '/',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.userId || req.user.id;
      const { type, limit = 100, offset = 0 } = req.query;

      const db = new sqlite3.Database(dbPath);
      
      let query = 'SELECT * FROM translation_feedbacks WHERE user_id = ?';
      const params = [userId];

      if (type && ['instruction', 'ingredient', 'recipeName'].includes(type)) {
        query += ' AND type = ?';
        params.push(type);
      }

      query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
      params.push(parseInt(limit), parseInt(offset));

      db.all(query, params, (err, rows) => {
        db.close();
        if (err) {
          console.error('Erreur récupération feedbacks:', err);
          return res.status(500).json({ error: 'Erreur lors de la récupération des feedbacks' });
        }

        res.json({
          success: true,
          count: rows.length,
          feedbacks: rows,
        });
      });
    } catch (error) {
      console.error('Erreur GET /api/translation-feedback:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

// GET /api/translation-feedback/stats - Statistiques des feedbacks
router.get(
  '/stats',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.userId || req.user.id;

      const db = new sqlite3.Database(dbPath);
      
      db.get(
        `SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN type = 'instruction' THEN 1 END) as instructions,
          COUNT(CASE WHEN type = 'ingredient' THEN 1 END) as ingredients,
          COUNT(CASE WHEN type = 'recipeName' THEN 1 END) as recipeNames
         FROM translation_feedbacks 
         WHERE user_id = ?`,
        [userId],
        (err, row) => {
          db.close();
          if (err) {
            console.error('Erreur stats feedbacks:', err);
            return res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
          }

          res.json({
            success: true,
            stats: row,
          });
        }
      );
    } catch (error) {
      console.error('Erreur GET /api/translation-feedback/stats:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

// GET /api/translation-feedback/training-data - Récupérer les données pour l'entraînement (admin uniquement)
router.get(
  '/training-data',
  authenticateToken,
  adminCheck,
  async (req, res) => {
    try {
      const db = new sqlite3.Database(dbPath);
      
      db.all(
        `SELECT 
          type,
          original_text,
          current_translation,
          suggested_translation,
          target_language,
          COUNT(*) as usage_count
         FROM translation_feedbacks 
         WHERE suggested_translation IS NOT NULL 
           AND suggested_translation != ''
           AND approved = 1
         GROUP BY type, original_text, suggested_translation, target_language
         ORDER BY usage_count DESC`,
        [],
        (err, rows) => {
          db.close();
          if (err) {
            console.error('Erreur récupération données entraînement:', err);
            return res.status(500).json({ error: 'Erreur lors de la récupération des données' });
          }

          // Organiser les données par type
          const trainingData = {
            instructions: [],
            ingredients: [],
            recipeNames: [],
          };

          rows.forEach(row => {
            const entry = {
              original: row.original_text,
              current: row.current_translation,
              suggested: row.suggested_translation,
              language: row.target_language,
              usageCount: row.usage_count,
            };

            if (row.type === 'instruction') {
              trainingData.instructions.push(entry);
            } else if (row.type === 'ingredient') {
              trainingData.ingredients.push(entry);
            } else if (row.type === 'recipeName') {
              trainingData.recipeNames.push(entry);
            }
          });

          res.json({
            success: true,
            totalEntries: rows.length,
            data: trainingData,
          });
        }
      );
    } catch (error) {
      console.error('Erreur GET /api/translation-feedback/training-data:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

module.exports = router;

