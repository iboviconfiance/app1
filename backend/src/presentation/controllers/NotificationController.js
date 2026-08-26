const NotificationRepository = require('../../infrastructure/repositories/NotificationRepository');

const notificationRepo = new NotificationRepository();

class NotificationController {
  async getNotifications(req, res, next) {
    try {
      const notifications = await notificationRepo.getByUser(req.userId);
      res.json({ success: true, data: notifications });
    } catch (error) {
      next(error);
    }
  }

  async markAllAsRead(req, res, next) {
    try {
      await notificationRepo.markAllAsRead(req.userId);
      res.json({ success: true, message: 'Toutes les notifications ont été marquées comme lues.' });
    } catch (error) {
      next(error);
    }
  }

  async markAsRead(req, res, next) {
    try {
      const { id } = req.params;
      const success = await notificationRepo.markAsRead(id, req.userId);
      if (!success) {
        return res.status(404).json({ success: false, message: 'Notification introuvable.' });
      }
      res.json({ success: true, message: 'Notification marquée comme lue.' });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new NotificationController();
