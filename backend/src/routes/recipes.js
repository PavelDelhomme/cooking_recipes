/**
 * Routes pour la recherche de recettes avec reconnaissance d'intention
 */

const express = require('express');
const router = express.Router();
const intentRecognitionService = require('../services/intent_recognition_service');
const { authenticateToken } = require('../middleware/auth');

/**
 * POST /api/recipes/search
 * Recherche de recettes avec reconnaissance d'intention
 */
router.post('/search', authenticateToken, async (req, res) => {
  try {
    const { query, context } = req.body;
    
    if (!query) {
      return res.status(400).json({ error: 'Query is required' });
    }

    // Reconnaître l'intention de la recherche
    const intent = await intentRecognitionService.recognizeSearchIntent(query, context || {});
    
    // Enregistrer l'intention pour améliorer le modèle
    await intentRecognitionService.saveIntent(query, intent, req.user?.id);

    res.json({
      intent,
      query,
      message: 'Intent recognized successfully',
    });
  } catch (error) {
    console.error('Error recognizing search intent:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/recipes/intent-stats
 * Obtenir les statistiques d'intention
 */
router.get('/intent-stats', authenticateToken, async (req, res) => {
  try {
    const stats = await intentRecognitionService.getIntentStatistics();
    res.json(stats);
  } catch (error) {
    console.error('Error getting intent statistics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/recipes/improve-intent
 * Améliorer le modèle d'intention avec un feedback utilisateur
 */
router.post('/improve-intent', authenticateToken, async (req, res) => {
  try {
    const { query, correctIntent } = req.body;
    
    if (!query || !correctIntent) {
      return res.status(400).json({ error: 'Query and correctIntent are required' });
    }

    await intentRecognitionService.improveModel(query, correctIntent);
    
    res.json({ message: 'Intent model improved successfully' });
  } catch (error) {
    console.error('Error improving intent model:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

