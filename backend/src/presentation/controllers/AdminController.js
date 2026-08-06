const pool = require('../../infrastructure/database/pool');
const path = require('path');
const fs = require('fs');
const AnalyticsRepository = require('../../infrastructure/repositories/AnalyticsRepository');

const analyticsRepo = new AnalyticsRepository();

// Helper: supprimer un fichier physique depuis son URL publique (ex: /uploads/courses/pdf-uuid.pdf)
function deleteFileByUrl(fileUrl) {
  if (!fileUrl) return;
  try {
    // fileUrl ressemble à "/uploads/courses/pdf-abc.pdf"
    const relativePath = fileUrl.startsWith('/') ? fileUrl.slice(1) : fileUrl;
    const absolutePath = path.join(__dirname, '../../../../', relativePath);
    if (fs.existsSync(absolutePath)) {
      fs.unlinkSync(absolutePath);
    }
  } catch (err) {
    console.warn('[AdminController] Impossible de supprimer le fichier:', err.message);
  }
}

class AdminController {
  // ──────────────────────────────────────────────────────────────────────────
  // 0. UPLOAD DE FICHIER
  // ──────────────────────────────────────────────────────────────────────────

  /**
   * POST /api/admin/upload?fileType=pdf|video|image|exam
   * Reçoit un fichier via multer (req.file) et renvoie son URL publique.
   */
  async uploadFile(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, message: 'Aucun fichier reçu.' });
      }

      // Construire l'URL publique relative (servie par Nginx)
      const subdir = req.file.destination.split('uploads/')[1] || 'courses';
      const publicUrl = `/uploads/${subdir}/${req.file.filename}`;

      return res.status(201).json({
        success: true,
        data: {
          url: publicUrl,
          filename: req.file.filename,
          originalName: req.file.originalname,
          size: req.file.size,
          mimetype: req.file.mimetype,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. STATS GLOBALES
  // ──────────────────────────────────────────────────────────────────────────

  async getStats(req, res, next) {
    try {
      const statsQuery = `
        SELECT 
          (SELECT COUNT(*) FROM users) as total_users,
          (SELECT COUNT(*) FROM subscriptions WHERE status = 'active' AND plan != 'gratuit') as active_subscriptions,
          (SELECT COUNT(*) FROM courses) as total_courses,
          (SELECT COUNT(*) FROM exercises) as total_exercises,
          (SELECT COUNT(*) FROM exams) as total_exams
      `;
      const { rows } = await pool.query(statsQuery);
      res.json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. SUBJECTS CRUD
  // ──────────────────────────────────────────────────────────────────────────

  async getSubjects(req, res, next) {
    try {
      const { rows } = await pool.query('SELECT * FROM subjects ORDER BY name');
      res.json({ success: true, data: rows });
    } catch (error) {
      next(error);
    }
  }

  async createSubject(req, res, next) {
    try {
      const { name, description, icon, color } = req.body;
      const { rows } = await pool.query(
        'INSERT INTO subjects (name, description, icon, color) VALUES ($1, $2, $3, $4) RETURNING *',
        [name, description || '', icon || 'menu_book_rounded', color || '#2563EB']
      );
      res.status(201).json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async updateSubject(req, res, next) {
    try {
      const { id } = req.params;
      const { name, description, icon, color } = req.body;
      const { rows } = await pool.query(
        'UPDATE subjects SET name = $1, description = $2, icon = $3, color = $4 WHERE id = $5 RETURNING *',
        [name, description || '', icon || 'menu_book_rounded', color || '#2563EB', id]
      );
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Matière introuvable' });
      res.json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async deleteSubject(req, res, next) {
    try {
      const { id } = req.params;
      const { rows } = await pool.query('DELETE FROM subjects WHERE id = $1 RETURNING *', [id]);
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Matière introuvable' });
      res.json({ success: true, message: 'Matière supprimée avec succès', data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. COURSES CRUD
  // ──────────────────────────────────────────────────────────────────────────

  async getCourses(req, res, next) {
    try {
      const { rows } = await pool.query(`
        SELECT c.*, s.name as subject_name, cl.name as classroom_name, ser.name as series_name 
        FROM courses c
        LEFT JOIN subjects s ON c.subject_id = s.id
        LEFT JOIN classrooms cl ON c.classroom_id = cl.id
        LEFT JOIN series ser ON c.series_id = ser.id
        ORDER BY c.created_at DESC
      `);
      res.json({ success: true, data: rows });
    } catch (error) {
      next(error);
    }
  }

  async createCourse(req, res, next) {
    try {
      const { title, description, type, fileUrl, videoUrl, thumbnailUrl, subjectId, seriesId, classroomId, isPremium } = req.body;
      const { rows } = await pool.query(
        `INSERT INTO courses (title, description, type, file_url, video_url, thumbnail_url, subject_id, series_id, classroom_id, is_premium)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
        [title, description || '', type, fileUrl || null, videoUrl || null, thumbnailUrl || null, subjectId, seriesId, classroomId || null, isPremium || false]
      );
      res.status(201).json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async updateCourse(req, res, next) {
    try {
      const { id } = req.params;
      const { title, description, type, fileUrl, videoUrl, thumbnailUrl, subjectId, seriesId, classroomId, isPremium } = req.body;
      const { rows } = await pool.query(
        `UPDATE courses SET title = $1, description = $2, type = $3, file_url = $4, video_url = $5, thumbnail_url = $6, subject_id = $7, series_id = $8, classroom_id = $9, is_premium = $10
         WHERE id = $11 RETURNING *`,
        [title, description || '', type, fileUrl || null, videoUrl || null, thumbnailUrl || null, subjectId, seriesId, classroomId || null, isPremium || false, id]
      );
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Cours introuvable' });
      res.json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async deleteCourse(req, res, next) {
    try {
      const { id } = req.params;
      const { rows } = await pool.query('DELETE FROM courses WHERE id = $1 RETURNING *', [id]);
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Cours introuvable' });

      // Nettoyage des fichiers physiques orphelins (Piège 4)
      deleteFileByUrl(rows[0].file_url);
      deleteFileByUrl(rows[0].video_url);
      deleteFileByUrl(rows[0].thumbnail_url);

      res.json({ success: true, message: 'Cours supprimé avec succès', data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. EXERCISES / QCM CRUD
  // ──────────────────────────────────────────────────────────────────────────

  async getExercises(req, res, next) {
    try {
      const { rows } = await pool.query(`
        SELECT e.*, s.name as subject_name, cl.name as classroom_name, ser.name as series_name 
        FROM exercises e
        LEFT JOIN subjects s ON e.subject_id = s.id
        LEFT JOIN classrooms cl ON e.classroom_id = cl.id
        LEFT JOIN series ser ON e.series_id = ser.id
        ORDER BY e.created_at DESC
      `);
      res.json({ success: true, data: rows });
    } catch (error) {
      next(error);
    }
  }

  async createExercise(req, res, next) {
    try {
      const { title, description, type, subjectId, seriesId, classroomId, durationMinutes, totalPoints, isPremium } = req.body;
      const { rows } = await pool.query(
        `INSERT INTO exercises (title, description, type, subject_id, series_id, classroom_id, duration_minutes, total_points, is_premium)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
        [title, description || '', type || 'qcm', subjectId, seriesId, classroomId || null, durationMinutes || 30, totalPoints || 20, isPremium || false]
      );
      res.status(201).json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async updateExercise(req, res, next) {
    try {
      const { id } = req.params;
      const { title, description, type, subjectId, seriesId, classroomId, durationMinutes, totalPoints, isPremium } = req.body;
      const { rows } = await pool.query(
        `UPDATE exercises SET title = $1, description = $2, type = $3, subject_id = $4, series_id = $5, classroom_id = $6, duration_minutes = $7, total_points = $8, is_premium = $9
         WHERE id = $10 RETURNING *`,
        [title, description || '', type || 'qcm', subjectId, seriesId, classroomId || null, durationMinutes || 30, totalPoints || 20, isPremium || false, id]
      );
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Exercice introuvable' });
      res.json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async deleteExercise(req, res, next) {
    try {
      const { id } = req.params;
      const { rows } = await pool.query('DELETE FROM exercises WHERE id = $1 RETURNING *', [id]);
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Exercice introuvable' });
      res.json({ success: true, message: 'Exercice supprimé avec succès', data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. EXERCISE QUESTIONS CRUD
  // ──────────────────────────────────────────────────────────────────────────

  async getQuestions(req, res, next) {
    try {
      const { id } = req.params;
      const { rows } = await pool.query(
        'SELECT * FROM exercise_questions WHERE exercise_id = $1 ORDER BY order_index',
        [id]
      );
      res.json({ success: true, data: rows });
    } catch (error) {
      next(error);
    }
  }

  async createQuestion(req, res, next) {
    try {
      const { id } = req.params;
      const { questionText, options, correctAnswer, points, explanation, orderIndex } = req.body;
      const { rows } = await pool.query(
        `INSERT INTO exercise_questions (exercise_id, question_text, options, correct_answer, points, explanation, order_index)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
        [id, questionText, JSON.stringify(options), correctAnswer, points || 1, explanation || '', orderIndex || 1]
      );
      res.status(201).json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async updateQuestion(req, res, next) {
    try {
      const { questionId } = req.params;
      const { questionText, options, correctAnswer, points, explanation, orderIndex } = req.body;
      const { rows } = await pool.query(
        `UPDATE exercise_questions 
         SET question_text = $1, options = $2, correct_answer = $3, points = $4, explanation = $5, order_index = $6
         WHERE id = $7 RETURNING *`,
        [questionText, JSON.stringify(options), correctAnswer, points, explanation || '', orderIndex, questionId]
      );
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Question introuvable' });
      res.json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async deleteQuestion(req, res, next) {
    try {
      const { questionId } = req.params;
      const { rows } = await pool.query('DELETE FROM exercise_questions WHERE id = $1 RETURNING *', [questionId]);
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Question introuvable' });
      res.json({ success: true, message: 'Question supprimée avec succès', data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. EXAMS / ANNALES CRUD
  // ──────────────────────────────────────────────────────────────────────────

  async getExams(req, res, next) {
    try {
      const { rows } = await pool.query(`
        SELECT e.*, s.name as subject_name, ser.name as series_name, cl.name as classroom_name
        FROM exams e
        LEFT JOIN subjects s ON e.subject_id = s.id
        LEFT JOIN series ser ON e.series_id = ser.id
        LEFT JOIN classrooms cl ON e.classroom_id = cl.id
        ORDER BY e.year DESC, e.created_at DESC
      `);
      res.json({ success: true, data: rows });
    } catch (error) {
      next(error);
    }
  }

  async createExam(req, res, next) {
    try {
      const {
        title, description, type, subjectId, seriesId, classroomId,
        durationMinutes, totalPoints, fileUrl, corrigePdfUrl, isPremium, year, serie
      } = req.body;

      const { rows } = await pool.query(
        `INSERT INTO exams 
          (title, description, type, subject_id, series_id, classroom_id, duration_minutes, total_points, file_url, corrige_pdf_url, is_premium, year, serie)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) RETURNING *`,
        [
          title, description || '', type,
          subjectId || null, seriesId || null, classroomId || null,
          durationMinutes || 180, totalPoints || 100,
          fileUrl || null, corrigePdfUrl || null,
          isPremium !== false, year || null, serie || null
        ]
      );
      res.status(201).json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async updateExam(req, res, next) {
    try {
      const { id } = req.params;
      const {
        title, description, type, subjectId, seriesId, classroomId,
        durationMinutes, totalPoints, fileUrl, corrigePdfUrl, isPremium, year, serie
      } = req.body;

      const { rows } = await pool.query(
        `UPDATE exams SET
          title = $1, description = $2, type = $3, subject_id = $4, series_id = $5, classroom_id = $6,
          duration_minutes = $7, total_points = $8, file_url = $9, corrige_pdf_url = $10,
          is_premium = $11, year = $12, serie = $13
         WHERE id = $14 RETURNING *`,
        [
          title, description || '', type,
          subjectId || null, seriesId || null, classroomId || null,
          durationMinutes || 180, totalPoints || 100,
          fileUrl || null, corrigePdfUrl || null,
          isPremium !== false, year || null, serie || null, id
        ]
      );
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Examen introuvable' });
      res.json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  async deleteExam(req, res, next) {
    try {
      const { id } = req.params;
      const { rows } = await pool.query('DELETE FROM exams WHERE id = $1 RETURNING *', [id]);
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Examen introuvable' });

      // Nettoyage des fichiers orphelins (Piège 4)
      deleteFileByUrl(rows[0].file_url);
      deleteFileByUrl(rows[0].corrige_pdf_url);

      res.json({ success: true, message: 'Examen supprimé avec succès' });
    } catch (error) {
      next(error);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. USERS MANAGEMENT
  // ──────────────────────────────────────────────────────────────────────────

  async getUsers(req, res, next) {
    try {
      const { rows } = await pool.query(`
        SELECT u.id, u.nom, u.prenom, u.telephone, u.email, u.etablissement, u.role, u.created_at,
               c.name as classroom_name, s.name as series_name
        FROM users u
        LEFT JOIN classrooms c ON u.classroom_id = c.id
        LEFT JOIN series s ON u.series_id = s.id
        ORDER BY u.created_at DESC
      `);
      res.json({ success: true, data: rows });
    } catch (error) {
      next(error);
    }
  }

  async updateUserRole(req, res, next) {
    try {
      const { id } = req.params;
      const { role } = req.body;
      if (!['student', 'teacher', 'admin'].includes(role)) {
        return res.status(400).json({ success: false, message: 'Rôle invalide' });
      }
      const { rows } = await pool.query(
        'UPDATE users SET role = $1, updated_at = NOW() WHERE id = $2 RETURNING id, nom, prenom, role',
        [role, id]
      );
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });
      res.json({ success: true, data: rows[0] });
    } catch (error) {
      next(error);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. ANALYTICS PROFESSEUR
  // ──────────────────────────────────────────────────────────────────────────

  async getAnalytics(req, res, next) {
    try {
      const { seriesId, classroomId, dateFrom } = req.query;
      const filters = {
        seriesId: seriesId || undefined,
        classroomId: classroomId || undefined,
        dateFrom: dateFrom ? new Date(dateFrom) : undefined,
      };

      // Toutes les requêtes en parallèle pour la performance
      const [subjectPerformance, weakExercises, globalStats] = await Promise.all([
        analyticsRepo.getSubjectPerformance(filters),
        analyticsRepo.getWeakExercises({ ...filters, threshold: 50 }),
        analyticsRepo.getGlobalStats(),
      ]);

      res.json({
        success: true,
        data: {
          globalStats,
          subjectPerformance,
          weakExercises,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AdminController();
