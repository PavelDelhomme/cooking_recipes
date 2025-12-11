/**
 * Moteur d'IA de traduction basé sur des modèles probabilistes et des réseaux de neurones simples
 * Utilise les feedbacks utilisateur pour s'améliorer continuellement
 * 
 * Système hybride :
 * - Modèles probabilistes (rapides, transparents)
 * - Réseaux de neurones (TensorFlow.js) - optionnel
 * - Apprentissage par renforcement
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

// Import optionnel du réseau de neurones (peut être désactivé si TensorFlow n'est pas installé)
let neuralTranslationEngine = null;
try {
  neuralTranslationEngine = require('./neural_translation_engine');
} catch (e) {
  console.warn('⚠️  Réseau de neurones non disponible (TensorFlow.js non installé). Utilisation du système probabiliste uniquement.');
}

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
      quantity: { fr: {}, es: {} }, // Conversions de quantités
    };
    
    // Statistiques et probabilités
    this.probabilities = {
      ingredients: { fr: new Map(), es: new Map() },
      instructions: { fr: new Map(), es: new Map() },
      recipeNames: { fr: new Map(), es: new Map() },
      units: { fr: new Map(), es: new Map() },
      quantity: { fr: new Map(), es: new Map() }, // Conversions de quantités
    };
    
    // N-grammes pour capturer les patterns
    this.ngrams = {
      ingredients: { fr: new Map(), es: new Map() },
      instructions: { fr: new Map(), es: new Map() },
      recipeNames: { fr: new Map(), es: new Map() },
      quantity: { fr: new Map(), es: new Map() }, // Conversions de quantités
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
    const types = ['ingredients', 'instructions', 'recipeNames', 'units', 'quantity'];
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
          selected_text,
          selected_text_translation,
          target_language,
          COUNT(*) as usage_count
        FROM translation_feedbacks 
        WHERE ((suggested_translation IS NOT NULL 
          AND suggested_translation != ''
          AND suggested_translation != current_translation)
          OR (selected_text IS NOT NULL 
          AND selected_text_translation IS NOT NULL
          AND selected_text_translation != ''))
          AND approved = 1
        GROUP BY type, original_text, suggested_translation, selected_text, selected_text_translation, target_language
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
            
            // Gérer les feedbacks au niveau des mots/groupe de mots
            if (row.selected_text && row.selected_text_translation) {
              const selectedText = row.selected_text.toLowerCase().trim();
              const selectedTranslation = row.selected_text_translation;
              
              // Traiter comme un feedback de type instruction pour les mots/groupe de mots
              if (lang === 'fr' || lang === 'es') {
                if (!this.models.instructions[lang][selectedText]) {
                  this.models.instructions[lang][selectedText] = {};
                }
                if (!this.models.instructions[lang][selectedText][selectedTranslation]) {
                  this.models.instructions[lang][selectedText][selectedTranslation] = 0;
                }
                this.models.instructions[lang][selectedText][selectedTranslation] += count;
              }
            }

            if (type === 'ingredient' || type === 'instruction' || type === 'recipeName' || type === 'unit' || type === 'quantity' || type === 'summary') {
              let modelType;
              if (type === 'recipeName') {
                modelType = 'recipeNames';
              } else if (type === 'summary') {
                modelType = 'instructions'; // Utiliser le même modèle que les instructions pour les résumés
              } else if (type === 'quantity') {
                modelType = 'quantity'; // Conversions de quantités
              } else {
                modelType = type + 's';
              }
              
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
   * Traduit un texte en utilisant le modèle ML (système hybride)
   * 1. Essaie d'abord le système probabiliste (rapide)
   * 2. Si échec, essaie le réseau de neurones (si disponible)
   * 3. Si échec, retourne null pour fallback LibreTranslate
   */
  async translate(text, type = 'ingredient', targetLang = 'fr') {
    await this.loadModels();

    if (!text || typeof text !== 'string' || text.trim().length === 0) {
      return text;
    }

    const normalizedText = text.toLowerCase().trim();
    let modelType;
    if (type === 'recipeName') {
      modelType = 'recipeNames';
    } else if (type === 'summary') {
      modelType = 'instructions'; // Utiliser le même modèle que les instructions pour les résumés
    } else if (type === 'quantity') {
      modelType = 'quantity'; // Conversions de quantités
    } else {
      modelType = type + 's';
    }

    // 1. Recherche exacte (système probabiliste)
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

    // 4. Essayer le réseau de neurones (si disponible)
    if (neuralTranslationEngine) {
      try {
        const neuralTranslation = await neuralTranslationEngine.translate(text, type, targetLang);
        if (neuralTranslation) {
          return neuralTranslation;
        }
      } catch (e) {
        // Ignorer les erreurs du réseau de neurones
      }
    }

    // 5. Fallback : retourner null pour utiliser le système de fallback (LibreTranslate)
    return null;
  }

  /**
   * Recherche une correspondance exacte
   * Choisit TOUJOURS la traduction avec le plus de points (plus haute probabilité)
   * Même si plusieurs traductions existent pour le même mot
   */
  _getExactMatch(text, modelType, targetLang) {
    const probs = this.probabilities[modelType][targetLang];
    const probMap = probs.get(text);

    if (probMap && probMap.size > 0) {
      // Retourner la traduction avec la plus haute probabilité (le plus de points)
      let bestTranslation = null;
      let bestProb = 0;
      let allTranslations = []; // Pour le logging

      for (const [translation, prob] of probMap.entries()) {
        allTranslations.push({ translation, prob });
        if (prob > bestProb) {
          bestProb = prob;
          bestTranslation = translation;
        }
      }

      // Trier pour le logging (meilleure en premier)
      allTranslations.sort((a, b) => b.prob - a.prob);

      // Si plusieurs traductions existent, log pour debug
      if (allTranslations.length > 1) {
        console.log(`🔍 Plusieurs traductions pour "${text}":`, 
          allTranslations.map(t => `${t.translation} (${(t.prob * 100).toFixed(1)}%)`).join(', '),
          `→ Choisi: "${bestTranslation}" (${(bestProb * 100).toFixed(1)}%)`);
      }

      // Choisir TOUJOURS la meilleure, même si prob < 0.5
      // (car c'est quand même la meilleure option disponible)
      if (bestTranslation) {
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
   * Choisit TOUJOURS la traduction avec le plus de points parmi les correspondances similaires
   */
  _getSimilarMatch(text, modelType, targetLang) {
    const probs = this.probabilities[modelType][targetLang];
    let bestMatch = null;
    let bestScore = 0;

    for (const [original, probMap] of probs.entries()) {
      const similarity = this._calculateSimilarity(text, original);
      
      if (similarity > 0.8 && similarity > bestScore) {
        // Trouver la meilleure traduction pour cette correspondance (celle avec le plus de points)
        let bestTranslation = null;
        let bestProb = 0;

        for (const [translation, prob] of probMap.entries()) {
          if (prob > bestProb) {
            bestProb = prob;
            bestTranslation = translation;
          }
        }

        if (bestTranslation) {
          // Score combiné : similarité × probabilité (plus de points = meilleur)
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
   * Choisit TOUJOURS la traduction avec le plus de points (score le plus élevé)
   */
  _getNgramMatch(text, modelType, targetLang) {
    const textNgrams = this._generateNgrams(text, 2);
    const probs = this.probabilities[modelType][targetLang];
    
    const scores = new Map(); // translation -> score cumulé

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
        
        // Accumuler les scores : similarité × probabilité (plus de points = meilleur)
        // Si plusieurs traductions existent pour le même original, on additionne leurs scores
        for (const [translation, prob] of probMap.entries()) {
          const currentScore = scores.get(translation) || 0;
          scores.set(translation, currentScore + (ngramSimilarity * prob));
        }
      }
    }

    // Trouver la meilleure traduction (celle avec le score le plus élevé = le plus de points)
    let bestTranslation = null;
    let bestScore = 0;

    for (const [translation, score] of scores.entries()) {
      if (score > bestScore) {
        bestScore = score;
        bestTranslation = translation;
      }
    }

    // Choisir la meilleure si le score est raisonnable
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
   * Entraîne le modèle avec de nouvelles données (système hybride)
   * Entraîne à la fois le système probabiliste ET le réseau de neurones
   */
  async train(feedback) {
    await this.loadModels();

    const { type, originalText, suggestedTranslation, targetLanguage } = feedback;
    
    if (!originalText || !suggestedTranslation || !targetLanguage) {
      return false;
    }

    const normalizedOriginal = originalText.toLowerCase().trim();
    let modelType;
    if (type === 'recipeName') {
      modelType = 'recipeNames';
    } else if (type === 'summary') {
      modelType = 'instructions'; // Utiliser le même modèle que les instructions pour les résumés
    } else {
      modelType = type + 's';
    }

    if (targetLanguage === 'fr' || targetLanguage === 'es') {
      // 1. Entraîner le système probabiliste
      if (!this.models[modelType][targetLanguage][normalizedOriginal]) {
        this.models[modelType][targetLanguage][normalizedOriginal] = {};
      }

      if (!this.models[modelType][targetLanguage][normalizedOriginal][suggestedTranslation]) {
        this.models[modelType][targetLanguage][normalizedOriginal][suggestedTranslation] = 0;
      }

      this.models[modelType][targetLanguage][normalizedOriginal][suggestedTranslation] += 1;

      // Recalculer les probabilités
      this._calculateProbabilities();

      // Sauvegarder le modèle probabiliste
      await this._saveModel(modelType, targetLanguage);

      // 2. Entraîner le réseau de neurones (apprentissage par renforcement)
      if (neuralTranslationEngine) {
        try {
          await neuralTranslationEngine.train(feedback);
        } catch (e) {
          console.warn('⚠️  Erreur entraînement réseau de neurones:', e.message);
        }
      }

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
   * Entraîne le modèle avec tous les feedbacks de la base de données (système hybride)
   */
  async retrain() {
    console.log('🔄 Réentraînement du modèle ML (système hybride)...');
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
    
    // Charger depuis les fichiers et la base de données
    await this.loadModels();
    
    // Entraîner le système probabiliste avec tous les feedbacks approuvés
    await this._trainFromApprovedFeedbacks();
    
    // Entraîner le réseau de neurones (si disponible)
    if (neuralTranslationEngine) {
      try {
        console.log('🧠 Réentraînement du réseau de neurones...');
        await neuralTranslationEngine.retrain();
      } catch (e) {
        console.warn('⚠️  Erreur réentraînement réseau de neurones:', e.message);
      }
    }
    
    console.log('✅ Réentraînement terminé');
  }

  /**
   * Entraîne le modèle avec tous les feedbacks approuvés
   */
  async _trainFromApprovedFeedbacks() {
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }

        db.all(
          `SELECT type, original_text, suggested_translation, target_language
           FROM translation_feedbacks 
           WHERE approved = 1 
             AND suggested_translation IS NOT NULL 
             AND suggested_translation != ''`,
          [],
          async (err, feedbacks) => {
            db.close();
            if (err) {
              return reject(err);
            }

            console.log(`📚 Entraînement avec ${feedbacks.length} feedbacks approuvés...`);

            for (const feedback of feedbacks) {
              try {
                await this.train({
                  type: feedback.type,
                  originalText: feedback.original_text,
                  suggestedTranslation: feedback.suggested_translation,
                  targetLanguage: feedback.target_language,
                });
              } catch (error) {
                console.warn(`⚠️  Erreur entraînement feedback ${feedback.id}:`, error.message);
              }
            }

            resolve();
          }
        );
      });
    });
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

