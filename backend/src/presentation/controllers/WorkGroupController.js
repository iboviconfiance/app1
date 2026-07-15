const WorkGroupService = require('../../application/services/WorkGroupService');

const workGroupService = new WorkGroupService();

class WorkGroupController {
  async list(req, res, next) {
    try {
      const data = await workGroupService.getUserGroups(req.userId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async create(req, res, next) {
    try {
      const { name, description, subjectId, seriesId, maxMembers } = req.body;
      const data = await workGroupService.createGroup(req.userId, {
        name, description, subjectId, seriesId, maxMembers,
      });
      res.status(201).json({ success: true, data });
    } catch (error) {
      error.status = 400;
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await workGroupService.getGroupDetails(req.params.id);
      res.json({ success: true, data });
    } catch (error) {
      error.status = 404;
      next(error);
    }
  }

  async join(req, res, next) {
    try {
      const { inviteCode } = req.body;
      const data = await workGroupService.joinGroup(req.userId, inviteCode);
      res.json({ success: true, data });
    } catch (error) {
      error.status = 400;
      next(error);
    }
  }

  async leave(req, res, next) {
    try {
      await workGroupService.leaveGroup(req.userId, req.params.id);
      res.json({ success: true, message: 'Vous avez quitté le groupe' });
    } catch (error) {
      error.status = 400;
      next(error);
    }
  }
}

module.exports = new WorkGroupController();
