const pool = require('../database/pool');
const User = require('../../domain/entities/User');

class UserRepository {
  async findById(id) {
    const { rows } = await pool.query(
      `SELECT u.*, c.name as classroom_name, s.name as series_name
       FROM users u
       LEFT JOIN classrooms c ON u.classroom_id = c.id
       LEFT JOIN series s ON u.series_id = s.id
       WHERE u.id = $1`,
      [id]
    );
    return rows[0] ? { ...new User(rows[0]).toJSON(), classroomName: rows[0].classroom_name, seriesName: rows[0].series_name } : null;
  }

  async findByTelephone(telephone) {
    const { rows } = await pool.query('SELECT * FROM users WHERE telephone = $1', [telephone]);
    return rows[0] || null;
  }

  async findByEmail(email) {
    const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    return rows[0] || null;
  }

  async create({ nom, prenom, telephone, email, passwordHash, etablissement, classroomId, seriesId }) {
    const { rows } = await pool.query(
      `INSERT INTO users (nom, prenom, telephone, email, password_hash, etablissement, classroom_id, series_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [nom, prenom, telephone, email, passwordHash, etablissement, classroomId, seriesId]
    );
    return new User(rows[0]);
  }

  async updateResetToken(userId, token, expires) {
    await pool.query(
      'UPDATE users SET reset_token = $1, reset_token_expires = $2, updated_at = NOW() WHERE id = $3',
      [token, expires, userId]
    );
  }

  async findByResetToken(token) {
    const { rows } = await pool.query(
      'SELECT * FROM users WHERE reset_token = $1 AND reset_token_expires > NOW()',
      [token]
    );
    return rows[0] || null;
  }

  async updatePassword(userId, passwordHash) {
    await pool.query(
      'UPDATE users SET password_hash = $1, reset_token = NULL, reset_token_expires = NULL, updated_at = NOW() WHERE id = $2',
      [passwordHash, userId]
    );
  }

  async updateProfile(userId, { nom, prenom, etablissement, classroomId, seriesId, email, telephone, avatarUrl }) {
    const { rows } = await pool.query(
      `UPDATE users SET
         nom = COALESCE($1, nom),
         prenom = COALESCE($2, prenom),
         etablissement = COALESCE($3, etablissement),
         classroom_id = COALESCE($4, classroom_id),
         series_id = COALESCE($5, series_id),
         email = COALESCE($6, email),
         telephone = COALESCE($7, telephone),
         avatar_url = COALESCE($8, avatar_url),
         updated_at = NOW()
       WHERE id = $9 RETURNING *`,
      [nom, prenom, etablissement, classroomId, seriesId, email, telephone, avatarUrl, userId]
    );
    return rows[0] ? await this.findById(userId) : null;
  }

  async findPasswordHash(userId) {
    const { rows } = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
    return rows[0] ? rows[0].password_hash : null;
  }
}

module.exports = UserRepository;
