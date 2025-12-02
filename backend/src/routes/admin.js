const express = require('express');
const { getDatabase, initDatabase, resetDatabase } = require('../database/db');

const router = express.Router();

// Route pour réinitialiser complètement la base de données
router.post('/reset-database', async (req, res) => {
  try {
    await resetDatabase();
    console.log('✅ Base de données réinitialisée');
    res.json({ 
      message: 'Base de données réinitialisée avec succès',
      tables: ['users', 'pantry', 'meal_plans', 'shopping_list']
    });
  } catch (error) {
    console.error('Erreur réinitialisation base de données:', error);
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
});

// Route pour vider tous les comptes utilisateurs (garder les tables)
router.post('/clear-users', (req, res) => {
  try {
    const db = getDatabase();
    
    db.serialize(() => {
      // Supprimer toutes les données liées aux utilisateurs
      db.run('DELETE FROM shopping_list', (err) => {
        if (err) {
          console.error('Erreur suppression shopping_list:', err);
        }
      });
      
      db.run('DELETE FROM meal_plans', (err) => {
        if (err) {
          console.error('Erreur suppression meal_plans:', err);
        }
      });
      
      db.run('DELETE FROM pantry', (err) => {
        if (err) {
          console.error('Erreur suppression pantry:', err);
        }
      });
      
      db.run('DELETE FROM users', (err) => {
        if (err) {
          console.error('Erreur suppression users:', err);
          return res.status(500).json({ message: 'Erreur lors de la suppression', error: err.message });
        }
        
        console.log('✅ Tous les comptes utilisateurs ont été supprimés');
        res.json({ 
          message: 'Tous les comptes utilisateurs ont été supprimés avec succès',
          deleted: ['users', 'pantry', 'meal_plans', 'shopping_list']
        });
      });
    });
  } catch (error) {
    console.error('Erreur suppression comptes:', error);
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
});

module.exports = router;

