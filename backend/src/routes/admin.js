const express = require('express');
const { getDatabase, initDatabase, resetDatabase } = require('../database/db');
const { authenticateToken } = require('../middleware/auth');

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

// Route pour ajouter des données de test (ingrédients dans le placard)
router.post('/seed-test-data', authenticateToken, (req, res) => {
  try {
    const db = getDatabase();
    const userId = req.user.userId || req.user.id;
    const now = new Date().toISOString();
    
    // Liste d'ingrédients de test variés
    const testIngredients = [
      { name: 'Farine', quantity: 500, unit: 'g' },
      { name: 'Sucre', quantity: 250, unit: 'g' },
      { name: 'Beurre', quantity: 200, unit: 'g' },
      { name: 'Oeufs', quantity: 6, unit: 'pièce' },
      { name: 'Lait', quantity: 1, unit: 'L' },
      { name: 'Tomates', quantity: 500, unit: 'g' },
      { name: 'Oignons', quantity: 3, unit: 'pièce' },
      { name: 'Ail', quantity: 1, unit: 'tête' },
      { name: 'Huile d\'olive', quantity: 500, unit: 'ml' },
      { name: 'Sel', quantity: 1, unit: 'kg' },
      { name: 'Poivre', quantity: 50, unit: 'g' },
      { name: 'Pâtes', quantity: 500, unit: 'g' },
      { name: 'Riz', quantity: 1, unit: 'kg' },
      { name: 'Pommes de terre', quantity: 1, unit: 'kg' },
      { name: 'Carottes', quantity: 500, unit: 'g' },
      { name: 'Courgettes', quantity: 3, unit: 'pièce' },
      { name: 'Fromage râpé', quantity: 200, unit: 'g' },
      { name: 'Crème fraîche', quantity: 200, unit: 'ml' },
      { name: 'Champignons', quantity: 250, unit: 'g' },
      { name: 'Poulet', quantity: 500, unit: 'g' },
      { name: 'Boeuf haché', quantity: 400, unit: 'g' },
      { name: 'Saumon', quantity: 300, unit: 'g' },
      { name: 'Citron', quantity: 3, unit: 'pièce' },
      { name: 'Basilic', quantity: 1, unit: 'pot' },
      { name: 'Thym', quantity: 1, unit: 'pot' },
      { name: 'Origan', quantity: 1, unit: 'pot' },
      { name: 'Paprika', quantity: 50, unit: 'g' },
      { name: 'Curry', quantity: 50, unit: 'g' },
      { name: 'Cumin', quantity: 50, unit: 'g' },
      { name: 'Cannelle', quantity: 50, unit: 'g' },
      { name: 'Chocolat noir', quantity: 200, unit: 'g' },
    ];
    
    // Vérifier si l'utilisateur a déjà des ingrédients
    db.get('SELECT COUNT(*) as count FROM pantry WHERE userId = ?', [userId], (err, row) => {
      if (err) {
        console.error('Erreur vérification pantry:', err);
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }
      
      if (row.count > 0) {
        return res.status(400).json({ 
          message: 'Vous avez déjà des ingrédients dans votre placard',
          existingCount: row.count,
          hint: 'Utilisez db-reset pour réinitialiser la base de données si vous voulez repartir de zéro'
        });
      }
    
      // Calculer une date d'expiration (dans 7-30 jours)
      const getExpiryDate = () => {
        const days = Math.floor(Math.random() * 23) + 7; // Entre 7 et 30 jours
        const date = new Date();
        date.setDate(date.getDate() + days);
        return date.toISOString().split('T')[0]; // Format YYYY-MM-DD
      };
      
      let inserted = 0;
      let errors = 0;
      
      // Insérer chaque ingrédient
      testIngredients.forEach((ingredient, index) => {
        const pantryId = `test-${Date.now()}-${index}`;
        const expiryDate = Math.random() > 0.3 ? getExpiryDate() : null; // 70% ont une date d'expiration
        
        db.run(
          `INSERT INTO pantry (id, userId, name, quantity, unit, expiryDate, createdAt, updatedAt)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [pantryId, userId, ingredient.name, ingredient.quantity, ingredient.unit, expiryDate, now, now],
          function(err) {
            if (err) {
              console.error(`Erreur insertion ${ingredient.name}:`, err);
              errors++;
            } else {
              inserted++;
            }
            
            // Quand tous les ingrédients ont été traités
            if (inserted + errors >= testIngredients.length) {
              console.log(`✅ Données de test ajoutées: ${inserted} ingrédients insérés, ${errors} erreurs`);
              res.json({
                message: 'Données de test ajoutées avec succès',
                inserted: inserted,
                errors: errors,
                total: testIngredients.length
              });
            }
          }
        );
      });
    });
  } catch (error) {
    console.error('Erreur ajout données de test:', error);
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
});

module.exports = router;
