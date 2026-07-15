'use strict';

module.exports = (sequelize, DataTypes) => {
  const ExerciseQuestion = sequelize.define('ExerciseQuestion', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    exercise_id: { type: DataTypes.UUID, allowNull: false },
    question_text: { type: DataTypes.TEXT, allowNull: false },
    options: { type: DataTypes.JSONB, allowNull: false },
    correct_answer: { type: DataTypes.INTEGER, allowNull: false },
    points: { type: DataTypes.INTEGER, defaultValue: 1 },
    explanation: DataTypes.TEXT,
    order_index: { type: DataTypes.INTEGER, allowNull: false },
  }, { tableName: 'exercise_questions', underscored: true, timestamps: false });

  ExerciseQuestion.associate = (models) => {
    ExerciseQuestion.belongsTo(models.Exercise, { foreignKey: 'exercise_id', as: 'exercise' });
  };

  return ExerciseQuestion;
};
