# =============================================================================
# KLAS+ - Dockerfile racine (orchestration complète)
# =============================================================================
#
# Ce projet utilise Docker Compose pour lancer toute la stack :
#
#   docker compose up --build
#
# Services :
#   - postgres  : PostgreSQL 16      (port 5432)
#   - backend   : API Node.js        (port 3000)
#   - frontend  : Flutter Web+Nginx  (port 8080)
#
# Accès :
#   - Application : http://localhost:8080
#   - API directe : http://localhost:3000/api/health
#
# Build manuel d'un service :
#   docker build -f backend/Dockerfile  -t klasplus-api ./backend
#   docker build -f frontend/Dockerfile -t klasplus-web ./frontend
#
# =============================================================================

# Image meta : affiche les instructions si buildée seule
FROM alpine:3.20

RUN apk add --no-cache bash

WORKDIR /app

COPY docker-compose.yml README.md ./

RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'echo ""' >> /entrypoint.sh && \
    echo 'echo "  KLAS+ - Utilisez Docker Compose pour lancer l application :"' >> /entrypoint.sh && \
    echo 'echo ""' >> /entrypoint.sh && \
    echo 'echo "    docker compose up --build"' >> /entrypoint.sh && \
    echo 'echo ""' >> /entrypoint.sh && \
    echo 'echo "  Puis ouvrez : http://localhost:8080"' >> /entrypoint.sh && \
    echo 'echo ""' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
