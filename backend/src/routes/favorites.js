const express = require('express');
const router = express.Router();
const { getDatabase } = require('../database/db');
const { authenticateToken } = require('../middleware/auth');

// Obtenir tous les favoris de l'utilisateur
router.get('/', authenticateToken, (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId || req.user.id;

  if (!userId) {
    console.error('❌ userId manquant dans req.user:', req.user);
    return res.status(401).json({ error: 'Utilisateur non authentifié' });
  }

  console.log(`📋 Récupération favoris pour userId=${userId}`);

  db.all(
    'SELECT * FROM favorites WHERE userId = ? ORDER BY createdAt DESC',
    [userId],
    (err, rows) => {
      if (err) {
        console.error('Erreur récupération favoris:', err);
        return res.status(500).json({ error: 'Erreur serveur' });
      }

      const favorites = rows.map((row, index) => {
        try {
          // Parser recipeData (peut être déjà un objet ou une string JSON)
          let recipeData = row.recipeData;
          if (typeof recipeData === 'string') {
            recipeData = JSON.parse(recipeData);
          }
          
          console.log(`  Favori ${index + 1}: recipeId=${row.recipeId}, recipeTitle=${row.recipeTitle}`);
          
          return {
            id: row.id,
            recipeId: row.recipeId,
            recipeTitle: row.recipeTitle,
            recipeImage: row.recipeImage,
            recipeData: recipeData,
            createdAt: row.createdAt,
          };
        } catch (e) {
          console.error(`Erreur parsing recipeData pour favori ${index + 1}:`, e);
          console.error(`  recipeData type: ${typeof row.recipeData}, value: ${row.recipeData?.substring(0, 100)}...`);
          // Retourner quand même l'item avec recipeData comme string
          return {
            id: row.id,
            recipeId: row.recipeId,
            recipeTitle: row.recipeTitle,
            recipeImage: row.recipeImage,
            recipeData: row.recipeData, // Laisser comme string si erreur
            createdAt: row.createdAt,
          };
        }
      });

      console.log(`✅ Envoi de ${favorites.length} favoris au client`);
      res.json(favorites);
    }
  );
});

// Ajouter un favori
router.post('/', authenticateToken, (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId || req.user.id;

  if (!userId) {
    console.error('❌ userId manquant dans req.user:', req.user);
    return res.status(401).json({ error: 'Utilisateur non authentifié' });
  }

  const { recipeId, recipeTitle, recipeImage, recipeData } = req.body;

  if (!recipeId || !recipeTitle || !recipeData) {
    console.error('❌ Données incomplètes:', { recipeId, recipeTitle, hasRecipeData: !!recipeData });
    return res.status(400).json({ error: 'Données incomplètes' });
  }

  // Vérifier d'abord si le favori existe déjà
  db.get(
    'SELECT id FROM favorites WHERE userId = ? AND recipeId = ?',
    [userId, recipeId],
    (err, existing) => {
      if (err) {
        console.error('Erreur vérification favori existant:', err);
        return res.status(500).json({ error: 'Erreur serveur' });
      }

      if (existing) {
        // Le favori existe déjà, retourner succès sans créer de doublon
        console.log(`✅ Favori déjà existant pour userId=${userId}, recipeId=${recipeId}`);
        return res.status(200).json({
          id: existing.id,
          recipeId,
          recipeTitle,
          recipeImage,
          recipeData,
          message: 'Recette déjà en favoris',
        });
      }

      // Créer le nouveau favori
      const id = `${userId}_${recipeId}_${Date.now()}`;
      const createdAt = new Date().toISOString();

      // S'assurer que recipeData est bien un objet avant de le stringify
      let recipeDataString;
      try {
        if (typeof recipeData === 'string') {
          // Si c'est déjà une string, vérifier que c'est du JSON valide
          JSON.parse(recipeData);
          recipeDataString = recipeData;
        } else {
          recipeDataString = JSON.stringify(recipeData);
        }
      } catch (e) {
        console.error('❌ Erreur sérialisation recipeData:', e);
        return res.status(400).json({ error: 'recipeData invalide' });
      }

      console.log(`➕ Ajout favori: userId=${userId}, recipeId=${recipeId}, recipeTitle=${recipeTitle}`);

      db.run(
        'INSERT INTO favorites (id, userId, recipeId, recipeTitle, recipeImage, recipeData, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [id, userId, recipeId, recipeTitle, recipeImage || null, recipeDataString, createdAt],
        function(err) {
          if (err) {
            if (err.message.includes('UNIQUE constraint failed')) {
              console.log(`⚠️ Doublon détecté pour userId=${userId}, recipeId=${recipeId}`);
              return res.status(409).json({ error: 'Recette déjà en favoris' });
            }
            console.error('❌ Erreur ajout favori:', err);
            console.error('   Détails:', {
              userId,
              recipeId,
              recipeTitle,
              recipeImage,
              recipeDataLength: recipeDataString?.length,
            });
            return res.status(500).json({ error: 'Erreur serveur', details: err.message });
          }

          console.log(`✅ Favori ajouté avec succès: id=${id}, recipeId=${recipeId}`);
          res.status(201).json({
            id,
            recipeId,
            recipeTitle,
            recipeImage,
            recipeData: typeof recipeData === 'string' ? JSON.parse(recipeData) : recipeData,
            createdAt,
          });
        }
      );
    }
  );
});

// Vérifier si une recette est en favoris
router.get('/check/:recipeId', authenticateToken, (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId || req.user.id;
  const { recipeId } = req.params;

  if (!userId) {
    console.error('❌ userId manquant dans req.user:', req.user);
    return res.status(401).json({ error: 'Utilisateur non authentifié' });
  }

  db.get(
    'SELECT * FROM favorites WHERE userId = ? AND recipeId = ?',
    [userId, recipeId],
    (err, row) => {
      if (err) {
        console.error('Erreur vérification favori:', err);
        return res.status(500).json({ error: 'Erreur serveur' });
      }

      res.json({ isFavorite: !!row });
    }
  );
});

// Supprimer un favori
router.delete('/:recipeId', authenticateToken, (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId || req.user.id;
  const { recipeId } = req.params;

  if (!userId) {
    console.error('❌ userId manquant dans req.user:', req.user);
    return res.status(401).json({ error: 'Utilisateur non authentifié' });
  }

  db.run(
    'DELETE FROM favorites WHERE userId = ? AND recipeId = ?',
    [userId, recipeId],
    function(err) {
      if (err) {
        console.error('Erreur suppression favori:', err);
        return res.status(500).json({ error: 'Erreur serveur' });
      }

      if (this.changes === 0) {
        return res.status(404).json({ error: 'Favori non trouvé' });
      }

      res.json({ success: true });
    }
  );
});

module.exports = router;

