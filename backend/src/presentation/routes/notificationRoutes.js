const express = require('express');
const notificationController = require('../controllers/NotificationController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', authMiddleware, notificationController.getNotifications.bind(notificationController));
router.post('/read-all', authMiddleware, notificationController.markAllAsRead.bind(notificationController));
router.post('/:id/read', authMiddleware, notificationController.markAsRead.bind(notificationController));

module.exports = router;
