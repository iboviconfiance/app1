const express = require('express');
const webhookController = require('../controllers/WebhookController');

const router = express.Router();

// Public webhook endpoint (signature verified in controller if configured)
router.post('/payment', webhookController.handlePaymentWebhook.bind(webhookController));

module.exports = router;
