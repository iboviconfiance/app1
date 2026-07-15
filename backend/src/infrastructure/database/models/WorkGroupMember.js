'use strict';

module.exports = (sequelize, DataTypes) => {
  const WorkGroupMember = sequelize.define('WorkGroupMember', {
    work_group_id: { type: DataTypes.UUID, primaryKey: true },
    user_id: { type: DataTypes.UUID, primaryKey: true },
    role: { type: DataTypes.ENUM('admin', 'member'), allowNull: false, defaultValue: 'member' },
    joined_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  }, { tableName: 'work_group_members', underscored: true, timestamps: false });

  WorkGroupMember.associate = (models) => {
    WorkGroupMember.belongsTo(models.WorkGroup, { foreignKey: 'work_group_id', as: 'workGroup' });
    WorkGroupMember.belongsTo(models.User, { foreignKey: 'user_id', as: 'user' });
  };

  return WorkGroupMember;
};
