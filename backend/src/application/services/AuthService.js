const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const config = require('../../config');
const UserRepository = require('../../infrastructure/repositories/UserRepository');
const SubscriptionRepository = require('../../infrastructure/repositories/SubscriptionRepository');

class AuthService {
  constructor() {
    this.userRepo = new UserRepository();
    this.subscriptionRepo = new SubscriptionRepository();
  }

  generateToken(userId) {
    return jwt.sign({ userId }, config.jwt.secret, { expiresIn: config.jwt.expiresIn });
  }

  async register({ nom, prenom, telephone, email, password, etablissement, classroomId, seriesId }) {
    const existing = await this.userRepo.findByTelephone(telephone);
    if (existing) {
      throw new Error('Ce numéro de téléphone est déjà utilisé');
    }

    if (email) {
      const existingEmail = await this.userRepo.findByEmail(email);
      if (existingEmail) {
        throw new Error('Cette adresse email est déjà utilisée');
      }
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await this.userRepo.create({
      nom, prenom, telephone, email, passwordHash, etablissement, classroomId, seriesId,
    });

    await this.subscriptionRepo.create(user.id, 'gratuit');

    const token = this.generateToken(user.id);
    const userData = await this.userRepo.findById(user.id);

    return { token, user: userData };
  }

  async login(identifier, password) {
    let user;
    if (identifier.includes('@')) {
      user = await this.userRepo.findByEmail(identifier);
    } else {
      user = await this.userRepo.findByTelephone(identifier);
    }

    if (!user) {
      throw new Error('Identifiants incorrects');
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      throw new Error('Identifiants incorrects');
    }

    const token = this.generateToken(user.id);
    const userData = await this.userRepo.findById(user.id);

    return { token, user: userData };
  }

  async forgotPassword(identifier) {
    let user;
    if (identifier.includes('@')) {
      user = await this.userRepo.findByEmail(identifier);
    } else {
      user = await this.userRepo.findByTelephone(identifier);
    }

    if (!user) {
      return { message: 'Si ce compte existe, un lien de réinitialisation a été envoyé' };
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    const expires = new Date(Date.now() + 3600000);

    await this.userRepo.updateResetToken(user.id, resetToken, expires);

    return {
      message: 'Si ce compte existe, un lien de réinitialisation a été envoyé',
      resetToken,
    };
  }

  async resetPassword(token, newPassword) {
    const user = await this.userRepo.findByResetToken(token);
    if (!user) {
      throw new Error('Token invalide ou expiré');
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await this.userRepo.updatePassword(user.id, passwordHash);

    return { message: 'Mot de passe réinitialisé avec succès' };
  }
}

module.exports = AuthService;
