const express = require('express');
const { getDatabase } = require('../database/db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

// Obtenir tous les plannings
router.get('/', (req, res) => {
  const db = getDatabase();

  db.all(
    'SELECT * FROM meal_plans WHERE userId = ? ORDER BY date ASC',
    [req.user.userId],
    (err, plans) => {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      res.json(plans.map(plan => ({
        ...plan,
        recipe: JSON.parse(plan.recipeData)
      })));
    }
  );
});

// Ajouter un planning
router.post('/', (req, res) => {
  const db = getDatabase();
  const { id, date, mealType, recipe } = req.body;
  const now = new Date().toISOString();

  db.run(
    'INSERT INTO meal_plans (id, userId, date, mealType, recipeId, recipeTitle, recipeImage, recipeData, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      id,
      req.user.userId,
      date,
      mealType,
      recipe.id,
      recipe.title,
      recipe.image || null,
      JSON.stringify(recipe),
      now
    ],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      res.status(201).json({ message: 'Planning ajouté', id });
    }
  );
});

// Supprimer un planning
router.delete('/:id', (req, res) => {
  const db = getDatabase();

  db.run(
    'DELETE FROM meal_plans WHERE id = ? AND userId = ?',
    [req.params.id, req.user.userId],
    function(err) {
      if (err) {
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({ message: 'Planning non trouvé' });
      }

      res.json({ message: 'Planning supprimé' });
    }
  );
});

module.exports = router;

