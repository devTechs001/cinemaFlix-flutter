const { requireAuth } = require('./auth');

// GET /api/auth/verify — validate a token and return the profile row that
// real_me (companion app) expects as response['user'].
function registerAuthVerifyRoute(app) {
  app.get('/api/auth/verify', requireAuth, async (req, res) => {
    try {
      const User = require('./models/User');
      const user = await User.findById(req.userId).select('-password');
      if (!user) return res.status(404).json({ error: 'User not found' });
      res.json({ user: { ...user.toPublic(), token: req.headers.authorization } });
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });
}

module.exports = { registerAuthVerifyRoute };
