#!/usr/bin/env node

/**
 * Script pour entraîner le modèle de traduction avec les feedbacks utilisateur
 * 
 * Usage: node scripts/train_translation_model.js [options]
 * 
 * Options:
 *   --export-json    Exporte les données d'entraînement en JSON
 *   --update-dict    Met à jour les dictionnaires JSON avec les traductions approuvées
 *   --stats          Affiche les statistiques des feedbacks
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const dbPath = path.join(__dirname, '../data/database.sqlite');
const exportPath = path.join(__dirname, '../data/training_data.json');
const dictionariesPath = path.join(__dirname, '../data/dictionaries');

// Créer le dossier dictionaries s'il n'existe pas
if (!fs.existsSync(dictionariesPath)) {
  fs.mkdirSync(dictionariesPath, { recursive: true });
}

function getDatabase() {
  return new sqlite3.Database(dbPath);
}

/**
 * Récupère toutes les données d'entraînement depuis la base de données
 */
function getTrainingData() {
  return new Promise((resolve, reject) => {
    const db = getDatabase();
    
    db.all(
      `SELECT 
        type,
        original_text,
        current_translation,
        suggested_translation,
        target_language,
        COUNT(*) as usage_count,
        GROUP_CONCAT(DISTINCT recipe_title) as recipe_titles
       FROM translation_feedbacks 
       WHERE suggested_translation IS NOT NULL 
         AND suggested_translation != ''
         AND suggested_translation != current_translation
       GROUP BY type, original_text, suggested_translation, target_language
       ORDER BY usage_count DESC, type`,
      [],
      (err, rows) => {
        db.close();
        if (err) {
          return reject(err);
        }
        resolve(rows);
      }
    );
  });
}

/**
 * Exporte les données d'entraînement en JSON
 */
async function exportTrainingData() {
  try {
    console.log('📊 Récupération des données d\'entraînement...');
    const data = await getTrainingData();
    
    // Organiser les données par type et langue
    const organized = {
      metadata: {
        exportDate: new Date().toISOString(),
        totalEntries: data.length,
        version: '1.0.0',
      },
      instructions: {
        fr: [],
        es: [],
      },
      ingredients: {
        fr: [],
        es: [],
      },
      recipeNames: {
        fr: [],
        es: [],
      },
    };
    
    data.forEach(row => {
      const entry = {
        original: row.original_text,
        current: row.current_translation,
        suggested: row.suggested_translation,
        usageCount: row.usage_count,
        recipes: row.recipe_titles ? row.recipe_titles.split(',') : [],
      };
      
      const lang = row.target_language;
      if (lang === 'fr' || lang === 'es') {
        if (row.type === 'instruction') {
          organized.instructions[lang].push(entry);
        } else if (row.type === 'ingredient') {
          organized.ingredients[lang].push(entry);
        } else if (row.type === 'recipeName') {
          organized.recipeNames[lang].push(entry);
        }
      }
    });
    
    // Écrire le fichier JSON
    fs.writeFileSync(exportPath, JSON.stringify(organized, null, 2), 'utf8');
    
    console.log(`✅ Données exportées: ${data.length} entrées`);
    console.log(`   Instructions FR: ${organized.instructions.fr.length}`);
    console.log(`   Instructions ES: ${organized.instructions.es.length}`);
    console.log(`   Ingrédients FR: ${organized.ingredients.fr.length}`);
    console.log(`   Ingrédients ES: ${organized.ingredients.es.length}`);
    console.log(`   Noms FR: ${organized.recipeNames.fr.length}`);
    console.log(`   Noms ES: ${organized.recipeNames.es.length}`);
    console.log(`\n📁 Fichier: ${exportPath}`);
  } catch (error) {
    console.error('❌ Erreur lors de l\'export:', error);
    process.exit(1);
  }
}

/**
 * Met à jour les dictionnaires JSON avec les traductions approuvées
 */
