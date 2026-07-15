'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // 1. Create plans table
    await queryInterface.createTable('plans', {
      id: { type: Sequelize.STRING(50), primaryKey: true },
      name: { type: Sequelize.STRING(100), allowNull: false },
      price: { type: Sequelize.DECIMAL(10, 2), allowNull: false },
      duration_days: { type: Sequelize.INTEGER, allowNull: false },
      features: { type: Sequelize.JSONB, allowNull: false },
      max_members: { type: Sequelize.INTEGER, defaultValue: 1 },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') }
    });

    // 2. Insert initial plans data
    await queryInterface.sequelize.query(`
      INSERT INTO plans (id, name, price, duration_days, features, max_members) VALUES
      ('gratuit', 'Gratuit', 0.00, 30, '["Accès limité aux cours", "5 exercices/mois", "Publicités"]', 1),
      ('individuel', 'Individuel', 5000.00, 365, '["Accès illimité", "Tous les exercices", "Examens blancs", "Sans publicité"]', 1),
      ('familial', 'Familial', 12000.00, 365, '["Jusqu''à 5 comptes", "Accès illimité", "Tous les examens", "Support prioritaire"]', 5)
      ON CONFLICT (id) DO NOTHING;
    `);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('plans');
  }
};
