# Dockerfile pour Flutter Web avec hot reload
FROM ubuntu:22.04

# Variables d'environnement
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_VERSION=3.24.0
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Installer les dépendances
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    python3 \
    python3-pip \
    bash \
    inotify-tools \
    && rm -rf /var/lib/apt/lists/*

# Installer Flutter
RUN git clone --branch stable https://github.com/flutter/flutter.git ${FLUTTER_HOME}
# Configurer pour ignorer l'avertissement root (normal dans Docker)
ENV FLUTTER_ROOT_WARNING=false
RUN flutter doctor || true

# Configurer Flutter pour le web
RUN flutter config --enable-web

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY pubspec.yaml pubspec.lock* ./

# Installer les dépendances
RUN flutter pub get

# Copier le script d'entrée
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Copier le reste du code
COPY . .

# Exposer le port pour le serveur de développement (interne)
EXPOSE 8080

# Utiliser le script d'entrée
ENTRYPOINT ["/app/docker-entrypoint.sh"]

