'use strict';

module.exports = (sequelize, DataTypes) => {
  const Exam = sequelize.define('Exam', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    title: { type: DataTypes.STRING(255), allowNull: false },
    description: DataTypes.TEXT,
    type: { type: DataTypes.ENUM('bepc', 'bac_general', 'bac_technique', 'bet'), allowNull: false },
    subject_id: DataTypes.UUID,
    series_id: DataTypes.UUID,
    classroom_id: DataTypes.UUID,
    duration_minutes: { type: DataTypes.INTEGER, defaultValue: 180 },
    total_points: { type: DataTypes.INTEGER, defaultValue: 100 },
    file_url: DataTypes.STRING(500),
    is_premium: { type: DataTypes.BOOLEAN, defaultValue: true },
    year: DataTypes.INTEGER,
  }, { tableName: 'exams', underscored: true, timestamps: true, createdAt: 'created_at', updatedAt: false });

  Exam.associate = (models) => {
    Exam.belongsTo(models.Subject, { foreignKey: 'subject_id', as: 'subject' });
    Exam.belongsTo(models.Series, { foreignKey: 'series_id', as: 'series' });
    Exam.hasMany(models.ExamQuestion, { foreignKey: 'exam_id', as: 'questions' });
  };

  return Exam;
};
