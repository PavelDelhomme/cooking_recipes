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
      console.log('✅ Base de données initialisée');
      resolve();
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
  closeDatabase
};

