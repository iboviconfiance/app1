const pool = require('./src/infrastructure/database/pool');

async function migrate() {
  console.log('🔄 Migration : ajout des colonnes pour les annales d\'examens...');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Ajouter corrige_pdf_url à la table exams
    console.log('   Ajout de la colonne "corrige_pdf_url" à la table "exams"...');
    await client.query(`
      ALTER TABLE exams 
      ADD COLUMN IF NOT EXISTS corrige_pdf_url VARCHAR(500)
    `);

    // Ajouter epreuve_pdf_url comme alias plus explicite (maps to file_url)
    // Note: file_url est déjà là, on crée corrige_pdf_url seulement
    console.log('   Ajout de la colonne "serie" (libellé court) à la table "exams" si absente...');
    await client.query(`
      ALTER TABLE exams 
      ADD COLUMN IF NOT EXISTS serie VARCHAR(50)
    `);

    // Index pour les recherches par année et type
    console.log('   Création d\'index sur exams(year, type)...');
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_exams_year ON exams(year);
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_exams_type ON exams(type);
    `);

    // Index pour les analytics sur exercise_results
    console.log('   Création d\'index sur exercise_results(exercise_id) pour les analytics...');
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_exercise_results_exercise ON exercise_results(exercise_id);
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_exercise_results_completed ON exercise_results(completed_at);
    `);

    await client.query('COMMIT');
    console.log('🎉 Migration exams effectuée avec succès !');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Échec de la migration:', error.message);
    process.exit(1);
  } finally {
    client.release();
    process.exit(0);
  }
}

migrate();
