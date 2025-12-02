const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDatabase } = require('../database/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Inscription
router.post('/signup', async (req, res) => {
  try {
    const { email, password, name } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email et mot de passe requis' });
    }

    const db = getDatabase();
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = Date.now().toString();
    const now = new Date().toISOString();

    db.run(
      'INSERT INTO users (id, email, password, name, createdAt) VALUES (?, ?, ?, ?, ?)',
      [userId, email, hashedPassword, name || null, now],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint')) {
            return res.status(409).json({ message: 'Cet email est déjà utilisé' });
          }
          return res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }

        const token = jwt.sign({ userId, email }, JWT_SECRET, { expiresIn: '30d' });

        res.status(201).json({
          token,
          user: {
            id: userId,
            email,
            name: name || null,
            isPremium: false,
            createdAt: now
          }
        });
      }
    );
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
});

// Connexion
router.post('/signin', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email et mot de passe requis' });
    }

    const db = getDatabase();

    db.get(
      'SELECT * FROM users WHERE email = ?',
      [email],
      async (err, user) => {
        if (err) {
          return res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }

        if (!user) {
          return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
        }

        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
          return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
        }

        const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });

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
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
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

module.exports = router;

