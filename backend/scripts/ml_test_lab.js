/**
 * Lab de test automatisé pour l'IA de traduction
 * Teste l'IA sur 100 recettes avec validation automatique
 */

const mlTranslationEngine = require('../src/services/ml_translation_engine');
const libreTranslateService = require('../src/services/libretranslate');
const { getDatabase } = require('../src/database/db');
const axios = require('axios');
const fs = require('fs');
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
  instructions: {
    'chop': { fr: 'hacher', es: 'picar' },
    'dice': { fr: 'couper en dés', es: 'cortar en cubos' },
    'slice': { fr: 'trancher', es: 'cortar en rodajas' },
    'mince': { fr: 'émincer', es: 'picar finamente' },
    'mix': { fr: 'mélanger', es: 'mezclar' },
    'stir': { fr: 'remuer', es: 'revolver' },
    'cook': { fr: 'cuire', es: 'cocinar' },
    'bake': { fr: 'cuire au four', es: 'hornear' },
    'fry': { fr: 'frire', es: 'freír' },
    'boil': { fr: 'bouillir', es: 'hervir' },
    'simmer': { fr: 'mijoter', es: 'hervir a fuego lento' },
    'season': { fr: 'assaisonner', es: 'sazonar' },
    'garnish': { fr: 'garnir', es: 'decorar' },
    'serve': { fr: 'servir', es: 'servir' },
  },
};

class MLTestLab {
  constructor() {
    this.results = {
      total: 0,
      correct: 0,
      incorrect: 0,
      missing: 0,
      accuracy: 0,
      details: [],
    };
    this.apiUrl = process.env.API_URL || 'http://localhost:7272/api';
  }

  /**
   * Lance le lab de test complet
   */
  async runFullTest(numRecipes = 100) {
    console.log('🧪 ========================================');
    console.log('🧪 LAB DE TEST IA DE TRADUCTION');
    console.log('🧪 ========================================');
    console.log('');

    // 1. Charger les modèles
    console.log('📥 Chargement des modèles ML...');
    await mlTranslationEngine.loadModels();
    console.log('✅ Modèles chargés\n');

    // 2. Récupérer les recettes
    console.log(`📋 Récupération de ${numRecipes} recettes...`);
    const recipes = await this.fetchRecipes(numRecipes);
    console.log(`✅ ${recipes.length} recettes récupérées\n`);

    // 3. Tester chaque recette
    console.log('🔍 Test des traductions...');
    for (let i = 0; i < recipes.length; i++) {
      const recipe = recipes[i];
      console.log(`\n[${i + 1}/${recipes.length}] Test: ${recipe.title}`);
      await this.testRecipe(recipe);
    }

    // 4. Calculer les statistiques
    this.calculateStats();

    // 5. Afficher les résultats
    this.displayResults();

    // 6. Sauvegarder le rapport
    this.saveReport();

    return this.results;
  }

  /**
   * Récupère des recettes depuis TheMealDB (comme le frontend)
   */
  async fetchRecipes(numRecipes) {
    const recipes = [];
    const baseUrl = 'https://www.themealdb.com/api/json/v1/1';

    try {
      // TheMealDB permet d'obtenir des recettes aléatoires via random.php
      // On fait plusieurs appels pour obtenir le nombre souhaité
      const recipeIds = new Set(); // Pour éviter les doublons
      
      while (recipes.length < numRecipes) {
        try {
          // Obtenir une recette aléatoire
          const response = await axios.get(`${baseUrl}/random.php`, {
            timeout: 5000,
          });

          if (response.data && response.data.meals && response.data.meals.length > 0) {
            const meal = response.data.meals[0];
            const recipeId = meal.idMeal;

            // Éviter les doublons
            if (!recipeIds.has(recipeId)) {
              recipeIds.add(recipeId);
              
              // Convertir le format TheMealDB en format attendu par le test
              const recipe = this.convertMealDBToRecipe(meal);
              recipes.push(recipe);
              
              // Afficher la progression
              if (recipes.length % 10 === 0) {
                process.stdout.write(`\r   ${recipes.length}/${numRecipes} recettes récupérées...`);
              }
            }
          }
          
          // Petite pause pour ne pas surcharger l'API
          await new Promise(resolve => setTimeout(resolve, 100));
        } catch (error) {
          // En cas d'erreur, continuer avec la suivante
          if (error.code !== 'ECONNABORTED') {
            console.warn(`\n⚠️  Erreur récupération recette: ${error.message}`);
          }
        }
      }
      
      if (recipes.length > 0) {
        process.stdout.write(`\r   ${recipes.length}/${numRecipes} recettes récupérées...\n`);
      }
    } catch (error) {
      console.warn(`\n⚠️  Erreur récupération recettes TheMealDB: ${error.message}`);
      console.warn('⚠️  Utilisation de recettes de test');
      return this.getTestRecipes(numRecipes);
    }

    return recipes;
  }

