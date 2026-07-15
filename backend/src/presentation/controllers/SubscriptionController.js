const { body } = require('express-validator');
const SubscriptionRepository = require('../../infrastructure/repositories/SubscriptionRepository');
const PaymentService = require('../../application/services/PaymentService');

const subscriptionRepo = new SubscriptionRepository();
const paymentService = new PaymentService();

const subscribeValidation = [
  body('plan').isIn(['gratuit', 'individuel', 'familial']).withMessage('Plan d\'abonnement invalide'),
  body('method').custom((value, { req }) => {
    if (req.body.plan !== 'gratuit' && !['airtel_money', 'mtn_mobile_money'].includes(value)) {
      throw new Error('Méthode de paiement requise et valide (airtel_money ou mtn_mobile_money)');
    }
    return true;
  }),
  body('phoneNumber').custom((value, { req }) => {
    if (req.body.plan !== 'gratuit' && (!value || value.trim() === '')) {
      throw new Error('Numéro de téléphone requis pour le paiement');
    }
    return true;
  })
];

class SubscriptionController {
  async getPlans(req, res, next) {
    try {
      const data = await subscriptionRepo.getPlans();
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async getActive(req, res, next) {
    try {
      const data = await subscriptionRepo.getActiveByUser(req.userId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async subscribe(req, res, next) {
    try {
      const { plan, method, phoneNumber } = req.body;

      if (plan === 'gratuit') {
        const subscription = await subscriptionRepo.create(req.userId, 'gratuit');
        return res.json({ success: true, data: { subscription, message: 'Abonnement gratuit activé' } });
      }

      const result = await paymentService.initiatePayment(req.userId, plan, method, phoneNumber);
      res.json({ success: true, data: result });
    } catch (error) {
      error.status = 400;
      next(error);
    }
  }

  async getPayments(req, res, next) {
    try {
      const data = await subscriptionRepo.getPayments(req.userId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = {
  SubscriptionController: new SubscriptionController(),
  subscribeValidation
};
