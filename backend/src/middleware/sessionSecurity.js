/**
 * Session Security Middleware
 * Gestion sécurisée des sessions et tokens JWT
 */

const jwt = require('jsonwebtoken');
const { getDatabase } = require('../database/db');
const { logSecurityEvent, SECURITY_EVENTS } = require('./securityLogger');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Table pour stocker les tokens révoqués (blacklist de tokens)
function initTokenBlacklist() {
  const db = getDatabase();
  db.run(`
    CREATE TABLE IF NOT EXISTS revoked_tokens (
      token_id TEXT PRIMARY KEY,
      user_id TEXT,
      revoked_at TEXT NOT NULL,
      expires_at TEXT,
      reason TEXT
    )
  `, (err) => {
    if (err) {
      console.error('Erreur création table revoked_tokens:', err);
    }
  });
}

// Initialiser au chargement
initTokenBlacklist();

/**
 * Révoquer un token (ajouter à la blacklist)
 */
function revokeToken(token, userId, reason = 'User logout') {
  const db = getDatabase();
  try {
    const decoded = jwt.decode(token);
    const tokenId = decoded?.jti || crypto.createHash('sha256').update(token).digest('hex');
    const expiresAt = decoded?.exp ? new Date(decoded.exp * 1000).toISOString() : null;

    db.run(
      'INSERT OR REPLACE INTO revoked_tokens (token_id, user_id, revoked_at, expires_at, reason) VALUES (?, ?, datetime("now"), ?, ?)',
      [tokenId, userId, expiresAt, reason],
      (err) => {
        if (err) {
          console.error('Erreur révocation token:', err);
        }
      }
    );
  } catch (error) {
    console.error('Erreur décodage token pour révocation:', error);
  }
}

/**
 * Vérifier si un token est révoqué
 */
function isTokenRevoked(token, callback) {
  const db = getDatabase();
  try {
    const decoded = jwt.decode(token);
    const tokenId = decoded?.jti || crypto.createHash('sha256').update(token).digest('hex');

    db.get(
      'SELECT * FROM revoked_tokens WHERE token_id = ? AND (expires_at IS NULL OR expires_at > datetime("now"))',
      [tokenId],
      (err, row) => {
        if (err) {
          console.error('Erreur vérification token révoqué:', err);
          return callback(false);
        }
        callback(!!row);
      }
    );
  } catch (error) {
    console.error('Erreur vérification token:', error);
    callback(false);
  }
}

/**
 * Middleware pour vérifier que le token n'est pas révoqué
 */
function sessionSecurityMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return next(); // Pas de token, laisser le middleware d'auth gérer
  }

  isTokenRevoked(token, (isRevoked) => {
    if (isRevoked) {
      const clientIP = req.ip || req.connection.remoteAddress;
      
      logSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, {
        ip: clientIP,
        url: req.url,
        method: req.method,
        reason: 'Revoked token used',
        severity: 'HIGH',
      });

      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Token révoqué. Veuillez vous reconnecter.',
        code: 'TOKEN_REVOKED',
      });
    }

    next();
  });
}

/**
 * Vérifier la force du token (expiration, signature)
 */
function validateTokenStrength(token) {
  try {
    const decoded = jwt.decode(token, { complete: true });
    
    if (!decoded) {
      return { valid: false, reason: 'Token invalide' };
    }

    // Vérifier l'expiration
    if (decoded.payload.exp && decoded.payload.exp < Date.now() / 1000) {
      return { valid: false, reason: 'Token expiré' };
    }

    // Vérifier l'algorithme (seulement HS256)
    if (decoded.header.alg !== 'HS256') {
      return { valid: false, reason: 'Algorithme de signature non autorisé' };
    }

    return { valid: true };
  } catch (error) {
    return { valid: false, reason: error.message };
  }
}

module.exports = {
  sessionSecurityMiddleware,
  revokeToken,
  isTokenRevoked,
  validateTokenStrength,
};

