'use strict';

module.exports = (sequelize, DataTypes) => {
  const Subscription = sequelize.define('Subscription', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    user_id: { type: DataTypes.UUID, allowNull: false },
    plan: { type: DataTypes.ENUM('gratuit', 'individuel', 'familial'), allowNull: false, defaultValue: 'gratuit' },
    status: { type: DataTypes.ENUM('active', 'expired', 'cancelled', 'pending'), allowNull: false, defaultValue: 'active' },
    start_date: DataTypes.DATE,
    end_date: DataTypes.DATE,
    max_members: { type: DataTypes.INTEGER, defaultValue: 1 },
  }, { tableName: 'subscriptions', underscored: true });

  Subscription.associate = (models) => {
    Subscription.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
    Subscription.hasMany(models.Payment, { foreignKey: 'subscription_id', as: 'payments' });
  };

  return Subscription;
};
