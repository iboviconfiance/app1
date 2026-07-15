const express = require('express');
const courseController = require('../controllers/CourseController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', courseController.getAll.bind(courseController));
router.get('/favorites', authMiddleware, courseController.getFavorites.bind(courseController));
router.get('/history', authMiddleware, courseController.getHistory.bind(courseController));
router.get('/:id', courseController.getById.bind(courseController));
router.post('/:id/favorite', authMiddleware, courseController.addFavorite.bind(courseController));
router.delete('/:id/favorite', authMiddleware, courseController.removeFavorite.bind(courseController));
router.post('/:id/progress', authMiddleware, courseController.updateProgress.bind(courseController));
router.get('/:id/download', authMiddleware, courseController.download.bind(courseController));

module.exports = router;
