const crypto = require('crypto');
const SubscriptionRepository = require('../../infrastructure/repositories/SubscriptionRepository');
const config = require('../../config');

const subscriptionRepo = new SubscriptionRepository();

class WebhookController {
  async handlePaymentWebhook(req, res, next) {
    try {
      const signature = req.headers['x-signature'] || req.headers['x-pay-signature'];
      const webhookSecret = process.env.WEBHOOK_SECRET;

      // 1. Signature Verification (HMAC SHA256)
      if (webhookSecret && signature) {
        const hmac = crypto.createHmac('sha256', webhookSecret);
        const payload = JSON.stringify(req.body);
        const computedSignature = hmac.update(payload).digest('hex');

        if (computedSignature !== signature) {
          return res.status(401).json({ success: false, message: 'Invalid webhook signature' });
        }
      }

      // Extract payload parameters (flexible for Airtel / MTN structure)
      const transactionId = req.body.transactionId || req.body.transaction_id || req.body.tx_ref;
      const status = req.body.status; // success, completed, failed, etc.
      const paymentId = req.body.paymentId || req.body.payment_id;

      if (!transactionId || !paymentId) {
        return res.status(400).json({ success: false, message: 'Missing transactionId or paymentId' });
      }

      // Map operator-specific status to app status
      let mappedStatus = 'failed';
      if (['success', 'completed', 'successful', 'APPROVED'].includes(status)) {
        mappedStatus = 'completed';
      }

      // 2. Idempotence Check
      const existingPayment = await subscriptionRepo.findPaymentByTransactionId(transactionId);
      if (existingPayment) {
        console.log(`Webhook duplicate received for transaction: ${transactionId}. Skipping processing.`);
        return res.json({ success: true, message: 'Webhook already processed (idempotent)' });
      }

      // 3. Update payment and subscription status with safety check for DB uniqueness error (Race Condition protection)
      try {
        const updatedPayment = await subscriptionRepo.updatePaymentAndSubscriptionStatus(
          paymentId,
          mappedStatus,
          transactionId
        );

        if (!updatedPayment) {
          return res.status(404).json({ success: false, message: 'Payment not found' });
        }

        res.json({ success: true, message: 'Webhook processed successfully' });
      } catch (dbError) {
        // Check for unique constraint violation in Postgres
        if (dbError.code === '23505' || dbError.message.includes('unique constraint') || dbError.name === 'SequelizeUniqueConstraintError') {
          console.log(`Concurrent request handled. Transaction ${transactionId} already exists.`);
          return res.json({ success: true, message: 'Webhook already processed concurrently' });
        }
        throw dbError;
      }
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new WebhookController();
