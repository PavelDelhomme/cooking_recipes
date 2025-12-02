const express = require('express');
const { getDatabase } = require('../database/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

// Obtenir tous les ingrédients du placard
router.get('/', (req, res) => {
  const db = getDatabase();

  db.all(
    'SELECT * FROM pantry WHERE userId = ? ORDER BY createdAt DESC',
    [req.user.userId],
    (err, items) => {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      res.json(items.map(item => ({
        ...item,
        quantity: parseFloat(item.quantity)
      })));
    }
  );
});

// Ajouter un ingrédient
router.post('/', (req, res) => {
  const db = getDatabase();
  const { id, name, quantity, unit, expiryDate } = req.body;
  const now = new Date().toISOString();

  db.run(
    'INSERT INTO pantry (id, userId, name, quantity, unit, expiryDate, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [id, req.user.userId, name, quantity, unit, expiryDate || null, now],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      res.status(201).json({ message: 'Ingrédient ajouté', id });
    }
  );
});

// Mettre à jour un ingrédient
router.put('/:id', (req, res) => {
  const db = getDatabase();
  const { name, quantity, unit, expiryDate } = req.body;
  const now = new Date().toISOString();

  db.run(
    'UPDATE pantry SET name = ?, quantity = ?, unit = ?, expiryDate = ?, updatedAt = ? WHERE id = ? AND userId = ?',
    [name, quantity, unit, expiryDate || null, now, req.params.id, req.user.userId],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({ message: 'Ingrédient non trouvé' });
      }

      res.json({ message: 'Ingrédient mis à jour' });
    }
  );
});

// Supprimer un ingrédient
router.delete('/:id', (req, res) => {
  const db = getDatabase();

  db.run(
    'DELETE FROM pantry WHERE id = ? AND userId = ?',
    [req.params.id, req.user.userId],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({ message: 'Ingrédient non trouvé' });
      }

      res.json({ message: 'Ingrédient supprimé' });
    }
  );
});

module.exports = router;

