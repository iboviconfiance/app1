class Exam {
  constructor(data) {
    this.id = data.id;
    this.title = data.title;
    this.description = data.description;
    this.type = data.type;
    this.subjectId = data.subject_id || data.subjectId;
    this.seriesId = data.series_id || data.seriesId;
    this.durationMinutes = data.duration_minutes || data.durationMinutes;
    this.totalPoints = data.total_points || data.totalPoints;
    this.fileUrl = data.file_url || data.fileUrl;
    this.isPremium = data.is_premium ?? data.isPremium;
    this.year = data.year;
    this.subjectName = data.subject_name;
  }

  toJSON() {
    return {
      id: this.id,
      title: this.title,
      description: this.description,
      type: this.type,
      subjectId: this.subjectId,
      subjectName: this.subjectName,
      durationMinutes: this.durationMinutes,
      totalPoints: this.totalPoints,
      fileUrl: this.fileUrl,
      isPremium: this.isPremium,
      year: this.year,
    };
  }
}

module.exports = Exam;
