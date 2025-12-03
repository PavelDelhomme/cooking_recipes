const rateLimit = require('express-rate-limit');
const { getClientIP, addToBlacklist } = require('./ipBlacklist');

// Rate limiter pour l'authentification avec blacklist automatique
const authLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 10, // 10 tentatives par fenêtre
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Ne pas compter les requêtes réussies
  skipFailedRequests: false, // Compter les échecs
  keyGenerator: (req) => {
    // Utiliser l'IP du client comme clé
    return getClientIP(req);
  },
  handler: (req, res) => {
    const ip = getClientIP(req);
    // Ajouter à la blacklist pour 1 heure après 10 tentatives échouées
    addToBlacklist(ip, 60, 'Trop de tentatives de connexion');
    
    // Si c'est une requête API (JSON), retourner JSON, sinon page HTML
    if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
      return res.status(429).json({
        error: 'Trop de tentatives de connexion. Votre adresse IP a été temporairement bloquée pour 1 heure.',
        retryAfter: 3600, // 1 heure en secondes
      });
    }
    
    // Utiliser le handler HTML pour les requêtes navigateur
    const { tooManyRequestsHandler } = require('./errorHandler');
    return tooManyRequestsHandler(req, res, 3600);
  },
});

// Rate limiter pour l'inscription avec blacklist automatique
const signupLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 inscriptions par 15 minutes
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Ne pas compter les inscriptions réussies
  keyGenerator: (req) => {
    // Utiliser l'IP du client comme clé
    return getClientIP(req);
  },
  handler: (req, res) => {
    const ip = getClientIP(req);
    // Ajouter à la blacklist pour 2 heures après 5 tentatives
    addToBlacklist(ip, 120, 'Trop de tentatives d\'inscription');
    
    // Si c'est une requête API (JSON), retourner JSON, sinon page HTML
    if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
      return res.status(429).json({
        error: 'Trop de tentatives d\'inscription. Votre adresse IP a été temporairement bloquée pour 2 heures.',
        retryAfter: 7200, // 2 heures en secondes
      });
    }
    
    // Utiliser le handler HTML pour les requêtes navigateur
    const { tooManyRequestsHandler } = require('./errorHandler');
    return tooManyRequestsHandler(req, res, 7200);
  },
});

// Rate limiter général pour l'API (seulement pour les routes non authentifiées)
// Plus permissif et sans blacklist automatique
const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // 100 requêtes par minute
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false,
  keyGenerator: (req) => {
    // Utiliser l'IP du client comme clé
    return getClientIP(req);
  },
  handler: (req, res) => {
    // Si c'est une requête API (JSON), retourner JSON, sinon page HTML
    if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
      return res.status(429).json({
        error: 'Trop de requêtes. Veuillez attendre 1 minute avant de réessayer.',
        retryAfter: 60, // 1 minute en secondes
      });
    }
    
    // Utiliser le handler HTML pour les requêtes navigateur
    const { tooManyRequestsHandler } = require('./errorHandler');
    return tooManyRequestsHandler(req, res, 60);
  },
});

module.exports = {
  authLimiter,
  apiLimiter,
  signupLimiter,
};
