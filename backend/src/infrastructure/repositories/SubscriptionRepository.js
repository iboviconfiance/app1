const pool = require('../database/pool');
const Subscription = require('../../domain/entities/Subscription');
const Payment = require('../../domain/entities/Payment');

const PLAN_PRICES = {
  gratuit: 0,
  individuel: 5000,
  familial: 12000,
};

class SubscriptionRepository {
  async getActiveByUser(userId) {
    const { rows } = await pool.query(
      `SELECT * FROM subscriptions WHERE user_id = $1 AND status = 'active'
       ORDER BY created_at DESC LIMIT 1`,
      [userId]
    );
    return rows[0] ? new Subscription(rows[0]).toJSON() : null;
  }

  async create(userId, plan) {
    const maxMembers = plan === 'familial' ? 5 : 1;
    const endDate = plan === 'gratuit'
      ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);

    const { rows } = await pool.query(
      `INSERT INTO subscriptions (user_id, plan, status, end_date, max_members)
       VALUES ($1, $2, 'active', $3, $4) RETURNING *`,
      [userId, plan, endDate, maxMembers]
    );
    return new Subscription(rows[0]).toJSON();
  }

  async upgrade(userId, plan) {
    await pool.query(
      `UPDATE subscriptions SET status = 'cancelled', updated_at = NOW()
       WHERE user_id = $1 AND status = 'active'`,
      [userId]
    );
    return this.create(userId, plan);
  }

  getPlanPrice(plan) {
    return PLAN_PRICES[plan] || 0;
  }

  getPlans() {
    return [
      { id: 'gratuit', name: 'Gratuit', price: 0, features: ['Accès limité aux cours', '5 exercices/mois', 'Publicités'] },
      { id: 'individuel', name: 'Individuel', price: 5000, features: ['Accès illimité', 'Tous les exercices', 'Examens blancs', 'Sans publicité'] },
      { id: 'familial', name: 'Familial', price: 12000, features: ['Jusqu\'à 5 comptes', 'Accès illimité', 'Tous les examens', 'Support prioritaire'] },
    ];
  }

  async createPayment({ userId, subscriptionId, amount, method, phoneNumber }) {
    const { rows } = await pool.query(
      `INSERT INTO payments (user_id, subscription_id, amount, method, phone_number, status)
       VALUES ($1, $2, $3, $4, $5, 'pending') RETURNING *`,
      [userId, subscriptionId, amount, method, phoneNumber]
    );
    return new Payment(rows[0]).toJSON();
  }

  async completePayment(paymentId, transactionId) {
    const { rows } = await pool.query(
      `UPDATE payments SET status = 'completed', transaction_id = $1, updated_at = NOW()
       WHERE id = $2 RETURNING *`,
      [transactionId, paymentId]
    );
    return rows[0] ? new Payment(rows[0]).toJSON() : null;
  }

  async findPaymentByTransactionId(transactionId) {
    if (!transactionId) return null;
    const { rows } = await pool.query(
      'SELECT * FROM payments WHERE transaction_id = $1',
      [transactionId]
    );
    return rows[0] ? new Payment(rows[0]).toJSON() : null;
  }

  async updatePaymentAndSubscriptionStatus(paymentId, paymentStatus, transactionId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // 1. Lock the payment row using FOR UPDATE to serialize concurrent webhooks
      const { rows: lockRows } = await client.query(
        'SELECT * FROM payments WHERE id = $1 FOR UPDATE',
        [paymentId]
      );
      
      const currentPayment = lockRows[0];
      if (!currentPayment) {
        await client.query('ROLLBACK');
        return null;
      }
      
      // 2. If already processed, skip reprocessing
      if (currentPayment.status === 'completed' || currentPayment.status === 'failed') {
        console.log(`Payment ${paymentId} is already processed with status: ${currentPayment.status}. Skipping.`);
        await client.query('COMMIT');
        return new Payment(currentPayment).toJSON();
      }

      // 3. Update the payment
      const { rows: paymentRows } = await client.query(
        `UPDATE payments 
         SET status = $1, transaction_id = $2, updated_at = NOW()
         WHERE id = $3 RETURNING *`,
        [paymentStatus, transactionId, paymentId]
      );
      
      const payment = paymentRows[0];
      if (!payment) {
        await client.query('ROLLBACK');
        return null;
      }
      
      if (payment.subscription_id) {
        const subStatus = paymentStatus === 'completed' ? 'active' : 'cancelled';
        await client.query(
          `UPDATE subscriptions 
           SET status = $1, updated_at = NOW()
           WHERE id = $2`,
          [subStatus, payment.subscription_id]
        );
      }
      
      await client.query('COMMIT');
      return new Payment(payment).toJSON();
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getPayments(userId) {
    const { rows } = await pool.query(
      'SELECT * FROM payments WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    return rows.map(r => new Payment(r).toJSON());
  }
}

module.exports = SubscriptionRepository;
