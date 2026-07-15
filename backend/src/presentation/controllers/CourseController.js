const CourseRepository = require('../../infrastructure/repositories/CourseRepository');

const courseRepo = new CourseRepository();

class CourseController {
  async getAll(req, res, next) {
    try {
      const { seriesId, subjectId, type } = req.query;
      const data = await courseRepo.findAll({ seriesId, subjectId, type });
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await courseRepo.findById(req.params.id);
      if (!data) return res.status(404).json({ success: false, message: 'Cours non trouvé' });
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async getFavorites(req, res, next) {
    try {
      const data = await courseRepo.getFavorites(req.userId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async addFavorite(req, res, next) {
    try {
      await courseRepo.addFavorite(req.userId, req.params.id);
      res.json({ success: true, message: 'Ajouté aux favoris' });
    } catch (error) {
      next(error);
    }
  }

  async removeFavorite(req, res, next) {
    try {
      await courseRepo.removeFavorite(req.userId, req.params.id);
      res.json({ success: true, message: 'Retiré des favoris' });
    } catch (error) {
      next(error);
    }
  }

  async getHistory(req, res, next) {
    try {
      const data = await courseRepo.getHistory(req.userId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async updateProgress(req, res, next) {
    try {
      const { progressPercent, lastPosition } = req.body;
      await courseRepo.addToHistory(req.userId, req.params.id, progressPercent, lastPosition);
      res.json({ success: true, message: 'Progression enregistrée' });
    } catch (error) {
      next(error);
    }
  }

  async download(req, res, next) {
    try {
      const course = await courseRepo.findById(req.params.id);
      if (!course) return res.status(404).json({ success: false, message: 'Cours non trouvé' });
      await courseRepo.incrementDownload(req.params.id);
      res.json({ success: true, data: { fileUrl: course.fileUrl, downloadCount: course.downloadCount + 1 } });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CourseController();
