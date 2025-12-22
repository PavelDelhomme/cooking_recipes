// Charger les variables d'environnement
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const hpp = require('hpp');
const os = require('os');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const pantryRoutes = require('./routes/pantry');
const mealPlanRoutes = require('./routes/mealPlans');
const shoppingListRoutes = require('./routes/shoppingList');
const favoritesRoutes = require('./routes/favorites');
const adminRoutes = require('./routes/admin');
const mlAdminRoutes = require('./routes/mlAdmin');
const translationRoutes = require('./routes/translation');
const translationFeedbackRoutes = require('./routes/translationFeedback');
const recipesRoutes = require('./routes/recipes');
const { initDatabase, createDefaultUser } = require('./database/db');
const { checkBlacklist } = require('./middleware/ipBlacklist');
const { wafMiddleware } = require('./middleware/waf');
const { generateCSRFMiddleware, verifyCSRFMiddleware } = require('./middleware/csrf');
const { securityLoggerMiddleware } = require('./middleware/securityLogger');
const { inputSanitizerMiddleware } = require('./middleware/inputSanitizer');
const { requestValidatorMiddleware } = require('./middleware/requestValidator');
const { replayProtectionMiddleware } = require('./middleware/replayProtection');
const { massAssignmentProtectionMiddleware } = require('./middleware/massAssignmentProtection');
const { globalDosLimiter, heavyRequestLimiter, dosProtectionMiddleware } = require('./middleware/dosProtection');
const { sessionSecurityMiddleware } = require('./middleware/sessionSecurity');
const { 
  notFoundHandler, 
  internalErrorHandler 
} = require('./middleware/errorHandler');

// Fonction pour obtenir l'IP de la machine
function getMachineIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Ignorer les adresses internes et IPv6
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

const app = express();
const PORT = process.env.PORT || 7272;

// Trust proxy pour obtenir la vraie IP du client (derrière Nginx)
app.set('trust proxy', true);

// CORS configuré de manière sécurisée (AVANT Helmet pour éviter les conflits)
const corsOptions = {
  origin: function (origin, callback) {
    // En production, vérifier l'origine
    if (process.env.NODE_ENV === 'production') {
      // Domaines autorisés par défaut (uniquement frontend, pas l'API)
      const defaultOrigins = [
        'https://cookingrecipes.delhomme.ovh',
        'https://cookingrecipe.delhomme.ovh', // Ancien domaine pour redirection
      ];
      const allowedOrigins = process.env.ALLOWED_ORIGINS 
        ? [...defaultOrigins, ...process.env.ALLOWED_ORIGINS.split(',')]
        : defaultOrigins;
      
      // Autoriser les requêtes sans origine (Postman, curl, etc.)
      if (!origin) {
        return callback(null, true);
      }
      
      // Vérifier si l'origine est autorisée
      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        console.warn(`CORS: Origin not allowed: ${origin}`);
        callback(new Error('Not allowed by CORS'));
      }
    } else {
      // En développement, autoriser toutes les origines
      callback(null, true);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'x-nonce', 'x-timestamp'],
  exposedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 200,
};

// Appliquer CORS AVANT Helmet pour éviter les conflits
app.use(cors(corsOptions));

// Sécurité : Helmet pour les headers HTTP sécurisés (APRÈS CORS)
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  crossOriginEmbedderPolicy: false, // Désactivé pour permettre les images externes
  crossOriginResourcePolicy: { policy: "cross-origin" }, // Permettre les ressources cross-origin
}));

// Logging de sécurité (en premier pour capturer toutes les requêtes)
app.use(securityLoggerMiddleware);

// Protection DoS globale (avant tout)
app.use('/api', globalDosLimiter);
app.use('/api', heavyRequestLimiter);
app.use('/api', dosProtectionMiddleware);

// Validation des requêtes (headers, méthodes, tailles)
app.use('/api', requestValidatorMiddleware);

// WAF - Web Application Firewall (avant les autres middlewares)
app.use('/api', wafMiddleware);

// Vérification de la blacklist pour toutes les routes API
app.use('/api', checkBlacklist);

// Protection contre les attaques de rejeu (désactivée en développement)
if (process.env.NODE_ENV === 'production') {
  app.use('/api', replayProtectionMiddleware);
}

// Protection contre Mass Assignment
app.use('/api', massAssignmentProtectionMiddleware);

// Sécurité des sessions (vérification tokens révoqués)
app.use('/api', sessionSecurityMiddleware);

// CSRF Protection (désactivée en développement pour faciliter les tests)
if (process.env.NODE_ENV === 'production') {
  app.use('/api', generateCSRFMiddleware);
  app.use('/api', verifyCSRFMiddleware);
}

// Input Sanitization (après WAF mais avant les routes)
app.use('/api', inputSanitizerMiddleware);

// Protection contre NoSQL Injection (même si on utilise SQLite, bonne pratique)
app.use(mongoSanitize());

