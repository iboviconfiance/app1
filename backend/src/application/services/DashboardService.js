const CourseRepository = require('../../infrastructure/repositories/CourseRepository');
const ExerciseRepository = require('../../infrastructure/repositories/ExerciseRepository');
const SubscriptionRepository = require('../../infrastructure/repositories/SubscriptionRepository');
const UserRepository = require('../../infrastructure/repositories/UserRepository');

class DashboardService {
  constructor() {
    this.courseRepo = new CourseRepository();
    this.exerciseRepo = new ExerciseRepository();
    this.subscriptionRepo = new SubscriptionRepository();
    this.userRepo = new UserRepository();
  }

  async getDashboard(userId) {
    const [user, subscription, recentCourses, recentExercises, exerciseResults, history] = await Promise.all([
      this.userRepo.findById(userId),
      this.subscriptionRepo.getActiveByUser(userId),
      this.courseRepo.getRecent(userId, 5),
      this.exerciseRepo.getRecent(userId, 5),
      this.exerciseRepo.getResults(userId),
      this.courseRepo.getHistory(userId),
    ]);

    const totalExercises = exerciseResults.length;
    const avgScore = totalExercises > 0
      ? Math.round(exerciseResults.reduce((sum, r) => sum + (r.score / r.total_points) * 100, 0) / totalExercises)
      : 0;
    const completedCourses = history.filter(h => h.completed).length;
    const totalCoursesViewed = history.length;
    const courseProgress = totalCoursesViewed > 0
      ? Math.round(history.reduce((sum, h) => sum + h.progressPercent, 0) / totalCoursesViewed)
      : 0;

    return {
      user,
      subscription,
      progression: {
        courseProgress,
        exerciseAverage: avgScore,
        completedCourses,
        totalExercises,
        overallProgress: Math.round((courseProgress + avgScore) / 2),
      },
      recentCourses,
      recentExercises,
    };
  }
}

module.exports = DashboardService;