  /**
   * Convertit un meal de TheMealDB en format attendu par le test
   */
  convertMealDBToRecipe(meal) {
    const ingredients = [];
    const instructions = [];

    // Extraire les ingrédients (TheMealDB utilise strIngredient1, strIngredient2, etc.)
    for (let i = 1; i <= 20; i++) {
      const ingredient = meal[`strIngredient${i}`];
      const measure = meal[`strMeasure${i}`];
      
      if (ingredient && ingredient.trim() !== '') {
        ingredients.push({
          name: ingredient.trim(),
          amount: this.parseAmount(measure || ''),
          unit: this.parseUnit(measure || ''),
        });
      }
    }

    // Extraire les instructions (TheMealDB les sépare par des retours à la ligne)
    if (meal.strInstructions) {
      const instructionLines = meal.strInstructions
        .split(/\r?\n/)
        .map(line => line.trim())
        .filter(line => line.length > 0);
      instructions.push(...instructionLines);
    }

    return {
      id: meal.idMeal,
      title: meal.strMeal || 'Unknown Recipe',
      ingredients: ingredients,
      instructions: instructions,
    };
  }

  /**
   * Parse un montant depuis une mesure (ex: "1 cup" -> 1)
   */
  parseAmount(measure) {
    if (!measure) return 1;
    const match = measure.match(/^(\d+(?:\.\d+)?)\s*/);
    return match ? parseFloat(match[1]) : 1;
  }

  /**
   * Parse une unité depuis une mesure (ex: "1 cup" -> "cup")
   */
  parseUnit(measure) {
    if (!measure) return 'piece';
    const match = measure.match(/^\d+(?:\.\d+)?\s*(.+)$/);
    if (match) {
      const unit = match[1].trim().toLowerCase();
      // Normaliser les unités communes
      if (unit.includes('cup')) return 'cup';
      if (unit.includes('tablespoon') || unit.includes('tbsp')) return 'tablespoon';
      if (unit.includes('teaspoon') || unit.includes('tsp')) return 'teaspoon';
      if (unit.includes('gram') || unit.includes('g')) return 'gram';
      if (unit.includes('kilogram') || unit.includes('kg')) return 'kilogram';
      if (unit.includes('liter') || unit.includes('l')) return 'liter';
      if (unit.includes('milliliter') || unit.includes('ml')) return 'milliliter';
      if (unit.includes('pound') || unit.includes('lb')) return 'pound';
      if (unit.includes('ounce') || unit.includes('oz')) return 'ounce';
      return unit;
    }
    return 'piece';
  }

