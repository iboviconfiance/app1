const fs = require('fs');
const path = require('path');
const pool = require('./pool');

async function initDatabase() {
  const schemaPath = path.join(__dirname, 'schema.sql');
  const schema = fs.readFileSync(schemaPath, 'utf8');

  try {
    await pool.query(schema);
    console.log('✅ Database schema initialized successfully');
  } catch (error) {
    if (error.code === '42P07') {
      console.log('ℹ️  Tables already exist, skipping schema creation');
    } else {
      console.error('❌ Database initialization failed:', error.message);
      throw error;
    }
  }
}

if (require.main === module) {
  initDatabase()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = { initDatabase };
