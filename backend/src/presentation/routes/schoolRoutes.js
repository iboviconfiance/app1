const express = require('express');
const schoolController = require('../controllers/SchoolController');

const router = express.Router();

router.get('/hierarchy', schoolController.getHierarchy.bind(schoolController));
router.get('/classrooms', schoolController.getClassrooms.bind(schoolController));
router.get('/series', schoolController.getSeries.bind(schoolController));
router.get('/subjects', schoolController.getSubjects.bind(schoolController));

module.exports = router;
