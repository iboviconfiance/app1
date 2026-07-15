'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.sequelize.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";');

    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE school_level AS ENUM ('college', 'lycee_general', 'lycee_technique');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);
    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE subscription_plan AS ENUM ('gratuit', 'individuel', 'familial');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);
    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE subscription_status AS ENUM ('active', 'expired', 'cancelled', 'pending');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);
    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE payment_method AS ENUM ('airtel_money', 'mtn_mobile_money');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);
    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);
    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE exercise_type AS ENUM ('qcm', 'quiz', 'examen_blanc');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);
    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE exam_type AS ENUM ('bepc', 'bac_general', 'bac_technique', 'bet');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);
    await queryInterface.sequelize.query(`
      DO $$ BEGIN
        CREATE TYPE course_type AS ENUM ('pdf', 'video');
      EXCEPTION WHEN duplicate_object THEN null; END $$;
    `);

    await queryInterface.createTable('classrooms', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      name: { type: Sequelize.STRING(50), allowNull: false },
      level: { type: 'school_level', allowNull: false },
      order_index: { type: Sequelize.INTEGER, allowNull: false },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('subjects', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      name: { type: Sequelize.STRING(100), allowNull: false },
      description: { type: Sequelize.TEXT },
      icon: { type: Sequelize.STRING(50) },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('series', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      name: { type: Sequelize.STRING(100), allowNull: false },
      level: { type: 'school_level', allowNull: false },
      classroom_id: { type: Sequelize.UUID, references: { model: 'classrooms', key: 'id' }, onDelete: 'SET NULL' },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('series_subjects', {
      series_id: { type: Sequelize.UUID, references: { model: 'series', key: 'id' }, onDelete: 'CASCADE', primaryKey: true },
      subject_id: { type: Sequelize.UUID, references: { model: 'subjects', key: 'id' }, onDelete: 'CASCADE', primaryKey: true },
    });

    await queryInterface.createTable('users', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      nom: { type: Sequelize.STRING(100), allowNull: false },
      prenom: { type: Sequelize.STRING(100), allowNull: false },
      telephone: { type: Sequelize.STRING(20), allowNull: false, unique: true },
      email: { type: Sequelize.STRING(255), allowNull: true, unique: true },
      password_hash: { type: Sequelize.STRING(255), allowNull: false },
      etablissement: { type: Sequelize.STRING(255) },
      classroom_id: { type: Sequelize.UUID, references: { model: 'classrooms', key: 'id' }, onDelete: 'SET NULL' },
      series_id: { type: Sequelize.UUID, references: { model: 'series', key: 'id' }, onDelete: 'SET NULL' },
      reset_token: { type: Sequelize.STRING(255) },
      reset_token_expires: { type: Sequelize.DATE },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('subscriptions', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      user_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE' },
      plan: { type: 'subscription_plan', allowNull: false, defaultValue: 'gratuit' },
      status: { type: 'subscription_status', allowNull: false, defaultValue: 'active' },
      start_date: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      end_date: { type: Sequelize.DATE },
      max_members: { type: Sequelize.INTEGER, defaultValue: 1 },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('payments', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      user_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE' },
      subscription_id: { type: Sequelize.UUID, references: { model: 'subscriptions', key: 'id' }, onDelete: 'SET NULL' },
      amount: { type: Sequelize.DECIMAL(10, 2), allowNull: false },
      method: { type: 'payment_method', allowNull: false },
      status: { type: 'payment_status', allowNull: false, defaultValue: 'pending' },
      transaction_id: { type: Sequelize.STRING(255) },
      phone_number: { type: Sequelize.STRING(20), allowNull: false },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('courses', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      title: { type: Sequelize.STRING(255), allowNull: false },
      description: { type: Sequelize.TEXT },
      type: { type: 'course_type', allowNull: false },
      file_url: { type: Sequelize.STRING(500) },
      video_url: { type: Sequelize.STRING(500) },
      thumbnail_url: { type: Sequelize.STRING(500) },
      duration_minutes: { type: Sequelize.INTEGER, defaultValue: 0 },
      subject_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'subjects', key: 'id' }, onDelete: 'CASCADE' },
      series_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'series', key: 'id' }, onDelete: 'CASCADE' },
      classroom_id: { type: Sequelize.UUID, references: { model: 'classrooms', key: 'id' }, onDelete: 'SET NULL' },
      is_premium: { type: Sequelize.BOOLEAN, defaultValue: false },
      download_count: { type: Sequelize.INTEGER, defaultValue: 0 },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('course_favorites', {
      user_id: { type: Sequelize.UUID, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE', primaryKey: true },
      course_id: { type: Sequelize.UUID, references: { model: 'courses', key: 'id' }, onDelete: 'CASCADE', primaryKey: true },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('course_history', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      user_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE' },
      course_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'courses', key: 'id' }, onDelete: 'CASCADE' },
      progress_percent: { type: Sequelize.INTEGER, defaultValue: 0 },
      last_position: { type: Sequelize.INTEGER, defaultValue: 0 },
      completed: { type: Sequelize.BOOLEAN, defaultValue: false },
      viewed_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('course_history', ['user_id', 'course_id'], { unique: true, name: 'course_history_user_course_unique' });

    await queryInterface.createTable('exercises', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      title: { type: Sequelize.STRING(255), allowNull: false },
      description: { type: Sequelize.TEXT },
      type: { type: 'exercise_type', allowNull: false },
      subject_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'subjects', key: 'id' }, onDelete: 'CASCADE' },
      series_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'series', key: 'id' }, onDelete: 'CASCADE' },
      classroom_id: { type: Sequelize.UUID, references: { model: 'classrooms', key: 'id' }, onDelete: 'SET NULL' },
      duration_minutes: { type: Sequelize.INTEGER, defaultValue: 30 },
      total_points: { type: Sequelize.INTEGER, defaultValue: 100 },
      is_premium: { type: Sequelize.BOOLEAN, defaultValue: false },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('exercise_questions', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      exercise_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'exercises', key: 'id' }, onDelete: 'CASCADE' },
      question_text: { type: Sequelize.TEXT, allowNull: false },
      options: { type: Sequelize.JSONB, allowNull: false },
      correct_answer: { type: Sequelize.INTEGER, allowNull: false },
      points: { type: Sequelize.INTEGER, defaultValue: 1 },
      explanation: { type: Sequelize.TEXT },
      order_index: { type: Sequelize.INTEGER, allowNull: false },
    });

    await queryInterface.createTable('exercise_results', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      user_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE' },
      exercise_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'exercises', key: 'id' }, onDelete: 'CASCADE' },
      score: { type: Sequelize.INTEGER, allowNull: false },
      total_points: { type: Sequelize.INTEGER, allowNull: false },
      answers: { type: Sequelize.JSONB },
      completed_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('exams', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      title: { type: Sequelize.STRING(255), allowNull: false },
      description: { type: Sequelize.TEXT },
      type: { type: 'exam_type', allowNull: false },
      subject_id: { type: Sequelize.UUID, references: { model: 'subjects', key: 'id' }, onDelete: 'SET NULL' },
      series_id: { type: Sequelize.UUID, references: { model: 'series', key: 'id' }, onDelete: 'SET NULL' },
      classroom_id: { type: Sequelize.UUID, references: { model: 'classrooms', key: 'id' }, onDelete: 'SET NULL' },
      duration_minutes: { type: Sequelize.INTEGER, defaultValue: 180 },
      total_points: { type: Sequelize.INTEGER, defaultValue: 100 },
      file_url: { type: Sequelize.STRING(500) },
      is_premium: { type: Sequelize.BOOLEAN, defaultValue: true },
      year: { type: Sequelize.INTEGER },
      created_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.createTable('exam_questions', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      exam_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'exams', key: 'id' }, onDelete: 'CASCADE' },
      question_text: { type: Sequelize.TEXT, allowNull: false },
      options: { type: Sequelize.JSONB, allowNull: false },
      correct_answer: { type: Sequelize.INTEGER, allowNull: false },
      points: { type: Sequelize.INTEGER, defaultValue: 1 },
      explanation: { type: Sequelize.TEXT },
      order_index: { type: Sequelize.INTEGER, allowNull: false },
    });

    await queryInterface.createTable('exam_results', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.literal('uuid_generate_v4()'), primaryKey: true },
      user_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'users', key: 'id' }, onDelete: 'CASCADE' },
      exam_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'exams', key: 'id' }, onDelete: 'CASCADE' },
      score: { type: Sequelize.INTEGER, allowNull: false },
      total_points: { type: Sequelize.INTEGER, allowNull: false },
      answers: { type: Sequelize.JSONB },
      completed_at: { type: Sequelize.DATE, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });

    await queryInterface.addIndex('users', ['telephone']);
    await queryInterface.addIndex('courses', ['series_id']);
    await queryInterface.addIndex('courses', ['subject_id']);
    await queryInterface.addIndex('exercises', ['series_id']);
    await queryInterface.addIndex('subscriptions', ['user_id']);
    await queryInterface.addIndex('course_history', ['user_id']);
    await queryInterface.addIndex('exercise_results', ['user_id']);
  },

  async down(queryInterface) {
    const tables = [
      'exam_results', 'exam_questions', 'exams',
      'exercise_results', 'exercise_questions', 'exercises',
      'course_history', 'course_favorites', 'courses',
      'payments', 'subscriptions', 'users',
      'series_subjects', 'series', 'subjects', 'classrooms',
    ];
    for (const table of tables) {
      await queryInterface.dropTable(table);
    }
  },
};
