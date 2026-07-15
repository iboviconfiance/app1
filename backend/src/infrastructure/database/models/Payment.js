'use strict';

module.exports = (sequelize, DataTypes) => {
  const Payment = sequelize.define('Payment', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    user_id: { type: DataTypes.UUID, allowNull: false },
    subscription_id: DataTypes.UUID,
    amount: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
    method: { type: DataTypes.ENUM('airtel_money', 'mtn_mobile_money'), allowNull: false },
    status: { type: DataTypes.ENUM('pending', 'completed', 'failed', 'refunded'), allowNull: false, defaultValue: 'pending' },
    transaction_id: DataTypes.STRING(255),
    phone_number: { type: DataTypes.STRING(20), allowNull: false },
  }, { tableName: 'payments', underscored: true });

  Payment.associate = (models) => {
    Payment.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
    Payment.belongsTo(models.Subscription, { foreignKey: 'subscription_id', as: 'subscription' });
  };

  return Payment;
};
