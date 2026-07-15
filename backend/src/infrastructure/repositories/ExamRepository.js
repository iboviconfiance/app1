const pool = require('../database/pool');
const Exam = require('../../domain/entities/Exam');

class ExamRepository {
  async findAll({ type, subjectId, limit = 50 } = {}) {
    let query = `
      SELECT e.*, s.name as subject_name FROM exams e
       LEFT JOIN subjects s ON e.subject_id = s.id WHERE 1=1`;
    const params = [];
    let idx = 1;

    if (type) { query += ` AND e.type = $${idx++}`; params.push(type); }
    if (subjectId) { query += ` AND e.subject_id = $${idx++}`; params.push(subjectId); }

    query += ` ORDER BY e.year DESC, e.created_at DESC LIMIT $${idx}`;
    params.push(limit);

    const { rows } = await pool.query(query, params);
    return rows.map(r => new Exam(r).toJSON());
  }

  async findById(id) {
    const { rows } = await pool.query(
      `SELECT e.*, s.name as subject_name FROM exams e
       LEFT JOIN subjects s ON e.subject_id = s.id WHERE e.id = $1`,
      [id]
    );
    return rows[0] ? new Exam(rows[0]).toJSON() : null;
  }

  async getQuestions(examId) {
    const { rows } = await pool.query(
      'SELECT id, question_text, options, order_index, points FROM exam_questions WHERE exam_id = $1 ORDER BY order_index',
      [examId]
    );
    return rows.map(q => ({
      id: q.id,
      questionText: q.question_text,
      options: typeof q.options === 'string' ? JSON.parse(q.options) : q.options,
      orderIndex: q.order_index,
      points: q.points,
    }));
  }

  async getQuestionsWithAnswers(examId) {
    const { rows } = await pool.query(
      'SELECT * FROM exam_questions WHERE exam_id = $1 ORDER BY order_index',
      [examId]
    );
    return rows.map(q => ({
      id: q.id,
      questionText: q.question_text,
      options: typeof q.options === 'string' ? JSON.parse(q.options) : q.options,
      correctAnswer: q.correct_answer,
      explanation: q.explanation,
      points: q.points,
    }));
  }

  async saveResult(userId, examId, score, totalPoints, answers) {
    const { rows } = await pool.query(
      `INSERT INTO exam_results (user_id, exam_id, score, total_points, answers)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, examId, score, totalPoints, JSON.stringify(answers)]
    );
    return rows[0];
  }
}

module.exports = ExamRepository;
