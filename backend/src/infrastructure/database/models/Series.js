'use strict';

module.exports = (sequelize, DataTypes) => {
  const Series = sequelize.define('Series', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    name: { type: DataTypes.STRING(100), allowNull: false },
    level: { type: DataTypes.ENUM('college', 'lycee_general', 'lycee_technique'), allowNull: false },
    classroom_id: DataTypes.UUID,
  }, { tableName: 'series', underscored: true, timestamps: true, createdAt: 'created_at', updatedAt: false });

  Series.associate = (models) => {
    Series.belongsTo(models.Classroom, { foreignKey: 'classroom_id', as: 'classroom' });
    Series.belongsToMany(models.Subject, { through: 'series_subjects', foreignKey: 'series_id', otherKey: 'subject_id', as: 'subjects' });
    Series.hasMany(models.Course, { foreignKey: 'series_id', as: 'courses' });
    Series.hasMany(models.Exercise, { foreignKey: 'series_id', as: 'exercises' });
  };

  return Series;
};
