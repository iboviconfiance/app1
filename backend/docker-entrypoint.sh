#!/bin/sh
set -e

echo "=========================================="
echo "  KLAS+ API - Démarrage"
echo "=========================================="

echo "⏳ Attente de PostgreSQL (${DB_HOST}:${DB_PORT})..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; do
  sleep 2
done
echo "✅ PostgreSQL prêt"

echo "📦 Exécution des migrations Sequelize..."
npx sequelize-cli db:migrate

echo "🌱 Insertion des données initiales..."
node src/infrastructure/database/seed.js || echo "ℹ️  Seed ignoré (données déjà présentes)"

echo "🚀 Démarrage du serveur sur le port ${PORT:-3000}..."
exec node src/server.js
