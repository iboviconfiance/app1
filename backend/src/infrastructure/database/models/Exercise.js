'use strict';

module.exports = (sequelize, DataTypes) => {
  const Exercise = sequelize.define('Exercise', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    title: { type: DataTypes.STRING(255), allowNull: false },
    description: DataTypes.TEXT,
    type: { type: DataTypes.ENUM('qcm', 'quiz', 'examen_blanc'), allowNull: false },
    subject_id: { type: DataTypes.UUID, allowNull: false },
    series_id: { type: DataTypes.UUID, allowNull: false },
    classroom_id: DataTypes.UUID,
    duration_minutes: { type: DataTypes.INTEGER, defaultValue: 30 },
    total_points: { type: DataTypes.INTEGER, defaultValue: 100 },
    is_premium: { type: DataTypes.BOOLEAN, defaultValue: false },
  }, { tableName: 'exercises', underscored: true, timestamps: true, createdAt: 'created_at', updatedAt: false });

  Exercise.associate = (models) => {
    Exercise.belongsTo(models.Subject, { foreignKey: 'subject_id', as: 'subject' });
    Exercise.belongsTo(models.Series, { foreignKey: 'series_id', as: 'series' });
    Exercise.hasMany(models.ExerciseQuestion, { foreignKey: 'exercise_id', as: 'questions' });
  };

  return Exercise;
};
