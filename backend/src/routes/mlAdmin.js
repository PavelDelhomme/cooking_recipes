/**
 * Routes admin pour la gestion de l'IA de traduction
 * Sécurisé avec adminCheck middleware
 * Accès réservé aux admins (dumb@delhomme.ovh, dev@delhomme.ovh)
 */

const express = require('express');
const router = express.Router();
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const { authenticateToken } = require('../middleware/auth');
const { adminCheck } = require('../middleware/adminCheck');
const { securityLoggerMiddleware } = require('../middleware/securityLogger');
const mlTranslationEngine = require('../services/ml_translation_engine');

// Import optionnel du réseau de neurones
let neuralTranslationEngine = null;
try {
  neuralTranslationEngine = require('../services/neural_translation_engine');
} catch (e) {
  // TensorFlow.js non installé, pas grave
}

const dbPath = path.join(__dirname, '../../data/database.sqlite');

/**
 * GET /api/ml-admin/stats
 * Récupère les statistiques des feedbacks (admin uniquement)
 */
router.get(
  '/stats',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const db = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          return res.status(500).json({ error: 'Erreur base de données' });
        }
      });

      // Compter tous les feedbacks
      db.get('SELECT COUNT(*) as total FROM translation_feedbacks', [], (err, totalRow) => {
        if (err) {
          db.close();
          return res.status(500).json({ error: 'Erreur requête' });
        }

        // Compter les feedbacks approuvés
        db.get('SELECT COUNT(*) as approved FROM translation_feedbacks WHERE approved = 1', [], (err, approvedRow) => {
          if (err) {
            db.close();
            return res.status(500).json({ error: 'Erreur requête' });
          }

          // Compter les feedbacks avec traduction
          db.get(
            `SELECT COUNT(*) as with_translation 
             FROM translation_feedbacks 
             WHERE approved = 1 
               AND suggested_translation IS NOT NULL 
               AND suggested_translation != ''`,
            [],
            (err, translationRow) => {
              if (err) {
                db.close();
                return res.status(500).json({ error: 'Erreur requête' });
              }

              // Compter par type
              db.all(
                `SELECT type, COUNT(*) as count 
                 FROM translation_feedbacks 
                 WHERE approved = 1 
                   AND suggested_translation IS NOT NULL 
                   AND suggested_translation != ''
                 GROUP BY type`,
                [],
                (err, typeRows) => {
                  db.close();
                  if (err) {
                    return res.status(500).json({ error: 'Erreur requête' });
                  }

                  res.json({
                    success: true,
                    stats: {
                      total: totalRow.total,
                      approved: approvedRow.approved,
                      withTranslation: translationRow.with_translation,
                      byType: typeRows.reduce((acc, row) => {
                        acc[row.type] = row.count;
                        return acc;
                      }, {}),
                    },
                  });
                }
              );
            }
          );
        });
      });
    } catch (error) {
      console.error('Erreur stats ML admin:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * POST /api/ml-admin/approve-all
 * Approuve tous les feedbacks en attente (admin uniquement)
 * Sécurisé : nécessite confirmation explicite
 */
router.post(
  '/approve-all',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const { confirm } = req.body;

      // Vérification de sécurité : nécessite confirmation explicite
      if (confirm !== true && confirm !== 'true') {
        return res.status(400).json({
          error: 'Confirmation requise. Envoyez { "confirm": true }',
        });
      }

      const db = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          return res.status(500).json({ error: 'Erreur base de données' });
        }
      });

      // Compter les feedbacks à approuver
      db.get(
        `SELECT COUNT(*) as count 
         FROM translation_feedbacks 
         WHERE approved = 0 
           AND suggested_translation IS NOT NULL 
           AND suggested_translation != ''`,
        [],
        (err, countRow) => {
          if (err) {
            db.close();
            return res.status(500).json({ error: 'Erreur requête' });
          }

          const countToApprove = countRow.count;

          if (countToApprove === 0) {
            db.close();
            return res.json({
              success: true,
              message: 'Aucun feedback à approuver',
              approved: 0,
            });
          }

          // Approuver tous les feedbacks
          const now = new Date().toISOString();
          db.run(
            `UPDATE translation_feedbacks 
             SET approved = 1, 
                 approved_by = ?, 
                 approved_at = ?
             WHERE approved = 0 
               AND suggested_translation IS NOT NULL 
               AND suggested_translation != ''`,
            [req.user.email, now],
            function (err) {
              if (err) {
                db.close();
                return res.status(500).json({ error: 'Erreur mise à jour' });
              }

              // Logger l'action admin
              securityLoggerMiddleware.log({
                event_type: 'ADMIN_ACTION',
                user_id: req.user.id,
                details: `Approbation en masse de ${this.changes} feedbacks`,
                severity: 'INFO',
              });

              db.close();
              res.json({
                success: true,
                message: `${this.changes} feedbacks approuvés avec succès`,
                approved: this.changes,
              });
            }
          );
        }
      );
    } catch (error) {
      console.error('Erreur approbation en masse:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * POST /api/ml-admin/retrain
 * Réentraîne le modèle ML (admin uniquement)
 */
router.post(
  '/retrain',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      // Logger l'action admin
      securityLoggerMiddleware.log({
        event_type: 'ADMIN_ACTION',
        user_id: req.user.id,
        details: 'Démarrage réentraînement modèle ML',
        severity: 'INFO',
      });

      // Réentraîner le modèle (asynchrone pour ne pas bloquer)
      mlTranslationEngine.retrain().catch((err) => {
        console.error('Erreur réentraînement ML:', err);
      });

      res.json({
        success: true,
        message: 'Réentraînement du modèle ML démarré en arrière-plan',
      });
    } catch (error) {
      console.error('Erreur démarrage réentraînement:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * POST /api/ml-admin/retrain-neural
 * Réentraîne le réseau de neurones (admin uniquement)
 */
router.post(
  '/retrain-neural',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      // Logger l'action admin
      securityLoggerMiddleware.log({
        event_type: 'ADMIN_ACTION',
        user_id: req.user.id,
        details: 'Démarrage réentraînement réseau de neurones',
        severity: 'INFO',
      });

      // Vérifier que TensorFlow.js est disponible
      if (!neuralTranslationEngine) {
        return res.status(503).json({
          error: 'TensorFlow.js non installé. Utilisez: make install-neural',
        });
      }

      // Réentraîner le réseau de neurones (asynchrone)
      neuralTranslationEngine.retrain().catch((err) => {
        console.error('Erreur réentraînement réseau de neurones:', err);
      });

      res.json({
        success: true,
        message: 'Réentraînement du réseau de neurones démarré en arrière-plan',
      });
    } catch (error) {
      console.error('Erreur démarrage réentraînement neural:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * GET /api/ml-admin/feedbacks
 * Récupère les feedbacks (admin uniquement)
 */
router.get(
  '/feedbacks',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const { limit = 50, offset = 0, approved } = req.query;

      const db = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          return res.status(500).json({ error: 'Erreur base de données' });
        }
      });

      let query = 'SELECT * FROM translation_feedbacks WHERE 1=1';
      const params = [];

      if (approved !== undefined) {
        query += ' AND approved = ?';
        params.push(approved === 'true' || approved === '1' ? 1 : 0);
      }

      query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
      params.push(parseInt(limit), parseInt(offset));

      db.all(query, params, (err, rows) => {
        db.close();
        if (err) {
          return res.status(500).json({ error: 'Erreur requête' });
        }

        res.json({
          success: true,
          feedbacks: rows,
          count: rows.length,
        });
      });
    } catch (error) {
      console.error('Erreur récupération feedbacks:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * POST /api/ml-admin/approve/:id
 * Approuve un feedback spécifique (admin uniquement)
 */
router.post(
  '/approve/:id',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const { id } = req.params;
      const db = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          return res.status(500).json({ error: 'Erreur base de données' });
        }
      });

      const now = new Date().toISOString();
      db.run(
        `UPDATE translation_feedbacks 
         SET approved = 1, 
             approved_by = ?, 
             approved_at = ?
         WHERE id = ?`,
        [req.user.email, now, id],
        function (err) {
          db.close();
          if (err) {
            return res.status(500).json({ error: 'Erreur mise à jour' });
          }

          if (this.changes === 0) {
            return res.status(404).json({ error: 'Feedback non trouvé' });
          }

          // Logger l'action admin
          securityLoggerMiddleware.log({
            event_type: 'ADMIN_ACTION',
            user_id: req.user.id,
            details: `Approbation feedback ${id}`,
            severity: 'INFO',
          });

          res.json({
            success: true,
            message: 'Feedback approuvé avec succès',
          });
        }
      );
    } catch (error) {
      console.error('Erreur approbation feedback:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * GET /api/ml-admin/critiques
 * Récupère les rapports d'autocritique (admin uniquement)
 */
router.get(
  '/critiques',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const { limit = 10, latest = false } = req.query;
      const critiquesDir = path.join(__dirname, '../../data/ml_critiques');

      if (!fs.existsSync(critiquesDir)) {
        return res.json({
          success: true,
          critiques: [],
          count: 0,
          message: 'Aucun rapport d\'autocritique disponible',
        });
      }

      if (latest === 'true' || latest === true) {
        // Retourner uniquement le dernier rapport
        const latestPath = path.join(critiquesDir, 'latest_self_critique.json');
        if (fs.existsSync(latestPath)) {
          const latestCritique = JSON.parse(fs.readFileSync(latestPath, 'utf8'));
          return res.json({
            success: true,
            critique: latestCritique,
            hasMore: false,
          });
        } else {
          return res.json({
            success: true,
            critique: null,
            hasMore: false,
            message: 'Aucun rapport disponible',
          });
        }
      }

      // Retourner les N derniers rapports
      const reportFiles = fs.readdirSync(critiquesDir)
        .filter(file => file.startsWith('self_critique_') && file.endsWith('.json') && file !== 'latest_self_critique.json')
        .sort()
        .reverse()
        .slice(0, parseInt(limit));

      const critiques = [];
      for (const file of reportFiles) {
        try {
          const filePath = path.join(critiquesDir, file);
          const critique = JSON.parse(fs.readFileSync(filePath, 'utf8'));
          // Simplifier pour l'API (ne pas envoyer tous les détails)
          critiques.push({
            id: file.replace('.json', ''),
            timestamp: critique.timestamp,
            overall: critique.overall,
            strengthsCount: critique.strengths?.length || 0,
            weaknessesCount: critique.weaknesses?.length || 0,
            recommendationsCount: critique.recommendations?.length || 0,
            challengesCount: critique.challenges?.length || 0,
            trend: critique.comparison?.trend || 'unknown',
            accuracyChange: critique.comparison?.metrics?.accuracy?.change || 0,
          });
        } catch (error) {
          console.warn(`Erreur lecture rapport ${file}:`, error.message);
        }
      }

      res.json({
        success: true,
        critiques,
        count: critiques.length,
      });
    } catch (error) {
      console.error('Erreur récupération critiques:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * GET /api/ml-admin/critiques/:id
 * Récupère un rapport d'autocritique spécifique (admin uniquement)
 */
router.get(
  '/critiques/:id',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const { id } = req.params;
      const critiquesDir = path.join(__dirname, '../../data/ml_critiques');

      let filePath;
      if (id === 'latest') {
        filePath = path.join(critiquesDir, 'latest_self_critique.json');
      } else {
        filePath = path.join(critiquesDir, `${id}.json`);
      }

      if (!fs.existsSync(filePath)) {
        return res.status(404).json({ error: 'Rapport non trouvé' });
      }

      const critique = JSON.parse(fs.readFileSync(filePath, 'utf8'));

      res.json({
        success: true,
        critique,
      });
    } catch (error) {
      console.error('Erreur récupération critique:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * GET /api/ml-admin/critiques/summary/history
 * Récupère l'historique des résumés (admin uniquement)
 */
router.get(
  '/critiques/summary/history',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const critiquesDir = path.join(__dirname, '../../data/ml_critiques');
      const summaryPath = path.join(critiquesDir, 'summary_history.json');

      if (!fs.existsSync(summaryPath)) {
        return res.json({
          success: true,
          history: [],
          count: 0,
        });
      }

      const history = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));

      res.json({
        success: true,
        history,
        count: history.length,
      });
    } catch (error) {
      console.error('Erreur récupération historique:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

/**
 * POST /api/ml-admin/auto-actions/execute
 * Exécute les actions automatiques basées sur les défis (admin uniquement)
 */
router.post(
  '/auto-actions/execute',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const mlAutoActions = require('../../scripts/ml_auto_actions');
      const result = await mlAutoActions.executeAutoActions();

      res.json({
        success: true,
        executed: result.executed,
        results: result.results,
        message: `${result.executed} action(s) exécutée(s) avec succès`,
      });
    } catch (error) {
      console.error('Erreur exécution actions automatiques:', error);
      res.status(500).json({ 
        success: false,
        error: 'Erreur serveur',
        message: error.message,
      });
    }
  }
);

/**
 * GET /api/ml-admin/auto-actions/history
 * Récupère l'historique des actions automatiques (admin uniquement)
 */
router.get(
  '/auto-actions/history',
  authenticateToken,
  adminCheck,
  securityLoggerMiddleware,
  async (req, res) => {
    try {
      const { limit = 20 } = req.query;
      const mlAutoActions = require('../../scripts/ml_auto_actions');
      const history = mlAutoActions.getActionsHistory(parseInt(limit));

      res.json({
        success: true,
        history,
        count: history.length,
      });
    } catch (error) {
      console.error('Erreur récupération historique actions:', error);
      res.status(500).json({ error: 'Erreur serveur' });
    }
  }
);

module.exports = router;

