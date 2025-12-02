const express = require('express');
const { getDatabase } = require('../database/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Toutes les routes nécessitent une authentification
router.use(authenticateToken);

// Obtenir un utilisateur
router.get('/:id', (req, res) => {
  const db = getDatabase();
  const userId = req.params.id;

  // Vérifier que l'utilisateur demande ses propres données
  if (userId !== req.user.userId) {
    return res.status(403).json({ message: 'Accès non autorisé' });
  }

  db.get(
    'SELECT id, email, name, avatarUrl, isPremium, premiumExpiresAt, createdAt, updatedAt FROM users WHERE id = ?',
    [userId],
    (err, user) => {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé' });
      }

      res.json({
        ...user,
        isPremium: user.isPremium === 1
      });
    }
  );
});

// Mettre à jour un utilisateur
router.put('/:id', (req, res) => {
  const db = getDatabase();
  const userId = req.params.id;
  const { name, avatarUrl } = req.body;

  if (userId !== req.user.userId) {
    return res.status(403).json({ message: 'Accès non autorisé' });
  }

  const now = new Date().toISOString();

  db.run(
    'UPDATE users SET name = ?, avatarUrl = ?, updatedAt = ? WHERE id = ?',
    [name || null, avatarUrl || null, now, userId],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({ message: 'Utilisateur non trouvé' });
      }

      res.json({ message: 'Utilisateur mis à jour avec succès' });
    }
  );
});

module.exports = router;

