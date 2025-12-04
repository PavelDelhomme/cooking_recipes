/**
 * Web Application Firewall (WAF) Middleware
 * Détecte et bloque les attaques courantes adaptées à notre stack :
 * - SQL Injection (SQLite)
 * - XSS (Cross-Site Scripting)
 * - Path Traversal
 * - Command Injection
 * - File Upload malveillants
 * 
 * Stack technique :
 * - Base de données : SQLite
 * - Backend : Node.js/Express
 * - Frontend : Flutter Web
 */

const { addToBlacklist } = require('./ipBlacklist');
const { logSecurityEvent, SECURITY_EVENTS } = require('./securityLogger');

// Patterns de détection d'attaques adaptés à notre stack
const ATTACK_PATTERNS = {
  sqlInjection: [
    // Commandes SQL dangereuses
    /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE|UNION|SCRIPT|TRUNCATE|REPLACE)\b)/i,
    // Patterns d'injection classiques
    /(\b(OR|AND)\s+\d+\s*=\s*\d+)/i,
    /(\b(UNION|SELECT).*FROM)/i,
    /(\b(SELECT|INSERT|UPDATE|DELETE).*WHERE)/i,
    /(\b(DROP|CREATE|ALTER).*(TABLE|DATABASE|INDEX|VIEW|TRIGGER))/i,
    // Caractères spéciaux SQL dangereux
    /(['";|&`*%()\\])/i,
    // Injection via commentaires SQL
    /(--|\/\*|\*\/|#)/i,
    // Tentatives de bypass avec espaces
    /(\bSELECT\s+\*\s+FROM)/i,
  ],
  xss: [
    /<script[^>]*>.*?<\/script>/gi,
    /<iframe[^>]*>.*?<\/iframe>/gi,
    /javascript:/gi,
    /on\w+\s*=/gi,
    /<img[^>]*src[^>]*=.*javascript:/gi,
    /<svg[^>]*onload/gi,
    /<body[^>]*onload/gi,
    /<input[^>]*onfocus/gi,
    /eval\s*\(/gi,
    /expression\s*\(/gi,
  ],
  pathTraversal: [
    /\.\.\//g,
    /\.\.\\/g,
    /\.\.%2F/gi,
    /\.\.%5C/gi,
    /\.\.%252F/gi,
    /\.\.%255C/gi,
    /\/etc\/passwd/gi,
    /\/etc\/shadow/gi,
    /\/proc\/self\/environ/gi,
    /\/windows\/system32/gi,
  ],
  commandInjection: [
    /([|&;`$])/g,
    /(\$\(|\$\{)/g,
    /(\b(cat|ls|pwd|whoami|id|uname|ps|kill|rm|mv|cp|chmod|chown|sudo|su)\b)/i,
    /(\b(bash|sh|zsh|fish|dash|ksh)\b)/i,
    /(\b(nc|netcat|wget|curl|ping|nmap)\b)/i,
    /(\b(python|perl|ruby|php|node|npm)\b)/i,
    /(>\s*\w+|<\s*\w+)/g,
  ],
  fileUpload: [
    /\.(php|phtml|php3|php4|php5|phps|cgi|exe|pl|asp|aspx|jsp|sh|bat|cmd|com|pif|scr|vbs|js|jar|war|ear|zip|rar|7z|tar|gz|bz2)/i,
  ],
};

// Patterns suspects mais moins critiques (warning seulement)
// Adaptés à notre stack : Node.js/Express + SQLite + Flutter Web
const SUSPICIOUS_PATTERNS = {
  suspiciousHeaders: [
    // User-agents de bots/scrapers
    /user-agent.*(bot|crawler|spider|scraper)/i,
    // Outils de ligne de commande
    /user-agent.*(curl|wget|python|java|go-http|postman|insomnia)/i,
  ],
  suspiciousPaths: [
    // Chemins d'administration sensibles
    /(admin|wp-admin|phpmyadmin|mysql|sql|database|config|\.env|\.git)/i,
    // Tentatives d'accès à des fichiers système
    /(\.php|\.asp|\.jsp|\.sh|\.bat|\.exe|\.sql|\.db)/i,
    // Chemins Node.js sensibles
    /(node_modules|package\.json|package-lock\.json|\.npm)/i,
  ],
};

/**
 * Détecte les attaques dans une chaîne
 */
function detectAttack(input, type = 'all') {
  if (!input || typeof input !== 'string') {
    return null;
  }

  const detected = {
    type: null,
    pattern: null,
    input: input.substring(0, 100), // Limiter la longueur pour les logs
  };

  // Vérifier les patterns selon le type demandé
  const patternsToCheck = type === 'all' 
    ? Object.keys(ATTACK_PATTERNS)
    : [type];

  for (const attackType of patternsToCheck) {
    if (!ATTACK_PATTERNS[attackType]) continue;
    
    for (const pattern of ATTACK_PATTERNS[attackType]) {
      if (pattern.test(input)) {
        detected.type = attackType;
        detected.pattern = pattern.toString();
        return detected;
      }
    }
  }

  return null;
}

/**
 * Détecte les patterns suspects (warning seulement)
 */
function detectSuspicious(input) {
  if (!input || typeof input !== 'string') {
    return null;
  }

  for (const [category, patterns] of Object.entries(SUSPICIOUS_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(input)) {
        return { category, pattern: pattern.toString() };
      }
    }
  }

  return null;
}

/**
 * Nettoie et sanitize une valeur
 */
function sanitizeInput(input) {
  if (typeof input === 'string') {
    // Échapper les caractères dangereux
    return input
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/\//g, '&#x2F;');
  }
  return input;
}

/**
 * Middleware WAF principal
 */
function wafMiddleware(req, res, next) {
  const clientIP = req.ip || req.connection.remoteAddress;
  const attackDetected = {
    ip: clientIP,
    url: req.url,
    method: req.method,
    timestamp: new Date().toISOString(),
    attacks: [],
    suspicious: [],
  };

  // Vérifier l'URL
  const urlAttack = detectAttack(req.url);
  if (urlAttack) {
    attackDetected.attacks.push({
      location: 'URL',
      ...urlAttack,
    });
  }

  const urlSuspicious = detectSuspicious(req.url);
  if (urlSuspicious) {
    attackDetected.suspicious.push({
      location: 'URL',
      ...urlSuspicious,
    });
  }

  // Vérifier les query parameters
  if (req.query) {
    for (const [key, value] of Object.entries(req.query)) {
      const paramAttack = detectAttack(String(value));
      if (paramAttack) {
        attackDetected.attacks.push({
          location: `Query param: ${key}`,
          ...paramAttack,
        });
      }
    }
  }

  // Vérifier le body
  if (req.body && typeof req.body === 'object') {
    const bodyStr = JSON.stringify(req.body);
    const bodyAttack = detectAttack(bodyStr);
    if (bodyAttack) {
      attackDetected.attacks.push({
        location: 'Body',
        ...bodyAttack,
      });
    }

    // Sanitizer les valeurs du body
    sanitizeObject(req.body);
  }

  // Vérifier les headers
  const userAgent = req.headers['user-agent'] || '';
  const userAgentSuspicious = detectSuspicious(userAgent);
  if (userAgentSuspicious) {
    attackDetected.suspicious.push({
      location: 'User-Agent',
      ...userAgentSuspicious,
    });
  }

  // Si une attaque est détectée, bloquer la requête
  if (attackDetected.attacks.length > 0) {
    const attackType = attackDetected.attacks[0].type;
    
    // Logger l'attaque dans le système de sécurité
    logSecurityEvent(SECURITY_EVENTS.WAF_BLOCKED, {
      ip: clientIP,
      url: req.url,
      method: req.method,
      attackType,
      attacks: attackDetected.attacks,
      severity: 'HIGH',
    });

    // Ajouter l'IP à la blacklist (temporairement, 1 heure)
    addToBlacklist(clientIP, 60, `WAF: ${attackType} détecté`);

    // Retourner une erreur 403
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Requête bloquée par le WAF',
      code: 'WAF_BLOCKED',
    });
  }

  // Logger les activités suspectes (mais ne pas bloquer)
  if (attackDetected.suspicious.length > 0) {
    console.warn('⚠️  WAF: Activité suspecte:', JSON.stringify(attackDetected.suspicious, null, 2));
  }

  next();
}

/**
 * Sanitize récursivement un objet
 */
function sanitizeObject(obj) {
  if (Array.isArray(obj)) {
    obj.forEach((item, index) => {
      if (typeof item === 'string') {
        obj[index] = sanitizeInput(item);
      } else if (typeof item === 'object' && item !== null) {
        sanitizeObject(item);
      }
    });
  } else if (typeof obj === 'object' && obj !== null) {
    for (const key in obj) {
      if (typeof obj[key] === 'string') {
        obj[key] = sanitizeInput(obj[key]);
      } else if (typeof obj[key] === 'object' && obj[key] !== null) {
        sanitizeObject(obj[key]);
      }
    }
  }
}

module.exports = {
  wafMiddleware,
  detectAttack,
  detectSuspicious,
  sanitizeInput,
};

