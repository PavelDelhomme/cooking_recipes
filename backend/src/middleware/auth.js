const jwt = require('jsonwebtoken');
const { unauthorizedHandler, forbiddenHandler } = require('./errorHandler');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    // Si c'est une requête API (JSON), retourner JSON, sinon page HTML
    if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
      return res.status(401).json({ 
        message: 'Token d\'authentification requis',
        error: 'Vous devez être connecté pour accéder à cette ressource.'
      });
    }
    return unauthorizedHandler(req, res, 'Vous devez être connecté pour accéder à cette ressource.');
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      // Si c'est une requête API (JSON), retourner JSON, sinon page HTML
      if (req.headers['accept'] && req.headers['accept'].includes('application/json')) {
        return res.status(403).json({ 
          message: 'Token invalide ou expiré',
          error: 'Votre session a expiré. Veuillez vous reconnecter.'
        });
      }
      return forbiddenHandler(req, res, 'Votre session a expiré. Veuillez vous reconnecter.');
    }
    req.user = user;
    next();
  });
}

module.exports = { authenticateToken };

