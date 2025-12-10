const express = require('express');
const router = express.Router();
const libreTranslateService = require('../services/libretranslate');
const mlTranslationEngine = require('../services/ml_translation_engine');
const { inputSanitizerMiddleware } = require('../middleware/inputSanitizer');

/**
 * Route POST /api/translation/translate
 * Traduit un texte en utilisant LibreTranslate
 * 
 * Body: {
 *   text: string,
 *   source: string (optionnel, défaut: 'en'),
 *   target: string (optionnel, défaut: 'fr')
 * }
 */
router.post('/translate', inputSanitizerMiddleware, async (req, res) => {
  try {
    const { text, source = 'en', target = 'fr', type = 'instruction' } = req.body;

    if (!text || typeof text !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Le texte à traduire est requis',
      });
    }

    // Valider les codes de langue
    const validLanguages = ['en', 'fr', 'es', 'de', 'it', 'pt', 'ru', 'zh', 'ja'];
    if (!validLanguages.includes(source) || !validLanguages.includes(target)) {
      return res.status(400).json({
        success: false,
        message: 'Codes de langue invalides',
      });
    }

    // 1. PRIORITÉ: Essayer le modèle ML d'abord (si source = 'en')
    if (source === 'en' && (target === 'fr' || target === 'es')) {
      try {
        const mlTranslation = await mlTranslationEngine.translate(text, type, target);
        if (mlTranslation) {
          return res.json({
            success: true,
            translatedText: mlTranslation,
            source: source,
            target: target,
            method: 'ml', // Indique que c'est le modèle ML qui a traduit
          });
        }
      } catch (mlError) {
        console.warn('⚠️ Erreur modèle ML (fallback LibreTranslate):', mlError.message);
      }
    }

    // 2. FALLBACK: Traduire avec LibreTranslate
    const translatedText = await libreTranslateService.translate(text, source, target);

    return res.json({
      success: true,
      translatedText: translatedText,
      source: source,
      target: target,
      method: 'libretranslate',
    });
  } catch (error) {
    console.error('Erreur traduction:', error);
    
    // Si LibreTranslate n'est pas disponible, retourner une erreur
    // Le client utilisera le fallback (dictionnaires JSON)
    return res.status(503).json({
      success: false,
      message: 'Service de traduction non disponible',
      error: error.message,
      fallback: true, // Indique au client d'utiliser le fallback
    });
  }
});

/**
 * Route POST /api/translation/ingredient
 * Traduit un ingrédient
 */
router.post('/ingredient', inputSanitizerMiddleware, async (req, res) => {
  try {
    const { ingredient, target = 'fr' } = req.body;

    if (!ingredient || typeof ingredient !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'L\'ingrédient est requis',
      });
    }

    // 1. PRIORITÉ: Essayer le modèle ML d'abord
    try {
      const mlTranslation = await mlTranslationEngine.translate(ingredient, 'ingredient', target);
      if (mlTranslation) {
        return res.json({
          success: true,
          translated: mlTranslation,
          original: ingredient,
          target: target,
          method: 'ml',
        });
      }
    } catch (mlError) {
      console.warn('⚠️ Erreur modèle ML (fallback LibreTranslate):', mlError.message);
    }

    // 2. FALLBACK: LibreTranslate
    const translated = await libreTranslateService.translateIngredient(ingredient, target);

    return res.json({
      success: true,
      translated: translated,
      original: ingredient,
      target: target,
      method: 'libretranslate',
    });
  } catch (error) {
    console.error('Erreur traduction ingrédient:', error);
    return res.status(503).json({
      success: false,
      message: 'Service de traduction non disponible',
      error: error.message,
      fallback: true,
    });
  }
});

/**
 * Route POST /api/translation/recipe-name
 * Traduit un nom de recette
 */
router.post('/recipe-name', inputSanitizerMiddleware, async (req, res) => {
  try {
    const { recipeName, target = 'fr' } = req.body;

    if (!recipeName || typeof recipeName !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Le nom de recette est requis',
      });
    }

    const translated = await libreTranslateService.translateRecipeName(recipeName, target);

    return res.json({
      success: true,
      translated: translated,
      original: recipeName,
      target: target,
    });
  } catch (error) {
    console.error('Erreur traduction nom de recette:', error);
    return res.status(503).json({
      success: false,
      message: 'Service de traduction non disponible',
      error: error.message,
      fallback: true,
    });
  }
});

/**
 * Route GET /api/translation/status
 * Vérifie si LibreTranslate est disponible et affiche les stats du modèle ML
 */
router.get('/status', async (req, res) => {
  try {
    const available = await libreTranslateService.isAvailable();
    const mlStats = mlTranslationEngine.getStats();
    
    return res.json({
      success: true,
      libreTranslate: {
        available: available,
        baseURL: libreTranslateService.baseURL,
      },
      mlModel: {
        loaded: mlTranslationEngine.loaded,
        stats: mlStats,
      },
    });
  } catch (error) {
    return res.json({
      success: false,
      available: false,
      error: error.message,
    });
  }
});

/**
 * Route POST /api/translation/retrain
 * Réentraîne le modèle ML avec tous les feedbacks
 */
router.post('/retrain', async (req, res) => {
  try {
    await mlTranslationEngine.retrain();
    const stats = mlTranslationEngine.getStats();
    
    return res.json({
      success: true,
      message: 'Modèle ML réentraîné avec succès',
      stats: stats,
    });
  } catch (error) {
    console.error('Erreur réentraînement:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors du réentraînement',
      error: error.message,
    });
  }
});

module.exports = router;

