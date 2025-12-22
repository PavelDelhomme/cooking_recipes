/**
 * Service de Reconnaissance d'Intention (Intent Recognition)
 * 
 * Comprend l'intention de l'utilisateur dans ses recherches et requêtes
 * pour améliorer les résultats et l'entraînement du modèle ML
 * 
 * Types d'intentions supportées :
 * - SEARCH_BY_NAME : Recherche par nom de recette
 * - SEARCH_BY_INGREDIENTS : Recherche par ingrédients disponibles
 * - SEARCH_BY_TYPE : Recherche par type de plat (dessert, entrée, etc.)
 * - SEARCH_BY_CONSTRAINTS : Recherche avec contraintes (rapide, végétarien, etc.)
 * - SEARCH_BY_DIFFICULTY : Recherche par difficulté
 * - SEARCH_BY_TIME : Recherche par temps de préparation
 * - TRANSLATION_FEEDBACK : Feedback sur une traduction
 * - LEARNING_INTENT : Intention d'apprentissage/amélioration
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

class IntentRecognitionService {
  constructor() {
    this.modelsPath = path.join(__dirname, '../../data/intent_models');
    this.dbPath = path.join(__dirname, '../../data/database.sqlite');
    
    // Créer le dossier des modèles d'intention s'il n'existe pas
    if (!fs.existsSync(this.modelsPath)) {
      fs.mkdirSync(this.modelsPath, { recursive: true });
    }
    
    // Modèles d'intention en mémoire
    this.intentModels = {
      search: new Map(), // Patterns de recherche
      constraints: new Map(), // Contraintes (rapide, végétarien, etc.)
      types: new Map(), // Types de plats
      feedback: new Map(), // Patterns de feedback
    };
    
    // Mots-clés et patterns pour la reconnaissance d'intention
    this.keywords = {
      // Types de plats
      types: {
        dessert: ['dessert', 'sweet', 'cake', 'pie', 'cookie', 'chocolate', 'sugar'],
        entree: ['appetizer', 'starter', 'entrée', 'hors d\'oeuvre'],
        main: ['main', 'dish', 'meal', 'dinner', 'lunch', 'plat principal'],
        breakfast: ['breakfast', 'morning', 'cereal', 'pancake', 'waffle'],
        snack: ['snack', 'bite', 'quick bite'],
        drink: ['drink', 'beverage', 'cocktail', 'smoothie'],
      },
      // Contraintes
      constraints: {
        quick: ['quick', 'fast', 'rapid', 'fast', 'speedy', '15 minutes', '30 minutes'],
        easy: ['easy', 'simple', 'basic', 'beginner', 'facile'],
        vegetarian: ['vegetarian', 'veggie', 'vegetable', 'végétarien'],
        vegan: ['vegan', 'plant-based'],
        glutenFree: ['gluten-free', 'gluten free', 'sans gluten'],
        healthy: ['healthy', 'light', 'low-calorie', 'diet', 'santé'],
        cheap: ['cheap', 'budget', 'affordable', 'économique'],
      },
      // Difficulté
      difficulty: {
        easy: ['easy', 'simple', 'beginner', 'facile'],
        medium: ['medium', 'moderate', 'intermediate', 'moyen'],
        hard: ['hard', 'difficult', 'advanced', 'complex', 'difficile'],
      },
      // Temps
      time: {
        short: ['quick', 'fast', '15 min', '30 min', 'rapide'],
        medium: ['1 hour', '45 min', 'moyen'],
        long: ['long', 'slow', '2 hours', '3 hours', 'long'],
      },
    };
    
    // Modèle chargé
    this.loaded = false;
  }

  /**
   * Charge les modèles d'intention depuis les fichiers et la base de données
   */
  async loadModels() {
    if (this.loaded) return;
    
    try {
      console.log('🧠 Chargement des modèles de reconnaissance d'intention...');
      
      // Charger depuis les fichiers JSON
      await this._loadFromFiles();
      
      // Charger depuis la base de données (historique des recherches)
      await this._loadFromDatabase();
      
      this.loaded = true;
      console.log('✅ Modèles d'intention chargés avec succès');
    } catch (error) {
      console.error('❌ Erreur lors du chargement des modèles d'intention:', error);
      this.loaded = true;
    }
  }

  /**
   * Charge les modèles depuis les fichiers JSON
   */
  async _loadFromFiles() {
    const filePath = path.join(this.modelsPath, 'intent_patterns.json');
    if (fs.existsSync(filePath)) {
      try {
        const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        if (data.search) {
          Object.entries(data.search).forEach(([pattern, intent]) => {
            this.intentModels.search.set(pattern.toLowerCase(), intent);
          });
        }
        if (data.constraints) {
          Object.entries(data.constraints).forEach(([pattern, constraint]) => {
            this.intentModels.constraints.set(pattern.toLowerCase(), constraint);
          });
        }
        if (data.types) {
          Object.entries(data.types).forEach(([pattern, type]) => {
            this.intentModels.types.set(pattern.toLowerCase(), type);
          });
        }
      } catch (error) {
        console.warn('⚠️  Erreur lors du chargement des patterns d'intention:', error.message);
      }
    }
  }

  /**
   * Charge les modèles depuis la base de données
   */
  async _loadFromDatabase() {
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }

        // Créer la table pour stocker l'historique des intentions si elle n'existe pas
        db.run(`
          CREATE TABLE IF NOT EXISTS search_intents (
            id TEXT PRIMARY KEY,
            query TEXT NOT NULL,
            intent_type TEXT NOT NULL,
            intent_data TEXT,
            user_id TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        `, (err) => {
          if (err) {
            db.close();
            return reject(err);
          }

          // Charger les patterns fréquents depuis l'historique
          db.all(`
            SELECT query, intent_type, COUNT(*) as count
            FROM search_intents
            GROUP BY query, intent_type
            ORDER BY count DESC
            LIMIT 1000
          `, [], (err, rows) => {
            if (err) {
              db.close();
              return reject(err);
            }

            rows.forEach(row => {
              const pattern = row.query.toLowerCase();
              if (!this.intentModels.search.has(pattern)) {
                this.intentModels.search.set(pattern, {
                  type: row.intent_type,
                  confidence: Math.min(row.count / 10, 1.0), // Confiance basée sur la fréquence
                });
              }
            });

            db.close();
            resolve();
          });
        });
      });
    });
  }

  /**
   * Reconnaît l'intention d'une requête de recherche
   * @param {string} query - La requête de recherche
   * @param {object} context - Contexte supplémentaire (ingrédients disponibles, etc.)
   * @returns {object} - Objet avec l'intention détectée et sa confiance
   */
  async recognizeSearchIntent(query, context = {}) {
    await this.loadModels();

    if (!query || typeof query !== 'string') {
      return {
        intent: 'SEARCH_BY_NAME',
        confidence: 0.5,
        extracted: {},
      };
    }

    const normalizedQuery = query.toLowerCase().trim();
    const result = {
      intent: 'SEARCH_BY_NAME', // Par défaut
      confidence: 0.5,
      extracted: {
        name: null,
        ingredients: [],
        type: null,
        constraints: [],
        difficulty: null,
        time: null,
      },
    };

    // 1. Vérifier si c'est un pattern connu
    if (this.intentModels.search.has(normalizedQuery)) {
      const knownIntent = this.intentModels.search.get(normalizedQuery);
      result.intent = knownIntent.type;
      result.confidence = knownIntent.confidence;
    }

    // 2. Analyser les mots-clés pour extraire l'intention
    const words = normalizedQuery.split(/\s+/);
    
    // Détecter les types de plats
    for (const [type, keywords] of Object.entries(this.keywords.types)) {
      if (keywords.some(keyword => normalizedQuery.includes(keyword))) {
        result.extracted.type = type;
        result.intent = 'SEARCH_BY_TYPE';
        result.confidence = Math.max(result.confidence, 0.7);
        break;
      }
    }

    // Détecter les contraintes
    for (const [constraint, keywords] of Object.entries(this.keywords.constraints)) {
      if (keywords.some(keyword => normalizedQuery.includes(keyword))) {
        result.extracted.constraints.push(constraint);
        result.intent = 'SEARCH_BY_CONSTRAINTS';
        result.confidence = Math.max(result.confidence, 0.7);
      }
    }

    // Détecter la difficulté
    for (const [difficulty, keywords] of Object.entries(this.keywords.difficulty)) {
      if (keywords.some(keyword => normalizedQuery.includes(keyword))) {
        result.extracted.difficulty = difficulty;
        result.intent = 'SEARCH_BY_DIFFICULTY';
        result.confidence = Math.max(result.confidence, 0.7);
        break;
      }
    }

    // Détecter le temps
    for (const [time, keywords] of Object.entries(this.keywords.time)) {
      if (keywords.some(keyword => normalizedQuery.includes(keyword))) {
        result.extracted.time = time;
        result.intent = 'SEARCH_BY_TIME';
        result.confidence = Math.max(result.confidence, 0.7);
        break;
      }
    }

    // Détecter les ingrédients (mots qui ne sont pas des mots-clés connus)
    const ingredientWords = words.filter(word => {
      const isKeyword = Object.values(this.keywords.types).some(kws => kws.includes(word)) ||
                        Object.values(this.keywords.constraints).some(kws => kws.includes(word)) ||
                        Object.values(this.keywords.difficulty).some(kws => kws.includes(word)) ||
                        Object.values(this.keywords.time).some(kws => kws.includes(word));
      return !isKeyword && word.length > 2;
    });

    if (ingredientWords.length > 0 && !result.extracted.type) {
      result.extracted.ingredients = ingredientWords;
      result.intent = 'SEARCH_BY_INGREDIENTS';
      result.confidence = Math.max(result.confidence, 0.6);
    }

    // Si le contexte contient des ingrédients disponibles, prioriser la recherche par ingrédients
    if (context.availableIngredients && context.availableIngredients.length > 0) {
      result.extracted.ingredients = context.availableIngredients;
      result.intent = 'SEARCH_BY_INGREDIENTS';
      result.confidence = Math.max(result.confidence, 0.8);
    }

    // Extraire le nom de la recette (mots qui ne sont pas des ingrédients ou des mots-clés)
    const nameWords = words.filter(word => {
      return !result.extracted.ingredients.includes(word) &&
             !result.extracted.constraints.some(c => this.keywords.constraints[c]?.includes(word)) &&
             word.length > 2;
    });

    if (nameWords.length > 0) {
      result.extracted.name = nameWords.join(' ');
    }

    return result;
  }

  /**
   * Reconnaît l'intention d'un feedback de traduction
   * @param {object} feedback - Le feedback de traduction
   * @returns {object} - Objet avec l'intention détectée
   */
  async recognizeFeedbackIntent(feedback) {
    await this.loadModels();

    const result = {
      intent: 'TRANSLATION_FEEDBACK',
      confidence: 0.8,
      extracted: {
        type: feedback.type || 'ingredient',
        improvement: null,
        correction: null,
      },
    };

    // Analyser le feedback pour comprendre l'intention
    if (feedback.suggestedTranslation && feedback.originalText) {
      // Si la traduction suggérée est différente, c'est une correction
      if (feedback.suggestedTranslation !== feedback.currentTranslation) {
        result.extracted.correction = true;
        result.intent = 'TRANSLATION_CORRECTION';
        result.confidence = 0.9;
      } else {
        result.extracted.improvement = true;
        result.intent = 'TRANSLATION_IMPROVEMENT';
        result.confidence = 0.7;
      }
    }

    return result;
  }

  /**
   * Enregistre une intention détectée pour améliorer le modèle
   * @param {string} query - La requête originale
   * @param {object} intent - L'intention détectée
   * @param {string} userId - ID de l'utilisateur (optionnel)
   */
  async saveIntent(query, intent, userId = null) {
    await this.loadModels();

    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }

        const id = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        const intentData = JSON.stringify(intent.extracted || {});

        db.run(`
          INSERT INTO search_intents (id, query, intent_type, intent_data, user_id)
          VALUES (?, ?, ?, ?, ?)
        `, [id, query, intent.intent, intentData, userId], (err) => {
          if (err) {
            db.close();
            return reject(err);
          }

          // Mettre à jour le modèle en mémoire
          const normalizedQuery = query.toLowerCase();
          if (!this.intentModels.search.has(normalizedQuery)) {
            this.intentModels.search.set(normalizedQuery, {
              type: intent.intent,
              confidence: intent.confidence,
            });
          }

          db.close();
          resolve();
        });
      });
    });
  }

  /**
   * Améliore le modèle d'intention avec un feedback
   * @param {string} query - La requête originale
   * @param {string} correctIntent - L'intention correcte (si l'utilisateur corrige)
   */
  async improveModel(query, correctIntent) {
    await this.loadModels();

    const normalizedQuery = query.toLowerCase();
    
    // Mettre à jour le modèle
    this.intentModels.search.set(normalizedQuery, {
      type: correctIntent,
      confidence: 1.0, // Confiance maximale car confirmé par l'utilisateur
    });

    // Sauvegarder dans les fichiers
    await this._saveToFiles();
  }

  /**
   * Sauvegarde les modèles dans les fichiers JSON
   */
  async _saveToFiles() {
    const filePath = path.join(this.modelsPath, 'intent_patterns.json');
    const data = {
      search: {},
      constraints: {},
      types: {},
    };

    // Convertir les Maps en objets
    this.intentModels.search.forEach((value, key) => {
      data.search[key] = value;
    });

    this.intentModels.constraints.forEach((value, key) => {
      data.constraints[key] = value;
    });

    this.intentModels.types.forEach((value, key) => {
      data.types[key] = value;
    });

    try {
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
    } catch (error) {
      console.error('❌ Erreur lors de la sauvegarde des modèles d'intention:', error);
    }
  }

  /**
   * Obtient les statistiques d'intention
   * @returns {object} - Statistiques sur les intentions détectées
   */
  async getIntentStatistics() {
    await this.loadModels();

    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }

        db.all(`
          SELECT intent_type, COUNT(*) as count
          FROM search_intents
          GROUP BY intent_type
          ORDER BY count DESC
        `, [], (err, rows) => {
          if (err) {
            db.close();
            return reject(err);
          }

          const stats = {
            total: 0,
            byType: {},
          };

          rows.forEach(row => {
            stats.byType[row.intent_type] = row.count;
            stats.total += row.count;
          });

          db.close();
          resolve(stats);
        });
      });
    });
  }
}

// Export singleton
let intentRecognitionService = null;

function getIntentRecognitionService() {
  if (!intentRecognitionService) {
    intentRecognitionService = new IntentRecognitionService();
  }
  return intentRecognitionService;
}

module.exports = getIntentRecognitionService();

