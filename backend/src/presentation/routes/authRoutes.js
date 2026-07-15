const express = require('express');
const { AuthController, registerValidation, loginValidation } = require('../controllers/AuthController');
const validate = require('../middleware/validate');

const router = express.Router();

router.post('/register', registerValidation, validate, AuthController.register.bind(AuthController));
router.post('/login', loginValidation, validate, AuthController.login.bind(AuthController));
router.post('/forgot-password', AuthController.forgotPassword.bind(AuthController));
router.post('/reset-password', AuthController.resetPassword.bind(AuthController));

module.exports = router;