// Protection contre HTTP Parameter Pollution
app.use(hpp());

// Body parser avec limites (AVANT les routes)
app.use(bodyParser.json({ 
  limit: '10mb',
  type: 'application/json',
  strict: false // Permettre des JSON non stricts
}));
app.use(bodyParser.urlencoded({ 
  extended: true, 
  limit: '10mb',
  type: 'application/x-www-form-urlencoded'
}));

// Servir les fichiers statiques (pages d'erreur)
app.use(express.static('public'));

// Middleware pour forcer l'encodage UTF-8
app.use((req, res, next) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/pantry', pantryRoutes);
app.use('/api/meal-plans', mealPlanRoutes);
app.use('/api/shopping-list', shoppingListRoutes);
app.use('/api/favorites', favoritesRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/ml-admin', mlAdminRoutes);
app.use('/api/translation', translationRoutes);
app.use('/api/translation-feedback', translationFeedbackRoutes);
app.use('/api/recipes', recipesRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'API is running' });
});

// Gestion des erreurs 404
app.use(notFoundHandler);

// Gestion des erreurs serveur
app.use(internalErrorHandler);

// Initialize database and start server
initDatabase().then(() => {
  // Créer un compte par défaut si aucun utilisateur n'existe
  return createDefaultUser();
}).then(async () => {
    // Charger les modèles ML de traduction au démarrage
    try {
      const mlTranslationEngine = require('./services/ml_translation_engine');
      await mlTranslationEngine.loadModels();
      
      // Charger le service de reconnaissance d'intention
      const intentRecognitionService = require('./services/intent_recognition_service');
      await intentRecognitionService.loadModels();
      console.log('✅ Service de reconnaissance d\'intention chargé');
    
    // Démarrer l'entraînement automatique périodique (toutes les 6 heures)
    const AUTO_TRAIN_INTERVAL = 6 * 60 * 60 * 1000; // 6 heures
    const AUTO_VALIDATE_INTERVAL = 1 * 60 * 60 * 1000; // 1 heure pour la validation auto
    const AUTO_CRITIQUE_INTERVAL = 2 * 60 * 60 * 1000; // 2 heures pour l'autocritique
    
    // Validation automatique des feedbacks (toutes les heures)
    setInterval(async () => {
      try {
        const MLAutoValidator = require('../scripts/ml_auto_validator');
        const validator = new MLAutoValidator();
        await validator.validatePendingFeedbacks();
      } catch (error) {
        console.error('❌ Erreur validation automatique:', error);
      }
    }, AUTO_VALIDATE_INTERVAL);
    
    // Entraînement automatique (toutes les 6 heures)
    setInterval(async () => {
      try {
        console.log('🔄 Entraînement automatique du modèle ML...');
        await mlTranslationEngine.retrain();
        console.log('✅ Entraînement automatique terminé');
      } catch (error) {
        console.error('❌ Erreur entraînement automatique:', error);
      }
    }, AUTO_TRAIN_INTERVAL);
    
    // Système d'autocritique continu (toutes les 2 heures)
    try {
      const MLSelfCritique = require('../scripts/ml_self_critique');
      const selfCritique = new MLSelfCritique();
      const critiqueIntervalMinutes = (AUTO_CRITIQUE_INTERVAL / (60 * 1000));
      
      // Callback pour exécuter les actions automatiques après chaque autocritique
      const onCritiqueComplete = async () => {
        try {
          const mlAutoActions = require('../scripts/ml_auto_actions');
          await mlAutoActions.executeAutoActions();
        } catch (error) {
          console.warn('⚠️ Erreur exécution actions automatiques (non bloquant):', error.message);
        }
      };
      
      await selfCritique.startContinuousCritique(critiqueIntervalMinutes, onCritiqueComplete);
      console.log(`✅ Système d'autocritique continu démarré (toutes les ${critiqueIntervalMinutes} minutes)`);
      console.log(`✅ Actions automatiques activées après chaque autocritique`);
    } catch (error) {
      console.warn('⚠️ Erreur démarrage système d\'autocritique (non bloquant):', error.message);
    }
    
    console.log(`✅ Validation automatique programmée (toutes les heures)`);
    console.log(`✅ Entraînement automatique programmé (toutes les 6 heures)`);
  } catch (error) {
    console.warn('⚠️ Erreur chargement modèles ML (non bloquant):', error.message);
  }
  
  return Promise.resolve();
}).then(() => {
  // Écouter sur toutes les interfaces pour permettre l'accès depuis le réseau local
  const HOST = process.env.HOST || '0.0.0.0';
  const MACHINE_IP = getMachineIP();
  app.listen(PORT, HOST, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📡 API available at http://localhost:${PORT}/api`);
    console.log(`📡 API accessible depuis le réseau: http://${MACHINE_IP}:${PORT}/api`);
  });
}).catch(err => {
  console.error('❌ Failed to initialize database:', err);
  process.exit(1);
});

module.exports = app;

