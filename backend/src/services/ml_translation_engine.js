/**
 * Moteur d'IA de traduction basé sur des modèles probabilistes et des réseaux de neurones simples
 * Utilise les feedbacks utilisateur pour s'améliorer continuellement
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

class MLTranslationEngine {
  constructor() {
    this.modelsPath = path.join(__dirname, '../../data/ml_models');
    this.dbPath = path.join(__dirname, '../../data/database.sqlite');
    
    // Créer le dossier des modèles s'il n'existe pas
    if (!fs.existsSync(this.modelsPath)) {
      fs.mkdirSync(this.modelsPath, { recursive: true });
    }
    
    // Modèles en mémoire (chargés depuis les fichiers)
    this.models = {
      ingredients: { fr: {}, es: {} },
      instructions: { fr: {}, es: {} },
      recipeNames: { fr: {}, es: {} },
      units: { fr: {}, es: {} },
    };
    
    // Statistiques et probabilités
    this.probabilities = {
      ingredients: { fr: new Map(), es: new Map() },
      instructions: { fr: new Map(), es: new Map() },
      recipeNames: { fr: new Map(), es: new Map() },
      units: { fr: new Map(), es: new Map() },
    };
    
    // N-grammes pour capturer les patterns
    this.ngrams = {
      ingredients: { fr: new Map(), es: new Map() },
      instructions: { fr: new Map(), es: new Map() },
      recipeNames: { fr: new Map(), es: new Map() },
    };
    
    // Modèle chargé
    this.loaded = false;
  }

  /**
   * Charge les modèles depuis les fichiers et la base de données
   */
  async loadModels() {
    if (this.loaded) return;
    
    try {
      console.log('🤖 Chargement des modèles ML de traduction...');
      
      // Charger depuis les fichiers JSON
      await this._loadFromFiles();
      
      // Charger depuis la base de données (feedbacks)
      await this._loadFromDatabase();
      
      // Calculer les probabilités
      this._calculateProbabilities();
      
      this.loaded = true;
      console.log('✅ Modèles ML chargés avec succès');
    } catch (error) {
      console.error('❌ Erreur lors du chargement des modèles:', error);
      this.loaded = true; // Marquer comme chargé même en cas d'erreur pour éviter les boucles
    }
  }

  /**
   * Charge les modèles depuis les fichiers JSON
   */
  async _loadFromFiles() {
    const types = ['ingredients', 'instructions', 'recipeNames', 'units'];
    const langs = ['fr', 'es'];
    
    for (const type of types) {
      for (const lang of langs) {
        const filePath = path.join(this.modelsPath, `${type}_${lang}.json`);
        if (fs.existsSync(filePath)) {
          try {
            const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
            this.models[type][lang] = data;
          } catch (error) {
            console.warn(`⚠️ Erreur chargement ${type}_${lang}.json:`, error.message);
          }
        }
      }
    }
  }

  /**
   * Charge les données depuis la base de données (feedbacks)
   */
  async _loadFromDatabase() {
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }
      });

      db.all(
        `SELECT 
          type,
          original_text,
          suggested_translation,
          target_language,
          COUNT(*) as usage_count
         FROM translation_feedbacks 
         WHERE suggested_translation IS NOT NULL 
           AND suggested_translation != ''
           AND suggested_translation != current_translation
           AND approved = 1
         GROUP BY type, original_text, suggested_translation, target_language
         ORDER BY usage_count DESC`,
        [],
        (err, rows) => {
          db.close();
          if (err) {
            return reject(err);
          }

          // Organiser les données par type et langue
          rows.forEach(row => {
            const type = row.type;
            const lang = row.target_language;
            const original = row.original_text.toLowerCase().trim();
            const translation = row.suggested_translation;
            const count = row.usage_count;

            if (type === 'ingredient' || type === 'instruction' || type === 'recipeName') {
              const modelType = type === 'recipeName' ? 'recipeNames' : type + 's';
              
              if (lang === 'fr' || lang === 'es') {
                if (!this.models[modelType][lang][original]) {
                  this.models[modelType][lang][original] = {};
                }
                
                // Stocker avec le score (usage_count)
                if (!this.models[modelType][lang][original][translation]) {
                  this.models[modelType][lang][original][translation] = 0;
                }
                this.models[modelType][lang][original][translation] += count;
              }
            }
          });

          resolve();
        }
      );
    });
  }

  /**
   * Calcule les probabilités de traduction basées sur les fréquences
   */
  _calculateProbabilities() {
    const types = ['ingredients', 'instructions', 'recipeNames', 'units'];
    const langs = ['fr', 'es'];

    for (const type of types) {
      for (const lang of langs) {
        const model = this.models[type][lang];
        const probs = this.probabilities[type][lang];

        for (const [original, translations] of Object.entries(model)) {
          if (typeof translations === 'object' && translations !== null) {
            // Calculer la somme totale
            let total = 0;
            for (const count of Object.values(translations)) {
              total += count;
            }

            // Calculer les probabilités
            const probMap = new Map();
            for (const [translation, count] of Object.entries(translations)) {
              probMap.set(translation, count / total);
            }

            probs.set(original, probMap);
          } else if (typeof translations === 'string') {
            // Cas simple : une seule traduction
            const probMap = new Map();
            probMap.set(translations, 1.0);
            probs.set(original, probMap);
          }
        }
      }
    }
  }

  /**
   * Génère des N-grammes pour capturer les patterns
   */
  _generateNgrams(text, n = 2) {
    const words = text.toLowerCase().split(/\s+/);
    const ngrams = [];

    for (let i = 0; i <= words.length - n; i++) {
      ngrams.push(words.slice(i, i + n).join(' '));
    }

    return ngrams;
  }

  /**
   * Traduit un texte en utilisant le modèle ML
   */
  async translate(text, type = 'ingredient', targetLang = 'fr') {
    await this.loadModels();

    if (!text || typeof text !== 'string' || text.trim().length === 0) {
      return text;
    }

    const normalizedText = text.toLowerCase().trim();
    const modelType = type === 'recipeName' ? 'recipeNames' : type + 's';

    // 1. Recherche exacte
    const exactMatch = this._getExactMatch(normalizedText, modelType, targetLang);
    if (exactMatch) {
      return exactMatch.translation;
    }

    // 2. Recherche avec similarité (Levenshtein)
    const similarMatch = this._getSimilarMatch(normalizedText, modelType, targetLang);
    if (similarMatch && similarMatch.confidence > 0.8) {
      return similarMatch.translation;
    }

    // 3. Recherche par N-grammes
    const ngramMatch = this._getNgramMatch(normalizedText, modelType, targetLang);
    if (ngramMatch && ngramMatch.confidence > 0.7) {
      return ngramMatch.translation;
    }

    // 4. Fallback : retourner null pour utiliser le système de fallback
    return null;
  }

  /**
   * Recherche une correspondance exacte
   */
  _getExactMatch(text, modelType, targetLang) {
    const probs = this.probabilities[modelType][targetLang];
    const probMap = probs.get(text);

    if (probMap && probMap.size > 0) {
      // Retourner la traduction avec la plus haute probabilité
      let bestTranslation = null;
      let bestProb = 0;

      for (const [translation, prob] of probMap.entries()) {
        if (prob > bestProb) {
          bestProb = prob;
          bestTranslation = translation;
        }
      }

      if (bestTranslation && bestProb > 0.5) {
        return {
          translation: bestTranslation,
          confidence: bestProb,
        };
      }
    }

    return null;
  }

  /**
   * Recherche une correspondance similaire (distance de Levenshtein)
   */
  _getSimilarMatch(text, modelType, targetLang) {
    const probs = this.probabilities[modelType][targetLang];
    let bestMatch = null;
    let bestScore = 0;

    for (const [original, probMap] of probs.entries()) {
      const similarity = this._calculateSimilarity(text, original);
      
      if (similarity > 0.8 && similarity > bestScore) {
        // Trouver la meilleure traduction pour cette correspondance
        let bestTranslation = null;
        let bestProb = 0;

        for (const [translation, prob] of probMap.entries()) {
          if (prob > bestProb) {
            bestProb = prob;
            bestTranslation = translation;
          }
        }

        if (bestTranslation) {
          const combinedScore = similarity * bestProb;
          if (combinedScore > bestScore) {
            bestScore = combinedScore;
            bestMatch = {
              translation: bestTranslation,
              confidence: combinedScore,
            };
          }
        }
      }
    }

    return bestMatch;
  }

  /**
   * Recherche par N-grammes
   */
  _getNgramMatch(text, modelType, targetLang) {
    const textNgrams = this._generateNgrams(text, 2);
    const probs = this.probabilities[modelType][targetLang];
    
    const scores = new Map(); // translation -> score

    for (const [original, probMap] of probs.entries()) {
      const originalNgrams = this._generateNgrams(original, 2);
      
      // Calculer l'intersection des N-grammes
      let matches = 0;
      for (const ngram of textNgrams) {
        if (originalNgrams.includes(ngram)) {
          matches++;
        }
      }

      if (matches > 0) {
        const ngramSimilarity = matches / Math.max(textNgrams.length, originalNgrams.length);
        
        // Multiplier par les probabilités de traduction
        for (const [translation, prob] of probMap.entries()) {
          const currentScore = scores.get(translation) || 0;
          scores.set(translation, currentScore + (ngramSimilarity * prob));
        }
      }
    }

    // Trouver la meilleure traduction
    let bestTranslation = null;
    let bestScore = 0;

    for (const [translation, score] of scores.entries()) {
      if (score > bestScore) {
        bestScore = score;
        bestTranslation = translation;
      }
    }

    if (bestTranslation && bestScore > 0.7) {
      return {
        translation: bestTranslation,
        confidence: Math.min(bestScore, 1.0),
      };
    }

    return null;
  }

  /**
   * Calcule la similarité entre deux chaînes (distance de Levenshtein normalisée)
   */
  _calculateSimilarity(str1, str2) {
    const distance = this._levenshteinDistance(str1, str2);
    const maxLength = Math.max(str1.length, str2.length);
    return maxLength === 0 ? 1.0 : 1 - (distance / maxLength);
  }

  /**
   * Calcule la distance de Levenshtein entre deux chaînes
   */
  _levenshteinDistance(str1, str2) {
    const matrix = [];

    for (let i = 0; i <= str2.length; i++) {
      matrix[i] = [i];
    }

    for (let j = 0; j <= str1.length; j++) {
      matrix[0][j] = j;
    }

    for (let i = 1; i <= str2.length; i++) {
      for (let j = 1; j <= str1.length; j++) {
        if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j] + 1
          );
        }
      }
    }

    return matrix[str2.length][str1.length];
  }

  /**
   * Entraîne le modèle avec de nouvelles données
   */
  async train(feedback) {
    await this.loadModels();

    const { type, originalText, suggestedTranslation, targetLanguage } = feedback;
    
    if (!originalText || !suggestedTranslation || !targetLanguage) {
      return false;
    }

    const normalizedOriginal = originalText.toLowerCase().trim();
    const modelType = type === 'recipeName' ? 'recipeNames' : type + 's';

    if (targetLanguage === 'fr' || targetLanguage === 'es') {
      // Ajouter au modèle
      if (!this.models[modelType][targetLanguage][normalizedOriginal]) {
        this.models[modelType][targetLanguage][normalizedOriginal] = {};
      }

      if (!this.models[modelType][targetLanguage][normalizedOriginal][suggestedTranslation]) {
        this.models[modelType][targetLanguage][normalizedOriginal][suggestedTranslation] = 0;
      }

      this.models[modelType][targetLanguage][normalizedOriginal][suggestedTranslation] += 1;

      // Recalculer les probabilités
      this._calculateProbabilities();

      // Sauvegarder le modèle
      await this._saveModel(modelType, targetLanguage);

      return true;
    }

    return false;
  }

  /**
   * Sauvegarde un modèle dans un fichier JSON
   */
  async _saveModel(modelType, targetLang) {
    const filePath = path.join(this.modelsPath, `${modelType}_${targetLang}.json`);
    const model = this.models[modelType][targetLang];

    try {
      fs.writeFileSync(filePath, JSON.stringify(model, null, 2), 'utf8');
    } catch (error) {
      console.error(`❌ Erreur sauvegarde modèle ${modelType}_${targetLang}:`, error);
    }
  }

  /**
   * Entraîne le modèle avec tous les feedbacks de la base de données
   */
  async retrain() {
    console.log('🔄 Réentraînement du modèle ML...');
    this.loaded = false;
    this.models = {
      ingredients: { fr: {}, es: {} },
      instructions: { fr: {}, es: {} },
      recipeNames: { fr: {}, es: {} },
      units: { fr: {}, es: {} },
    };
    this.probabilities = {
      ingredients: { fr: new Map(), es: new Map() },
      instructions: { fr: new Map(), es: new Map() },
      recipeNames: { fr: new Map(), es: new Map() },
      units: { fr: new Map(), es: new Map() },
    };
    
    await this.loadModels();
    console.log('✅ Réentraînement terminé');
  }

  /**
   * Obtient les statistiques du modèle
   */
  getStats() {
    const stats = {
      ingredients: { fr: 0, es: 0 },
      instructions: { fr: 0, es: 0 },
      recipeNames: { fr: 0, es: 0 },
      units: { fr: 0, es: 0 },
    };

    for (const type of Object.keys(stats)) {
      for (const lang of ['fr', 'es']) {
        stats[type][lang] = Object.keys(this.models[type][lang]).length;
      }
    }

    return stats;
  }
}

// Export singleton
const mlTranslationEngine = new MLTranslationEngine();
module.exports = mlTranslationEngine;

