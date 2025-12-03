const rateLimit = require('express-rate-limit');

// Rate limiter pour l'authentification (moins strict pour éviter les blocages)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // 20 tentatives par fenêtre (augmenté de 5 à 20)
  message: {
    error: 'Trop de tentatives de connexion. Veuillez réessayer dans quelques minutes.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Ne pas compter les requêtes réussies
  skipFailedRequests: false, // Compter les échecs
  // Délai progressif : augmenter le délai après chaque échec
  handler: (req, res) => {
    res.status(429).json({
      error: 'Trop de tentatives de connexion. Veuillez attendre quelques minutes avant de réessayer.',
      retryAfter: Math.ceil(15 * 60 / 1000), // Secondes
    });
  },
});

// Rate limiter général pour l'API (plus permissif)
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 500, // 500 requêtes par fenêtre (augmenté de 100 à 500)
  message: {
    error: 'Trop de requêtes. Veuillez réessayer dans quelques minutes.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false,
});

// Rate limiter pour l'inscription (moins strict)
const signupLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 10, // 10 inscriptions par heure (augmenté de 3 à 10)
  message: {
    error: 'Trop de tentatives d\'inscription. Veuillez réessayer dans une heure.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Ne pas compter les inscriptions réussies
  handler: (req, res) => {
    res.status(429).json({
      error: 'Trop de tentatives d\'inscription. Veuillez attendre avant de réessayer.',
      retryAfter: Math.ceil(60 * 60 / 1000), // Secondes
    });
  },
});

module.exports = {
  authLimiter,
  apiLimiter,
  signupLimiter,
};

