const { body } = require('express-validator');
const AuthService = require('../../application/services/AuthService');

const authService = new AuthService();

const registerValidation = [
  body('nom').trim().notEmpty().withMessage('Le nom est requis'),
  body('prenom').trim().notEmpty().withMessage('Le prénom est requis'),
  body('telephone').trim().notEmpty().withMessage('Le téléphone est requis'),
  body('email').trim().isEmail().withMessage('Une adresse email valide est requise'),
  body('password').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  body('classroomId').optional().isUUID(),
  body('seriesId').optional().isUUID(),
];

const loginValidation = [
  body('password').notEmpty(),
  body().custom(body => {
    if (!body.telephone && !body.identifier) {
      throw new Error('Le téléphone ou l\'adresse email est requis');
    }
    return true;
  })
];

class AuthController {
  async register(req, res, next) {
    try {
      const result = await authService.register(req.body);
      res.status(201).json({ success: true, data: result });
    } catch (error) {
      error.status = 400;
      next(error);
    }
  }

  async login(req, res, next) {
    try {
      const { telephone, identifier, password } = req.body;
      const loginVal = identifier || telephone;
      const result = await authService.login(loginVal, password);
      res.json({ success: true, data: result });
    } catch (error) {
      error.status = 401;
      next(error);
    }
  }

  async forgotPassword(req, res, next) {
    try {
      const { telephone, identifier } = req.body;
      const resetVal = identifier || telephone;
      const result = await authService.forgotPassword(resetVal);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  async resetPassword(req, res, next) {
    try {
      const { token, password } = req.body;
      const result = await authService.resetPassword(token, password);
      res.json({ success: true, data: result });
    } catch (error) {
      error.status = 400;
      next(error);
    }
  }
}

module.exports = { AuthController: new AuthController(), registerValidation, loginValidation };
