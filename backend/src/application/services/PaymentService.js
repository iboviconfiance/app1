const SubscriptionRepository = require('../../infrastructure/repositories/SubscriptionRepository');
const { v4: uuidv4 } = require('uuid');

class PaymentService {
  constructor() {
    this.subscriptionRepo = new SubscriptionRepository();
  }

  async initiatePayment(userId, plan, method, phoneNumber) {
    const validMethods = ['airtel_money', 'mtn_mobile_money'];
    if (!validMethods.includes(method)) {
      throw new Error('Méthode de paiement non supportée. Utilisez Airtel Money ou MTN Mobile Money.');
    }

    const validPlans = ['individuel', 'familial'];
    if (!validPlans.includes(plan)) {
      throw new Error('Plan invalide');
    }

    const amount = this.subscriptionRepo.getPlanPrice(plan);
    const subscription = await this.subscriptionRepo.upgrade(userId, plan);

    const payment = await this.subscriptionRepo.createPayment({
      userId,
      subscriptionId: subscription.id,
      amount,
      method,
      phoneNumber,
    });

    // Simulate mobile money payment processing
    const transactionId = `${method.toUpperCase()}-${uuidv4().slice(0, 8).toUpperCase()}`;
    const completedPayment = await this.subscriptionRepo.completePayment(payment.id, transactionId);

    return {
      payment: completedPayment,
      subscription,
      message: `Paiement de ${amount} FCFA effectué via ${method === 'airtel_money' ? 'Airtel Money' : 'MTN Mobile Money'}`,
    };
  }
}

module.exports = PaymentService;
