const axios = require('axios');

/**
 * Service de traduction utilisant LibreTranslate (auto-hébergé)
 * Fallback sur les dictionnaires JSON si LibreTranslate n'est pas disponible
 */
class LibreTranslateService {
  constructor() {
    // URL de l'instance LibreTranslate
    // En production Docker, utiliser le nom du service
    // En développement local, utiliser localhost:7071
    const defaultURL = process.env.NODE_ENV === 'production' 
      ? 'http://cookingrecipes-libretranslate:5000'
      : 'http://localhost:7071';
    this.baseURL = process.env.LIBRETRANSLATE_URL || defaultURL;
    this.timeout = 10000; // 10 secondes de timeout (augmenté pour le premier chargement)
    this.enabled = process.env.LIBRETRANSLATE_ENABLED !== 'false';
    
    // Client HTTP
    this.client = axios.create({
      baseURL: this.baseURL,
      timeout: this.timeout,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  /**
   * Vérifie si LibreTranslate est disponible
   */
  async isAvailable() {
    if (!this.enabled) {
      return false;
    }
    
    try {
      const response = await this.client.get('/languages');
      return response.status === 200;
    } catch (error) {
      console.warn('LibreTranslate non disponible:', error.message);
      return false;
    }
  }

  /**
   * Traduit un texte
   * @param {string} text - Texte à traduire
   * @param {string} source - Langue source (ex: 'en', 'fr', 'es')
   * @param {string} target - Langue cible (ex: 'en', 'fr', 'es')
   * @returns {Promise<string>} Texte traduit
   */
  async translate(text, source = 'en', target = 'fr') {
    if (!text || text.trim().length === 0) {
      return text;
    }

    // Si source et target sont identiques, retourner le texte original
    if (source === target) {
      return text;
    }

    // Vérifier si LibreTranslate est disponible
    const available = await this.isAvailable();
    if (!available) {
      throw new Error('LibreTranslate non disponible');
    }

    try {
      const response = await this.client.post('/translate', {
        q: text,
        source: source,
        target: target,
        format: 'text',
      });

      if (response.data && response.data.translatedText) {
        return response.data.translatedText;
      }

      throw new Error('Réponse invalide de LibreTranslate');
    } catch (error) {
      if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
        throw new Error('LibreTranslate non disponible');
      }
      throw error;
    }
  }

  /**
   * Traduit un ingrédient
   */
  async translateIngredient(ingredient, targetLang = 'fr') {
    try {
      return await this.translate(ingredient, 'en', targetLang);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Traduit un nom de recette
   */
  async translateRecipeName(recipeName, targetLang = 'fr') {
    try {
      return await this.translate(recipeName, 'en', targetLang);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Traduit un texte (instructions, etc.)
   */
  async translateText(text, sourceLang = 'en', targetLang = 'fr') {
    try {
      return await this.translate(text, sourceLang, targetLang);
    } catch (error) {
      throw error;
    }
  }
}

// Export singleton
const libreTranslateService = new LibreTranslateService();
module.exports = libreTranslateService;

