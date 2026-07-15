const pool = require('../database/pool');
const crypto = require('crypto');

class WorkGroupRepository {
  generateInviteCode() {
    return crypto.randomBytes(4).toString('hex').toUpperCase();
  }

  async create({ name, description, subjectId, seriesId, createdBy, maxMembers = 10 }) {
    const inviteCode = this.generateInviteCode();
    const { rows } = await pool.query(
      `INSERT INTO work_groups (name, description, subject_id, series_id, created_by, max_members, invite_code)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [name, description, subjectId, seriesId, createdBy, maxMembers, inviteCode]
    );
    await pool.query(
      `INSERT INTO work_group_members (work_group_id, user_id, role) VALUES ($1, $2, 'admin')`,
      [rows[0].id, createdBy]
    );
    return this.formatGroup(rows[0]);
  }

  formatGroup(row) {
    return {
      id: row.id,
      name: row.name,
      description: row.description,
      subjectId: row.subject_id,
      seriesId: row.series_id,
      createdBy: row.created_by,
      maxMembers: row.max_members,
      inviteCode: row.invite_code,
      createdAt: row.created_at,
    };
  }

  async findByUser(userId) {
    const { rows } = await pool.query(
      `SELECT wg.*, s.name as subject_name,
              (SELECT COUNT(*) FROM work_group_members wgm WHERE wgm.work_group_id = wg.id) as member_count
       FROM work_groups wg
       JOIN work_group_members wgm ON wg.id = wgm.work_group_id
       LEFT JOIN subjects s ON wg.subject_id = s.id
       WHERE wgm.user_id = $1
       ORDER BY wg.created_at DESC`,
      [userId]
    );
    return rows.map(r => ({ ...this.formatGroup(r), subjectName: r.subject_name, memberCount: parseInt(r.member_count, 10) }));
  }

  async findById(id) {
    const { rows } = await pool.query(
      `SELECT wg.*, s.name as subject_name FROM work_groups wg
       LEFT JOIN subjects s ON wg.subject_id = s.id WHERE wg.id = $1`,
      [id]
    );
    return rows[0] ? { ...this.formatGroup(rows[0]), subjectName: rows[0].subject_name } : null;
  }

  async getMembers(groupId) {
    const { rows } = await pool.query(
      `SELECT u.id, u.nom, u.prenom, u.telephone, wgm.role, wgm.joined_at
       FROM work_group_members wgm
       JOIN users u ON wgm.user_id = u.id
       WHERE wgm.work_group_id = $1 ORDER BY wgm.joined_at`,
      [groupId]
    );
    return rows.map(r => ({
      id: r.id,
      nom: r.nom,
      prenom: r.prenom,
      telephone: r.telephone,
      role: r.role,
      joinedAt: r.joined_at,
    }));
  }

  async joinByInviteCode(userId, inviteCode) {
    const { rows } = await pool.query('SELECT * FROM work_groups WHERE invite_code = $1', [inviteCode.toUpperCase()]);
    if (!rows[0]) throw new Error('Code d\'invitation invalide');

    const group = rows[0];
    const { rows: members } = await pool.query(
      'SELECT COUNT(*) FROM work_group_members WHERE work_group_id = $1',
      [group.id]
    );
    if (parseInt(members[0].count, 10) >= group.max_members) {
      throw new Error('Le groupe est complet');
    }

    const { rows: existing } = await pool.query(
      'SELECT * FROM work_group_members WHERE work_group_id = $1 AND user_id = $2',
      [group.id, userId]
    );
    if (existing.length > 0) throw new Error('Vous êtes déjà membre de ce groupe');

    await pool.query(
      `INSERT INTO work_group_members (work_group_id, user_id, role) VALUES ($1, $2, 'member')`,
      [group.id, userId]
    );

    return this.findById(group.id);
  }

  async leave(userId, groupId) {
    const { rows } = await pool.query(
      'SELECT role FROM work_group_members WHERE work_group_id = $1 AND user_id = $2',
      [groupId, userId]
    );
    if (!rows[0]) throw new Error('Vous n\'êtes pas membre de ce groupe');

    await pool.query('DELETE FROM work_group_members WHERE work_group_id = $1 AND user_id = $2', [groupId, userId]);

    const { rows: remaining } = await pool.query(
      'SELECT COUNT(*) FROM work_group_members WHERE work_group_id = $1',
      [groupId]
    );
    if (parseInt(remaining[0].count, 10) === 0) {
      await pool.query('DELETE FROM work_groups WHERE id = $1', [groupId]);
    }
  }
}

module.exports = WorkGroupRepository;
