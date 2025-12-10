/**
 * Script pour visualiser les données d'entraînement de l'IA
 * Affiche ce que l'IA a appris et d'où viennent les données
 */

const { getDatabase } = require('../src/database/db');
const mlTranslationEngine = require('../src/services/ml_translation_engine');
const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

class MLTrainingDataViewer {
  constructor() {
    this.dbPath = path.join(__dirname, '../../data/database.sqlite');
    this.modelsPath = path.join(__dirname, '../../data/ml_models');
  }

  /**
   * Affiche toutes les sources de données d'entraînement
   */
  async showAllTrainingData() {
    console.log('📊 ========================================');
    console.log('📊 DONNÉES D\'ENTRAÎNEMENT DE L\'IA');
    console.log('📊 ========================================');
    console.log('');

    // 1. Base de données (feedbacks approuvés)
    await this.showDatabaseFeedbacks();

    // 2. Fichiers JSON (modèles sauvegardés)
    await this.showModelFiles();

    // 3. Modèles en mémoire (chargés)
    await this.showLoadedModels();

    // 4. Statistiques globales
    await this.showStatistics();
  }

  /**
   * Affiche les feedbacks de la base de données
   */
  async showDatabaseFeedbacks() {
    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }
      });

      console.log('🗄️  BASE DE DONNÉES (SQLite)');
      console.log('─────────────────────────────────────────');
      console.log('Fichier: backend/data/database.sqlite');
      console.log('Table: translation_feedbacks');
      console.log('');

      // Vérifier si la table existe
      db.get(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='translation_feedbacks'`,
        [],
        (err, table) => {
          if (err || !table) {
            db.close();
            console.log('⚠️  La table translation_feedbacks n\'existe pas encore');
            console.log('   Elle sera créée lors du premier feedback utilisateur');
            console.log('');
            return resolve();
          }

          // Total des feedbacks
          db.get(
            `SELECT 
              COUNT(*) as total,
              COUNT(CASE WHEN approved = 1 THEN 1 END) as approved,
              COUNT(CASE WHEN approved = 0 THEN 1 END) as pending,
              COUNT(CASE WHEN approved = -1 THEN 1 END) as rejected
             FROM translation_feedbacks`,
            [],
            (err, stats) => {
              if (err) {
                db.close();
                return reject(err);
              }

              console.log(`📈 Statistiques:`);
              console.log(`   Total: ${stats.total || 0}`);
              console.log(`   ✅ Approuvés: ${stats.approved || 0}`);
              console.log(`   ⏳ En attente: ${stats.pending || 0}`);
              console.log(`   ❌ Rejetés: ${stats.rejected || 0}`);
              console.log('');

              // Feedbacks approuvés par type
              db.all(
            `SELECT 
              type,
              COUNT(*) as count
             FROM translation_feedbacks 
             WHERE approved = 1
             GROUP BY type
             ORDER BY count DESC`,
            [],
            (err, rows) => {
              if (err) {
                db.close();
                return reject(err);
              }

              if (rows.length > 0) {
                console.log('📚 Feedbacks approuvés par type:');
                rows.forEach(row => {
                  const typeLabel = {
                    'ingredient': 'Ingrédients',
                    'instruction': 'Instructions',
                    'recipeName': 'Noms de recettes',
                    'unit': 'Unités',
                  }[row.type] || row.type;
                  console.log(`   ${typeLabel}: ${row.count}`);
                });
                console.log('');
              }

              // Exemples de feedbacks approuvés
              db.all(
                `SELECT 
                  type,
                  original_text,
                  suggested_translation,
                  target_language,
                  COUNT(*) as usage_count
                 FROM translation_feedbacks 
                 WHERE approved = 1
                   AND suggested_translation IS NOT NULL
                 GROUP BY type, original_text, suggested_translation, target_language
                 ORDER BY usage_count DESC
                 LIMIT 10`,
                [],
                (err, examples) => {
                  db.close();
                  if (err) {
                    return reject(err);
                  }

                  if (examples.length > 0) {
                    console.log('💡 Exemples de traductions apprises (top 10):');
                    examples.forEach((ex, i) => {
                      console.log(`   ${i + 1}. [${ex.type}] "${ex.original_text}" → "${ex.suggested_translation}" (${ex.target_language}, utilisé ${ex.usage_count}x)`);
                    });
                    console.log('');
                  }

                  resolve();
                }
              );
            }
          );
            }
          );
        }
      );
    });
  }

  /**
   * Affiche les fichiers de modèles JSON
   */
  async showModelFiles() {
    console.log('📁 FICHIERS JSON (Modèles sauvegardés)');
    console.log('─────────────────────────────────────────');
    console.log('Dossier: backend/data/ml_models/');
    console.log('');

    if (!fs.existsSync(this.modelsPath)) {
      console.log('⚠️  Le dossier n\'existe pas encore');
      console.log('');
      return;
    }

    const files = fs.readdirSync(this.modelsPath).filter(f => f.endsWith('.json'));
    
    if (files.length === 0) {
      console.log('⚠️  Aucun fichier de modèle trouvé');
      console.log('   (Les modèles seront créés lors du premier entraînement)');
      console.log('');
      return;
    }

    console.log(`📄 Fichiers trouvés: ${files.length}`);
    files.forEach(file => {
      const filePath = path.join(this.modelsPath, file);
      const stats = fs.statSync(filePath);
      const sizeKB = (stats.size / 1024).toFixed(2);
      console.log(`   - ${file} (${sizeKB} KB)`);
    });
    console.log('');

    // Afficher le contenu d'un fichier exemple
    if (files.length > 0) {
      const exampleFile = files[0];
      const filePath = path.join(this.modelsPath, exampleFile);
      try {
        const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        const entries = Object.keys(data).length;
        console.log(`📖 Exemple: ${exampleFile}`);
        console.log(`   Entrées: ${entries}`);
        if (entries > 0) {
          const firstKey = Object.keys(data)[0];
          const firstValue = data[firstKey];
          console.log(`   Exemple: "${firstKey}" → ${JSON.stringify(firstValue).substring(0, 100)}...`);
        }
        console.log('');
      } catch (e) {
        console.log(`   ⚠️  Erreur lecture: ${e.message}`);
        console.log('');
      }
    }
  }

  /**
   * Affiche les modèles chargés en mémoire
   */
  async showLoadedModels() {
    console.log('🧠 MODÈLES EN MÉMOIRE (Chargés)');
    console.log('─────────────────────────────────────────');
    console.log('');

    await mlTranslationEngine.loadModels();
    const stats = mlTranslationEngine.getStats();

    console.log('📊 Statistiques des modèles chargés:');
    console.log('');
    
    const types = {
      'ingredients': 'Ingrédients',
      'instructions': 'Instructions',
      'recipeNames': 'Noms de recettes',
      'units': 'Unités',
    };

    for (const [type, label] of Object.entries(types)) {
      console.log(`   ${label}:`);
      console.log(`      Français: ${stats[type].fr} traductions`);
      console.log(`      Espagnol: ${stats[type].es} traductions`);
      console.log('');
    }
  }

  /**
   * Affiche les statistiques globales
   */
  async showStatistics() {
    console.log('📈 STATISTIQUES GLOBALES');
    console.log('─────────────────────────────────────────');
    console.log('');

    return new Promise((resolve, reject) => {
      const db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          return reject(err);
        }
      });

      // Vérifier si la table existe
      db.get(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='translation_feedbacks'`,
        [],
        (err, table) => {
          if (err || !table) {
            db.close();
            // Afficher quand même les sources
            this.showDataSources();
            return resolve();
          }

          // Statistiques détaillées
          db.all(
        `SELECT 
          type,
          target_language,
          COUNT(DISTINCT original_text) as unique_originals,
          COUNT(*) as total_feedbacks,
          COUNT(DISTINCT suggested_translation) as unique_translations
         FROM translation_feedbacks 
         WHERE approved = 1
           AND suggested_translation IS NOT NULL
         GROUP BY type, target_language
         ORDER BY type, target_language`,
        [],
        (err, rows) => {
          db.close();
          if (err) {
            return reject(err);
          }

          if (rows.length > 0) {
            console.log('📊 Détails par type et langue:');
            let currentType = '';
            rows.forEach(row => {
              if (row.type !== currentType) {
                currentType = row.type;
                const typeLabel = {
                  'ingredient': 'Ingrédients',
                  'instruction': 'Instructions',
                  'recipeName': 'Noms de recettes',
                  'unit': 'Unités',
                }[row.type] || row.type;
                console.log(`\n   ${typeLabel}:`);
              }
              console.log(`      ${row.target_language.toUpperCase()}: ${row.unique_originals} originaux → ${row.unique_translations} traductions (${row.total_feedbacks} feedbacks)`);
            });
            console.log('');
          }

          // Source des données
          this.showDataSources();

          resolve();
            }
          );
        }
      );
    });
  }

  /**
   * Affiche les sources de données
   */
  showDataSources() {
    console.log('🔍 SOURCES DES DONNÉES:');
    console.log('');
    console.log('1. Base de données SQLite (backend/data/database.sqlite)');
    console.log('   → Table: translation_feedbacks');
    console.log('   → Contient: Tous les feedbacks utilisateur (approuvés et en attente)');
    console.log('   → Utilisé pour: Charger les traductions apprises');
    console.log('   → Structure:');
    console.log('      - id: Identifiant unique');
    console.log('      - user_id: Utilisateur qui a créé le feedback');
    console.log('      - type: ingredient, instruction, recipeName, unit');
    console.log('      - original_text: Texte original (anglais)');
    console.log('      - suggested_translation: Traduction suggérée par l\'utilisateur');
    console.log('      - target_language: Langue cible (fr, es)');
    console.log('      - approved: 0=en attente, 1=approuvé, -1=rejeté');
    console.log('');
    console.log('2. Fichiers JSON (backend/data/ml_models/)');
    console.log('   → Format: {type}_{lang}.json (ex: ingredients_fr.json)');
    console.log('   → Contient: Modèles ML sauvegardés');
    console.log('   → Structure: { "original": { "translation": count, ... }, ... }');
    console.log('   → Utilisé pour: Chargement rapide au démarrage');
    console.log('   → Créé lors de: Sauvegarde après entraînement');
    console.log('');
    console.log('3. Modèles en mémoire');
    console.log('   → Format: Objets JavaScript avec probabilités');
    console.log('   → Contient: Modèles chargés depuis DB + fichiers');
    console.log('   → Utilisé pour: Traduction en temps réel');
    console.log('   → Mis à jour: En continu lors de l\'apprentissage');
    console.log('');
  }

  /**
   * Affiche le flux d'apprentissage
   */
  showLearningFlow() {
    console.log('🔄 FLUX D\'APPRENTISSAGE');
    console.log('─────────────────────────────────────────');
    console.log('');
    console.log('1. Utilisateur corrige une traduction');
    console.log('   → Feedback créé dans translation_feedbacks (approved = 0)');
    console.log('');
    console.log('2. Validation automatique (toutes les heures)');
    console.log('   → Compare avec traductions de référence');
    console.log('   → Approuve automatiquement si correct (approved = 1)');
    console.log('   → Sinon, reste en attente pour validation manuelle');
    console.log('');
    console.log('3. Apprentissage continu (toutes les 30 min)');
    console.log('   → Traite les nouveaux feedbacks approuvés');
    console.log('   → Entraîne le modèle ML immédiatement');
    console.log('   → Met à jour les probabilités');
    console.log('');
    console.log('4. Réentraînement complet (toutes les 6 heures)');
    console.log('   → Recharge tous les feedbacks approuvés');
    console.log('   → Recalcule toutes les probabilités');
    console.log('   → Sauvegarde dans les fichiers JSON');
    console.log('');
    console.log('5. Utilisation pour traduire');
    console.log('   → L\'IA cherche dans les modèles en mémoire');
    console.log('   → Utilise les probabilités pour choisir la meilleure traduction');
    console.log('   → Retourne la traduction apprise ou null (fallback)');
    console.log('');
  }
}

// Exécution si appelé directement
if (require.main === module) {
  const viewer = new MLTrainingDataViewer();
  
  viewer.showAllTrainingData()
    .then(() => {
      viewer.showLearningFlow();
      console.log('✅ Affichage terminé');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Erreur:', error);
      process.exit(1);
    });
}

module.exports = MLTrainingDataViewer;

