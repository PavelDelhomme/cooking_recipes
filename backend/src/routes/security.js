/**
 * Routes de sécurité pour l'administration
 * Permet de consulter les logs de sécurité et gérer la blacklist
 */

const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const { getDatabase } = require('../database/db');
const router = express.Router();

// Toutes les routes nécessitent une authentification
router.use(authenticateToken);

/**
 * GET /api/security/logs
 * Récupère les logs de sécurité (nécessite authentification)
 */
router.get('/logs', async (req, res) => {
  try {
    const db = getDatabase();
    const { limit = 100, offset = 0, eventType, severity, ipAddress } = req.query;

    let query = 'SELECT * FROM security_logs WHERE 1=1';
    const params = [];

    if (eventType) {
      query += ' AND event_type = ?';
      params.push(eventType);
    }

    if (severity) {
      query += ' AND severity = ?';
      params.push(severity);
    }

    if (ipAddress) {
      query += ' AND ip_address = ?';
      params.push(ipAddress);
    }

    query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    db.all(query, params, (err, rows) => {
      if (err) {
        console.error('Erreur récupération logs sécurité:', err);
        return res.status(500).json({ message: 'Erreur serveur' });
      }

      res.json({
        logs: rows,
        total: rows.length,
        limit: parseInt(limit),
        offset: parseInt(offset),
      });
    });
  } catch (error) {
    console.error('Erreur route sécurité logs:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /api/security/stats
 * Statistiques de sécurité
 */
router.get('/stats', async (req, res) => {
  try {
    const db = getDatabase();
    const { days = 7 } = req.query;
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

    const queries = {
      total: 'SELECT COUNT(*) as count FROM security_logs WHERE timestamp >= ?',
      byType: 'SELECT event_type, COUNT(*) as count FROM security_logs WHERE timestamp >= ? GROUP BY event_type',
      bySeverity: 'SELECT severity, COUNT(*) as count FROM security_logs WHERE timestamp >= ? GROUP BY severity',
      topIPs: 'SELECT ip_address, COUNT(*) as count FROM security_logs WHERE timestamp >= ? GROUP BY ip_address ORDER BY count DESC LIMIT 10',
    };

    db.get(queries.total, [since], (err, totalRow) => {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur' });
      }

      db.all(queries.byType, [since], (err, byTypeRows) => {
        if (err) {
          return res.status(500).json({ message: 'Erreur serveur' });
        }

        db.all(queries.bySeverity, [since], (err, bySeverityRows) => {
          if (err) {
            return res.status(500).json({ message: 'Erreur serveur' });
          }

          db.all(queries.topIPs, [since], (err, topIPsRows) => {
            if (err) {
              return res.status(500).json({ message: 'Erreur serveur' });
            }

            res.json({
              period: `${days} jours`,
              total: totalRow.count,
              byType: byTypeRows,
              bySeverity: bySeverityRows,
              topIPs: topIPsRows,
            });
          });
        });
      });
    });
  } catch (error) {
    console.error('Erreur route sécurité stats:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /api/security/blacklist
 * Liste des IPs blacklistées
 */
router.get('/blacklist', async (req, res) => {
  try {
    const db = getDatabase();
    db.all(
      'SELECT * FROM ip_blacklist WHERE expires_at IS NULL OR expires_at > datetime("now") ORDER BY created_at DESC',
      [],
      (err, rows) => {
        if (err) {
          console.error('Erreur récupération blacklist:', err);
          return res.status(500).json({ message: 'Erreur serveur' });
        }

        res.json({ blacklist: rows });
      }
    );
  } catch (error) {
    console.error('Erreur route sécurité blacklist:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;

