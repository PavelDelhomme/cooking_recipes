/**
 * Request Validator Middleware
 * Valide les headers HTTP, les méthodes, et les tailles de requêtes
 * Protection contre les attaques de type "Mass Assignment" et requêtes malformées
 */

const { logSecurityEvent, SECURITY_EVENTS } = require('./securityLogger');

// Headers HTTP requis ou interdits
const REQUIRED_HEADERS = {
  // Headers requis pour certaines routes
  'content-type': ['application/json', 'application/x-www-form-urlencoded'],
};

const FORBIDDEN_HEADERS = [
  'x-forwarded-host',
  'x-original-url',
  'x-rewrite-url',
];

// Taille maximale des requêtes par type
const MAX_REQUEST_SIZES = {
  'application/json': 10 * 1024 * 1024, // 10MB
  'application/x-www-form-urlencoded': 5 * 1024 * 1024, // 5MB
  'multipart/form-data': 20 * 1024 * 1024, // 20MB
  default: 10 * 1024 * 1024, // 10MB par défaut
};

/**
 * Valide les headers HTTP
 */
function validateHeaders(req) {
  const issues = [];

  // Vérifier les headers interdits
  for (const forbiddenHeader of FORBIDDEN_HEADERS) {
    if (req.headers[forbiddenHeader.toLowerCase()]) {
      issues.push({
        type: 'forbidden_header',
        header: forbiddenHeader,
        value: req.headers[forbiddenHeader.toLowerCase()],
      });
    }
  }

  // Vérifier les headers suspects
  const suspiciousHeaders = ['x-forwarded-for', 'x-real-ip'];
  for (const header of suspiciousHeaders) {
    const value = req.headers[header.toLowerCase()];
    if (value && !/^[\d\.:,\s]+$/.test(value)) {
      issues.push({
        type: 'suspicious_header',
        header,
        value,
      });
    }
  }

  // Vérifier Content-Type pour les requêtes avec body
  if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
    const contentType = req.headers['content-type'];
    if (contentType) {
      const allowedTypes = REQUIRED_HEADERS['content-type'];
      const isValid = allowedTypes.some(type => contentType.includes(type));
      if (!isValid) {
        issues.push({
          type: 'invalid_content_type',
          contentType,
          allowed: allowedTypes,
        });
      }
    }
  }

  return issues;
}

/**
 * Valide la taille de la requête
 */
function validateRequestSize(req) {
  const contentType = req.headers['content-type'] || 'default';
  const maxSize = MAX_REQUEST_SIZES[contentType] || MAX_REQUEST_SIZES.default;
  const contentLength = parseInt(req.headers['content-length'] || '0', 10);

  if (contentLength > maxSize) {
    return {
      valid: false,
      size: contentLength,
      maxSize,
    };
  }

  return { valid: true };
}

/**
 * Valide les méthodes HTTP
 */
function validateMethod(req) {
  const allowedMethods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD'];
  return allowedMethods.includes(req.method);
}

/**
 * Valide les paramètres de requête (protection Mass Assignment)
 */
function validateQueryParams(req) {
  const suspiciousParams = [
    '__proto__',
    'constructor',
    'prototype',
    'password',
    'token',
    'secret',
    'key',
    'api_key',
  ];

  const issues = [];
  for (const param of Object.keys(req.query)) {
    if (suspiciousParams.includes(param.toLowerCase())) {
      issues.push({
        type: 'suspicious_query_param',
        param,
      });
    }
  }

  return issues;
}

/**
 * Middleware de validation des requêtes
 */
function requestValidatorMiddleware(req, res, next) {
  const clientIP = req.ip || req.connection.remoteAddress;
  const issues = [];

  // Valider la méthode HTTP
  if (!validateMethod(req)) {
    logSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, {
      ip: clientIP,
      url: req.url,
      method: req.method,
      reason: 'Invalid HTTP method',
      severity: 'MEDIUM',
    });
    return res.status(405).json({
      error: 'Method Not Allowed',
      message: `Méthode HTTP ${req.method} non autorisée`,
      code: 'INVALID_METHOD',
    });
  }

  // Valider les headers
  const headerIssues = validateHeaders(req);
  if (headerIssues.length > 0) {
    issues.push(...headerIssues);
    logSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, {
      ip: clientIP,
      url: req.url,
      method: req.method,
      headerIssues,
      severity: 'MEDIUM',
    });
  }

  // Valider la taille de la requête
  const sizeValidation = validateRequestSize(req);
  if (!sizeValidation.valid) {
    logSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, {
      ip: clientIP,
      url: req.url,
      method: req.method,
      reason: 'Request too large',
      size: sizeValidation.size,
      maxSize: sizeValidation.maxSize,
      severity: 'HIGH',
    });
    return res.status(413).json({
      error: 'Payload Too Large',
      message: `Requête trop volumineuse (max: ${sizeValidation.maxSize / 1024 / 1024}MB)`,
      code: 'REQUEST_TOO_LARGE',
    });
  }

  // Valider les paramètres de requête
  const queryIssues = validateQueryParams(req);
  if (queryIssues.length > 0) {
    issues.push(...queryIssues);
    logSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, {
      ip: clientIP,
      url: req.url,
      method: req.method,
      queryIssues,
      severity: 'HIGH',
    });
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Paramètres de requête suspects détectés',
      code: 'SUSPICIOUS_QUERY_PARAMS',
    });
  }

  // Si des problèmes mineurs sont détectés mais pas bloquants, continuer
  if (issues.length > 0 && issues.every(i => i.type === 'suspicious_header')) {
    // Logger mais ne pas bloquer pour les headers suspects (peuvent être légitimes)
    console.warn('⚠️  Headers suspects détectés:', issues);
  }

  next();
}

module.exports = {
  requestValidatorMiddleware,
  validateHeaders,
  validateRequestSize,
  validateMethod,
  validateQueryParams,
};

