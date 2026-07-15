'use strict';

module.exports = (sequelize, DataTypes) => {
  const Subject = sequelize.define('Subject', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    name: { type: DataTypes.STRING(100), allowNull: false },
    description: DataTypes.TEXT,
    icon: DataTypes.STRING(50),
  }, { tableName: 'subjects', underscored: true, timestamps: true, createdAt: 'created_at', updatedAt: false });

  Subject.associate = (models) => {
    Subject.belongsToMany(models.Series, { through: 'series_subjects', foreignKey: 'subject_id', otherKey: 'series_id', as: 'series' });
    Subject.hasMany(models.Course, { foreignKey: 'subject_id', as: 'courses' });
    Subject.hasMany(models.Exercise, { foreignKey: 'subject_id', as: 'exercises' });
    Subject.hasMany(models.Exam, { foreignKey: 'subject_id', as: 'exams' });
  };

  return Subject;
};
