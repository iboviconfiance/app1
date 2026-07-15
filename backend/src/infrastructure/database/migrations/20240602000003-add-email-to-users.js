'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const tableInfo = await queryInterface.describeTable('users');
    if (!tableInfo.email) {
      await queryInterface.addColumn('users', 'email', {
        type: Sequelize.STRING(255),
        allowNull: true,
        unique: true
      });
    }
  },

  async down(queryInterface, Sequelize) {
    const tableInfo = await queryInterface.describeTable('users');
    if (tableInfo.email) {
      await queryInterface.removeColumn('users', 'email');
    }
  }
};
