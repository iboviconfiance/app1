const WorkGroupRepository = require('../../infrastructure/repositories/WorkGroupRepository');

class WorkGroupService {
  constructor() {
    this.repo = new WorkGroupRepository();
  }

  async createGroup(userId, data) {
    return this.repo.create({ ...data, createdBy: userId });
  }

  async getUserGroups(userId) {
    return this.repo.findByUser(userId);
  }

  async getGroupDetails(groupId) {
    const group = await this.repo.findById(groupId);
    if (!group) throw new Error('Groupe non trouvé');
    const members = await this.repo.getMembers(groupId);
    return { ...group, members };
  }

  async joinGroup(userId, inviteCode) {
    return this.repo.joinByInviteCode(userId, inviteCode);
  }

  async leaveGroup(userId, groupId) {
    return this.repo.leave(userId, groupId);
  }
}

module.exports = WorkGroupService;
