const express = require('express');
const { SubscriptionController, subscribeValidation } = require('../controllers/SubscriptionController');
const authMiddleware = require('../middleware/authMiddleware');
const validate = require('../middleware/validate');

const router = express.Router();

router.get('/plans', SubscriptionController.getPlans.bind(SubscriptionController));
router.get('/active', authMiddleware, SubscriptionController.getActive.bind(SubscriptionController));
router.post('/subscribe', authMiddleware, subscribeValidation, validate, SubscriptionController.subscribe.bind(SubscriptionController));
router.get('/payments', authMiddleware, SubscriptionController.getPayments.bind(SubscriptionController));

module.exports = router;
