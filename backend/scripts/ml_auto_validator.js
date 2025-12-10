/**
 * Système de validation automatique des feedbacks de traduction
 * Valide automatiquement les feedbacks qui correspondent aux traductions de référence
 */

const { getDatabase } = require('../src/database/db');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Traductions de référence pour validation automatique
const REFERENCE_TRANSLATIONS = {
  ingredients: {
    'chicken': { fr: 'poulet', es: 'pollo' },
    'beef': { fr: 'boeuf', es: 'carne de res' },
    'pork': { fr: 'porc', es: 'cerdo' },
    'fish': { fr: 'poisson', es: 'pescado' },
    'tomato': { fr: 'tomate', es: 'tomate' },
    'onion': { fr: 'oignon', es: 'cebolla' },
    'garlic': { fr: 'ail', es: 'ajo' },
    'carrot': { fr: 'carotte', es: 'zanahoria' },
    'potato': { fr: 'pomme de terre', es: 'patata' },
    'rice': { fr: 'riz', es: 'arroz' },
    'pasta': { fr: 'pâtes', es: 'pasta' },
    'flour': { fr: 'farine', es: 'harina' },
    'sugar': { fr: 'sucre', es: 'azúcar' },
    'salt': { fr: 'sel', es: 'sal' },
    'pepper': { fr: 'poivre', es: 'pimienta' },
    'oil': { fr: 'huile', es: 'aceite' },
    'butter': { fr: 'beurre', es: 'mantequilla' },
    'egg': { fr: 'œuf', es: 'huevo' },
    'milk': { fr: 'lait', es: 'leche' },
    'cheese': { fr: 'fromage', es: 'queso' },
  },
  units: {
    'cup': { fr: 'tasse', es: 'taza' },
    'tablespoon': { fr: 'cuillère à soupe', es: 'cucharada' },
    'teaspoon': { fr: 'cuillère à café', es: 'cucharadita' },
    'gram': { fr: 'gramme', es: 'gramo' },
    'kilogram': { fr: 'kilogramme', es: 'kilogramo' },
    'liter': { fr: 'litre', es: 'litro' },
    'milliliter': { fr: 'millilitre', es: 'mililitro' },
    'piece': { fr: 'pièce', es: 'pieza' },
    'pound': { fr: 'livre', es: 'libra' },
    'ounce': { fr: 'once', es: 'onza' },
  },
};

class MLAutoValidator {
  constructor() {
    this.dbPath = path.join(__dirname, '../../data/database.sqlite');
  }

  /**
   * Valide automatiquement les feedbacks en attente
   */
  async validatePendingFeedbacks() {
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }

        // Récupérer les feedbacks en attente
        db.all(
          `SELECT * FROM translation_feedbacks 
           WHERE approved = 0 
             AND suggested_translation IS NOT NULL 
             AND suggested_translation != ''`,
          [],
          (err, feedbacks) => {
            if (err) {
              db.close();
              return reject(err);
            }

            if (feedbacks.length === 0) {
              console.log('✅ Aucun feedback en attente');
              db.close();
              return resolve({ validated: 0, rejected: 0 });
            }

            console.log(`🔍 Validation de ${feedbacks.length} feedbacks...`);

            let validated = 0;
            let rejected = 0;

            const processFeedback = (index) => {
              if (index >= feedbacks.length) {
                db.close();
                console.log(`✅ Validation terminée: ${validated} approuvés, ${rejected} rejetés`);
                return resolve({ validated, rejected });
              }

              const feedback = feedbacks[index];
              const isValid = this.validateFeedback(feedback);

              if (isValid) {
                // Approuver automatiquement
                db.run(
                  `UPDATE translation_feedbacks 
                   SET approved = 1, 
                       approved_by = 'auto-validator',
                       approved_at = datetime('now')
                   WHERE id = ?`,
                  [feedback.id],
                  (err) => {
                    if (!err) {
                      validated++;
                      console.log(`✅ Auto-validé: ${feedback.type} "${feedback.original_text}" → "${feedback.suggested_translation}"`);
                    }
                    processFeedback(index + 1);
                  }
                );
              } else {
                // Laisser en attente pour validation manuelle
                rejected++;
                processFeedback(index + 1);
              }
            };

            processFeedback(0);
          }
        );
      });
    });
  }

  /**
   * Valide un feedback contre les traductions de référence
   */
  validateFeedback(feedback) {
    const { type, original_text, suggested_translation, target_language } = feedback;

    // Normaliser
    const original = original_text.toLowerCase().trim();
    const suggested = suggested_translation.toLowerCase().trim();

    // Vérifier selon le type
    if (type === 'ingredient') {
      const reference = REFERENCE_TRANSLATIONS.ingredients[original];
      if (reference && reference[target_language]) {
        return suggested === reference[target_language].toLowerCase();
      }
    } else if (type === 'unit') {
      const reference = REFERENCE_TRANSLATIONS.units[original];
      if (reference && reference[target_language]) {
        return suggested === reference[target_language].toLowerCase();
      }
    }

    // Pour les autres types (instructions, recipeName), on ne valide pas automatiquement
    // car ils sont plus complexes et nécessitent une validation manuelle
    return false;
  }
}

// Exécution si appelé directement
if (require.main === module) {
  const validator = new MLAutoValidator();
  
  validator.validatePendingFeedbacks()
    .then((result) => {
      console.log(`\n📊 Résultat: ${result.validated} validés, ${result.rejected} en attente`);
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Erreur:', error);
      process.exit(1);
    });
}

module.exports = MLAutoValidator;

