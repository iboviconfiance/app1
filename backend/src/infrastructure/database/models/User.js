'use strict';

module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    nom: { type: DataTypes.STRING(100), allowNull: false },
    prenom: { type: DataTypes.STRING(100), allowNull: false },
    telephone: { type: DataTypes.STRING(20), allowNull: false, unique: true },
    email: { type: DataTypes.STRING(255), allowNull: true, unique: true },
    password_hash: { type: DataTypes.STRING(255), allowNull: false },
    etablissement: DataTypes.STRING(255),
    classroom_id: DataTypes.UUID,
    series_id: DataTypes.UUID,
    reset_token: DataTypes.STRING(255),
    reset_token_expires: DataTypes.DATE,
    avatar_url: DataTypes.STRING(255),
  }, { tableName: 'users', underscored: true, timestamps: true });

  User.associate = (models) => {
    User.belongsTo(models.Classroom, { foreignKey: 'classroom_id', as: 'classroom' });
    User.belongsTo(models.Series, { foreignKey: 'series_id', as: 'series' });
    User.hasMany(models.Subscription, { foreignKey: 'user_id', as: 'subscriptions' });
    User.hasMany(models.Payment, { foreignKey: 'user_id', as: 'payments' });
    User.hasMany(models.WorkGroup, { foreignKey: 'created_by', as: 'createdGroups' });
    User.belongsToMany(models.WorkGroup, { through: models.WorkGroupMember, foreignKey: 'user_id', otherKey: 'work_group_id', as: 'workGroups' });
  };

  return User;
};
