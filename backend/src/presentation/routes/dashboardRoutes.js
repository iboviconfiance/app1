const express = require('express');
const dashboardController = require('../controllers/DashboardController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', authMiddleware, dashboardController.getDashboard.bind(dashboardController));

module.exports = router;
