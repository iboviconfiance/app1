const pool = require('../database/pool');
const Classroom = require('../../domain/entities/Classroom');
const Series = require('../../domain/entities/Series');
const Subject = require('../../domain/entities/Subject');

class SchoolRepository {
  async getAllClassrooms() {
    const { rows } = await pool.query('SELECT * FROM classrooms ORDER BY order_index');
    return rows.map(r => new Classroom(r).toJSON());
  }

  async getClassroomsByLevel(level) {
    const { rows } = await pool.query(
      'SELECT * FROM classrooms WHERE level = $1 ORDER BY order_index',
      [level]
    );
    return rows.map(r => new Classroom(r).toJSON());
  }

  async getSeriesByClassroom(classroomId) {
    const { rows } = await pool.query(
      `SELECT s.*, c.name as classroom_name FROM series s
       JOIN classrooms c ON s.classroom_id = c.id
       WHERE s.classroom_id = $1 ORDER BY s.name`,
      [classroomId]
    );
    return rows.map(r => new Series(r).toJSON());
  }

  async getAllSeries() {
    const { rows } = await pool.query(
      `SELECT s.*, c.name as classroom_name FROM series s
       LEFT JOIN classrooms c ON s.classroom_id = c.id ORDER BY c.order_index, s.name`
    );
    return rows.map(r => new Series(r).toJSON());
  }

  async getSubjectsBySeries(seriesId) {
    const { rows } = await pool.query(
      `SELECT sub.* FROM subjects sub
       JOIN series_subjects ss ON sub.id = ss.subject_id
       WHERE ss.series_id = $1 ORDER BY sub.name`,
      [seriesId]
    );
    return rows.map(r => new Subject(r).toJSON());
  }

  async getAllSubjects() {
    const { rows } = await pool.query('SELECT * FROM subjects ORDER BY name');
    return rows.map(r => new Subject(r).toJSON());
  }

  async getHierarchy() {
    const { rows } = await pool.query(`
      SELECT 
        c.id AS classroom_id,
        c.name AS classroom_name,
        c.level AS classroom_level,
        c.order_index AS classroom_order_index,
        s.id AS series_id,
        s.name AS series_name,
        s.level AS series_level
      FROM classrooms c
      LEFT JOIN series s ON s.classroom_id = c.id
      ORDER BY c.order_index, s.name
    `);

    const hierarchy = {};
    const classroomMap = new Map();

    for (const row of rows) {
      const classId = row.classroom_id;
      if (!classroomMap.has(classId)) {
        const classroomObj = {
          id: classId,
          name: row.classroom_name,
          level: row.classroom_level,
          orderIndex: row.classroom_order_index,
          series: []
        };
        classroomMap.set(classId, classroomObj);
        
        if (!hierarchy[classroomObj.level]) {
          hierarchy[classroomObj.level] = [];
        }
        hierarchy[classroomObj.level].push(classroomObj);
      }

      if (row.series_id) {
        classroomMap.get(classId).series.push({
          id: row.series_id,
          name: row.series_name,
          level: row.series_level,
          classroomId: classId,
          classroomName: row.classroom_name
        });
      }
    }
    return hierarchy;
  }
}

module.exports = SchoolRepository;
