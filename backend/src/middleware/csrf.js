/**
 * CSRF (Cross-Site Request Forgery) Protection Middleware
 * Génère et vérifie les tokens CSRF pour protéger contre les attaques CSRF
 */

const crypto = require('crypto');

// Stockage des tokens CSRF (en production, utiliser Redis ou une base de données)
const csrfTokens = new Map();
const TOKEN_EXPIRY = 30 * 60 * 1000; // 30 minutes

/**
 * Génère un token CSRF
 */
function generateCSRFToken() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Crée un token CSRF et le stocke
 */
function createCSRFToken(req) {
  const token = generateCSRFToken();
  const sessionId = req.headers['x-session-id'] || req.ip || 'anonymous';
  const expiry = Date.now() + TOKEN_EXPIRY;
  
  csrfTokens.set(sessionId, {
    token,
    expiry,
    createdAt: Date.now(),
  });

  // Nettoyer les tokens expirés
  cleanupExpiredTokens();

  return token;
}

/**
 * Vérifie un token CSRF
 */
function verifyCSRFToken(req) {
  const sessionId = req.headers['x-session-id'] || req.ip || 'anonymous';
  const token = req.headers['x-csrf-token'] || (req.body && req.body._csrf) || req.query._csrf;

  if (!token) {
    return { valid: false, error: 'Token CSRF manquant' };
  }

  const stored = csrfTokens.get(sessionId);
  if (!stored) {
    return { valid: false, error: 'Session invalide' };
  }

  if (Date.now() > stored.expiry) {
    csrfTokens.delete(sessionId);
    return { valid: false, error: 'Token CSRF expiré' };
  }

  if (stored.token !== token) {
    return { valid: false, error: 'Token CSRF invalide' };
  }

  return { valid: true };
}

/**
 * Nettoie les tokens expirés
 */
function cleanupExpiredTokens() {
  const now = Date.now();
  for (const [sessionId, data] of csrfTokens.entries()) {
    if (now > data.expiry) {
      csrfTokens.delete(sessionId);
    }
  }
}

/**
 * Middleware pour générer un token CSRF (GET requests)
 */
function generateCSRFMiddleware(req, res, next) {
  // Générer un token pour les requêtes GET
  if (req.method === 'GET') {
    const token = createCSRFToken(req);
    res.setHeader('X-CSRF-Token', token);
  }
  next();
}

/**
 * Middleware pour vérifier le token CSRF (POST, PUT, DELETE, PATCH)
 */
function verifyCSRFMiddleware(req, res, next) {
  // Méthodes qui nécessitent une protection CSRF
  const protectedMethods = ['POST', 'PUT', 'DELETE', 'PATCH'];
  
  if (!protectedMethods.includes(req.method)) {
    return next();
  }

  // Exclure certaines routes (ex: webhooks externes si nécessaire)
  const excludedPaths = ['/api/webhook'];
  if (excludedPaths.some(path => req.path.startsWith(path))) {
    return next();
  }

  const verification = verifyCSRFToken(req);
  
  if (!verification.valid) {
    const { logSecurityEvent, SECURITY_EVENTS } = require('./securityLogger');
    logSecurityEvent(SECURITY_EVENTS.CSRF_INVALID, {
      ip: req.ip || req.connection.remoteAddress,
      url: req.url,
      method: req.method,
      error: verification.error,
      severity: 'MEDIUM',
    });
    
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Token CSRF invalide ou manquant',
      code: 'CSRF_INVALID',
    });
  }

  next();
}

// Nettoyer les tokens expirés toutes les 5 minutes
setInterval(cleanupExpiredTokens, 5 * 60 * 1000);

module.exports = {
  generateCSRFMiddleware,
  verifyCSRFMiddleware,
  createCSRFToken,
  verifyCSRFToken,
};

