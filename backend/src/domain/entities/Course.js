class Course {
  constructor(data) {
    this.id = data.id;
    this.title = data.title;
    this.description = data.description;
    this.type = data.type;
    this.fileUrl = data.file_url || data.fileUrl;
    this.videoUrl = data.video_url || data.videoUrl;
    this.thumbnailUrl = data.thumbnail_url || data.thumbnailUrl;
    this.durationMinutes = data.duration_minutes || data.durationMinutes;
    this.subjectId = data.subject_id || data.subjectId;
    this.seriesId = data.series_id || data.seriesId;
    this.classroomId = data.classroom_id || data.classroomId;
    this.isPremium = data.is_premium ?? data.isPremium;
    this.downloadCount = data.download_count || data.downloadCount;
    this.subjectName = data.subject_name;
    this.createdAt = data.created_at || data.createdAt;
  }

  toJSON() {
    return {
      id: this.id,
      title: this.title,
      description: this.description,
      type: this.type,
      fileUrl: this.fileUrl,
      videoUrl: this.videoUrl,
      thumbnailUrl: this.thumbnailUrl,
      durationMinutes: this.durationMinutes,
      subjectId: this.subjectId,
      subjectName: this.subjectName,
      seriesId: this.seriesId,
      isPremium: this.isPremium,
      downloadCount: this.downloadCount,
      createdAt: this.createdAt,
    };
  }
}

module.exports = Course;
