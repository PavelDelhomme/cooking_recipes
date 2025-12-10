/**
 * Script pour entraîner le réseau de neurones avec tous les feedbacks
 * Usage: node backend/scripts/train_neural_network.js
 */

const neuralTranslationEngine = require('../src/services/neural_translation_engine');

async function main() {
  console.log('🧠 ========================================');
  console.log('🧠 ENTRAÎNEMENT DU RÉSEAU DE NEURONES');
  console.log('🧠 ========================================');
  console.log('');

  try {
    // Réentraîner le réseau de neurones
    await neuralTranslationEngine.retrain();
    
    // Afficher les statistiques
    const stats = neuralTranslationEngine.getStats();
    console.log('\n📊 Statistiques du réseau de neurones:');
    console.log('─────────────────────────────────────────');
    for (const [type, langs] of Object.entries(stats)) {
      console.log(`\n${type.toUpperCase()}:`);
      console.log(`  Source (anglais): ${langs.source} mots`);
      console.log(`  Français: ${langs.fr} mots`);
      console.log(`  Espagnol: ${langs.es} mots`);
    }
    
    console.log('\n✅ Entraînement terminé avec succès !');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de l\'entraînement:', error);
    process.exit(1);
  }
}

// Vérifier que TensorFlow.js est installé
try {
  require('@tensorflow/tfjs-node');
} catch (e) {
  console.error('❌ TensorFlow.js n\'est pas installé !');
  console.error('   Installez-le avec: make install-neural');
  process.exit(1);
}

main();

