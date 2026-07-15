require('dotenv').config();

module.exports = {
  development: {
    username: process.env.DB_USER || 'klasplus',
    password: process.env.DB_PASSWORD || 'klasplus_secret',
    database: process.env.DB_NAME || 'klasplus',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    dialect: 'postgres',
    logging: false,
  },
  test: {
    username: process.env.DB_USER || 'klasplus',
    password: process.env.DB_PASSWORD || 'klasplus_secret',
    database: process.env.DB_NAME || 'klasplus_test',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    dialect: 'postgres',
    logging: false,
  },
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    dialect: 'postgres',
    logging: false,
  },
};
