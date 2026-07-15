const SchoolRepository = require('../../infrastructure/repositories/SchoolRepository');

const schoolRepo = new SchoolRepository();

class SchoolController {
  async getHierarchy(req, res, next) {
    try {
      const data = await schoolRepo.getHierarchy();
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async getClassrooms(req, res, next) {
    try {
      const { level } = req.query;
      const data = level
        ? await schoolRepo.getClassroomsByLevel(level)
        : await schoolRepo.getAllClassrooms();
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async getSeries(req, res, next) {
    try {
      const { classroomId } = req.query;
      const data = classroomId
        ? await schoolRepo.getSeriesByClassroom(classroomId)
        : await schoolRepo.getAllSeries();
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async getSubjects(req, res, next) {
    try {
      const { seriesId } = req.query;
      const data = seriesId
        ? await schoolRepo.getSubjectsBySeries(seriesId)
        : await schoolRepo.getAllSubjects();
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SchoolController();
