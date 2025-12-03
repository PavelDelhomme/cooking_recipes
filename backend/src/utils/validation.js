const validator = require('validator');

/**
 * Valide un email
 */
function validateEmail(email) {
  if (!email || typeof email !== 'string') {
    return { valid: false, error: 'Email requis' };
  }
  
  const trimmedEmail = email.trim().toLowerCase();
  
  if (!validator.isEmail(trimmedEmail)) {
    return { valid: false, error: 'Format d\'email invalide' };
  }
  
  if (trimmedEmail.length > 254) {
    return { valid: false, error: 'Email trop long (max 254 caractères)' };
  }
  
  return { valid: true, email: trimmedEmail };
}

/**
 * Valide la force d'un mot de passe
 */
function validatePassword(password) {
  if (!password || typeof password !== 'string') {
    return { valid: false, error: 'Mot de passe requis' };
  }
  
  if (password.length < 8) {
    return { valid: false, error: 'Le mot de passe doit contenir au moins 8 caractères' };
  }
  
  if (password.length > 128) {
    return { valid: false, error: 'Le mot de passe est trop long (max 128 caractères)' };
  }
  
  // Vérifier la complexité
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumbers = /\d/.test(password);
  const hasSpecialChar = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);
  
  const complexityScore = [hasUpperCase, hasLowerCase, hasNumbers, hasSpecialChar].filter(Boolean).length;
  
  if (complexityScore < 3) {
    return {
      valid: false,
      error: 'Le mot de passe doit contenir au moins 3 des éléments suivants : majuscules, minuscules, chiffres, caractères spéciaux',
    };
  }
  
  // Vérifier les mots de passe courants/faibles
  const commonPasswords = [
    'password', '12345678', 'password123', 'admin123', 'qwerty123',
    'welcome123', 'letmein', 'monkey123', 'dragon123', 'master123',
  ];
  
  if (commonPasswords.some(common => password.toLowerCase().includes(common))) {
    return { valid: false, error: 'Ce mot de passe est trop commun. Veuillez en choisir un plus fort.' };
  }
  
  return { valid: true };
}

/**
 * Sanitize une chaîne de caractères
 */
function sanitizeString(str, maxLength = 255) {
  if (!str || typeof str !== 'string') {
    return null;
  }
  
  // Trim et limiter la longueur
  let sanitized = str.trim();
  
  if (sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength);
  }
  
  // Enlever les caractères de contrôle
  sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, '');
  
  return sanitized || null;
}

/**
 * Valide et sanitize un nom
 */
function validateName(name) {
  if (!name) {
    return { valid: true, name: null }; // Nom optionnel
  }
  
  const sanitized = sanitizeString(name, 100);
  
  if (!sanitized) {
    return { valid: true, name: null };
  }
  
  if (sanitized.length < 2) {
    return { valid: false, error: 'Le nom doit contenir au moins 2 caractères' };
  }
  
  // Vérifier qu'il ne contient pas que des caractères spéciaux
  if (!/[\p{L}\p{N}]/u.test(sanitized)) {
    return { valid: false, error: 'Le nom contient des caractères invalides' };
  }
  
  return { valid: true, name: sanitized };
}

module.exports = {
  validateEmail,
  validatePassword,
  sanitizeString,
  validateName,
};

