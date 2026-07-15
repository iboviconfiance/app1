const express = require('express');
const workGroupController = require('../controllers/WorkGroupController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/', workGroupController.list.bind(workGroupController));
router.post('/', workGroupController.create.bind(workGroupController));
router.post('/join', workGroupController.join.bind(workGroupController));
router.get('/:id', workGroupController.getById.bind(workGroupController));
router.delete('/:id/leave', workGroupController.leave.bind(workGroupController));

module.exports = router;
