class Payment {
  constructor(data) {
    this.id = data.id;
    this.userId = data.user_id || data.userId;
    this.subscriptionId = data.subscription_id || data.subscriptionId;
    this.amount = parseFloat(data.amount);
    this.method = data.method;
    this.status = data.status;
    this.transactionId = data.transaction_id || data.transactionId;
    this.phoneNumber = data.phone_number || data.phoneNumber;
    this.createdAt = data.created_at || data.createdAt;
  }

  toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      subscriptionId: this.subscriptionId,
      amount: this.amount,
      method: this.method,
      status: this.status,
      transactionId: this.transactionId,
      phoneNumber: this.phoneNumber,
      createdAt: this.createdAt,
    };
  }
}

module.exports = Payment;
