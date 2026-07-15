class ConfigController {
  getConfig(req, res, next) {
    try {
      res.json({
        success: true,
        data: {
          supportPhoneNumber: process.env.SUPPORT_PHONE_NUMBER || '+242060000000',
          supportEmail: process.env.SUPPORT_EMAIL || 'support@klasplus.cg',
          helpUrl: process.env.HELP_URL || 'https://klasplus.cg/help',
        }
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ConfigController();
