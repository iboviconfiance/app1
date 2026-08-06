/**
 * Script de configuration de la base de données KLAS+ pour PostgreSQL local.
 * Crée l'utilisateur 'klasplus' et la base de données 'klasplus' si nécessaire.
 */
const { Client } = require('pg');

const POSTGRES_PASSWORDS = ['postgres', '', 'admin', 'root', 'password', '1234', '12345'];

async function tryConnect(password) {
  const client = new Client({
    host: 'localhost',
    port: 5432,
    user: 'postgres',
    password: password,
    database: 'postgres',
  });
  try {
    await client.connect();
    return client;
  } catch (e) {
    try { await client.end(); } catch (_) {}
    return null;
  }
}

async function main() {
  console.log('🔍 Tentative de connexion à PostgreSQL local (port 5432)...');
  
  let client = null;
  let usedPassword = '';
  
  for (const pwd of POSTGRES_PASSWORDS) {
    console.log(`   Essai avec mot de passe: "${pwd || '(vide)'}"...`);
    client = await tryConnect(pwd);
    if (client) {
      usedPassword = pwd;
      console.log(`   ✅ Connecté avec le mot de passe: "${pwd || '(vide)'}"`);
      break;
    }
  }
  
  if (!client) {
    console.error('\n❌ Impossible de se connecter à PostgreSQL.');
    console.error('   Veuillez fournir le mot de passe de l\'utilisateur "postgres".');
    console.error('   Usage: set PGPASSWORD=votre_mot_de_passe && node setup_db.js');
    process.exit(1);
  }

  try {
    // 1. Vérifier/Créer l'utilisateur klasplus
    const userCheck = await client.query(
      "SELECT 1 FROM pg_roles WHERE rolname = 'klasplus'"
    );
    if (userCheck.rows.length === 0) {
      console.log('\n📦 Création de l\'utilisateur "klasplus"...');
      await client.query("CREATE USER klasplus WITH PASSWORD 'klasplus_secret'");
      console.log('   ✅ Utilisateur "klasplus" créé.');
    } else {
      console.log('\n✅ L\'utilisateur "klasplus" existe déjà.');
      // Mettre à jour le mot de passe au cas où
      await client.query("ALTER USER klasplus WITH PASSWORD 'klasplus_secret'");
      console.log('   🔑 Mot de passe mis à jour.');
    }

    // 2. Vérifier/Créer la base de données klasplus
    const dbCheck = await client.query(
      "SELECT 1 FROM pg_database WHERE datname = 'klasplus'"
    );
    if (dbCheck.rows.length === 0) {
      console.log('\n📦 Création de la base de données "klasplus"...');
      await client.query("CREATE DATABASE klasplus OWNER klasplus");
      console.log('   ✅ Base de données "klasplus" créée.');
    } else {
      console.log('✅ La base de données "klasplus" existe déjà.');
      // S'assurer que klasplus est propriétaire
      await client.query("ALTER DATABASE klasplus OWNER TO klasplus");
    }

    // 3. Donner les privilèges
    await client.query("GRANT ALL PRIVILEGES ON DATABASE klasplus TO klasplus");
    console.log('   🔑 Privilèges accordés.');

    console.log('\n🎉 Configuration de la base de données terminée !');
    console.log('   Prochaine étape: npm run db:setup');
  } catch (err) {
    console.error('\n❌ Erreur:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();
