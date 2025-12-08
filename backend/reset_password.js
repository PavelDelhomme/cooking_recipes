const bcrypt = require('bcryptjs');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const { promisify } = require('util');

const dbPath = path.join(__dirname, 'data/database.sqlite');

// Récupérer les arguments
const email = process.argv[2];
const password = process.argv[3];

if (!email || !password) {
  console.error('❌ Usage: node reset_password.js <email> <password>');
  console.error('   Exemple: node reset_password.js dumb@delhomme.ovh "jaqHGcn7buxBAKQVJdx^"');
  process.exit(1);
}

// Vérifier que la base de données existe
if (!fs.existsSync(dbPath)) {
  console.error('❌ Base de données non trouvée:', dbPath);
  process.exit(1);
}

console.log('🔄 Réinitialisation du mot de passe...');
console.log('   Email:', email);
console.log('   Mot de passe:', '*'.repeat(password.length));

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Erreur connexion DB:', err.message);
    process.exit(1);
  }
  
  // Vérifier que l'utilisateur existe
  db.get('SELECT id, email FROM users WHERE email = ?', [email], async (err, user) => {
    if (err) {
      console.error('❌ Erreur recherche utilisateur:', err.message);
      db.close();
      process.exit(1);
    }
    
    if (!user) {
      console.error('❌ Utilisateur non trouvé:', email);
      db.close();
      process.exit(1);
    }
    
    console.log('✅ Utilisateur trouvé:', user.email);
    
    try {
      // Hasher le nouveau mot de passe
      console.log('   Hachage du mot de passe...');
      const hashedPassword = await bcrypt.hash(password, 12);
      
      // Mettre à jour le mot de passe
      db.run(
        'UPDATE users SET password = ? WHERE email = ?',
        [hashedPassword, email],
        function(err) {
          if (err) {
            console.error('❌ Erreur mise à jour:', err.message);
            db.close();
            process.exit(1);
          }
          
          if (this.changes === 0) {
            console.error('❌ Aucune ligne mise à jour');
            db.close();
            process.exit(1);
          }
          
          console.log('✅ Mot de passe mis à jour avec succès !');
          console.log('   Hash:', hashedPassword.substring(0, 30) + '...');
          console.log('');
          console.log('🔄 Vous pouvez maintenant vous connecter avec :');
          console.log('   Email:', email);
          console.log('   Mot de passe:', password);
          
          db.close((err) => {
            if (err) {
              console.error('⚠️ Erreur fermeture DB:', err.message);
            }
            process.exit(0);
          });
        }
      );
    } catch (error) {
      console.error('❌ Erreur hash:', error.message);
      db.close();
      process.exit(1);
    }
  });
});

// Gérer les erreurs non capturées
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Erreur non gérée:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Exception non capturée:', error.message);
  process.exit(1);
});
