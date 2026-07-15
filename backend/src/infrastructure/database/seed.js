const pool = require('./pool');

const SUBJECTS = [
  'Mathématiques', 'Français', 'Anglais', 'Physique',
  'SVT', 'Philosophie', 'Technologie', 'Dessin Technique',
];

const CLASSROOMS = {
  college: ['6ème', '5ème', '4ème', '3ème'],
  lycee_general: ['Seconde', 'Première', 'Terminale'],
  lycee_technique: ['Seconde', 'Première', 'Terminale'],
};

const SERIES = {
  college: [],
  lycee_general: ['A', 'C', 'D'],
  lycee_technique: ['F1', 'F2', 'F3', 'F4', 'Électricité', 'Électronique', 'Bâtiment', 'Mécanique', 'Informatique'],
};

async function seed() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: existingSubjects } = await client.query('SELECT COUNT(*) FROM subjects');
    if (parseInt(existingSubjects[0].count, 10) > 0) {
      console.log('ℹ️  Database already seeded, skipping');
      await client.query('COMMIT');
      return;
    }

    // Insert subjects
    const subjectIds = {};
    for (const name of SUBJECTS) {
      const { rows } = await client.query(
        'INSERT INTO subjects (name, icon) VALUES ($1, $2) RETURNING id',
        [name, name.toLowerCase().replace(/\s/g, '_')]
      );
      subjectIds[name] = rows[0].id;
    }

    // Insert classrooms and series
    const classroomMap = {};
    const seriesMap = {};
    let orderIndex = 0;

    for (const [level, classes] of Object.entries(CLASSROOMS)) {
      for (const className of classes) {
        orderIndex++;
        const { rows } = await client.query(
          'INSERT INTO classrooms (name, level, order_index) VALUES ($1, $2, $3) RETURNING id',
          [className, level, orderIndex]
        );
        classroomMap[`${level}_${className}`] = rows[0].id;

        const seriesList = SERIES[level] || [];
        if (seriesList.length === 0) {
          // College: one default series per classroom
          const { rows: sRows } = await client.query(
            'INSERT INTO series (name, level, classroom_id) VALUES ($1, $2, $3) RETURNING id',
            ['Général', level, rows[0].id]
          );
          seriesMap[`${level}_${className}_Général`] = sRows[0].id;
          for (const subjectName of SUBJECTS) {
            await client.query(
              'INSERT INTO series_subjects (series_id, subject_id) VALUES ($1, $2)',
              [sRows[0].id, subjectIds[subjectName]]
            );
          }
        } else {
          for (const seriesName of seriesList) {
            const { rows: sRows } = await client.query(
              'INSERT INTO series (name, level, classroom_id) VALUES ($1, $2, $3) RETURNING id',
              [seriesName, level, rows[0].id]
            );
            seriesMap[`${level}_${className}_${seriesName}`] = sRows[0].id;
            for (const subjectName of SUBJECTS) {
              await client.query(
                'INSERT INTO series_subjects (series_id, subject_id) VALUES ($1, $2)',
                [sRows[0].id, subjectIds[subjectName]]
              );
            }
          }
        }
      }
    }

    // Sample courses for Terminale série A
    const termAKey = Object.keys(seriesMap).find(k => k.includes('Terminale') && k.includes('_A'));
    if (termAKey) {
      const seriesId = seriesMap[termAKey];
      const mathId = subjectIds['Mathématiques'];
      const frId = subjectIds['Français'];

      const courses = [
        { title: 'Limites et continuité', type: 'pdf', subject: mathId, premium: false },
        { title: 'Dérivation - Cours complet', type: 'video', subject: mathId, premium: false },
        { title: 'Intégration - Méthodes', type: 'pdf', subject: mathId, premium: true },
        { title: 'La dissertation - Méthode', type: 'video', subject: frId, premium: false },
        { title: 'Commentaire composé', type: 'pdf', subject: frId, premium: true },
      ];

      for (const c of courses) {
        await client.query(
          `INSERT INTO courses (title, description, type, file_url, video_url, subject_id, series_id, is_premium)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [
            c.title,
            `Cours de ${c.title}`,
            c.type,
            c.type === 'pdf' ? `/uploads/courses/${c.title.replace(/\s/g, '_')}.pdf` : null,
            c.type === 'video' ? `https://example.com/videos/${c.title.replace(/\s/g, '_')}.mp4` : null,
            c.subject,
            seriesId,
            c.premium,
          ]
        );
      }

      // Sample exercises
      const { rows: exRows } = await client.query(
        `INSERT INTO exercises (title, description, type, subject_id, series_id, duration_minutes, total_points)
         VALUES ($1, $2, $3, $4, $5, 30, 20) RETURNING id`,
        ['QCM Mathématiques - Limites', 'Testez vos connaissances sur les limites', 'qcm', mathId, seriesId]
      );

      const questions = [
        { text: 'Quelle est la limite de 1/x quand x tend vers +∞ ?', options: ['0', '1', '+∞', '-∞'], correct: 0 },
        { text: 'La fonction f(x) = x² est-elle continue sur ℝ ?', options: ['Oui', 'Non', 'Seulement sur ℝ+', 'Seulement sur ℝ-'], correct: 0 },
        { text: 'Quelle est la dérivée de x³ ?', options: ['3x²', 'x²', '3x', 'x³/3'], correct: 0 },
        { text: '∫x dx = ?', options: ['x²/2 + C', 'x + C', '2x + C', 'x² + C'], correct: 0 },
        { text: 'lim(sin(x)/x) quand x→0 = ?', options: ['1', '0', '+∞', 'Indéterminé'], correct: 0 },
      ];

      for (let i = 0; i < questions.length; i++) {
        const q = questions[i];
        await client.query(
          `INSERT INTO exercise_questions (exercise_id, question_text, options, correct_answer, order_index, points)
           VALUES ($1, $2, $3, $4, $5, 4)`,
          [exRows[0].id, q.text, JSON.stringify(q.options), q.correct, i + 1]
        );
      }

      // Quiz
      const { rows: quizRows } = await client.query(
        `INSERT INTO exercises (title, description, type, subject_id, series_id, duration_minutes, total_points)
         VALUES ($1, $2, $3, $4, $5, 15, 10) RETURNING id`,
        ['Quiz Français - Figures de style', 'Quiz rapide sur les figures de style', 'quiz', frId, seriesId]
      );

      const quizQuestions = [
        { text: 'Une comparaison explicite est une...', options: ['Métaphore', 'Comparaison', 'Hyperbole', 'Antithèse'], correct: 1 },
        { text: '"Cette obscure clarté" est une...', options: ['Oxymore', 'Métaphore', 'Allitération', 'Anaphore'], correct: 0 },
      ];

      for (let i = 0; i < quizQuestions.length; i++) {
        const q = quizQuestions[i];
        await client.query(
          `INSERT INTO exercise_questions (exercise_id, question_text, options, correct_answer, order_index, points)
           VALUES ($1, $2, $3, $4, $5, 5)`,
          [quizRows[0].id, q.text, JSON.stringify(q.options), q.correct, i + 1]
        );
      }
    }

    // Sample exams
    const examTypes = [
      { title: 'BEPC 2024 - Mathématiques', type: 'bepc', subject: subjectIds['Mathématiques'] },
      { title: 'BAC Général 2024 - Philosophie', type: 'bac_general', subject: subjectIds['Philosophie'] },
      { title: 'BAC Technique 2024 - Technologie', type: 'bac_technique', subject: subjectIds['Technologie'] },
      { title: 'BET 2024 - Électricité', type: 'bet', subject: subjectIds['Physique'] },
    ];

    for (const exam of examTypes) {
      const { rows } = await client.query(
        `INSERT INTO exams (title, description, type, subject_id, duration_minutes, year, is_premium)
         VALUES ($1, $2, $3, $4, 180, 2024, true) RETURNING id`,
        [exam.title, `Examen ${exam.title}`, exam.type, exam.subject]
      );

      await client.query(
        `INSERT INTO exam_questions (exam_id, question_text, options, correct_answer, order_index, points)
         VALUES ($1, $2, $3, $4, 1, 20)`,
        [rows[0].id, 'Question type examen - Choix multiple', JSON.stringify(['Réponse A', 'Réponse B', 'Réponse C', 'Réponse D']), 0]
      );
    }

    // Demo user
    const bcrypt = require('bcryptjs');
    const passwordHash = await bcrypt.hash('password123', 10);
    const termClassId = classroomMap['lycee_general_Terminale'];
    const termSeriesId = seriesMap['lycee_general_Terminale_A'];

    const { rows: userRows } = await client.query(
      `INSERT INTO users (nom, prenom, telephone, password_hash, etablissement, classroom_id, series_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      ['Dupont', 'Jean', '+237670000001', passwordHash, 'Lycée de Yaoundé', termClassId, termSeriesId]
    );

    await client.query(
      `INSERT INTO subscriptions (user_id, plan, status, end_date, max_members)
       VALUES ($1, 'gratuit', 'active', NOW() + INTERVAL '30 days', 1)`,
      [userRows[0].id]
    );

    await client.query('COMMIT');
    console.log('✅ Database seeded successfully');
    console.log('   Demo user: +237670000001 / password123');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Seed failed:', error.message);
    throw error;
  } finally {
    client.release();
  }
}

if (require.main === module) {
  seed()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = { seed };
