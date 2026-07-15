'use strict';

module.exports = (sequelize, DataTypes) => {
  const ExamQuestion = sequelize.define('ExamQuestion', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    exam_id: { type: DataTypes.UUID, allowNull: false },
    question_text: { type: DataTypes.TEXT, allowNull: false },
    options: { type: DataTypes.JSONB, allowNull: false },
    correct_answer: { type: DataTypes.INTEGER, allowNull: false },
    points: { type: DataTypes.INTEGER, defaultValue: 1 },
    explanation: DataTypes.TEXT,
    order_index: { type: DataTypes.INTEGER, allowNull: false },
  }, { tableName: 'exam_questions', underscored: true, timestamps: false });

  ExamQuestion.associate = (models) => {
    ExamQuestion.belongsTo(models.Exam, { foreignKey: 'exam_id', as: 'exam' });
  };

  return ExamQuestion;
};
