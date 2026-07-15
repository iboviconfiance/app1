'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // 1. Unique constraint/index on payments.transaction_id to prevent race condition/duplicate transactions
    await queryInterface.sequelize.query(`
      ALTER TABLE payments ADD CONSTRAINT uq_payments_transaction_id UNIQUE (transaction_id);
    `).catch(err => console.log('Constraint uq_payments_transaction_id might already exist:', err.message));

    // 2. Indexes for performance
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_exercises_subject_id ON exercises(subject_id);');
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);');
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments(transaction_id);');
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_course_history_course_id ON course_history(course_id);');
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_series_classroom_id ON series(classroom_id);');
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_exercise_questions_exercise_id ON exercise_questions(exercise_id);');
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_exam_questions_exam_id ON exam_questions(exam_id);');
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_exam_results_user_id ON exam_results(user_id);');
    await queryInterface.sequelize.query('CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON subscriptions(user_id, status);');
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.sequelize.query('ALTER TABLE payments DROP CONSTRAINT IF EXISTS uq_payments_transaction_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_exercises_subject_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_payments_user_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_payments_transaction_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_course_history_course_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_series_classroom_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_exercise_questions_exercise_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_exam_questions_exam_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_exam_results_user_id;');
    await queryInterface.sequelize.query('DROP INDEX IF EXISTS idx_subscriptions_user_status;');
  }
};
