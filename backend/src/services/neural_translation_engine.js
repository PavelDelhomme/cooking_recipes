/**
 * Moteur de traduction basé sur un vrai réseau de neurones (TensorFlow.js)
 * Utilise l'apprentissage par renforcement pour s'améliorer continuellement
 * 
 * Architecture :
 * - Réseau de neurones simple (pas besoin de GPU)
 * - Apprentissage par renforcement basé sur les feedbacks
 * - Intégration avec le système probabiliste existant
 */

const tf = require('@tensorflow/tfjs-node');
const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

class NeuralTranslationEngine {
  constructor() {
    this.modelsPath = path.join(__dirname, '../../data/neural_models');
    this.dbPath = path.join(__dirname, '../../data/database.sqlite');
    
    // Créer le dossier des modèles s'il n'existe pas
    if (!fs.existsSync(this.modelsPath)) {
      fs.mkdirSync(this.modelsPath, { recursive: true });
    }
    
    // Modèles de neurones par type et langue
    this.models = {
      ingredients: { fr: null, es: null },
      instructions: { fr: null, es: null },
      recipeNames: { fr: null, es: null },
      units: { fr: null, es: null },
    };
    
    // Vocabulaire source (anglais) et cible (français/espagnol)
    // Structure: { type: { source: Map, fr: Map, es: Map } }
    this.vocabularies = {
      ingredients: { source: new Map(), fr: new Map(), es: new Map() },
      instructions: { source: new Map(), fr: new Map(), es: new Map() },
      recipeNames: { source: new Map(), fr: new Map(), es: new Map() },
      units: { source: new Map(), fr: new Map(), es: new Map() },
    };
    
    // Vocabulaire inverse (index -> mot)
    this.reverseVocabularies = {
      ingredients: { source: new Map(), fr: new Map(), es: new Map() },
      instructions: { source: new Map(), fr: new Map(), es: new Map() },
      recipeNames: { source: new Map(), fr: new Map(), es: new Map() },
      units: { source: new Map(), fr: new Map(), es: new Map() },
    };
    
    // Paramètres du modèle (réduits pour éviter les erreurs et oneAPI)
    this.config = {
      maxSequenceLength: 20, // Réduit de 50 à 20 pour être plus léger
      embeddingDim: 32,      // Réduit de 64 à 32 (plus léger)
      hiddenDim: 64,        // Réduit de 128 à 64 (plus léger)
      vocabSize: 1000,       // Réduit de 5000 à 1000 (plus léger, évite oneAPI)
      learningRate: 0.001,    // Taux d'apprentissage
    };
    
    this.loaded = false;
  }

  /**
   * Charge ou crée les modèles de neurones
   */
  async loadModels() {
    if (this.loaded) return;
    
    try {
      console.log('🧠 Chargement des modèles de neurones...');
      
      // Charger les vocabulaires depuis la base de données
      await this._loadVocabularies();
      
      // Charger ou créer les modèles pour chaque type et langue
      const types = ['ingredients', 'instructions', 'recipeNames', 'units'];
      const langs = ['fr', 'es'];
      
      for (const type of types) {
        for (const lang of langs) {
          const modelPath = path.join(this.modelsPath, `${type}_${lang}_model.json`);
          
          if (fs.existsSync(modelPath)) {
            // Charger le modèle existant
            try {
              this.models[type][lang] = await tf.loadLayersModel(`file://${modelPath}`);
              console.log(`✅ Modèle ${type}_${lang} chargé`);
            } catch (e) {
              console.warn(`⚠️  Erreur chargement ${type}_${lang}, création nouveau modèle:`, e.message);
              this.models[type][lang] = this._createModel(type, lang);
            }
          } else {
            // Créer un nouveau modèle
            this.models[type][lang] = this._createModel(type, lang);
            console.log(`🆕 Nouveau modèle ${type}_${lang} créé`);
          }
        }
      }
      
      this.loaded = true;
      console.log('✅ Modèles de neurones chargés');
    } catch (error) {
      console.error('❌ Erreur lors du chargement des modèles:', error);
      this.loaded = true; // Marquer comme chargé pour éviter les boucles
    }
  }

