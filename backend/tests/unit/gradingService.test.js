const GradingService = require('../../src/application/services/GradingService');

describe('GradingService', () => {
  const gradingService = new GradingService();

  const questions = [
    { id: 'q1', questionText: 'Q1', correctAnswer: 0, points: 10 },
    { id: 'q2', questionText: 'Q2', correctAnswer: 2, points: 10 },
    { id: 'q3', questionText: 'Q3', correctAnswer: 1, points: 10 },
  ];

  test('gradeAnswers calcule le score correctement', () => {
    const answers = { q1: 0, q2: 2, q3: 0 };
    const result = gradingService.gradeAnswers(questions, answers);

    expect(result.score).toBe(20);
    expect(result.totalPoints).toBe(30);
    expect(result.percentage).toBe(67);
    expect(result.corrections).toHaveLength(3);
    expect(result.corrections[0].isCorrect).toBe(true);
    expect(result.corrections[2].isCorrect).toBe(false);
  });

  test('gradeAnswers retourne 0% sans réponses', () => {
    const result = gradingService.gradeAnswers(questions, {});
    expect(result.score).toBe(0);
    expect(result.percentage).toBe(0);
  });
});
