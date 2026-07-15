const ExerciseRepository = require('../../infrastructure/repositories/ExerciseRepository');
const ExamRepository = require('../../infrastructure/repositories/ExamRepository');

class GradingService {
  constructor() {
    this.exerciseRepo = new ExerciseRepository();
    this.examRepo = new ExamRepository();
  }

  gradeAnswers(questions, userAnswers) {
    let score = 0;
    let totalPoints = 0;
    const corrections = [];

    for (const question of questions) {
      totalPoints += question.points;
      const userAnswer = userAnswers[question.id];
      const isCorrect = userAnswer === question.correctAnswer;

      if (isCorrect) score += question.points;

      corrections.push({
        questionId: question.id,
        questionText: question.questionText || question.question_text,
        userAnswer,
        correctAnswer: question.correctAnswer ?? question.correct_answer,
        isCorrect,
        points: isCorrect ? question.points : 0,
        explanation: question.explanation,
      });
    }

    return { score, totalPoints, corrections, percentage: totalPoints > 0 ? Math.round((score / totalPoints) * 100) : 0 };
  }

  async submitExercise(userId, exerciseId, answers) {
    const questions = await this.exerciseRepo.getQuestions(exerciseId);
    const { score, totalPoints, corrections, percentage } = this.gradeAnswers(questions, answers);

    await this.exerciseRepo.saveResult(userId, exerciseId, score, totalPoints, answers);

    return { score, totalPoints, percentage, corrections };
  }

  async submitExam(userId, examId, answers) {
    const questions = await this.examRepo.getQuestionsWithAnswers(examId);
    const { score, totalPoints, corrections, percentage } = this.gradeAnswers(questions, answers);

    await this.examRepo.saveResult(userId, examId, score, totalPoints, answers);

    return { score, totalPoints, percentage, corrections };
  }
}

module.exports = GradingService;
