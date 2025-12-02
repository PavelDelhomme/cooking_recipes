const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const os = require('os');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const pantryRoutes = require('./routes/pantry');
const mealPlanRoutes = require('./routes/mealPlans');
const shoppingListRoutes = require('./routes/shoppingList');
const adminRoutes = require('./routes/admin');
const { initDatabase, createDefaultUser } = require('./database/db');

// Fonction pour obtenir l'IP de la machine
function getMachineIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Ignorer les adresses internes et IPv6
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

const app = express();
const PORT = process.env.PORT || 7272;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

// Middleware pour forcer l'encodage UTF-8
app.use((req, res, next) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/pantry', pantryRoutes);
app.use('/api/meal-plans', mealPlanRoutes);
app.use('/api/shopping-list', shoppingListRoutes);
app.use('/api/admin', adminRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'API is running' });
});

// Initialize database and start server
initDatabase().then(() => {
  // Créer un compte par défaut si aucun utilisateur n'existe
  return createDefaultUser();
}).then(() => {
  // Écouter sur toutes les interfaces pour permettre l'accès depuis le réseau local
  const HOST = process.env.HOST || '0.0.0.0';
  const MACHINE_IP = getMachineIP();
  app.listen(PORT, HOST, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📡 API available at http://localhost:${PORT}/api`);
    console.log(`📡 API accessible depuis le réseau: http://${MACHINE_IP}:${PORT}/api`);
  });
}).catch(err => {
  console.error('❌ Failed to initialize database:', err);
  process.exit(1);
});

module.exports = app;

