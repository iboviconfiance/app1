const express = require('express');
const exerciseController = require('../controllers/ExerciseController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', exerciseController.getAll.bind(exerciseController));
router.get('/results', authMiddleware, exerciseController.getResults.bind(exerciseController));
router.get('/:id', exerciseController.getById.bind(exerciseController));
router.post('/:id/submit', authMiddleware, exerciseController.submit.bind(exerciseController));

module.exports = router;
