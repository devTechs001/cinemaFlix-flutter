const jwt = require('jsonwebtoken');
const User = require('./models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'cinemaflix_jwt_secret_change_in_prod';

function generateToken(user) {
  return jwt.sign({ id: user._id.toString(), email: user.email }, JWT_SECRET, { expiresIn: '7d' });
}

async function authMiddleware(req, res, next) {
  const token = req.headers['authorization']?.replace('Bearer ', '');
  if (!token) {
    req.userId = req.headers['x-user-id'] || null;
    return next();
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.id;
    req.userEmail = decoded.email;
  } catch {
    req.userId = req.headers['x-user-id'] || null;
  }
  next();
}

async function requireAuth(req, res, next) {
  await authMiddleware(req, res, () => {});
  if (!req.userId) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  next();
}

module.exports = { generateToken, authMiddleware, requireAuth, JWT_SECRET };