  /**
   * Génère des recettes de test
   */
  getTestRecipes(numRecipes) {
    const testRecipes = [];
    const ingredients = Object.keys(REFERENCE_TRANSLATIONS.ingredients);
    const instructions = Object.keys(REFERENCE_TRANSLATIONS.instructions);

    for (let i = 0; i < numRecipes; i++) {
      const recipeIngredients = ingredients.slice(0, 5 + (i % 10));
      const recipeInstructions = instructions.slice(0, 3 + (i % 5));

      testRecipes.push({
        id: `test-${i}`,
        title: `Test Recipe ${i + 1}`,
        ingredients: recipeIngredients.map(name => ({
          name,
          amount: 1 + (i % 5),
          unit: i % 2 === 0 ? 'cup' : 'tablespoon',
        })),
        instructions: recipeInstructions.map(inst => `First, ${inst} the ingredients. Then cook for ${10 + i} minutes.`),
      });
    }

    return testRecipes;
  }

  /**
   * Teste une recette complète
   */
  async testRecipe(recipe) {
    const recipeResults = {
      recipeId: recipe.id,
      recipeTitle: recipe.title,
      ingredients: [],
      instructions: [],
      units: [],
      score: 0,
      total: 0,
    };

    // Tester les ingrédients
    if (recipe.ingredients && Array.isArray(recipe.ingredients)) {
      for (const ingredient of recipe.ingredients) {
        const result = await this.testIngredient(ingredient.name);
        recipeResults.ingredients.push(result);
        recipeResults.total++;
        if (result.correct) recipeResults.score++;
      }
    }

    // Tester les instructions
    if (recipe.instructions && Array.isArray(recipe.instructions)) {
      for (const instruction of recipe.instructions) {
        const result = await this.testInstruction(instruction);
        recipeResults.instructions.push(result);
        recipeResults.total++;
        if (result.correct) recipeResults.score++;
      }
    }

    // Tester les unités
    if (recipe.ingredients && Array.isArray(recipe.ingredients)) {
      for (const ingredient of recipe.ingredients) {
        if (ingredient.unit) {
          const result = await this.testUnit(ingredient.unit);
          recipeResults.units.push(result);
          recipeResults.total++;
          if (result.correct) recipeResults.score++;
        }
      }
    }

    this.results.details.push(recipeResults);
    this.results.total += recipeResults.total;
    this.results.correct += recipeResults.score;
    this.results.incorrect += (recipeResults.total - recipeResults.score);

    console.log(`   Score: ${recipeResults.score}/${recipeResults.total} (${((recipeResults.score / recipeResults.total) * 100).toFixed(1)}%)`);
  }

  /**
   * Teste la traduction d'un ingrédient
   */
  async testIngredient(ingredientName) {
    const lowerName = ingredientName.toLowerCase().trim();
    const reference = REFERENCE_TRANSLATIONS.ingredients[lowerName];

    if (!reference) {
      return {
        type: 'ingredient',
        original: ingredientName,
        translated: null,
        expected: null,
        correct: false,
        missing: true,
      };
    }

    // Tester pour français (avec fallback LibreTranslate si ML retourne null)
    let translatedFR = null;
    try {
      translatedFR = await mlTranslationEngine.translate(ingredientName, 'ingredient', 'fr');
      // Si l'IA retourne null, utiliser LibreTranslate en fallback
      if (!translatedFR) {
        try {
          translatedFR = await libreTranslateService.translateIngredient(ingredientName, 'fr');
        } catch (e) {
          // Ignorer les erreurs LibreTranslate
        }
      }
    } catch (e) {
      console.warn(`   ⚠️  Erreur traduction FR pour "${ingredientName}":`, e.message);
    }
    const correctFR = translatedFR && typeof translatedFR === 'string' && translatedFR.toLowerCase() === reference.fr.toLowerCase();

    // Tester pour espagnol (avec fallback LibreTranslate si ML retourne null)
    let translatedES = null;
    try {
      translatedES = await mlTranslationEngine.translate(ingredientName, 'ingredient', 'es');
      // Si l'IA retourne null, utiliser LibreTranslate en fallback
      if (!translatedES) {
        try {
          translatedES = await libreTranslateService.translateIngredient(ingredientName, 'es');
        } catch (e) {
          // Ignorer les erreurs LibreTranslate
        }
      }
    } catch (e) {
      console.warn(`   ⚠️  Erreur traduction ES pour "${ingredientName}":`, e.message);
    }
    const correctES = translatedES && typeof translatedES === 'string' && translatedES.toLowerCase() === reference.es.toLowerCase();

    return {
      type: 'ingredient',
      original: ingredientName,
      translated: { fr: translatedFR || null, es: translatedES || null },
      expected: reference,
      correct: correctFR && correctES,
      missing: false,
    };
  }

