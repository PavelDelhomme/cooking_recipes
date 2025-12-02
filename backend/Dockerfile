FROM node:18-alpine

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le reste du code
COPY . .

# Créer le dossier data
RUN mkdir -p data

# Exposer le port
EXPOSE 4040

# Commande de démarrage
CMD ["npm", "start"]

