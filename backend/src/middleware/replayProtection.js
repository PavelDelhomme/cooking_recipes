/**
 * Replay Attack Protection Middleware
 * Protège contre les attaques de rejeu en utilisant des nonces et timestamps
 */

const crypto = require('crypto');
const { getDatabase } = require('../database/db');
const { logSecurityEvent, SECURITY_EVENTS } = require('./securityLogger');

// Stockage des nonces utilisés (en production, utiliser Redis)
const usedNonces = new Map();
const NONCE_EXPIRY = 5 * 60 * 1000; // 5 minutes
const MAX_TIMESTAMP_DIFF = 5 * 60 * 1000; // 5 minutes de tolérance

/**
 * Nettoie les nonces expirés
 */
function cleanupNonces() {
  const now = Date.now();
  for (const [nonce, timestamp] of usedNonces.entries()) {
    if (now - timestamp > NONCE_EXPIRY) {
      usedNonces.delete(nonce);
    }
  }
}

// Nettoyer toutes les 5 minutes
setInterval(cleanupNonces, 5 * 60 * 1000);

/**
 * Génère un nonce pour une requête
 */
function generateNonce() {
  return crypto.randomBytes(16).toString('hex');
}

/**
 * Vérifie un nonce et un timestamp
 */
function verifyNonceAndTimestamp(nonce, timestamp) {
  if (!nonce || !timestamp) {
    return { valid: false, reason: 'Nonce ou timestamp manquant' };
  }

  // Vérifier que le nonce n'a pas déjà été utilisé
  if (usedNonces.has(nonce)) {
    return { valid: false, reason: 'Nonce déjà utilisé (replay attack)' };
  }

  // Vérifier le timestamp
  const now = Date.now();
  const requestTime = parseInt(timestamp, 10);
  const diff = Math.abs(now - requestTime);

  if (diff > MAX_TIMESTAMP_DIFF) {
    return { valid: false, reason: 'Timestamp trop ancien ou dans le futur' };
  }

  // Marquer le nonce comme utilisé
  usedNonces.set(nonce, now);

  return { valid: true };
}

/**
 * Middleware de protection contre les attaques de rejeu
 */
function replayProtectionMiddleware(req, res, next) {
  // Seulement pour les requêtes modifiantes
  const protectedMethods = ['POST', 'PUT', 'DELETE', 'PATCH'];
  
  if (!protectedMethods.includes(req.method)) {
    return next();
  }

  // Exclure certaines routes (ex: health check)
  const excludedPaths = ['/health', '/api/health'];
  if (excludedPaths.some(path => req.path === path || req.path.startsWith(path))) {
    return next();
  }

  const clientIP = req.ip || req.connection.remoteAddress;
  const nonce = req.headers['x-nonce'] || req.body?._nonce;
  const timestamp = req.headers['x-timestamp'] || req.body?._timestamp;

  const verification = verifyNonceAndTimestamp(nonce, timestamp);

  if (!verification.valid) {
    logSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, {
      ip: clientIP,
      url: req.url,
      method: req.method,
      reason: `Replay protection failed: ${verification.reason}`,
      nonce,
      timestamp,
      severity: 'HIGH',
    });

    return res.status(403).json({
      error: 'Forbidden',
      message: 'Protection contre les attaques de rejeu: requête invalide ou rejouée',
      code: 'REPLAY_ATTACK_DETECTED',
    });
  }

  next();
}

module.exports = {
  replayProtectionMiddleware,
  generateNonce,
  verifyNonceAndTimestamp,
};

