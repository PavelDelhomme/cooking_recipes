/**
 * Error Handler Middleware
 * Gère les erreurs et sert des pages HTML personnalisées ou des réponses JSON
 */

const path = require('path');
const fs = require('fs');

// Chemin vers les pages d'erreur
const ERROR_PAGES_DIR = path.join(__dirname, '../../public/errors');

/**
 * Lit une page d'erreur HTML
 */
function readErrorPage(statusCode) {
  const errorPagePath = path.join(ERROR_PAGES_DIR, `${statusCode}.html`);
  try {
    if (fs.existsSync(errorPagePath)) {
      return fs.readFileSync(errorPagePath, 'utf8');
    }
  } catch (error) {
    console.error(`Erreur lecture page d'erreur ${statusCode}:`, error);
  }
  return null;
}

/**
 * Handler pour 401 Unauthorized
 */
function unauthorizedHandler(req, res, message = 'Vous devez être connecté pour accéder à cette ressource.') {
  // Si c'est une requête API (JSON), retourner JSON
  if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message,
      code: 'AUTH_REQUIRED',
    });
  }

  // Sinon, servir la page HTML
  const html = readErrorPage(401);
  if (html) {
    return res.status(401).type('text/html').send(html);
  }

  // Fallback si la page n'existe pas
  res.status(401).type('text/html').send(`
    <!DOCTYPE html>
    <html>
    <head><title>401 - Authentification requise</title></head>
    <body><h1>401 - Authentification requise</h1><p>${message}</p></body>
    </html>
  `);
}

/**
 * Handler pour 403 Forbidden
 */
function forbiddenHandler(req, res, message = 'Accès refusé.') {
  // Si c'est une requête API (JSON), retourner JSON
  if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
    return res.status(403).json({
      error: 'Forbidden',
      message,
      code: 'ACCESS_DENIED',
    });
  }

  // Sinon, servir la page HTML
  const html = readErrorPage(403);
  if (html) {
    return res.status(403).type('text/html').send(html);
  }

  // Fallback si la page n'existe pas
  res.status(403).type('text/html').send(`
    <!DOCTYPE html>
    <html>
    <head><title>403 - Accès refusé</title></head>
    <body><h1>403 - Accès refusé</h1><p>${message}</p></body>
    </html>
  `);
}

/**
 * Handler pour 404 Not Found
 */
function notFoundHandler(req, res) {
  // Si c'est une requête API (JSON), retourner JSON
  if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
    return res.status(404).json({
      error: 'Not Found',
      message: 'La ressource demandée n\'a pas été trouvée.',
      code: 'NOT_FOUND',
      path: req.path,
    });
  }

  // Sinon, servir la page HTML
  const html = readErrorPage(404);
  if (html) {
    return res.status(404).type('text/html').send(html);
  }

  // Fallback si la page n'existe pas
  res.status(404).type('text/html').send(`
    <!DOCTYPE html>
    <html>
    <head><title>404 - Page non trouvée</title></head>
    <body><h1>404 - Page non trouvée</h1><p>La page que vous recherchez n'existe pas.</p></body>
    </html>
  `);
}

/**
 * Handler pour 429 Too Many Requests
 */
function tooManyRequestsHandler(req, res, retryAfter = 60) {
  // Si c'est une requête API (JSON), retourner JSON
  if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
    return res.status(429).json({
      error: 'Too Many Requests',
      message: 'Trop de requêtes. Veuillez patienter avant de réessayer.',
      code: 'RATE_LIMIT_EXCEEDED',
      retryAfter,
    });
  }

  // Sinon, servir la page HTML avec retryAfter dans l'URL
  const html = readErrorPage(429);
  if (html) {
    // Injecter retryAfter dans l'URL si présent
    const htmlWithRetry = html.replace('location.reload()', `location.href='?retryAfter=${retryAfter}'`);
    return res.status(429)
      .set('Retry-After', retryAfter.toString())
      .type('text/html')
      .send(htmlWithRetry);
  }

  // Fallback si la page n'existe pas
  res.status(429)
    .set('Retry-After', retryAfter.toString())
    .type('text/html')
    .send(`
    <!DOCTYPE html>
    <html>
    <head><title>429 - Trop de requêtes</title></head>
    <body>
      <h1>429 - Trop de requêtes</h1>
      <p>Veuillez patienter ${retryAfter} secondes avant de réessayer.</p>
    </body>
    </html>
  `);
}

/**
 * Handler pour 500 Internal Server Error
 */
function internalErrorHandler(err, req, res, next) {
  console.error('Erreur serveur:', err);

  // Si c'est une requête API (JSON), retourner JSON
  if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
    return res.status(500).json({
      error: 'Internal Server Error',
      message: process.env.NODE_ENV === 'production' 
        ? 'Une erreur interne s\'est produite.'
        : err.message,
      code: 'INTERNAL_ERROR',
    });
  }

  // Sinon, servir la page HTML
  const html = readErrorPage(500);
  if (html) {
    return res.status(500).type('text/html').send(html);
  }

  // Fallback si la page n'existe pas
  res.status(500).type('text/html').send(`
    <!DOCTYPE html>
    <html>
    <head><title>500 - Erreur serveur</title></head>
    <body>
      <h1>500 - Erreur serveur</h1>
      <p>Une erreur interne s'est produite.</p>
      ${process.env.NODE_ENV !== 'production' ? `<pre>${err.stack}</pre>` : ''}
    </body>
    </html>
  `);
}

module.exports = {
  unauthorizedHandler,
  forbiddenHandler,
  notFoundHandler,
  tooManyRequestsHandler,
  internalErrorHandler,
};
