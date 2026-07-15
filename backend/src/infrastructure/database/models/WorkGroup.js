'use strict';

module.exports = (sequelize, DataTypes) => {
  const WorkGroup = sequelize.define('WorkGroup', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    name: { type: DataTypes.STRING(255), allowNull: false },
    description: DataTypes.TEXT,
    subject_id: DataTypes.UUID,
    series_id: DataTypes.UUID,
    created_by: { type: DataTypes.UUID, allowNull: false },
    max_members: { type: DataTypes.INTEGER, defaultValue: 10 },
    invite_code: { type: DataTypes.STRING(20), unique: true },
  }, { tableName: 'work_groups', underscored: true });

  WorkGroup.associate = (models) => {
    WorkGroup.belongsTo(models.User, { foreignKey: 'created_by', as: 'creator' });
    WorkGroup.belongsTo(models.Subject, { foreignKey: 'subject_id', as: 'subject' });
    WorkGroup.belongsTo(models.Series, { foreignKey: 'series_id', as: 'series' });
    WorkGroup.belongsToMany(models.User, { through: models.WorkGroupMember, foreignKey: 'work_group_id', otherKey: 'user_id', as: 'members' });
  };

  return WorkGroup;
};
