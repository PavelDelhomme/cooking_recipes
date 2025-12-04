const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const DB_PATH = path.join(__dirname, '../../data/database.sqlite');
const DB_DIR = path.dirname(DB_PATH);

// Créer le dossier data s'il n'existe pas
if (!fs.existsSync(DB_DIR)) {
  fs.mkdirSync(DB_DIR, { recursive: true });
}

let db = null;

function getDatabase() {
  if (!db) {
    db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        console.error('Erreur de connexion à la base de données:', err);
      } else {
        console.log('✅ Connexion à la base de données SQLite établie');
      }
    });
  }
  return db;
}

function initDatabase() {
  return new Promise((resolve, reject) => {
    const database = getDatabase();

    // Table Users
    database.run(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT,
        avatarUrl TEXT,
        isPremium INTEGER DEFAULT 0,
        premiumExpiresAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table users:', err);
        return reject(err);
      }
    });

    // Table Pantry
    database.run(`
      CREATE TABLE IF NOT EXISTS pantry (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        expiryDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table pantry:', err);
        return reject(err);
      }
    });

    // Table Meal Plans
    database.run(`
      CREATE TABLE IF NOT EXISTS meal_plans (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        date TEXT NOT NULL,
        mealType TEXT NOT NULL,
        recipeId TEXT NOT NULL,
        recipeTitle TEXT NOT NULL,
        recipeImage TEXT,
        recipeData TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table meal_plans:', err);
        return reject(err);
      }
    });

    // Table Shopping List
    database.run(`
      CREATE TABLE IF NOT EXISTS shopping_list (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL,
        unit TEXT,
        isChecked INTEGER DEFAULT 0,
        isRegular INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table shopping_list:', err);
        return reject(err);
      }
    });

    // Table IP Blacklist
    database.run(`
      CREATE TABLE IF NOT EXISTS ip_blacklist (
        ip TEXT PRIMARY KEY,
        reason TEXT,
        created_at TEXT NOT NULL,
        expires_at TEXT,
        attempts INTEGER DEFAULT 1
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table ip_blacklist:', err);
        return reject(err);
      }
    });

    // Table Favorites
    database.run(`
      CREATE TABLE IF NOT EXISTS favorites (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        recipeId TEXT NOT NULL,
        recipeTitle TEXT NOT NULL,
        recipeImage TEXT,
        recipeData TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id),
        UNIQUE(userId, recipeId)
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table favorites:', err);
        return reject(err);
      }
    });

    // Table Security Logs
    database.run(`
      CREATE TABLE IF NOT EXISTS security_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        event_type TEXT NOT NULL,
        ip_address TEXT,
        user_id TEXT,
        details TEXT,
        severity TEXT DEFAULT 'INFO',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table security_logs:', err);
        return reject(err);
      }
    });

    // Table Revoked Tokens (pour session security)
    database.run(`
      CREATE TABLE IF NOT EXISTS revoked_tokens (
        token_id TEXT PRIMARY KEY,
        user_id TEXT,
        revoked_at TEXT NOT NULL,
        expires_at TEXT,
        reason TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `, (err) => {
      if (err) {
        console.error('Erreur création table revoked_tokens:', err);
        // Ne pas rejeter, ce n'est pas critique
      }
    });

    // Index pour recherche rapide
    database.run(`
      CREATE INDEX IF NOT EXISTS idx_security_logs_timestamp ON security_logs(timestamp)
    `, (err) => {
      if (err) {
        console.error('Erreur création index security_logs:', err);
      }
    });

    database.run(`
      CREATE INDEX IF NOT EXISTS idx_security_logs_ip ON security_logs(ip_address)
    `, (err) => {
      if (err) {
        console.error('Erreur création index security_logs_ip:', err);
      }
      console.log('✅ Base de données initialisée');
      resolve();
    });
  });
}

function createDefaultUser() {
  return new Promise((resolve, reject) => {
    const db = getDatabase();
    const bcrypt = require('bcryptjs');
    
    // Vérifier si des utilisateurs existent déjà
    db.get('SELECT COUNT(*) as count FROM users', async (err, row) => {
      if (err) {
        console.error('Erreur vérification utilisateurs:', err);
        return reject(err);
      }
      
      // Si des utilisateurs existent déjà, ne rien faire
      if (row.count > 0) {
        console.log('✅ Utilisateurs existants détectés, pas de création de compte par défaut');
        return resolve();
      }
      
      // Créer un compte par défaut
      const defaultEmail = 'admin@cookingrecipe.com';
      const defaultPassword = 'admin123';
      const defaultName = 'Administrateur';
      const userId = 'default-' + Date.now().toString();
      const now = new Date().toISOString();
      
      try {
        const hashedPassword = await bcrypt.hash(defaultPassword, 10);
        
        db.run(
          'INSERT INTO users (id, email, password, name, createdAt) VALUES (?, ?, ?, ?, ?)',
          [userId, defaultEmail, hashedPassword, defaultName, now],
          function(err) {
            if (err) {
              console.error('Erreur création compte par défaut:', err);
              return reject(err);
            }
            
            console.log('✅ Compte par défaut créé automatiquement');
            console.log(`   Email: ${defaultEmail}`);
            console.log(`   Mot de passe: ${defaultPassword}`);
            console.log(`   ⚠️  Changez ce mot de passe après la première connexion!`);
            resolve();
          }
        );
      } catch (error) {
        console.error('Erreur hachage mot de passe:', error);
        return reject(error);
      }
    });
  });
}

function resetDatabase() {
  return new Promise((resolve, reject) => {
    if (!db) {
      return reject(new Error('Database not initialized'));
    }
    
    db.serialize(() => {
      db.run('DROP TABLE IF EXISTS shopping_list', (err) => {
        if (err) return reject(err);
      });
      
      db.run('DROP TABLE IF EXISTS meal_plans', (err) => {
        if (err) return reject(err);
      });
      
      db.run('DROP TABLE IF EXISTS pantry', (err) => {
        if (err) return reject(err);
      });
      
      db.run('DROP TABLE IF EXISTS users', (err) => {
        if (err) return reject(err);
        
        // Réinitialiser
        initDatabase().then(resolve).catch(reject);
      });
    });
  });
}

function closeDatabase() {
  if (db) {
    db.close((err) => {
      if (err) {
        console.error('Erreur fermeture base de données:', err);
      } else {
        console.log('✅ Base de données fermée');
      }
    });
  }
}

module.exports = {
  getDatabase,
  initDatabase,
  resetDatabase,
  createDefaultUser,
  closeDatabase
};

