const express = require('express');
const { getDatabase } = require('../database/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

// Obtenir la liste de courses
router.get('/', (req, res) => {
  const db = getDatabase();

  db.all(
    'SELECT * FROM shopping_list WHERE userId = ? ORDER BY createdAt DESC',
    [req.user.userId],
    (err, items) => {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      res.json(items.map(item => ({
        ...item,
        quantity: item.quantity ? parseFloat(item.quantity) : null,
        isChecked: item.isChecked === 1,
        isRegular: item.isRegular === 1
      })));
    }
  );
});

// Ajouter un élément
router.post('/', (req, res) => {
  const db = getDatabase();
  const { id, name, quantity, unit, isRegular } = req.body;
  const now = new Date().toISOString();

  db.run(
    'INSERT INTO shopping_list (id, userId, name, quantity, unit, isRegular, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [id, req.user.userId, name, quantity || null, unit || null, isRegular ? 1 : 0, now],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      res.status(201).json({ message: 'Élément ajouté', id });
    }
  );
});

// Mettre à jour un élément
router.put('/:id', (req, res) => {
  const db = getDatabase();
  const { name, quantity, unit, isChecked, isRegular } = req.body;
  const now = new Date().toISOString();

  db.run(
    'UPDATE shopping_list SET name = ?, quantity = ?, unit = ?, isChecked = ?, isRegular = ?, updatedAt = ? WHERE id = ? AND userId = ?',
    [name, quantity || null, unit || null, isChecked ? 1 : 0, isRegular ? 1 : 0, now, req.params.id, req.user.userId],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({ message: 'Élément non trouvé' });
      }

      res.json({ message: 'Élément mis à jour' });
    }
  );
});

// Supprimer un élément
router.delete('/:id', (req, res) => {
  const db = getDatabase();

  db.run(
    'DELETE FROM shopping_list WHERE id = ? AND userId = ?',
    [req.params.id, req.user.userId],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({ message: 'Élément non trouvé' });
      }

      res.json({ message: 'Élément supprimé' });
    }
  );
});

module.exports = router;

