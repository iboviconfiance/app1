const UserRepository = require('../../infrastructure/repositories/UserRepository');
const userRepo = new UserRepository();

async function adminMiddleware(req, res, next) {
  if (!req.userId) {
    return res.status(401).json({ success: false, message: 'Non authentifié' });
  }

  try {
    const user = await userRepo.findById(req.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });
    }

    if (user.role !== 'admin' && user.role !== 'teacher') {
      return res.status(403).json({ success: false, message: 'Accès interdit : privilèges insuffisants' });
    }

    req.user = user; // attacher l'utilisateur à la requête
    next();
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Erreur lors de la vérification des permissions' });
  }
}

module.exports = adminMiddleware;
