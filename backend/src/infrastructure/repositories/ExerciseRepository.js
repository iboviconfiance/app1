const pool = require('../database/pool');
const Exercise = require('../../domain/entities/Exercise');

class ExerciseRepository {
  async findAll({ seriesId, subjectId, type, limit = 50 } = {}) {
    let query = `
      SELECT e.*, s.name as subject_name FROM exercises e
      JOIN subjects s ON e.subject_id = s.id WHERE 1=1`;
    const params = [];
    let idx = 1;

    if (seriesId) { query += ` AND e.series_id = $${idx++}`; params.push(seriesId); }
    if (subjectId) { query += ` AND e.subject_id = $${idx++}`; params.push(subjectId); }
    if (type) { query += ` AND e.type = $${idx++}`; params.push(type); }

    query += ` ORDER BY e.created_at DESC LIMIT $${idx}`;
    params.push(limit);

    const { rows } = await pool.query(query, params);
    return rows.map(r => new Exercise(r).toJSON());
  }

  async findById(id, includeQuestions = false) {
    const { rows } = await pool.query(
      `SELECT e.*, s.name as subject_name FROM exercises e
       JOIN subjects s ON e.subject_id = s.id WHERE e.id = $1`,
      [id]
    );
    if (!rows[0]) return null;

    const exercise = new Exercise(rows[0]);
    if (includeQuestions) {
      const { rows: questions } = await pool.query(
        'SELECT id, question_text, options, order_index, points FROM exercise_questions WHERE exercise_id = $1 ORDER BY order_index',
        [id]
      );
      exercise.questions = questions.map(q => ({
        ...q,
        options: typeof q.options === 'string' ? JSON.parse(q.options) : q.options,
      }));
    }
    return exercise.toJSON(includeQuestions);
  }

  async getQuestions(exerciseId) {
    const { rows } = await pool.query(
      'SELECT * FROM exercise_questions WHERE exercise_id = $1 ORDER BY order_index',
      [exerciseId]
    );
    return rows.map(q => ({
      id: q.id,
      questionText: q.question_text,
      options: typeof q.options === 'string' ? JSON.parse(q.options) : q.options,
      correctAnswer: q.correct_answer,
      points: q.points,
      explanation: q.explanation,
      orderIndex: q.order_index,
    }));
  }

  async saveResult(userId, exerciseId, score, totalPoints, answers) {
    const { rows } = await pool.query(
      `INSERT INTO exercise_results (user_id, exercise_id, score, total_points, answers)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, exerciseId, score, totalPoints, JSON.stringify(answers)]
    );
    return rows[0];
  }

  async getRecent(userId, limit = 5) {
    const { rows } = await pool.query(
      `SELECT e.*, s.name as subject_name, er.score, er.total_points, er.completed_at
       FROM exercise_results er
       JOIN exercises e ON er.exercise_id = e.id
       JOIN subjects s ON e.subject_id = s.id
       WHERE er.user_id = $1
       ORDER BY er.completed_at DESC LIMIT $2`,
      [userId, limit]
    );
    return rows.map(r => ({
      ...new Exercise(r).toJSON(),
      score: r.score,
      totalPoints: r.total_points,
      completedAt: r.completed_at,
    }));
  }

  async getResults(userId) {
    const { rows } = await pool.query(
      `SELECT e.title, e.type, s.name as subject_name, er.score, er.total_points, er.completed_at
       FROM exercise_results er
       JOIN exercises e ON er.exercise_id = e.id
       JOIN subjects s ON e.subject_id = s.id
       WHERE er.user_id = $1 ORDER BY er.completed_at DESC`,
      [userId]
    );
    return rows;
  }
}

module.exports = ExerciseRepository;
