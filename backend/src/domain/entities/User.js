class User {
  constructor(data) {
    this.id = data.id;
    this.nom = data.nom;
    this.prenom = data.prenom;
    this.telephone = data.telephone;
    this.email = data.email;
    this.etablissement = data.etablissement;
    this.classroomId = data.classroom_id || data.classroomId;
    this.seriesId = data.series_id || data.seriesId;
    this.avatarUrl = data.avatar_url || data.avatarUrl;
    this.createdAt = data.created_at || data.createdAt;
  }

  get fullName() {
    return `${this.prenom} ${this.nom}`;
  }

  toJSON() {
    return {
      id: this.id,
      nom: this.nom,
      prenom: this.prenom,
      telephone: this.telephone,
      email: this.email,
      etablissement: this.etablissement,
      classroomId: this.classroomId,
      seriesId: this.seriesId,
      avatarUrl: this.avatarUrl,
      fullName: this.fullName,
      createdAt: this.createdAt,
    };
  }
}

module.exports = User;
