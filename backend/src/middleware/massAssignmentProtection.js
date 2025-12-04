/**
 * Mass Assignment Protection Middleware
 * Protège contre les attaques de type "Mass Assignment" en validant strictement les champs autorisés
 */

const { logSecurityEvent, SECURITY_EVENTS } = require('./securityLogger');

// Champs interdits dans toutes les requêtes
const FORBIDDEN_FIELDS = [
  '__proto__',
  'constructor',
  'prototype',
  'password', // Ne doit jamais être modifié directement
  'isAdmin',
  'isPremium',
  'premiumExpiresAt',
  'createdAt',
  'updatedAt',
  'id', // ID ne doit jamais être modifiable
];

// Champs autorisés par route (whitelist)
const ALLOWED_FIELDS = {
  '/api/auth/signup': ['email', 'password', 'name'],
  '/api/auth/signin': ['email', 'password'],
  '/api/users/:id': ['name', 'avatarUrl'],
  '/api/pantry': ['name', 'quantity', 'unit', 'expiryDate'],
  '/api/meal-plans': ['date', 'mealType', 'recipeId', 'recipeTitle', 'recipeImage', 'recipeData'],
  '/api/shopping-list': ['name', 'quantity', 'unit', 'purchased'],
  '/api/favorites': ['recipeId', 'recipeTitle', 'recipeImage', 'recipeData'],
};

/**
 * Trouve la route correspondante dans les champs autorisés
 */
function findMatchingRoute(path, method) {
  // Essayer de matcher exactement
  for (const route in ALLOWED_FIELDS) {
    if (path === route || path.startsWith(route)) {
      return ALLOWED_FIELDS[route];
    }
  }

  // Essayer de matcher avec des paramètres (ex: /api/users/123 -> /api/users/:id)
  const routePattern = path.replace(/\/\d+/g, '/:id').replace(/\/[a-f0-9-]+/g, '/:id');
  if (ALLOWED_FIELDS[routePattern]) {
    return ALLOWED_FIELDS[routePattern];
  }

  return null;
}

/**
 * Valide les champs d'une requête
 */
function validateFields(req) {
  const body = req.body || {};
  const issues = [];

  // Vérifier les champs interdits
  for (const field of Object.keys(body)) {
    const lowerField = field.toLowerCase();
    
    if (FORBIDDEN_FIELDS.some(forbidden => lowerField.includes(forbidden.toLowerCase()))) {
      issues.push({
        type: 'forbidden_field',
        field,
        value: body[field],
      });
    }
  }

  // Vérifier les champs autorisés (whitelist)
  const allowedFields = findMatchingRoute(req.path, req.method);
  if (allowedFields) {
    for (const field of Object.keys(body)) {
      if (!allowedFields.includes(field)) {
        issues.push({
          type: 'unauthorized_field',
          field,
          allowed: allowedFields,
        });
      }
    }
  }

  return issues;
}

/**
 * Middleware de protection contre Mass Assignment
 */
function massAssignmentProtectionMiddleware(req, res, next) {
  // Seulement pour les requêtes avec body
  if (!['POST', 'PUT', 'PATCH'].includes(req.method)) {
    return next();
  }

  // Exclure certaines routes
  const excludedPaths = ['/health', '/api/health'];
  if (excludedPaths.some(path => req.path === path || req.path.startsWith(path))) {
    return next();
  }

  const issues = validateFields(req);

  if (issues.length > 0) {
    const clientIP = req.ip || req.connection.remoteAddress;
    
    logSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, {
      ip: clientIP,
      url: req.url,
      method: req.method,
      issues,
      severity: 'HIGH',
    });

    return res.status(400).json({
      error: 'Bad Request',
      message: 'Champs non autorisés ou interdits détectés',
      code: 'MASS_ASSIGNMENT_DETECTED',
      issues: issues.map(i => i.field),
    });
  }

  next();
}

module.exports = {
  massAssignmentProtectionMiddleware,
  validateFields,
};

