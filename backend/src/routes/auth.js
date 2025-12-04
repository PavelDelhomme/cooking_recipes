const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDatabase } = require('../database/db');
const { authenticateToken } = require('../middleware/auth');
const { authLimiter, signupLimiter } = require('../middleware/rateLimiter');
const { validateEmail, validatePassword, validateName } = require('../utils/validation');
const { logSecurityEvent, SECURITY_EVENTS } = require('../middleware/securityLogger');
const crypto = require('crypto');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Inscription
router.post('/signup', signupLimiter, async (req, res) => {
  try {
    // Log pour debug (à retirer en production si nécessaire)
    console.log('Signup request body:', JSON.stringify(req.body));
    
    const { email, password, name } = req.body;

    // Vérifier que les champs requis sont présents
    if (!email) {
      return res.status(400).json({ message: 'Email requis' });
    }
    if (!password) {
      return res.status(400).json({ message: 'Mot de passe requis' });
    }

    // Valider l'email
    const emailValidation = validateEmail(email);
    if (!emailValidation.valid) {
      console.log('Email validation failed:', emailValidation.error);
      return res.status(400).json({ message: emailValidation.error });
    }

    // Valider le mot de passe
    const passwordValidation = validatePassword(password);
    if (!passwordValidation.valid) {
      console.log('Password validation failed:', passwordValidation.error);
      return res.status(400).json({ message: passwordValidation.error });
    }

    // Valider le nom (optionnel)
    const nameValidation = validateName(name);
    if (!nameValidation.valid) {
      console.log('Name validation failed:', nameValidation.error);
      return res.status(400).json({ message: nameValidation.error });
    }

    const db = getDatabase();
    
    // Vérifier si l'email existe déjà (protection contre les attaques de timing)
    db.get(
      'SELECT id FROM users WHERE email = ?',
      [emailValidation.email],
      async (err, existingUser) => {
        if (err) {
          console.error('Erreur vérification email:', err);
          // Délai constant pour éviter les attaques de timing
          await new Promise(resolve => setTimeout(resolve, 100));
          return res.status(500).json({ message: 'Erreur serveur' });
        }

        if (existingUser) {
          // Délai constant même si l'utilisateur existe
          await new Promise(resolve => setTimeout(resolve, 100));
          return res.status(409).json({ message: 'Cet email est déjà utilisé' });
        }

        // Hasher le mot de passe avec un coût élevé
        const hashedPassword = await bcrypt.hash(password, 12);
        const userId = Date.now().toString() + '-' + Math.random().toString(36).substring(2, 15);
        const now = new Date().toISOString();

        db.run(
          'INSERT INTO users (id, email, password, name, createdAt) VALUES (?, ?, ?, ?, ?)',
          [userId, emailValidation.email, hashedPassword, nameValidation.name, now],
          function(err) {
            if (err) {
              console.error('Erreur création utilisateur:', err);
              if (err.message.includes('UNIQUE constraint')) {
                return res.status(409).json({ message: 'Cet email est déjà utilisé' });
              }
              return res.status(500).json({ message: 'Erreur serveur' });
            }

            // Générer un jti (JWT ID) unique pour pouvoir révoquer le token
            const jti = crypto.randomBytes(16).toString('hex');
            const token = jwt.sign(
              { userId, email: emailValidation.email, jti },
              JWT_SECRET,
              { expiresIn: '30d', algorithm: 'HS256' }
            );

            // Logger l'inscription réussie
            logSecurityEvent(SECURITY_EVENTS.AUTH_SUCCESS, {
              ip: req.ip || req.connection.remoteAddress,
              userId,
              email: emailValidation.email,
              action: 'signup',
              severity: 'INFO',
            });

            res.status(201).json({
              token,
              user: {
                id: userId,
                email: emailValidation.email,
                name: nameValidation.name,
                isPremium: false,
                createdAt: now
              }
            });
          }
        );
      }
    );
  } catch (error) {
    console.error('Erreur inscription:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Connexion
router.post('/signin', authLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;

    // Valider les entrées
    const emailValidation = validateEmail(email);
    if (!emailValidation.valid) {
      return res.status(400).json({ message: emailValidation.error });
    }

    if (!password || typeof password !== 'string') {
      return res.status(400).json({ message: 'Mot de passe requis' });
    }

    const db = getDatabase();
    const startTime = Date.now();

    db.get(
      'SELECT * FROM users WHERE email = ?',
      [emailValidation.email],
      async (err, user) => {
        // Délai constant pour éviter les attaques de timing
        const elapsed = Date.now() - startTime;
        const minDelay = 200; // Délai minimum de 200ms
        if (elapsed < minDelay) {
          await new Promise(resolve => setTimeout(resolve, minDelay - elapsed));
        }

        if (err) {
          console.error('Erreur connexion:', err);
          return res.status(500).json({ message: 'Erreur serveur' });
        }

        // Toujours vérifier le mot de passe même si l'utilisateur n'existe pas
        // pour éviter les attaques de timing
        const dummyHash = '$2a$12$dummy.hash.to.prevent.timing.attacks.here';
        const hashToCompare = user ? user.password : dummyHash;
        
        const validPassword = await bcrypt.compare(password, hashToCompare);

        if (!user || !validPassword) {
          // Log de la tentative échouée (sans exposer d'informations sensibles)
          // Logger l'échec de connexion
          logSecurityEvent(SECURITY_EVENTS.AUTH_FAILURE, {
            ip: req.ip || req.connection.remoteAddress,
            email: emailValidation.email,
            reason: 'Invalid credentials',
            severity: 'MEDIUM',
          });
          return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
        }

        // Générer un jti (JWT ID) unique pour pouvoir révoquer le token
        const jti = crypto.randomBytes(16).toString('hex');
        const token = jwt.sign(
          { userId: user.id, email: user.email, jti },
          JWT_SECRET,
          { expiresIn: '30d', algorithm: 'HS256' }
        );

        // Logger la connexion réussie
        logSecurityEvent(SECURITY_EVENTS.AUTH_SUCCESS, {
          ip: req.ip || req.connection.remoteAddress,
          userId: user.id,
          email: user.email,
          action: 'signin',
          severity: 'INFO',
        });

        res.json({
          token,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            avatarUrl: user.avatarUrl,
            isPremium: user.isPremium === 1,
            premiumExpiresAt: user.premiumExpiresAt,
            createdAt: user.createdAt
          }
        });
      }
    );
  } catch (error) {
    console.error('Erreur connexion:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Obtenir l'utilisateur actuel
router.get('/me', authenticateToken, (req, res) => {
  const db = getDatabase();

  db.get(
    'SELECT id, email, name, avatarUrl, isPremium, premiumExpiresAt, createdAt, updatedAt FROM users WHERE id = ?',
    [req.user.userId],
    (err, user) => {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé' });
      }

      res.json({
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
        isPremium: user.isPremium === 1,
        premiumExpiresAt: user.premiumExpiresAt,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      });
    }
  );
});

// Déconnexion (révoquer le token)
router.post('/signout', authenticateToken, async (req, res) => {
  try {
    const { revokeToken } = require('../middleware/sessionSecurity');
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      revokeToken(token, req.user.userId, 'User logout');
      
      logSecurityEvent(SECURITY_EVENTS.AUTH_SUCCESS, {
        ip: req.ip || req.connection.remoteAddress,
        userId: req.user.userId,
        action: 'signout',
        severity: 'INFO',
      });
    }

    res.json({ message: 'Déconnexion réussie' });
  } catch (error) {
    console.error('Erreur déconnexion:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;

