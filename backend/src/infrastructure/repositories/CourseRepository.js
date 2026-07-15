const pool = require('../database/pool');
const Course = require('../../domain/entities/Course');

class CourseRepository {
  async findAll({ seriesId, subjectId, type, limit = 50, offset = 0 } = {}) {
    let query = `
      SELECT c.*, s.name as subject_name FROM courses c
      JOIN subjects s ON c.subject_id = s.id WHERE 1=1`;
    const params = [];
    let idx = 1;

    if (seriesId) { query += ` AND c.series_id = $${idx++}`; params.push(seriesId); }
    if (subjectId) { query += ` AND c.subject_id = $${idx++}`; params.push(subjectId); }
    if (type) { query += ` AND c.type = $${idx++}`; params.push(type); }

    query += ` ORDER BY c.created_at DESC LIMIT $${idx++} OFFSET $${idx}`;
    params.push(limit, offset);

    const { rows } = await pool.query(query, params);
    return rows.map(r => new Course(r).toJSON());
  }

  async findById(id) {
    const { rows } = await pool.query(
      `SELECT c.*, s.name as subject_name FROM courses c
       JOIN subjects s ON c.subject_id = s.id WHERE c.id = $1`,
      [id]
    );
    return rows[0] ? new Course(rows[0]).toJSON() : null;
  }

  async getRecent(userId, limit = 5) {
    const { rows } = await pool.query(
      `SELECT c.*, s.name as subject_name, ch.progress_percent, ch.viewed_at
       FROM course_history ch
       JOIN courses c ON ch.course_id = c.id
       JOIN subjects s ON c.subject_id = s.id
       WHERE ch.user_id = $1
       ORDER BY ch.viewed_at DESC LIMIT $2`,
      [userId, limit]
    );
    return rows.map(r => ({ ...new Course(r).toJSON(), progressPercent: r.progress_percent, viewedAt: r.viewed_at }));
  }

  async addToHistory(userId, courseId, progressPercent = 0, lastPosition = 0) {
    await pool.query(
      `INSERT INTO course_history (user_id, course_id, progress_percent, last_position, viewed_at)
       VALUES ($1, $2, $3, $4, NOW())
       ON CONFLICT (user_id, course_id) DO UPDATE SET
         progress_percent = $3, last_position = $4, viewed_at = NOW(),
         completed = CASE WHEN $3 >= 100 THEN TRUE ELSE course_history.completed END`,
      [userId, courseId, progressPercent, lastPosition]
    );
  }

  async getHistory(userId) {
    const { rows } = await pool.query(
      `SELECT c.*, s.name as subject_name, ch.progress_percent, ch.completed, ch.viewed_at
       FROM course_history ch
       JOIN courses c ON ch.course_id = c.id
       JOIN subjects s ON c.subject_id = s.id
       WHERE ch.user_id = $1 ORDER BY ch.viewed_at DESC`,
      [userId]
    );
    return rows.map(r => ({
      ...new Course(r).toJSON(),
      progressPercent: r.progress_percent,
      completed: r.completed,
      viewedAt: r.viewed_at,
    }));
  }

  async addFavorite(userId, courseId) {
    await pool.query(
      'INSERT INTO course_favorites (user_id, course_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [userId, courseId]
    );
  }

  async removeFavorite(userId, courseId) {
    await pool.query('DELETE FROM course_favorites WHERE user_id = $1 AND course_id = $2', [userId, courseId]);
  }

  async getFavorites(userId) {
    const { rows } = await pool.query(
      `SELECT c.*, s.name as subject_name FROM course_favorites cf
       JOIN courses c ON cf.course_id = c.id
       JOIN subjects s ON c.subject_id = s.id
       WHERE cf.user_id = $1 ORDER BY cf.created_at DESC`,
      [userId]
    );
    return rows.map(r => new Course(r).toJSON());
  }

  async incrementDownload(courseId) {
    await pool.query('UPDATE courses SET download_count = download_count + 1 WHERE id = $1', [courseId]);
  }
}

module.exports = CourseRepository;
