'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE work_group_role AS ENUM ('admin', 'member');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);

    await queryInterface.createTable('work_groups', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      name: { type: Sequelize.STRING(255), allowNull: false },
      description: { type: Sequelize.TEXT },
      subject_id: { type: Sequelize.UUID, references: { model: 'subjects', key: 'id' }, onDelete: 'SET NULL' },
      series_id: { type: Sequelize.UUID, references: { model: 'series', key: 'id' }, onDelete: 'SET NULL' },
      created_by: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE' },
      max_members: { type: Sequelize.INTEGER, defaultValue: 10 },
      invite_code: { type: Sequelize.STRING(20), unique: true },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('work_group_members', {
      work_group_id: { type: Sequelize.UUID, references: { model: 'work_groups', key: 'id' }, onDelete: 'CASCADE', primaryKey: true },
      user_id: { type: Sequelize.UUID, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE', primaryKey: true },
      role: { type: 'work_group_role', allowNull: false, defaultValue: 'member' },
      joined_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.addIndex('work_groups', ['created_by']);
    await queryInterface.addIndex('work_group_members', ['user_id']);
  },

  async down(queryInterface) {
    await queryInterface.dropTable('work_group_members');
    await queryInterface.dropTable('work_groups');
  },
};