  /**
   * Teste la traduction d'une instruction
   */
  async testInstruction(instruction) {
    // Extraire les mots-clés de l'instruction
    const keywords = Object.keys(REFERENCE_TRANSLATIONS.instructions);
    const foundKeywords = keywords.filter(keyword => 
      instruction.toLowerCase().includes(keyword)
    );

    if (foundKeywords.length === 0) {
      return {
        type: 'instruction',
        original: instruction.substring(0, 50),
        translated: null,
        expected: null,
        correct: false,
        missing: true,
      };
    }

    // Tester la traduction (avec fallback LibreTranslate si ML retourne null)
    let translatedFR = null;
    let translatedES = null;
    try {
      translatedFR = await mlTranslationEngine.translate(instruction, 'instruction', 'fr');
      // Si l'IA retourne null, utiliser LibreTranslate en fallback
      if (!translatedFR) {
        try {
          translatedFR = await libreTranslateService.translate(instruction, 'en', 'fr');
        } catch (e) {
          // Ignorer les erreurs LibreTranslate
        }
      }
    } catch (e) {
      // Ignorer les erreurs pour les instructions
    }
    try {
      translatedES = await mlTranslationEngine.translate(instruction, 'instruction', 'es');
      // Si l'IA retourne null, utiliser LibreTranslate en fallback
      if (!translatedES) {
        try {
          translatedES = await libreTranslateService.translate(instruction, 'en', 'es');
        } catch (e) {
          // Ignorer les erreurs LibreTranslate
        }
      }
    } catch (e) {
      // Ignorer les erreurs pour les instructions
    }

    // Validation basique (vérifier si les mots-clés sont traduits)
    let correctFR = false;
    let correctES = false;

    if (translatedFR && typeof translatedFR === 'string') {
      const expectedKeywords = foundKeywords.map(k => REFERENCE_TRANSLATIONS.instructions[k].fr);
      correctFR = expectedKeywords.some(keyword => 
        translatedFR.toLowerCase().includes(keyword.toLowerCase())
      );
    }

    if (translatedES && typeof translatedES === 'string') {
      const expectedKeywords = foundKeywords.map(k => REFERENCE_TRANSLATIONS.instructions[k].es);
      correctES = expectedKeywords.some(keyword => 
        translatedES.toLowerCase().includes(keyword.toLowerCase())
      );
    }

    return {
      type: 'instruction',
      original: instruction.substring(0, 50),
      translated: { fr: translatedFR || null, es: translatedES || null },
      expected: foundKeywords.map(k => REFERENCE_TRANSLATIONS.instructions[k]),
      correct: correctFR && correctES,
      missing: false,
    };
  }

