const pool = require('../database/pool');

class NotificationRepository {
  async getByUser(userId) {
    const { rows } = await pool.query(
      `SELECT * FROM notifications 
       WHERE user_id = $1 
       ORDER BY created_at DESC`,
      [userId]
    );
    return rows.map(r => ({
      id: r.id,
      userId: r.user_id,
      title: r.title,
      message: r.message,
      type: r.type,
      actionRoute: r.action_route,
      isRead: r.is_read,
      createdAt: r.created_at,
    }));
  }

  async markAllAsRead(userId) {
    const { rows } = await pool.query(
      `UPDATE notifications 
       SET is_read = TRUE, updated_at = NOW() 
       WHERE user_id = $1 
       RETURNING *`,
      [userId]
    );
    return rows.length;
  }

  async markAsRead(notificationId, userId) {
    const { rows } = await pool.query(
      `UPDATE notifications 
       SET is_read = TRUE, updated_at = NOW() 
       WHERE id = $1 AND user_id = $2 
       RETURNING *`,
      [notificationId, userId]
    );
    return rows[0] ? true : false;
  }
}

module.exports = NotificationRepository;
