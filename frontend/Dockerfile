# =============================================================================
# KLAS+ Frontend Flutter Web - Dockerfile multi-étapes
# =============================================================================

# --- Étape 1 : Build Flutter Web ---
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Dépendances Flutter (cache layer)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Code source
COPY lib ./lib
COPY web ./web
COPY assets ./assets
COPY analysis_options.yaml ./

# Génère les dossiers plateforme manquants (si besoin) tout en conservant les fichiers existants
RUN flutter create . --platforms=web --org com.klasplus

# URL API : chemin relatif via proxy nginx (/api)
ARG API_URL=/api
RUN flutter build web --release \
    --dart-define=API_URL=${API_URL}

# --- Étape 2 : Serveur Nginx ---
FROM nginx:1.27-alpine

LABEL maintainer="KLAS+"
LABEL description="Frontend Flutter Web servi par Nginx"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