async function updateDictionaries() {
  try {
    console.log('📚 Mise à jour des dictionnaires...');
    const data = await getTrainingData();
    
    // Filtrer les traductions avec un usage_count élevé (>= 2) pour plus de confiance
    const approved = data.filter(row => row.usage_count >= 2);
    
    const dictionaries = {
      instructions: { fr: {}, es: {} },
      ingredients: { fr: {}, es: {} },
      recipeNames: { fr: {}, es: {} },
    };
    
    approved.forEach(row => {
      const lang = row.target_language;
      if (lang === 'fr' || lang === 'es') {
        const key = row.original_text.toLowerCase().trim();
        
        if (row.type === 'instruction') {
          dictionaries.instructions[lang][key] = row.suggested_translation;
        } else if (row.type === 'ingredient') {
          dictionaries.ingredients[lang][key] = row.suggested_translation;
        } else if (row.type === 'recipeName') {
          dictionaries.recipeNames[lang][key] = row.suggested_translation;
        }
      }
    });
    
    // Écrire les dictionnaires
    Object.keys(dictionaries).forEach(type => {
      ['fr', 'es'].forEach(lang => {
        const dict = dictionaries[type][lang];
        if (Object.keys(dict).length > 0) {
          const filePath = path.join(dictionariesPath, `${type}_${lang}.json`);
          fs.writeFileSync(
            filePath,
            JSON.stringify(dict, null, 2),
            'utf8'
          );
          console.log(`   ✅ ${type}_${lang}.json: ${Object.keys(dict).length} entrées`);
        }
      });
    });
    
    console.log(`\n✅ Dictionnaires mis à jour avec ${approved.length} traductions approuvées`);
  } catch (error) {
    console.error('❌ Erreur lors de la mise à jour:', error);
    process.exit(1);
  }
}

/**
 * Affiche les statistiques des feedbacks
 */
async function showStats() {
  try {
    const db = getDatabase();
    
    db.get(
      `SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN type = 'instruction' THEN 1 END) as instructions,
        COUNT(CASE WHEN type = 'ingredient' THEN 1 END) as ingredients,
        COUNT(CASE WHEN type = 'recipeName' THEN 1 END) as recipeNames,
        COUNT(CASE WHEN suggested_translation IS NOT NULL AND suggested_translation != '' THEN 1 END) as withSuggestions,
        COUNT(DISTINCT user_id) as uniqueUsers,
        COUNT(DISTINCT recipe_id) as uniqueRecipes
       FROM translation_feedbacks`,
      [],
      (err, stats) => {
        db.close();
        if (err) {
          console.error('❌ Erreur:', err);
          process.exit(1);
        }
        
        console.log('📊 Statistiques des feedbacks de traduction:');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log(`   Total de feedbacks: ${stats.total}`);
        console.log(`   Instructions: ${stats.instructions}`);
        console.log(`   Ingrédients: ${stats.ingredients}`);
        console.log(`   Noms de recettes: ${stats.recipeNames}`);
        console.log(`   Avec suggestions: ${stats.withSuggestions}`);
        console.log(`   Utilisateurs uniques: ${stats.uniqueUsers}`);
        console.log(`   Recettes uniques: ${stats.uniqueRecipes}`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    );
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

// Main
const args = process.argv.slice(2);

if (args.includes('--export-json')) {
  exportTrainingData();
} else if (args.includes('--update-dict')) {
  updateDictionaries();
} else if (args.includes('--stats')) {
  showStats();
} else {
  console.log('Usage: node scripts/train_translation_model.js [option]');
  console.log('');
  console.log('Options:');
  console.log('  --export-json    Exporte les données d\'entraînement en JSON');
  console.log('  --update-dict    Met à jour les dictionnaires JSON');
  console.log('  --stats          Affiche les statistiques');
  console.log('');
  console.log('Exemples:');
  console.log('  node scripts/train_translation_model.js --stats');
  console.log('  node scripts/train_translation_model.js --export-json');
  console.log('  node scripts/train_translation_model.js --update-dict');
}

