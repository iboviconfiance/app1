const ExamRepository = require('../../infrastructure/repositories/ExamRepository');
const GradingService = require('../../application/services/GradingService');

const examRepo = new ExamRepository();
const gradingService = new GradingService();

class ExamController {
  async getAll(req, res, next) {
    try {
      const { type, subjectId } = req.query;
      const data = await examRepo.findAll({ type, subjectId });
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const exam = await examRepo.findById(req.params.id);
      if (!exam) return res.status(404).json({ success: false, message: 'Examen non trouvé' });

      const questions = await examRepo.getQuestions(req.params.id);
      res.json({ success: true, data: { ...exam, questions } });
    } catch (error) {
      next(error);
    }
  }

  async submit(req, res, next) {
    try {
      const { answers } = req.body;
      const result = await gradingService.submitExam(req.userId, req.params.id, answers);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ExamController();
