FROM node:18-alpine

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le reste du code
COPY . .

# Créer les dossiers nécessaires avec les bonnes permissions
RUN mkdir -p data/ml_models data/ml_critiques data/ml_reports logs && \
    chmod -R 755 data && \
    chmod -R 755 logs

# Exposer le port
EXPOSE 7272

# Variables d'environnement
ENV PORT=7272
ENV HOST=0.0.0.0
ENV NODE_ENV=production

# Commande de démarrage
# La création automatique du compte se fait dans server.js via createDefaultUser()
CMD ["npm", "start"]

