/**
 * Middleware pour vérifier si l'utilisateur est un administrateur
 * Seuls les comptes dumb@delhomme.ovh et dev@delhomme.ovh sont autorisés
 */

const ADMIN_EMAILS = ['dumb@delhomme.ovh', 'dev@delhomme.ovh'];

function isAdmin(email) {
  return ADMIN_EMAILS.includes(email?.toLowerCase());
}

function adminCheck(req, res, next) {
  // Vérifier que l'utilisateur est authentifié
  if (!req.user || !req.user.email) {
    return res.status(401).json({
      success: false,
      message: 'Authentification requise',
    });
  }

  // Vérifier que l'utilisateur est admin
  if (!isAdmin(req.user.email)) {
    return res.status(403).json({
      success: false,
      message: 'Accès refusé. Réservé aux administrateurs.',
    });
  }

  next();
}

module.exports = { adminCheck, isAdmin };

