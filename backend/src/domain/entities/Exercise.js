class Exercise {
  constructor(data) {
    this.id = data.id;
    this.title = data.title;
    this.description = data.description;
    this.type = data.type;
    this.subjectId = data.subject_id || data.subjectId;
    this.seriesId = data.series_id || data.seriesId;
    this.durationMinutes = data.duration_minutes || data.durationMinutes;
    this.totalPoints = data.total_points || data.totalPoints;
    this.isPremium = data.is_premium ?? data.isPremium;
    this.subjectName = data.subject_name;
    this.questions = data.questions;
  }

  toJSON(includeQuestions = false) {
    const base = {
      id: this.id,
      title: this.title,
      description: this.description,
      type: this.type,
      subjectId: this.subjectId,
      subjectName: this.subjectName,
      durationMinutes: this.durationMinutes,
      totalPoints: this.totalPoints,
      isPremium: this.isPremium,
    };
    if (includeQuestions && this.questions) {
      base.questions = this.questions.map(q => ({
        id: q.id,
        questionText: q.question_text || q.questionText,
        options: q.options,
        orderIndex: q.order_index || q.orderIndex,
        points: q.points,
      }));
    }
    return base;
  }
}

module.exports = Exercise;
