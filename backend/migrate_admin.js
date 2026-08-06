const pool = require('./src/infrastructure/database/pool');

async function migrate() {
  console.log('🔄 Démarrage de la migration de la base de données pour le module Admin...');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Ajouter le rôle aux utilisateurs
    console.log('   Ajout de la colonne "role" à la table "users"...');
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'student'
    `);

    // 2. Ajouter la couleur aux matières
    console.log('   Ajout de la colonne "color" à la table "subjects"...');
    await client.query(`
      ALTER TABLE subjects 
      ADD COLUMN IF NOT EXISTS color VARCHAR(20) DEFAULT '#2563EB'
    `);

    // 3. Promouvoir le compte de démo à admin
    console.log('   Promotion de l\'utilisateur démo (+237670000001) au rôle "admin"...');
    await client.query(`
      UPDATE users 
      SET role = 'admin' 
      WHERE telephone = '+237670000001'
    `);

    // 4. Mettre à jour des couleurs pour les matières existantes afin de tester la dynamisation
    console.log('   Initialisation de couleurs distinctes pour les matières existantes...');
    const subjectColors = {
      'Mathématiques': '#2563EB',     // Bleu
      'Français': '#EC4899',          // Rose
      'Anglais': '#10B981',           // Émeraude
      'Physique': '#EF4444',          // Rouge
      'SVT': '#8B5CF6',               // Violet
      'Philosophie': '#6B7280',       // Gris
      'Technologie': '#F59E0B',       // Ambre
      'Dessin Technique': '#06B6D4',  // Cyan
    };

    for (const [name, color] of Object.entries(subjectColors)) {
      await client.query(
        'UPDATE subjects SET color = $1 WHERE name = $2',
        [color, name]
      );
    }

    await client.query('COMMIT');
    console.log('🎉 Migration effectuée avec succès !');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Échec de la migration:', error);
    process.exit(1);
  } finally {
    client.release();
    process.exit(0);
  }
}

migrate();
