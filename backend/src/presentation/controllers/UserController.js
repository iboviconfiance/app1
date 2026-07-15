const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const UserRepository = require('../../infrastructure/repositories/UserRepository');
const SubscriptionRepository = require('../../infrastructure/repositories/SubscriptionRepository');
const ExerciseRepository = require('../../infrastructure/repositories/ExerciseRepository');
const CourseRepository = require('../../infrastructure/repositories/CourseRepository');

const userRepo = new UserRepository();
const subscriptionRepo = new SubscriptionRepository();
const exerciseRepo = new ExerciseRepository();
const courseRepo = new CourseRepository();

class UserController {
  async getProfile(req, res, next) {
    try {
      const data = await userRepo.findById(req.userId);
      if (!data) return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });

      // Fetch active subscription
      const subscription = await subscriptionRepo.getActiveByUser(req.userId);

      // Fetch statistics
      const exerciseResults = await exerciseRepo.getResults(req.userId);
      const totalExercises = exerciseResults.length;
      const avgScore = totalExercises > 0
        ? Math.round(exerciseResults.reduce((sum, r) => sum + (r.score / r.total_points) * 100, 0) / totalExercises)
        : 0;

      const history = await courseRepo.getHistory(req.userId);
      const completedCourses = history.filter(h => h.completed).length;

      const stats = {
        totalExercises,
        avgScore,
        completedCourses
      };

      res.json({
        success: true,
        data: {
          ...data,
          subscription,
          stats
        }
      });
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const user = await userRepo.findById(req.userId);
      if (!user) {
        return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
      }

      // Check if security-sensitive fields are being changed
      const changingEmail = req.body.email && req.body.email !== user.email;
      const changingPhone = req.body.telephone && req.body.telephone !== user.telephone;
      const changingPassword = req.body.newPassword && req.body.newPassword.trim().length > 0;

      if (changingEmail || changingPhone || changingPassword) {
        const { currentPassword } = req.body;
        if (!currentPassword) {
          return res.status(400).json({
            success: false,
            message: 'Le mot de passe actuel est requis pour modifier ces informations de sécurité.'
          });
        }

        const passwordHash = await userRepo.findPasswordHash(req.userId);
        if (!passwordHash) {
          return res.status(500).json({ success: false, message: 'Erreur interne d\'authentification' });
        }

        const isMatch = await bcrypt.compare(currentPassword, passwordHash);
        if (!isMatch) {
          return res.status(401).json({
            success: false,
            message: 'Mot de passe actuel incorrect.'
          });
        }
      }

      // Handle base64 avatar decoding and saving to file
      let avatarUrl = undefined;
      if (req.body.avatar) {
        const base64Data = req.body.avatar.replace(/^data:image\/\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');

        const dirPath = path.join(__dirname, '../../../uploads/avatars');
        if (!fs.existsSync(dirPath)) {
          fs.mkdirSync(dirPath, { recursive: true });
        }

        // Delete old avatar file if it exists to clean up disk space
        if (user.avatarUrl && user.avatarUrl.startsWith('/uploads/avatars/')) {
          try {
            const oldFilename = path.basename(user.avatarUrl);
            const oldFilePath = path.join(dirPath, oldFilename);
            if (fs.existsSync(oldFilePath)) {
              fs.unlinkSync(oldFilePath);
            }
          } catch (unlinkErr) {
            console.error('Failed to delete old avatar:', unlinkErr);
          }
        }

        // Cache busting using timestamp in the filename
        const filename = `${req.userId}-${Date.now()}.png`;
        const filePath = path.join(dirPath, filename);
        fs.writeFileSync(filePath, buffer);

        avatarUrl = `/uploads/avatars/${filename}`;
      }

      // If password is changing, hash it and update it
      if (changingPassword) {
        const salt = await bcrypt.genSalt(10);
        const newPasswordHash = await bcrypt.hash(req.body.newPassword, salt);
        await userRepo.updatePassword(req.userId, newPasswordHash);
      }

      const data = await userRepo.updateProfile(req.userId, {
        ...req.body,
        avatarUrl
      });

      res.json({ success: true, data });
    } catch (error) {
      if (error.code === '23505' || (error.message && error.message.includes('unique constraint'))) {
        return res.status(400).json({
          success: false,
          message: 'Ce numéro de téléphone ou cette adresse email est déjà utilisé.'
        });
      }
      next(error);
    }
  }
}

module.exports = new UserController();

