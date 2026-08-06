const pool = require('../database/pool');

class AnalyticsRepository {
  /**
   * Récupère les performances moyennes par matière.
   * Retourne pour chaque matière : nom, score moyen (%), nombre de soumissions.
   */
  async getSubjectPerformance({ seriesId, classroomId, dateFrom } = {}) {
    const params = [];
    let idx = 1;
    let dateFilter = '';
    let seriesFilter = '';
    let classroomFilter = '';

    if (dateFrom) {
      dateFilter = ` AND er.completed_at >= $${idx++}`;
      params.push(dateFrom);
    }
    if (seriesId) {
      seriesFilter = ` AND e.series_id = $${idx++}`;
      params.push(seriesId);
    }
    if (classroomId) {
      classroomFilter = ` AND e.classroom_id = $${idx++}`;
      params.push(classroomId);
    }

    const query = `
      SELECT 
        s.id AS subject_id,
        s.name AS subject_name,
        s.color AS subject_color,
        COUNT(er.id) AS total_submissions,
        ROUND(AVG(
          CASE 
            WHEN er.total_points > 0 THEN (er.score::FLOAT / er.total_points::FLOAT) * 100
            ELSE 0
          END
        )::NUMERIC, 1) AS avg_score_percent
      FROM exercise_results er
      JOIN exercises e ON er.exercise_id = e.id
      JOIN subjects s ON e.subject_id = s.id
      WHERE 1=1
        ${dateFilter}
        ${seriesFilter}
        ${classroomFilter}
      GROUP BY s.id, s.name, s.color
      ORDER BY avg_score_percent ASC
    `;

    const { rows } = await pool.query(query, params);
    return rows.map((r) => ({
      subjectId: r.subject_id,
      subjectName: r.subject_name,
      subjectColor: r.subject_color || '#2563EB',
      totalSubmissions: parseInt(r.total_submissions, 10),
      avgScorePercent: parseFloat(r.avg_score_percent) || 0,
      isAlert: parseFloat(r.avg_score_percent) < 50,
    }));
  }

  /**
   * Retourne les exercices "en alerte rouge" (score moyen < seuil).
   * @param {number} threshold - Seuil en % (défaut 50)
   */
  async getWeakExercises({ threshold = 50, seriesId, classroomId, dateFrom } = {}) {
    const params = [threshold / 100];
    let idx = 2;
    let dateFilter = '';
    let seriesFilter = '';
    let classroomFilter = '';

    if (dateFrom) {
      dateFilter = ` AND er.completed_at >= $${idx++}`;
      params.push(dateFrom);
    }
    if (seriesId) {
      seriesFilter = ` AND e.series_id = $${idx++}`;
      params.push(seriesId);
    }
    if (classroomId) {
      classroomFilter = ` AND e.classroom_id = $${idx++}`;
      params.push(classroomId);
    }

    const query = `
      SELECT 
        e.id AS exercise_id,
        e.title AS exercise_title,
        e.type AS exercise_type,
        s.name AS subject_name,
        s.color AS subject_color,
        COUNT(er.id) AS total_submissions,
        ROUND(AVG(
          CASE 
            WHEN er.total_points > 0 THEN (er.score::FLOAT / er.total_points::FLOAT)
            ELSE 0
          END
        )::NUMERIC, 3) AS avg_ratio
      FROM exercise_results er
      JOIN exercises e ON er.exercise_id = e.id
      JOIN subjects s ON e.subject_id = s.id
      WHERE 1=1
        ${dateFilter}
        ${seriesFilter}
        ${classroomFilter}
      GROUP BY e.id, e.title, e.type, s.name, s.color
      HAVING AVG(
        CASE 
          WHEN er.total_points > 0 THEN (er.score::FLOAT / er.total_points::FLOAT)
          ELSE 0
        END
      ) < $1
      ORDER BY avg_ratio ASC
      LIMIT 20
    `;

    const { rows } = await pool.query(query, params);
    return rows.map((r) => ({
      exerciseId: r.exercise_id,
      exerciseTitle: r.exercise_title,
      exerciseType: r.exercise_type,
      subjectName: r.subject_name,
      subjectColor: r.subject_color || '#EF4444',
      totalSubmissions: parseInt(r.total_submissions, 10),
      avgScorePercent: Math.round(parseFloat(r.avg_ratio) * 100),
    }));
  }

