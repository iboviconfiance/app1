# =============================================================================
# KLAS+ Backend API - Dockerfile
# =============================================================================
FROM node:20-alpine

LABEL maintainer="KLAS+"
LABEL description="API REST Node.js / Express / PostgreSQL"

# Outils pour attendre PostgreSQL et exécuter les migrations
RUN set -eux; \
    for attempt in 1 2 3; do \
      if apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/v3.20/main postgresql-client tini wget; then \
        break; \
      elif [ "$attempt" -eq 3 ]; then \
        exit 1; \
      else \
        echo "apk add failed, retrying in 3s... ($attempt/3)"; \
        sleep 3; \
      fi; \
    done

WORKDIR /app

# Dépendances (cache Docker layer)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm install sequelize-cli --no-save && npm cache clean --force

# Code source
COPY . .

# Dossier uploads pour les fichiers PDF
RUN mkdir -p uploads && chmod +x docker-entrypoint.sh

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/health || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./docker-entrypoint.sh"]
