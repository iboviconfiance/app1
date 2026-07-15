const ExerciseRepository = require('../../infrastructure/repositories/ExerciseRepository');
const GradingService = require('../../application/services/GradingService');

const exerciseRepo = new ExerciseRepository();
const gradingService = new GradingService();

class ExerciseController {
  async getAll(req, res, next) {
    try {
      const { seriesId, subjectId, type } = req.query;
      const data = await exerciseRepo.findAll({ seriesId, subjectId, type });
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await exerciseRepo.findById(req.params.id, true);
      if (!data) return res.status(404).json({ success: false, message: 'Exercice non trouvé' });
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async submit(req, res, next) {
    try {
      const { answers } = req.body;
      const result = await gradingService.submitExercise(req.userId, req.params.id, answers);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  async getResults(req, res, next) {
    try {
      const data = await exerciseRepo.getResults(req.userId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ExerciseController();
