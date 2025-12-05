/**
 * Security Logger Middleware
 * Enregistre toutes les activités de sécurité pour audit et détection d'intrusion
 */

const fs = require('fs');
const path = require('path');
const { getDatabase } = require('../database/db');

const LOG_DIR = path.join(__dirname, '../../logs/security');
const LOG_FILE = path.join(LOG_DIR, `security-${new Date().toISOString().split('T')[0]}.log`);

// Créer le répertoire de logs s'il n'existe pas
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}

/**
 * Types d'événements de sécurité
 */
const SECURITY_EVENTS = {
  AUTH_SUCCESS: 'AUTH_SUCCESS',
  AUTH_FAILURE: 'AUTH_FAILURE',
  RATE_LIMIT: 'RATE_LIMIT',
  IP_BLACKLISTED: 'IP_BLACKLISTED',
  WAF_BLOCKED: 'WAF_BLOCKED',
  CSRF_INVALID: 'CSRF_INVALID',
  SQL_INJECTION: 'SQL_INJECTION',
  XSS_ATTEMPT: 'XSS_ATTEMPT',
  PATH_TRAVERSAL: 'PATH_TRAVERSAL',
  COMMAND_INJECTION: 'COMMAND_INJECTION',
  SUSPICIOUS_ACTIVITY: 'SUSPICIOUS_ACTIVITY',
  ADMIN_ACTION: 'ADMIN_ACTION',
  DATA_ACCESS: 'DATA_ACCESS',
  ERROR: 'ERROR',
  REPLAY_ATTACK: 'REPLAY_ATTACK',
  MASS_ASSIGNMENT: 'MASS_ASSIGNMENT',
  DOS_ATTACK: 'DOS_ATTACK',
  TOKEN_REVOKED: 'TOKEN_REVOKED',
  INVALID_REQUEST: 'INVALID_REQUEST',
};

/**
 * Logger un événement de sécurité
 */
function logSecurityEvent(eventType, details) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    event: eventType,
    ...details,
  };

  // Écrire dans le fichier de log
  const logLine = JSON.stringify(logEntry) + '\n';
  fs.appendFileSync(LOG_FILE, logLine, 'utf8');

  // Écrire dans la base de données pour recherche rapide
  try {
    const db = getDatabase();
    db.run(
      `INSERT INTO security_logs (timestamp, event_type, ip_address, user_id, details, severity)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        logEntry.timestamp,
        eventType,
        details.ip || details.ipAddress || 'unknown',
        details.userId || null,
        JSON.stringify(details),
        details.severity || 'INFO',
      ],
      (err) => {
        if (err) {
          console.error('Erreur écriture log sécurité DB:', err);
        }
      }
    );
  } catch (error) {
    console.error('Erreur log sécurité:', error);
  }

  // Afficher dans la console selon la sévérité
  const severity = details.severity || 'INFO';
  // Formater la date complète pour l'affichage
  const formattedDate = new Date().toLocaleString('fr-FR', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    timeZone: 'Europe/Paris'
  });
  
  // Créer un objet avec la date complète pour l'affichage
  const logOutput = {
    date: formattedDate,
    timestamp: logEntry.timestamp,
    ...details
  };
  
  if (severity === 'CRITICAL' || severity === 'HIGH') {
    console.error(`🚨 [${severity}] ${eventType}:`, logOutput);
  } else if (severity === 'MEDIUM' || severity === 'WARNING') {
    console.warn(`⚠️  [${severity}] ${eventType}:`, logOutput);
  } else {
    console.log(`ℹ️  [${severity}] ${eventType}:`, logOutput);
  }
}

/**
 * Middleware pour logger toutes les requêtes
 */
function securityLoggerMiddleware(req, res, next) {
  const startTime = Date.now();
  const clientIP = req.ip || req.connection.remoteAddress;

  // Logger la réponse (après que tous les middlewares aient été exécutés)
  // Cela permet de capturer le userId si l'utilisateur est authentifié
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const statusCode = res.statusCode;
    
    // Récupérer le userId après l'authentification (si disponible)
    // Le middleware authenticateToken définit req.user.userId ou req.user.id
    const userId = req.user?.userId || req.user?.id || null;

    // Logger l'accès aux données avec le userId correct
    logSecurityEvent(SECURITY_EVENTS.DATA_ACCESS, {
      ip: clientIP,
      userId,
      method: req.method,
      url: req.url,
      userAgent: req.headers['user-agent'],
      statusCode,
      duration,
      severity: 'INFO',
    });

    // Logger les erreurs
    if (statusCode >= 400) {
      logSecurityEvent(SECURITY_EVENTS.ERROR, {
        ip: clientIP,
        userId,
        method: req.method,
        url: req.url,
        statusCode,
        duration,
        severity: statusCode >= 500 ? 'HIGH' : 'MEDIUM',
      });
    }
  });

  next();
}

module.exports = {
  logSecurityEvent,
  securityLoggerMiddleware,
  SECURITY_EVENTS,
};

