/**
 * Denial of Service (DoS) Protection Middleware
 * Protection avancée contre les attaques de déni de service
 */

const rateLimit = require('express-rate-limit');
const { getClientIP } = require('./ipBlacklist');
const { logSecurityEvent, SECURITY_EVENTS } = require('./securityLogger');

// Limite globale par IP (plus stricte que le rate limiter général)
const globalDosLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 60, // 60 requêtes par minute par IP
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => getClientIP(req),
  handler: (req, res) => {
    const clientIP = getClientIP(req);
    
    logSecurityEvent(SECURITY_EVENTS.RATE_LIMIT, {
      ip: clientIP,
      endpoint: req.url,
      limit: 60,
      window: '1 minute',
      severity: 'HIGH',
      type: 'DoS protection',
    });

    res.status(429).json({
      error: 'Too Many Requests',
      message: 'Trop de requêtes. Protection DoS activée.',
      retryAfter: 60,
      code: 'DOS_PROTECTION',
    });
  },
});

// Limite pour les requêtes lourdes (POST, PUT, DELETE)
const heavyRequestLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 20, // 20 requêtes lourdes par minute
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => getClientIP(req),
  skip: (req) => {
    // Ne pas limiter les requêtes GET et HEAD
    return ['GET', 'HEAD', 'OPTIONS'].includes(req.method);
  },
  handler: (req, res) => {
    const clientIP = getClientIP(req);
    
    logSecurityEvent(SECURITY_EVENTS.RATE_LIMIT, {
      ip: clientIP,
      endpoint: req.url,
      method: req.method,
      limit: 20,
      window: '1 minute',
      severity: 'HIGH',
      type: 'Heavy request DoS protection',
    });

    res.status(429).json({
      error: 'Too Many Requests',
      message: 'Trop de requêtes modifiantes. Protection DoS activée.',
      retryAfter: 60,
      code: 'HEAVY_REQUEST_DOS',
    });
  },
});

/**
 * Détecte les patterns d'attaque DoS
 */
function detectDosPattern(req) {
  const clientIP = getClientIP(req);
  const userAgent = req.headers['user-agent'] || '';
  const patterns = [];

  // Détecter les user-agents suspects
  if (userAgent.length > 500) {
    patterns.push('suspicious_user_agent_length');
  }

  // Détecter les URLs anormalement longues
  if (req.url.length > 2000) {
    patterns.push('suspicious_url_length');
  }

  // Détecter les headers suspects
  const totalHeaderSize = Object.keys(req.headers).reduce((sum, key) => {
    return sum + key.length + (req.headers[key]?.length || 0);
  }, 0);
  
  if (totalHeaderSize > 10000) {
    patterns.push('suspicious_header_size');
  }

  if (patterns.length > 0) {
    logSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, {
      ip: clientIP,
      url: req.url,
      method: req.method,
      patterns,
      severity: 'HIGH',
      type: 'DoS pattern detected',
    });
  }

  return patterns;
}

/**
 * Middleware de protection DoS
 */
function dosProtectionMiddleware(req, res, next) {
  // Détecter les patterns d'attaque
  const patterns = detectDosPattern(req);
  
  if (patterns.length > 0) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Requête suspecte détectée (protection DoS)',
      code: 'DOS_PATTERN_DETECTED',
    });
  }

  next();
}

module.exports = {
  globalDosLimiter,
  heavyRequestLimiter,
  dosProtectionMiddleware,
  detectDosPattern,
};

