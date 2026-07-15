const express = require('express');
const examController = require('../controllers/ExamController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', examController.getAll.bind(examController));
router.get('/:id', examController.getById.bind(examController));
router.post('/:id/submit', authMiddleware, examController.submit.bind(examController));

module.exports = router;