  /**
   * Analyse JSONB-safe des questions les plus souvent ratées.
   * Ignores corrupted / non-array answers via JSONB_TYPEOF check.
   */
  async getWorstQuestions({ exerciseId, limit = 10 } = {}) {
    const params = [];
    let exerciseFilter = '';
    let idx = 1;

    if (exerciseId) {
      exerciseFilter = ` AND er.exercise_id = $${idx++}`;
      params.push(exerciseId);
    }
    params.push(limit);

    const query = `
      SELECT 
        eq.id AS question_id,
        eq.question_text,
        eq.correct_answer,
        e.title AS exercise_title,
        s.name AS subject_name,
        COUNT(er.id) AS total_attempts,
        SUM(
          CASE 
            -- JSONB_TYPEOF safety check: skip corrupted/null answers
            WHEN JSONB_TYPEOF(er.answers) = 'object'
              AND er.answers ? eq.id::TEXT
              AND (er.answers ->> eq.id::TEXT)::INTEGER != eq.correct_answer
            THEN 1 ELSE 0 
          END
        ) AS wrong_answers
      FROM exercise_questions eq
      JOIN exercises e ON eq.exercise_id = e.id
      JOIN subjects s ON e.subject_id = s.id
      JOIN exercise_results er ON er.exercise_id = e.id
      WHERE JSONB_TYPEOF(er.answers) = 'object'
        ${exerciseFilter}
      GROUP BY eq.id, eq.question_text, eq.correct_answer, e.title, s.name
      HAVING COUNT(er.id) > 0
      ORDER BY 
        (SUM(CASE 
          WHEN JSONB_TYPEOF(er.answers) = 'object'
            AND er.answers ? eq.id::TEXT
            AND (er.answers ->> eq.id::TEXT)::INTEGER != eq.correct_answer
          THEN 1 ELSE 0 
        END)::FLOAT / NULLIF(COUNT(er.id), 0)) DESC
      LIMIT $${idx}
    `;

    try {
      const { rows } = await pool.query(query, params);
      return rows.map((r) => ({
        questionId: r.question_id,
        questionText: r.question_text,
        exerciseTitle: r.exercise_title,
        subjectName: r.subject_name,
        totalAttempts: parseInt(r.total_attempts, 10),
        wrongAnswers: parseInt(r.wrong_answers, 10),
        errorRate: r.total_attempts > 0
          ? Math.round((parseInt(r.wrong_answers, 10) / parseInt(r.total_attempts, 10)) * 100)
          : 0,
      }));
    } catch (err) {
      // Si la structure JSONB est invalide sur cet environnement, renvoie tableau vide
      console.warn('[AnalyticsRepository] getWorstQuestions fallback:', err.message);
      return [];
    }
  }

  /**
   * Statistiques globales pour le résumé du tableau de bord analytique.
   */
  async getGlobalStats() {
    const { rows } = await pool.query(`
      SELECT 
        COUNT(DISTINCT er.user_id) AS active_students,
        COUNT(er.id) AS total_submissions,
        ROUND(AVG(
          CASE 
            WHEN er.total_points > 0 THEN (er.score::FLOAT / er.total_points::FLOAT) * 100
            ELSE 0
          END
        )::NUMERIC, 1) AS global_avg_percent
      FROM exercise_results er
    `);

    return {
      activeStudents: parseInt(rows[0].active_students, 10) || 0,
      totalSubmissions: parseInt(rows[0].total_submissions, 10) || 0,
      globalAvgPercent: parseFloat(rows[0].global_avg_percent) || 0,
    };
  }
}

module.exports = AnalyticsRepository;
