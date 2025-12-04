/**
 * Input Sanitizer Middleware
 * Nettoie et sanitize tous les inputs pour prévenir les injections
 */

const { sanitizeInput } = require('./waf');

/**
 * Sanitize récursivement un objet
 */
function sanitizeObject(obj) {
  if (Array.isArray(obj)) {
    return obj.map(item => {
      if (typeof item === 'string') {
        return sanitizeInput(item);
      } else if (typeof item === 'object' && item !== null) {
        return sanitizeObject(item);
      }
      return item;
    });
  } else if (typeof obj === 'object' && obj !== null) {
    const sanitized = {};
    for (const key in obj) {
      if (typeof obj[key] === 'string') {
        sanitized[key] = sanitizeInput(obj[key]);
      } else if (typeof obj[key] === 'object' && obj[key] !== null) {
        sanitized[key] = sanitizeObject(obj[key]);
      } else {
        sanitized[key] = obj[key];
      }
    }
    return sanitized;
  }
  return obj;
}

/**
 * Middleware pour sanitizer les inputs
 */
function inputSanitizerMiddleware(req, res, next) {
  // Sanitizer le body
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeObject(req.body);
  }

  // Sanitizer les query parameters
  if (req.query && typeof req.query === 'object') {
    req.query = sanitizeObject(req.query);
  }

  // Sanitizer les params
  if (req.params && typeof req.params === 'object') {
    req.params = sanitizeObject(req.params);
  }

  next();
}

module.exports = {
  inputSanitizerMiddleware,
  sanitizeObject,
};

