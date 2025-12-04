const { getDatabase } = require('../database/db');
const { logSecurityEvent, SECURITY_EVENTS } = require('./securityLogger');

// Fonction pour obtenir l'IP réelle du client
function getClientIP(req) {
  // Vérifier les headers de proxy (Nginx, Cloudflare, etc.)
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded) {
    // Prendre la première IP de la chaîne
    return forwarded.split(',')[0].trim();
  }
  
  // Vérifier x-real-ip (Nginx)
  if (req.headers['x-real-ip']) {
    return req.headers['x-real-ip'];
  }
  
  // IP directe
  return req.ip || req.connection.remoteAddress || req.socket.remoteAddress;
}

// Vérifier si une IP est blacklistée
function isIPBlacklisted(ip, callback) {
  const db = getDatabase();
  db.get(
    'SELECT * FROM ip_blacklist WHERE ip = ? AND (expires_at IS NULL OR expires_at > datetime("now"))',
    [ip],
    (err, row) => {
      if (err) {
        console.error('Erreur vérification blacklist:', err);
        return callback(false); // En cas d'erreur, ne pas bloquer
      }
      callback(!!row);
    }
  );
}

// Ajouter une IP à la blacklist
function addToBlacklist(ip, durationMinutes = 60, reason = 'Trop de tentatives') {
  const db = getDatabase();
  const expiresAt = durationMinutes > 0 
    ? new Date(Date.now() + durationMinutes * 60 * 1000).toISOString()
    : null;
  
  db.run(
    'INSERT OR REPLACE INTO ip_blacklist (ip, reason, created_at, expires_at) VALUES (?, ?, datetime("now"), ?)',
    [ip, reason, expiresAt],
    (err) => {
      if (err) {
        console.error('Erreur ajout blacklist:', err);
      } else {
        console.log(`IP ${ip} ajoutée à la blacklist jusqu'à ${expiresAt || 'jamais'}`);
      }
    }
  );
}

// Retirer une IP de la blacklist
function removeFromBlacklist(ip) {
  const db = getDatabase();
  db.run(
    'DELETE FROM ip_blacklist WHERE ip = ?',
    [ip],
    (err) => {
      if (err) {
        console.error('Erreur retrait blacklist:', err);
      } else {
        console.log(`IP ${ip} retirée de la blacklist`);
      }
    }
  );
}

// Middleware pour vérifier la blacklist
function checkBlacklist(req, res, next) {
  const ip = getClientIP(req);
  
  isIPBlacklisted(ip, (isBlacklisted) => {
    if (isBlacklisted) {
      // Si c'est une requête API (JSON), retourner JSON, sinon page HTML
      if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
        return res.status(403).json({
          error: 'Votre adresse IP a été temporairement bloquée pour cause de trop nombreuses tentatives.',
          retryAfter: 3600, // 1 heure
        });
      }
      // Utiliser le handler HTML pour les requêtes navigateur
      const { forbiddenHandler } = require('./errorHandler');
      return forbiddenHandler(req, res, 'Votre adresse IP a été temporairement bloquée pour cause de trop nombreuses tentatives.');
    }
    req.clientIP = ip; // Ajouter l'IP à la requête
    next();
  });
}

module.exports = {
  getClientIP,
  isIPBlacklisted,
  addToBlacklist,
  removeFromBlacklist,
  checkBlacklist,
};

