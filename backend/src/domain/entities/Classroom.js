class Classroom {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.level = data.level;
    this.orderIndex = data.order_index || data.orderIndex;
  }

  toJSON() {
    return {
      id: this.id,
      name: this.name,
      level: this.level,
      orderIndex: this.orderIndex,
    };
  }
}

module.exports = Classroom;
