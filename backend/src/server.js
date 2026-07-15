const express = require('express');
const cors = require('cors');
const path = require('path');
const config = require('./config');
const errorHandler = require('./presentation/middleware/errorHandler');

const authRoutes = require('./presentation/routes/authRoutes');
const userRoutes = require('./presentation/routes/userRoutes');
const dashboardRoutes = require('./presentation/routes/dashboardRoutes');
const schoolRoutes = require('./presentation/routes/schoolRoutes');
const courseRoutes = require('./presentation/routes/courseRoutes');
const exerciseRoutes = require('./presentation/routes/exerciseRoutes');
const examRoutes = require('./presentation/routes/examRoutes');
const subscriptionRoutes = require('./presentation/routes/subscriptionRoutes');
const workGroupRoutes = require('./presentation/routes/workGroupRoutes');
const webhookRoutes = require('./presentation/routes/webhookRoutes');

function createApp() {
  const app = express();

  const corsOrigin = config.nodeEnv === 'development'
    ? (origin, callback) => {
        // Allow requests with no origin (curl, mobile, etc.) and any localhost port
        if (!origin || /^https?:\/\/localhost(:\d+)?$/.test(origin)) {
          callback(null, true);
        } else {
          callback(new Error('Not allowed by CORS'));
        }
      }
    : config.frontendUrl;
  app.use(cors({ origin: corsOrigin, credentials: true }));
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));
  app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

  app.get('/api/health', (req, res) => {
    res.json({ success: true, message: 'KLAS+ API is running', version: '1.0.0' });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/users', userRoutes);
  app.use('/api/dashboard', dashboardRoutes);
  app.use('/api/school', schoolRoutes);
  app.use('/api/courses', courseRoutes);
  app.use('/api/exercises', exerciseRoutes);
  app.use('/api/exams', examRoutes);
  app.use('/api/subscriptions', subscriptionRoutes);
  app.use('/api/work-groups', workGroupRoutes);
  app.use('/api/webhooks', webhookRoutes);

  app.use(errorHandler);

  return app;
}

const app = createApp();

if (require.main === module) {
  const PORT = config.port;
  app.listen(PORT, () => {
    console.log(`🚀 KLAS+ API running on http://localhost:${PORT}`);
    console.log(`📚 Environment: ${config.nodeEnv}`);
  });
}

module.exports = { app, createApp };
