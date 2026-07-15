const DashboardService = require('../../application/services/DashboardService');

const dashboardService = new DashboardService();

class DashboardController {
  async getDashboard(req, res, next) {
    try {
      const data = await dashboardService.getDashboard(req.userId);
      res.json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new DashboardController();
