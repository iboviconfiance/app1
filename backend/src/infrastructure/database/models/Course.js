'use strict';

module.exports = (sequelize, DataTypes) => {
  const Course = sequelize.define('Course', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    title: { type: DataTypes.STRING(255), allowNull: false },
    description: DataTypes.TEXT,
    type: { type: DataTypes.ENUM('pdf', 'video'), allowNull: false },
    file_url: DataTypes.STRING(500),
    video_url: DataTypes.STRING(500),
    thumbnail_url: DataTypes.STRING(500),
    duration_minutes: { type: DataTypes.INTEGER, defaultValue: 0 },
    subject_id: { type: DataTypes.UUID, allowNull: false },
    series_id: { type: DataTypes.UUID, allowNull: false },
    classroom_id: DataTypes.UUID,
    is_premium: { type: DataTypes.BOOLEAN, defaultValue: false },
    download_count: { type: DataTypes.INTEGER, defaultValue: 0 },
  }, { tableName: 'courses', underscored: true });

  Course.associate = (models) => {
    Course.belongsTo(models.Subject, { foreignKey: 'subject_id', as: 'subject' });
    Course.belongsTo(models.Series, { foreignKey: 'series_id', as: 'series' });
    Course.belongsTo(models.Classroom, { foreignKey: 'classroom_id', as: 'classroom' });
  };

  return Course;
};