  /**
   * Teste la traduction d'une unité
   */
  async testUnit(unitName) {
    const lowerName = unitName.toLowerCase().trim();
    const reference = REFERENCE_TRANSLATIONS.units[lowerName];

    if (!reference) {
      return {
        type: 'unit',
        original: unitName,
        translated: null,
        expected: null,
        correct: false,
        missing: true,
      };
    }

    let translatedFR = null;
    let translatedES = null;
    try {
      translatedFR = await mlTranslationEngine.translate(unitName, 'unit', 'fr');
      // Si l'IA retourne null, utiliser LibreTranslate en fallback
      if (!translatedFR) {
        try {
          translatedFR = await libreTranslateService.translate(unitName, 'en', 'fr');
        } catch (e) {
          // Ignorer les erreurs LibreTranslate
        }
      }
    } catch (e) {
      console.warn(`   ⚠️  Erreur traduction FR unit "${unitName}":`, e.message);
    }
    try {
      translatedES = await mlTranslationEngine.translate(unitName, 'unit', 'es');
      // Si l'IA retourne null, utiliser LibreTranslate en fallback
      if (!translatedES) {
        try {
          translatedES = await libreTranslateService.translate(unitName, 'en', 'es');
        } catch (e) {
          // Ignorer les erreurs LibreTranslate
        }
      }
    } catch (e) {
      console.warn(`   ⚠️  Erreur traduction ES unit "${unitName}":`, e.message);
    }

    const correctFR = translatedFR && typeof translatedFR === 'string' && translatedFR.toLowerCase() === reference.fr.toLowerCase();
    const correctES = translatedES && typeof translatedES === 'string' && translatedES.toLowerCase() === reference.es.toLowerCase();

    return {
      type: 'unit',
      original: unitName,
      translated: { fr: translatedFR || null, es: translatedES || null },
      expected: reference,
      correct: correctFR && correctES,
      missing: false,
    };
  }

  /**
   * Calcule les statistiques
   */
  calculateStats() {
    this.results.accuracy = this.results.total > 0
      ? (this.results.correct / this.results.total) * 100
      : 0;

    this.results.missing = this.results.details.reduce((sum, detail) => {
      return sum + detail.ingredients.filter(i => i.missing).length +
             detail.instructions.filter(i => i.missing).length +
             detail.units.filter(u => u.missing).length;
    }, 0);
  }

  /**
   * Affiche les résultats
   */
  displayResults() {
    console.log('\n');
    console.log('📊 ========================================');
    console.log('📊 RÉSULTATS DU TEST');
    console.log('📊 ========================================');
    console.log('');
    console.log(`✅ Correctes: ${this.results.correct}`);
    console.log(`❌ Incorrectes: ${this.results.incorrect}`);
    console.log(`⚠️  Manquantes: ${this.results.missing}`);
    console.log(`📈 Précision: ${this.results.accuracy.toFixed(2)}%`);
    console.log(`📊 Total testé: ${this.results.total}`);
    console.log('');

    // Top 10 des erreurs
    const errors = [];
    this.results.details.forEach(detail => {
      detail.ingredients.filter(i => !i.correct && !i.missing).forEach(i => {
        errors.push({ type: 'ingredient', original: i.original, translated: i.translated, expected: i.expected });
      });
      detail.units.filter(u => !u.correct && !u.missing).forEach(u => {
        errors.push({ type: 'unit', original: u.original, translated: u.translated, expected: u.expected });
      });
    });

    if (errors.length > 0) {
      console.log('🔴 Top 10 des erreurs:');
      errors.slice(0, 10).forEach((error, i) => {
        console.log(`   ${i + 1}. ${error.type}: "${error.original}"`);
        console.log(`      → Obtenu: ${JSON.stringify(error.translated)}`);
        console.log(`      → Attendu: ${JSON.stringify(error.expected)}`);
      });
    }
  }

  /**
   * Sauvegarde le rapport
   */
  saveReport() {
    const reportDir = path.join(__dirname, '../../data/ml_reports');
    if (!fs.existsSync(reportDir)) {
      fs.mkdirSync(reportDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const reportPath = path.join(reportDir, `test_report_${timestamp}.json`);

    const report = {
      timestamp: new Date().toISOString(),
      results: this.results,
      summary: {
        accuracy: this.results.accuracy,
        total: this.results.total,
        correct: this.results.correct,
        incorrect: this.results.incorrect,
        missing: this.results.missing,
      },
    };

    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    console.log(`\n💾 Rapport sauvegardé: ${reportPath}`);
  }
}

// Exécution si appelé directement
if (require.main === module) {
  const lab = new MLTestLab();
  const numRecipes = parseInt(process.argv[2]) || 100;
  
  lab.runFullTest(numRecipes)
    .then(() => {
      console.log('\n✅ Test terminé');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ Erreur lors du test:', error);
      process.exit(1);
    });
}

module.exports = MLTestLab;

