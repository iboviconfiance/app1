const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');
const AdminController = require('../controllers/AdminController');

// Toutes les routes d'administration nécessitent d'être connecté ET d'être admin/enseignant
router.use(authMiddleware);
router.use(adminMiddleware);

// Statistiques générales
router.get('/stats', AdminController.getStats);

// CRUD Matières (Subjects)
router.get('/subjects', AdminController.getSubjects);
router.post('/subjects', AdminController.createSubject);
router.put('/subjects/:id', AdminController.updateSubject);
router.delete('/subjects/:id', AdminController.deleteSubject);

// CRUD Cours (Courses)
router.get('/courses', AdminController.getCourses);
router.post('/courses', AdminController.createCourse);
router.put('/courses/:id', AdminController.updateCourse);
router.delete('/courses/:id', AdminController.deleteCourse);

// CRUD Exercices (Exercises)
router.get('/exercises', AdminController.getExercises);
router.post('/exercises', AdminController.createExercise);
router.put('/exercises/:id', AdminController.updateExercise);
router.delete('/exercises/:id', AdminController.deleteExercise);

// CRUD Questions d'exercices
router.get('/exercises/:id/questions', AdminController.getQuestions);
router.post('/exercises/:id/questions', AdminController.createQuestion);
router.put('/questions/:questionId', AdminController.updateQuestion);
router.delete('/questions/:questionId', AdminController.deleteQuestion);

// CRUD Utilisateurs
router.get('/users', AdminController.getUsers);
router.put('/users/:id/role', AdminController.updateUserRole);

module.exports = router;