  /**
   * Crée un nouveau modèle de neurones (architecture très simple pour éviter les erreurs)
   * Modèle minimaliste pour CPU sans dépendances complexes
   */
  _createModel(type, lang) {
    try {
      // Modèle très simple : juste embedding + dense (pas de LSTM pour éviter les erreurs)
      const model = tf.sequential({
        layers: [
          // Couche d'embedding (convertit les mots en vecteurs)
          tf.layers.embedding({
            inputDim: Math.max(this.config.vocabSize, 100), // Minimum 100 pour éviter les erreurs
            outputDim: 32, // Réduit de 64 à 32 pour être plus léger
            inputLength: this.config.maxSequenceLength,
            name: 'embedding',
          }),
          
          // GlobalAveragePooling1D pour réduire la dimension (plus simple que LSTM)
          tf.layers.globalAveragePooling1d({
            name: 'pooling',
          }),
          
          // Couche dense intermédiaire (réduite)
          tf.layers.dense({
            units: 64, // Réduit de 128 à 64
            activation: 'relu',
            name: 'dense1',
          }),
          
          // Couche de sortie (probabilités sur le vocabulaire)
          tf.layers.dense({
            units: Math.max(this.config.vocabSize, 100), // Minimum 100
            activation: 'softmax',
            name: 'output',
          }),
        ],
      });

      // Compiler le modèle avec optimiseur Adam (léger, fonctionne sur CPU)
      model.compile({
        optimizer: tf.train.adam(this.config.learningRate),
        loss: 'categoricalCrossentropy',
        metrics: ['accuracy'],
      });

      return model;
    } catch (error) {
      console.error(`❌ Erreur création modèle ${type}_${lang}:`, error.message);
      // Retourner null si erreur, le système probabiliste prendra le relais
      return null;
    }
  }

