const rateLimit = require('express-rate-limit');

// Rate limiter pour l'authentification (moins strict pour éviter les blocages)
const authLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes (réduit de 15 à 5)
  max: 30, // 30 tentatives par fenêtre (augmenté de 20 à 30)
  message: {
    error: 'Trop de tentatives de connexion. Veuillez réessayer dans quelques minutes.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Ne pas compter les requêtes réussies
  skipFailedRequests: false, // Compter les échecs
  handler: (req, res) => {
    res.status(429).json({
      error: 'Trop de tentatives de connexion. Veuillez attendre 5 minutes avant de réessayer.',
      retryAfter: 300, // 5 minutes en secondes
    });
  },
});

// Rate limiter général pour l'API (plus permissif)
const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute (réduit de 15 à 1)
  max: 200, // 200 requêtes par minute (plus raisonnable)
  message: {
    error: 'Trop de requêtes. Veuillez réessayer dans une minute.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Trop de requêtes. Veuillez attendre 1 minute avant de réessayer.',
      retryAfter: 60, // 1 minute en secondes
    });
  },
});

// Rate limiter pour l'inscription (moins strict avec fenêtre plus courte)
const signupLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes (réduit de 1 heure à 15 min)
  max: 10, // 10 inscriptions par 15 minutes
  message: {
    error: 'Trop de tentatives d\'inscription. Veuillez réessayer dans 15 minutes.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Ne pas compter les inscriptions réussies
  handler: (req, res) => {
    res.status(429).json({
      error: 'Trop de tentatives d\'inscription. Veuillez attendre 15 minutes avant de réessayer.',
      retryAfter: 900, // 15 minutes en secondes
    });
  },
});

module.exports = {
  authLimiter,
  apiLimiter,
  signupLimiter,
};

