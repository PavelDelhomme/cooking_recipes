/**
 * Script pour vérifier les feedbacks dans la base de données
 * Usage: node backend/scripts/check_feedbacks.js
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '../data/database.sqlite');

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Erreur ouverture base de données:', err);
    process.exit(1);
  }
});

console.log('📊 Vérification des feedbacks dans la base de données...\n');

// Compter tous les feedbacks
db.get('SELECT COUNT(*) as total FROM translation_feedbacks', [], (err, row) => {
  if (err) {
    console.error('❌ Erreur:', err);
    db.close();
    process.exit(1);
  }
  console.log(`📋 Total de feedbacks: ${row.total}`);
});

// Compter les feedbacks approuvés
db.get('SELECT COUNT(*) as approved FROM translation_feedbacks WHERE approved = 1', [], (err, row) => {
  if (err) {
    console.error('❌ Erreur:', err);
    db.close();
    process.exit(1);
  }
  console.log(`✅ Feedbacks approuvés: ${row.approved}`);
});

// Compter les feedbacks avec traduction
db.get(`SELECT COUNT(*) as with_translation 
        FROM translation_feedbacks 
        WHERE approved = 1 
          AND suggested_translation IS NOT NULL 
          AND suggested_translation != ''`, [], (err, row) => {
  if (err) {
    console.error('❌ Erreur:', err);
    db.close();
    process.exit(1);
  }
  console.log(`📝 Feedbacks avec traduction: ${row.with_translation}`);
  
  // Afficher quelques exemples
  db.all(`SELECT type, original_text, suggested_translation, target_language
          FROM translation_feedbacks 
          WHERE approved = 1 
            AND suggested_translation IS NOT NULL 
            AND suggested_translation != ''
          LIMIT 5`, [], (err, rows) => {
    if (err) {
      console.error('❌ Erreur:', err);
      db.close();
      process.exit(1);
    }
    
    if (rows && rows.length > 0) {
      console.log('\n📚 Exemples de feedbacks:');
      rows.forEach((row, index) => {
        console.log(`\n  ${index + 1}. Type: ${row.type}, Langue: ${row.target_language}`);
        console.log(`     Original: ${row.original_text}`);
        console.log(`     Traduction: ${row.suggested_translation}`);
      });
    } else {
      console.log('\n⚠️  Aucun feedback approuvé avec traduction trouvé.');
      console.log('   Vous devez d\'abord approuver des traductions dans l\'application !');
    }
    
    db.close();
    process.exit(0);
  });
});

