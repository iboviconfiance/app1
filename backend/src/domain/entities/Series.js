class Series {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.level = data.level;
    this.classroomId = data.classroom_id || data.classroomId;
    this.classroomName = data.classroom_name;
  }

  toJSON() {
    return {
      id: this.id,
      name: this.name,
      level: this.level,
      classroomId: this.classroomId,
      classroomName: this.classroomName,
    };
  }
}

module.exports = Series;
