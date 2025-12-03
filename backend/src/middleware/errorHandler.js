const path = require('path');
const fs = require('fs');

// Fonction pour servir une page d'erreur HTML
function serveErrorPage(res, statusCode, title, message, details = null) {
  const errorPage = `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title} - Cooking Recipes API</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .error-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 600px;
            width: 100%;
            padding: 40px;
            text-align: center;
        }
        .error-code {
            font-size: 120px;
            font-weight: bold;
            color: #667eea;
            line-height: 1;
            margin-bottom: 20px;
        }
        .error-title {
            font-size: 32px;
            color: #333;
            margin-bottom: 16px;
        }
        .error-message {
            font-size: 18px;
            color: #666;
            margin-bottom: 24px;
            line-height: 1.6;
        }
        .error-details {
            background: #f5f5f5;
            border-radius: 10px;
            padding: 16px;
            margin-top: 24px;
            text-align: left;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            color: #333;
            word-break: break-all;
        }
        .home-button {
            display: inline-block;
            margin-top: 24px;
            padding: 12px 32px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: background 0.3s;
        }
        .home-button:hover {
            background: #5568d3;
        }
        @media (max-width: 600px) {
            .error-code {
                font-size: 80px;
            }
            .error-title {
                font-size: 24px;
            }
            .error-message {
                font-size: 16px;
            }
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-code">${statusCode}</div>
        <h1 class="error-title">${title}</h1>
        <p class="error-message">${message}</p>
        ${details ? `<div class="error-details">${details}</div>` : ''}
        <a href="https://cookingrecipes.delhomme.ovh" class="home-button">Retour à l'accueil</a>
    </div>
</body>
</html>
  `;
  
  res.status(statusCode).setHeader('Content-Type', 'text/html; charset=utf-8').send(errorPage);
}

// Middleware pour gérer les erreurs 404
function notFoundHandler(req, res, next) {
  serveErrorPage(
    res,
    404,
    'Page non trouvée',
    'La ressource demandée n\'existe pas ou a été déplacée.',
    `URL: ${req.originalUrl}`
  );
}

// Middleware pour gérer les erreurs 429 (Too Many Requests)
function tooManyRequestsHandler(req, res, retryAfter = null) {
  const message = retryAfter 
    ? `Trop de requêtes. Veuillez réessayer dans ${Math.ceil(retryAfter / 60)} minute(s).`
    : 'Trop de requêtes. Veuillez réessayer plus tard.';
  
  serveErrorPage(
    res,
    429,
    'Trop de requêtes',
    message,
    `IP: ${req.clientIP || req.ip || 'Inconnue'}`
  );
}

// Middleware pour gérer les erreurs 403 (Forbidden - IP blacklistée)
function forbiddenHandler(req, res, message = 'Accès refusé') {
  serveErrorPage(
    res,
    403,
    'Accès refusé',
    message,
    `IP: ${req.clientIP || req.ip || 'Inconnue'}`
  );
}

// Middleware pour gérer les erreurs 401 (Unauthorized)
function unauthorizedHandler(req, res, message = 'Authentification requise') {
  serveErrorPage(
    res,
    401,
    'Authentification requise',
    message,
    'Veuillez vous connecter pour accéder à cette ressource.'
  );
}

// Middleware pour gérer les erreurs 500 (Internal Server Error)
function internalErrorHandler(err, req, res, next) {
  console.error('Erreur serveur:', err);
  
  const isDevelopment = process.env.NODE_ENV !== 'production';
  const details = isDevelopment ? err.stack : null;
  
  serveErrorPage(
    res,
    500,
    'Erreur serveur',
    'Une erreur interne s\'est produite. Veuillez réessayer plus tard.',
    details
  );
}

module.exports = {
  serveErrorPage,
  notFoundHandler,
  tooManyRequestsHandler,
  forbiddenHandler,
  unauthorizedHandler,
  internalErrorHandler,
};

