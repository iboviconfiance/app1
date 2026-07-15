const express = require('express');
const configController = require('../controllers/ConfigController');

const router = express.Router();

router.get('/', configController.getConfig.bind(configController));

module.exports = router;
