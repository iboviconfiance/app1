'use strict';

module.exports = (sequelize, DataTypes) => {
  const Classroom = sequelize.define('Classroom', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    name: { type: DataTypes.STRING(50), allowNull: false },
    level: { type: DataTypes.ENUM('college', 'lycee_general', 'lycee_technique'), allowNull: false },
    order_index: { type: DataTypes.INTEGER, allowNull: false },
  }, { tableName: 'classrooms', underscored: true, timestamps: true, createdAt: 'created_at', updatedAt: false });

  Classroom.associate = (models) => {
    Classroom.hasMany(models.Series, { foreignKey: 'classroom_id', as: 'series' });
    Classroom.hasMany(models.User, { foreignKey: 'classroom_id', as: 'users' });
  };

  return Classroom;
};
