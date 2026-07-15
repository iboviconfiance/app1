class Subscription {
  constructor(data) {
    this.id = data.id;
    this.userId = data.user_id || data.userId;
    this.plan = data.plan;
    this.status = data.status;
    this.startDate = data.start_date || data.startDate;
    this.endDate = data.end_date || data.endDate;
    this.maxMembers = data.max_members || data.maxMembers;
  }

  toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      plan: this.plan,
      status: this.status,
      startDate: this.startDate,
      endDate: this.endDate,
      maxMembers: this.maxMembers,
      isActive: this.status === 'active',
    };
  }
}

module.exports = Subscription;
