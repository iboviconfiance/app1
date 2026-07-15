class WorkGroup {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.subjectId = data.subject_id || data.subjectId;
    this.seriesId = data.series_id || data.seriesId;
    this.createdBy = data.created_by || data.createdBy;
    this.maxMembers = data.max_members || data.maxMembers;
    this.inviteCode = data.invite_code || data.inviteCode;
    this.memberCount = data.memberCount;
    this.createdAt = data.created_at || data.createdAt;
  }

  toJSON() {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
      subjectId: this.subjectId,
      seriesId: this.seriesId,
      createdBy: this.createdBy,
      maxMembers: this.maxMembers,
      inviteCode: this.inviteCode,
      memberCount: this.memberCount,
      createdAt: this.createdAt,
    };
  }
}

module.exports = WorkGroup;
