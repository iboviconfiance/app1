require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    database: process.env.DB_NAME || 'klasplus',
    user: process.env.DB_USER || 'klasplus',
    password: process.env.DB_PASSWORD || 'klasplus_secret',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'dev_secret_change_in_production',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:8080',
  
  // Payment operators config (Airtel / MTN)
  payment: {
    webhookSecret: process.env.WEBHOOK_SECRET || 'default_webhook_hmac_secret_key',
    redirectUrl: process.env.PAYMENT_REDIRECT_URL || 'http://localhost:8080/subscription/callback',
    airtel: {
      merchantId: process.env.AIRTEL_MERCHANT_ID || '',
      apiKey: process.env.AIRTEL_API_KEY || '',
    },
    mtn: {
      merchantId: process.env.MTN_MERCHANT_ID || '',
      apiKey: process.env.MTN_API_KEY || '',
    }
  }
};