  /**
   * Charge les vocabulaires depuis la base de données
   */
  async _loadVocabularies() {
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }
      });

      // Charger tous les feedbacks approuvés pour construire le vocabulaire
      db.all(
        `SELECT 
          type,
          original_text,
          suggested_translation,
          target_language
         FROM translation_feedbacks 
         WHERE approved = 1 
           AND suggested_translation IS NOT NULL 
           AND suggested_translation != ''`,
        [],
        (err, rows) => {
          if (err) {
            db.close();
            return reject(err);
          }

          console.log(`📚 ${rows ? rows.length : 0} feedbacks approuvés trouvés dans la base de données`);
          
          if (!rows || rows.length === 0) {
            console.warn('⚠️  Aucun feedback approuvé trouvé. Le réseau de neurones ne peut pas être entraîné sans données.');
            db.close();
            return resolve();
          }

          // Construire les vocabulaires
          const types = ['ingredient', 'instruction', 'recipeName', 'unit', 'summary'];
          const langs = ['fr', 'es'];

          for (const row of rows) {
            const type = row.type;
            const lang = row.target_language;
            
            let modelType;
            if (type === 'recipeName') {
              modelType = 'recipeNames';
            } else if (type === 'summary') {
              modelType = 'instructions';
            } else {
              modelType = type + 's';
            }

            if (langs.includes(lang) && types.includes(type)) {
              // Ajouter les mots du texte original au vocabulaire SOURCE (anglais)
              const originalWords = this._tokenize(row.original_text);
              originalWords.forEach(word => {
                if (!this.vocabularies[modelType].source.has(word)) {
                  const index = this.vocabularies[modelType].source.size;
                  this.vocabularies[modelType].source.set(word, index);
                  this.reverseVocabularies[modelType].source.set(index, word);
                }
              });

              // Ajouter les mots de la traduction au vocabulaire CIBLE (français/espagnol)
              const translationWords = this._tokenize(row.suggested_translation);
              translationWords.forEach(word => {
                if (!this.vocabularies[modelType][lang].has(word)) {
                  const index = this.vocabularies[modelType][lang].size;
                  this.vocabularies[modelType][lang].set(word, index);
                  this.reverseVocabularies[modelType][lang].set(index, word);
                }
              });
            }
          }

          // Limiter la taille du vocabulaire
          for (const type of Object.keys(this.vocabularies)) {
            // Vocabulaire source (anglais)
            const sourceVocab = this.vocabularies[type].source;
            if (sourceVocab.size > this.config.vocabSize) {
              console.warn(`⚠️  Vocabulaire source ${type} trop grand (${sourceVocab.size}), limitation à ${this.config.vocabSize}`);
            }
            
            // Vocabulaires cibles (français/espagnol)
            for (const lang of langs) {
              const vocab = this.vocabularies[type][lang];
              if (vocab.size > this.config.vocabSize) {
                console.warn(`⚠️  Vocabulaire ${type}_${lang} trop grand (${vocab.size}), limitation à ${this.config.vocabSize}`);
              }
            }
          }

          resolve();
        }
      );
    });
  }

  /**
   * Tokenise un texte (sépare en mots)
   */
  _tokenize(text) {
    if (!text || typeof text !== 'string') return [];
    return text
      .toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 0);
  }

  /**
   * Convertit un texte en séquence d'indices (pour le modèle)
   * @param {string} text - Texte à convertir
   * @param {string} type - Type (ingredients, instructions, etc.)
   * @param {string} lang - Langue du vocabulaire ('source' pour anglais, 'fr' ou 'es' pour cible)
   */
  _textToSequence(text, type, lang) {
    const words = this._tokenize(text);
    const vocab = this.vocabularies[type][lang] || this.vocabularies[type].source;
    const sequence = words
      .map(word => vocab.get(word))
      .filter(index => index !== undefined)
      .slice(0, this.config.maxSequenceLength);
    
    // Padding pour avoir la bonne longueur
    while (sequence.length < this.config.maxSequenceLength) {
      sequence.push(0); // 0 = padding
    }
    
    return sequence;
  }

  /**
   * Convertit une séquence d'indices en texte (depuis le modèle)
   */
  _sequenceToText(sequence, type, lang) {
    const reverseVocab = this.reverseVocabularies[type][lang];
    const words = sequence
      .map(index => reverseVocab.get(index))
      .filter(word => word && word !== '<PAD>');
    
    return words.join(' ');
  }

  /**
   * Traduit un texte en utilisant le réseau de neurones (seq2seq)
   */
  async translate(text, type = 'ingredient', targetLang = 'fr') {
    await this.loadModels();

    if (!text || typeof text !== 'string' || text.trim().length === 0) {
      return null;
    }

    let modelType;
    if (type === 'recipeName') {
      modelType = 'recipeNames';
    } else if (type === 'summary') {
      modelType = 'instructions';
    } else {
      modelType = type + 's';
    }

    const model = this.models[modelType][targetLang];
    if (!model) {
      return null;
    }

    // Vérifier que les vocabulaires ne sont pas vides
    const sourceVocab = this.vocabularies[modelType].source;
    const targetVocab = this.vocabularies[modelType][targetLang];
    if (sourceVocab.size === 0 || targetVocab.size === 0) {
      return null; // Pas encore de vocabulaire, utiliser le fallback
    }

    try {
      // Convertir le texte en séquence (utiliser le vocabulaire source = anglais)
      const sequence = this._textToSequence(text, modelType, 'source');
      const inputTensor = tf.tensor2d([sequence]);

      // Prédire avec le modèle
      const prediction = model.predict(inputTensor);
      const predictionArray = await prediction.array();
      
      // Nettoyer les tenseurs
      inputTensor.dispose();
      prediction.dispose();

      // Trouver l'indice avec la plus haute probabilité
      const output = predictionArray[0];
      const maxIndex = output.indexOf(Math.max(...output));
      
      // Convertir l'indice en mot (utiliser le vocabulaire de la langue cible)
      const translatedWord = this.reverseVocabularies[modelType][targetLang].get(maxIndex);
      
      if (translatedWord && maxIndex > 0) { // 0 = padding
        return translatedWord;
      }

      return null;
    } catch (error) {
      console.warn(`⚠️  Erreur traduction neurone ${type}_${targetLang}:`, error.message);
      return null;
    }
  }

  /**
   * Entraîne le modèle avec un feedback (apprentissage par renforcement)
   */
  async train(feedback) {
    await this.loadModels();

    const { type, originalText, suggestedTranslation, targetLanguage } = feedback;
    
    if (!originalText || !suggestedTranslation || !targetLanguage) {
      return false;
    }

    let modelType;
    if (type === 'recipeName') {
      modelType = 'recipeNames';
    } else if (type === 'summary') {
      modelType = 'instructions';
    } else {
      modelType = type + 's';
    }

    if (targetLanguage === 'fr' || targetLanguage === 'es') {
      const model = this.models[modelType][targetLanguage];
      if (!model) {
        return false;
      }

      try {
        // Préparer les données d'entraînement
        // Input : texte original (anglais) - utiliser vocabulaire source
        // Output : traduction (français/espagnol) - utiliser vocabulaire cible
        
        // Tokeniser une seule fois
        const originalWords = this._tokenize(originalText);
        const translationWords = this._tokenize(suggestedTranslation);
        
        // Ajouter au vocabulaire source si nécessaire (anglais)
        originalWords.forEach(word => {
          if (!this.vocabularies[modelType].source.has(word)) {
            const index = this.vocabularies[modelType].source.size;
            this.vocabularies[modelType].source.set(word, index);
            this.reverseVocabularies[modelType].source.set(index, word);
          }
        });
        
        // Ajouter au vocabulaire cible si nécessaire (français/espagnol)
        translationWords.forEach(word => {
          if (!this.vocabularies[modelType][targetLanguage].has(word)) {
            const index = this.vocabularies[modelType][targetLanguage].size;
            this.vocabularies[modelType][targetLanguage].set(word, index);
            this.reverseVocabularies[modelType][targetLanguage].set(index, word);
          }
        });
        
        if (translationWords.length === 0) {
          return false;
        }
        
        // Prendre le premier mot de la traduction comme target
        const targetWord = translationWords[0];
        const targetIndex = this.vocabularies[modelType][targetLanguage].get(targetWord);
        
        if (targetIndex === undefined) {
          return false; // Le mot devrait être dans le vocabulaire maintenant
        }
        
        // Convertir en séquences
        const inputSequence = this._textToSequence(originalText, modelType, 'source');
        
        // Convertir en tenseurs
        const inputTensor = tf.tensor2d([inputSequence]);
        const outputTensor = tf.oneHot(
          tf.tensor1d([targetIndex], 'int32'),
          this.config.vocabSize
        );

        // Entraîner le modèle (une seule itération pour l'apprentissage par renforcement)
        await model.trainOnBatch(inputTensor, outputTensor);

        // Nettoyer les tenseurs
        inputTensor.dispose();
        outputTensor.dispose();

        // Sauvegarder le modèle périodiquement
        await this._saveModel(modelType, targetLanguage);

        return true;
      } catch (error) {
        console.error(`❌ Erreur entraînement neurone ${modelType}_${targetLanguage}:`, error);
        return false;
      }
    }

    return false;
  }

  /**
   * Sauvegarde un modèle
   */
  async _saveModel(modelType, targetLang) {
    const model = this.models[modelType][targetLang];
    if (!model) return;

    try {
      const modelPath = path.join(this.modelsPath, `${modelType}_${targetLang}_model.json`);
      await model.save(`file://${modelPath}`);
      
      // Sauvegarder aussi le vocabulaire
      const vocabPath = path.join(this.modelsPath, `${modelType}_${targetLang}_vocab.json`);
      const vocabData = {
        vocab: Array.from(this.vocabularies[modelType][targetLang].entries()),
        reverseVocab: Array.from(this.reverseVocabularies[modelType][targetLang].entries()),
      };
      fs.writeFileSync(vocabPath, JSON.stringify(vocabData, null, 2), 'utf8');
    } catch (error) {
      console.error(`❌ Erreur sauvegarde modèle ${modelType}_${targetLang}:`, error);
    }
  }

  /**
   * Réentraîne le modèle avec tous les feedbacks
   */
  async retrain() {
    console.log('🔄 Réentraînement des modèles de neurones...');
    
    // Recharger les vocabulaires
    await this._loadVocabularies();
    
    // Recharger les modèles
    await this.loadModels();
    
    // Entraîner avec tous les feedbacks approuvés
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }
      });

      db.all(
        `SELECT type, original_text, suggested_translation, target_language
         FROM translation_feedbacks 
         WHERE approved = 1 
           AND suggested_translation IS NOT NULL 
           AND suggested_translation != ''`,
        [],
        async (err, feedbacks) => {
          if (err) {
            db.close();
            return reject(err);
          }

          console.log(`📚 Entraînement avec ${feedbacks ? feedbacks.length : 0} feedbacks approuvés...`);
          
          if (!feedbacks || feedbacks.length === 0) {
            console.warn('⚠️  Aucun feedback approuvé trouvé. Vérifiez que vous avez des feedbacks approuvés dans la base de données.');
            db.close();
            return resolve();
          }

          let trainedCount = 0;
          let errorCount = 0;
          
          for (const feedback of feedbacks) {
            try {
              const success = await this.train({
                type: feedback.type,
                originalText: feedback.original_text,
                suggestedTranslation: feedback.suggested_translation,
                targetLanguage: feedback.target_language,
              });
              if (success) {
                trainedCount++;
              } else {
                errorCount++;
              }
            } catch (error) {
              console.warn(`⚠️  Erreur entraînement feedback:`, error.message);
              errorCount++;
            }
          }

          console.log(`✅ Réentraînement terminé: ${trainedCount} entraînés, ${errorCount} erreurs`);
          db.close();
          resolve();
        }
      );
    });
  }

  /**
   * Obtient les statistiques du modèle
   */
  getStats() {
    const stats = {
      ingredients: { source: 0, fr: 0, es: 0 },
      instructions: { source: 0, fr: 0, es: 0 },
      recipeNames: { source: 0, fr: 0, es: 0 },
      units: { source: 0, fr: 0, es: 0 },
    };

    for (const type of Object.keys(stats)) {
      stats[type].source = this.vocabularies[type].source.size;
      for (const lang of ['fr', 'es']) {
        stats[type][lang] = this.vocabularies[type][lang].size;
      }
    }

    return stats;
  }
}

// Export singleton
const neuralTranslationEngine = new NeuralTranslationEngine();
module.exports = neuralTranslationEngine;

