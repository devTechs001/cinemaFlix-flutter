// CinemaFlix Systems — in-memory stores for admin, wallet, ads, gaming,
// ecommerce, user settings, live tokens and phone OTP. Works with or without
// a connected database so the API is fully explorable in dev mode.
const crypto = require('crypto');

const ADMIN_CODE = process.env.ADMIN_CODE || 'admin123';

// ---------- in-memory state ----------
const db = {
  wallets: new Map(),        // userId -> { diamonds, points, usdCents, transactions: [] }
  ads: [
    { id: 'ad_001', advertiser: 'StreamFlix VPN', tagline: 'Stream anywhere, unblock everything', cta: 'Try Free', banner: '🎬', cpmCents: 45 },
    { id: 'ad_002', advertiser: 'PopcornBox', tagline: 'Movie night kits delivered weekly', cta: 'Get 20% Off', banner: '🍿', cpmCents: 60 },
    { id: 'ad_003', advertiser: 'CineAudio+', tagline: 'Dolby-grade sound for your headphones', cta: 'Listen Now', banner: '🎧', cpmCents: 38 },
  ],
  adEvents: [],              // { adId, userId, type: impression|click, at }
  games: [
    { id: 'quiz_blitz', name: 'CineQuiz Blitz', entryDiamonds: 2, description: 'Answer movie trivia fast for diamonds' },
    { id: 'spin_reel', name: 'Reel Spinner', entryDiamonds: 5, description: 'Spin the reel — win diamonds up to 10x' },
    { id: 'guess_frames', name: 'Guess the Frames', entryDiamonds: 3, description: 'Guess the movie from blurred frames' },
  ],
  gameRound: 0,
  leaderboard: [],           // { userId, username, diamondsWon, rounds } — kept in memory
  sessions: [],              // { id, userId, gameId, stake, reward, at }
  products: [
    { id: 'p_001', sellerId: 'sys', title: 'CinemaFlix Hoodie', priceCents: 4900, stock: 20, approved: true, category: 'Merch' },
    { id: 'p_002', sellerId: 'sys', title: 'Vintage Film Poster Set', priceCents: 2500, stock: 50, approved: true, category: 'Decor' },
  ],
  sellerApplications: new Map(), // userId -> { status: pending|approved|rejected, shopName, at }
  orders: [],
  settings: new Map(),       // userId -> { sounds: {...}, notifications: {...}, autoClean: bool }
  otps: new Map(),           // phone -> { code, expires, attempts }
  liveTokens: new Map(),     // callId -> { token, role, at }
  featureFlags: {
    ecommerce: true,
    gaming: true,
    ads: true,
    dating: true,
    live: true,
    shorts: true,
    walletPoints: true,
  },
  maintenance: { enabled: false, message: 'CinemaFlix is under maintenance. Please try again later.', allowAdmins: true, allowSpecific: [] },
  usersIndex: new Map(),     // in-memory user registry fallback for offline mode
  notificationsSenderOn: true, // toggle for the "random popups" system
};

// ---------- helpers ----------
function requireAdmin(req) {
  return (req.headers['x-admin-code'] || req.query.adminCode) === ADMIN_CODE;
}

function getWallet(userId, username) {
  if (!db.wallets.has(userId)) {
    db.wallets.set(userId, {
      userId,
      username: username || 'user',
      diamonds: 100,
      points: 1000,
      usdCents: 0,
      transactions: [],
      createdAt: new Date().toISOString(),
    });
  }
  return db.wallets.get(userId);
}

function pushTx(wallet, type, currency, amount, note) {
  wallet.transactions.unshift({ id: `tx_${crypto.randomUUID().slice(0, 8)}`, type, currency, amount, note: note || '', at: new Date().toISOString() });
  if (wallet.transactions.length > 200) wallet.transactions.pop();
}

// PHONE OTP
const OTP_TTL_MS = 5 * 60 * 1000;

function requestPhoneOtp(phone) {
  const code = String(Math.floor(100000 + Math.random() * 900000));
  db.otps.set(phone, { code, expires: Date.now() + OTP_TTL_MS, attempts: 0 });
  return code;
}

function verifyPhoneOtp(phone, code) {
  const rec = db.otps.get(phone);
  if (!rec) return { ok: false, error: 'No OTP requested for this phone' };
  if (Date.now() > rec.expires) { db.otps.delete(phone); return { ok: false, error: 'OTP expired' }; }
  rec.attempts += 1;
  if (rec.attempts > 5) { db.otps.delete(phone); return { ok: false, error: 'Too many attempts' }; }
  if (rec.code !== String(code)) return { ok: false, error: 'Invalid code' };
  db.otps.delete(phone);
  return { ok: true, phone };
}

// LIVE tokens (used with the real_me companion app)
function issueLiveToken(callId, role) {
  const token = `dev_${role}_${crypto.randomBytes(16).toString('hex')}`;
  db.liveTokens.set(callId, { token, role, at: new Date().toISOString() });
  return token;
}

// ---------- routes ----------
function registerSystemRoutes(app) {
  // ---- AUTH EXTENSIONS ----
  app.post('/api/auth/oauth/google', async (req, res) => {
    // Dev-simulated Google OAuth: client posts the provider profile payload.
    // In production, verify idToken against Google's JWKs before trusting this.
    const { email, displayName } = req.body || {};
    if (!email) return res.status(400).json({ error: 'email required in oauth payload' });
    const user = await upsertOAuthUser(email.toLowerCase(), displayName || email.split('@')[0], 'google');
    res.json(user);
  });

  app.post('/api/auth/oauth/apple', async (req, res) => {
    const { email, displayName } = req.body || {};
    if (!email) return res.status(400).json({ error: 'email required in oauth payload' });
    const user = await upsertOAuthUser(email.toLowerCase(), displayName || email.split('@')[0], 'apple');
    res.json(user);
  });

  app.post('/api/auth/phone/request-otp', (req, res) => {
    const { phone } = req.body || {};
    if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) return res.status(400).json({ error: 'valid phone required' });
    const code = requestPhoneOtp(phone);
    // Dev convenience: return the code. In production send via SMS provider instead.
    res.json({ sent: true, devCode: code });
  });

  app.post('/api/auth/phone/verify-otp', (req, res) => {
    const { phone, code, username } = req.body || {};
    const result = verifyPhoneOtp(phone, code);
    if (!result.ok) return res.status(400).json({ error: result.error });
    const userId = `phone_${crypto.createHash('sha1').update(phone).digest('hex').slice(0, 12)}`;
    const user = db.usersIndex.get(userId) || { id: userId, email: `${phone}@phone.cinemaflix`, username: username || `CineFan_${phone.slice(-4)}`, createdAt: new Date().toISOString(), banned: false, role: 'user' };
    db.usersIndex.set(userId, user);
    res.json({ user: { id: user.id, email: user.email, username: user.username, token: `phone_${crypto.randomBytes(16).toString('hex')}` } });
  });

  // ---- ADMIN / DEV SYSTEM ----
  app.get('/api/admin/stats', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    let dbUsers = 0;
    res.json({
      users: db.usersIndex.size + dbUsers,
      wallets: db.wallets.size,
      orders: db.orders.length,
      adImpressions: db.adEvents.filter((e) => e.type === 'impression').length,
      adClicks: db.adEvents.filter((e) => e.type === 'click').length,
      gamingSessions: db.sessions.length,
      featureFlags: db.featureFlags,
      maintenance: db.maintenance,
      uptimeSec: Math.round(process.uptime()),
    });
  });

  app.get('/api/admin/feature-flags', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    res.json(db.featureFlags);
  });

  app.put('/api/admin/feature-flags', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    Object.assign(db.featureFlags, req.body || {});
    res.json(db.featureFlags);
  });

  app.get('/api/admin/maintenance', (req, res) => res.json(db.maintenance));

  app.put('/api/admin/maintenance', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    const { enabled, message, allowAdmins, allowSpecific } = req.body || {};
    if (enabled !== undefined) db.maintenance.enabled = !!enabled;
    if (message !== undefined) db.maintenance.message = String(message);
    if (allowAdmins !== undefined) db.maintenance.allowAdmins = !!allowAdmins;
    if (Array.isArray(allowSpecific)) db.maintenance.allowSpecific = allowSpecific;
    res.json(db.maintenance);
  });

  app.put('/api/admin/users/:id/ban', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    const user = db.usersIndex.get(req.params.id);
    if (!user && !getIsConnectedSafe()) return res.status(404).json({ error: 'User not found (not indexed locally)' });
    if (user) user.banned = true;
    res.json({ ok: true, banned: user ? true : 'db-managed', userId: req.params.id });
  });

  app.put('/api/admin/users/:id/unban', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    const user = db.usersIndex.get(req.params.id);
    if (user) user.banned = false;
    res.json({ ok: true, banned: user ? false : 'db-managed', userId: req.params.id });
  });

  // Public status any client reads at boot (no admin rights needed)
  app.get('/api/app/config', (req, res) => {
    res.json({
      version: process.env.APP_VERSION || '1.0.0',
      minSupported: process.env.APP_MIN_VERSION || '1.0.0',
      maintenance: { enabled: db.maintenance.enabled, message: db.maintenance.message },
      featureFlags: db.featureFlags,
      adsEnabled: db.featureFlags.ads && db.notificationsSenderOn,
    });
  });

  // ---- WALLET (wire gifts/points/payments here) ----
  app.get('/api/wallet/:userId', (req, res) => {
    const wallet = getWallet(req.params.userId, req.query.username);
    res.json({ ...wallet, transactions: wallet.transactions.slice(0, 50) });
  });

  app.post('/api/wallet/:userId/spend', (req, res) => {
    const { currency, amount, note } = req.body || {};
    const amt = parseInt(amount, 10);
    if (!['diamonds', 'points'].includes(currency) || !Number.isFinite(amt) || amt <= 0) {
      return res.status(400).json({ error: 'currency (diamonds|points) and positive amount required' });
    }
    const wallet = getWallet(req.params.userId);
    if (wallet[currency] < amt) return res.status(402).json({ error: `Insufficient ${currency}` });
    wallet[currency] -= amt;
    pushTx(wallet, 'spend', currency, -amt, note);
    res.json({ ...wallet, transactions: wallet.transactions.slice(0, 50) });
  });

  app.post('/api/wallet/:userId/earn', (req, res) => {
    const { currency, amount, note } = req.body || {};
    const amt = parseInt(amount, 10);
    if (!['diamonds', 'points', 'usdCents'].includes(currency) || !Number.isFinite(amt) || amt <= 0) {
      return res.status(400).json({ error: 'currency (diamonds|points|usdCents) and positive amount required' });
    }
    const wallet = getWallet(req.params.userId);
    wallet[currency] += amt;
    pushTx(wallet, 'earn', currency, amt, note);
    res.json({ ...wallet, transactions: wallet.transactions.slice(0, 50) });
  });

  app.post('/api/wallet/:userId/convert', (req, res) => {
    const { from, amount } = req.body || {};
    const amt = parseInt(amount, 10);
    const RATES = { points: 10, diamonds: 1 }; // 1 diamond = 10 points
    if (!RATES[from] || !Number.isFinite(amt) || amt <= 0) return res.status(400).json({ error: 'from (points|diamonds) and positive amount required' });
    const wallet = getWallet(req.params.userId);
    if (from === 'points') {
      if (wallet.points < amt) return res.status(402).json({ error: 'Insufficient points' });
      const diamonds = Math.floor(amt / RATES.points);
      wallet.points -= amt;
      wallet.diamonds += diamonds;
      pushTx(wallet, 'convert', 'points→diamonds', diamonds, `${amt} points → ${diamonds} diamonds`);
      res.json({ ...wallet, transactions: wallet.transactions.slice(0, 50) });
    } else {
      if (wallet.diamonds < amt) return res.status(402).json({ error: 'Insufficient diamonds' });
      wallet.diamonds -= amt;
      wallet.points += amt * RATES.points;
      pushTx(wallet, 'convert', 'diamonds→points', -amt, `${amt} diamonds → ${amt * RATES.points} points`);
      res.json({ ...wallet, transactions: wallet.transactions.slice(0, 50) });
    }
  });

  app.post('/api/wallet/:userId/gift', (req, res) => {
    const { toUserId, currency, amount, note } = req.body || {};
    const amt = parseInt(amount, 10);
    const from = getWallet(req.params.userId);
    const to = getWallet(toUserId);
    if (!['diamonds', 'points'].includes(currency) || !Number.isFinite(amt) || amt <= 0) {
      return res.status(400).json({ error: 'currency (diamonds|points) and positive amount required' });
    }
    if (from[currency] < amt) return res.status(402).json({ error: `Insufficient ${currency}` });
    from[currency] -= amt;
    to[currency] += amt;
    pushTx(from, 'gift-out', currency, -amt, note || `Gift to ${to.username}`);
    pushTx(to, 'gift-in', currency, amt, note || `Gift from ${from.username}`);
    res.json({ from: from, to: to });
  });

  // ---- ADS ----
  app.get('/api/ads', (req, res) => {
    if (!db.featureFlags.ads) return res.json({ ads: [] });
    const { context = 'general' } = req.query; // general | shorts | between-movies
    const ads = db.ads.filter(() => true);
    res.json({ context, ads });
  });

  app.post('/api/ads/:id/impression', (req, res) => {
    db.adEvents.push({ adId: req.params.id, userId: req.userId || null, type: 'impression', at: new Date().toISOString() });
    res.json({ ok: true });
  });

  app.post('/api/ads/:id/click', (req, res) => {
    db.adEvents.push({ adId: req.params.id, userId: req.userId || null, type: 'click', at: new Date().toISOString() });
    // Small reward for clicking the ad ("earn from ads" system)
    const w = getWallet(req.userId || 'guest');
    if (req.userId) { w.points += 2; pushTx(w, 'ad-reward', 'points', 2, 'Ad interaction'); }
    res.json({ ok: true, rewarded: !!req.userId, points: req.userId ? 2 : 0 });
  });

  app.get('/api/admin/ads/stats', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    res.json({ events: db.adEvents.slice(-200), partners: db.ads });
  });

  // ---- GAMING ----
  app.get('/api/games', (req, res) => {
    if (!db.featureFlags.gaming) return res.status(403).json({ error: 'Gaming disabled by admin' });
    res.json({ games: db.games });
  });

  app.post('/api/games/:id/play', (req, res) => {
    if (!db.featureFlags.gaming) return res.status(403).json({ error: 'Gaming disabled by admin' });
    const game = db.games.find((g) => g.id === req.params.id);
    if (!game) return res.status(404).json({ error: 'Game not found' });
    if (!req.userId) return res.status(401).json({ error: 'Auth required to play' });
    const wallet = getWallet(req.userId, req.body?.username);
    if (wallet.diamonds < game.entryDiamonds) return res.status(402).json({ error: 'Insufficient diamonds' });
    wallet.diamonds -= game.entryDiamonds;
    db.gameRound += 1;
    // Deterministic-ish pseudo reward: 60% lose nothing, 40% win 1..10x stake
    const roll = Math.random();
    let multiplier = 0;
    if (roll < 0.25) multiplier = 0.5;
    else if (roll < 0.4) multiplier = 1;
    else if (roll < 0.46) multiplier = 3;
    else if (roll < 0.49) multiplier = 10;
    const reward = Math.floor(game.entryDiamonds * multiplier);
    if (reward > 0) wallet.diamonds += reward;
    pushTx(wallet, 'game', 'diamonds', reward > 0 ? reward : -game.entryDiamonds, `${game.name} round #${db.gameRound}`);
    db.sessions.push({ id: `s_${crypto.randomUUID().slice(0, 8)}`, userId: req.userId, gameId: game.id, stake: game.entryDiamonds, reward, at: new Date().toISOString() });
    db.sessions = db.sessions.slice(-500);
    const entry = db.leaderboard.find((e) => e.userId === req.userId);
    if (entry) { entry.rounds += 1; entry.diamondsWon += Math.max(reward - game.entryDiamonds, 0); }
    else db.leaderboard.push({ userId: req.userId, username: wallet.username || req.body?.username || 'player', diamondsWon: Math.max(reward - game.entryDiamonds, 0), rounds: 1 });
    res.json({ outcome: reward > 0 ? 'win' : 'lose', reward, multiplier, wallet: { ...wallet, transactions: wallet.transactions.slice(0, 20) } });
  });

  app.get('/api/games/leaderboard', (req, res) => {
    res.json({ leaderboard: [...db.leaderboard].sort((a, b) => b.diamondsWon - a.diamondsWon).slice(0, 20) });
  });

  // ---- ECOMMERCE (admin-approved sellers) ----
  app.get('/api/ecommerce/products', (req, res) => {
    const approved = req.query.all === 'true' && requireAdmin(req);
    const list = db.products.filter((p) => approved || p.approved);
    res.json({ products: list });
  });

  app.post('/api/ecommerce/seller/apply', (req, res) => {
    if (!req.userId) return res.status(401).json({ error: 'Auth required' });
    const { shopName, category } = req.body || {};
    if (!shopName) return res.status(400).json({ error: 'shopName required' });
    db.sellerApplications.set(req.userId, { shopName, category: category || 'General', status: 'pending', at: new Date().toISOString() });
    res.json({ ok: true, status: 'pending', message: 'Application submitted — an admin must approve you before the seller nav appears' });
  });

  app.get('/api/ecommerce/seller/status', (req, res) => {
    const appRec = db.sellerApplications.get(req.userId || '');
    res.json({ application: appRec ? { ...appRec, approved: appRec.status === 'approved' } : { status: 'none', approved: false } });
  });

  app.put('/api/ecommerce/seller/:userId/approve', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    const rec = db.sellerApplications.get(req.params.userId);
    if (!rec) return res.status(404).json({ error: 'No application from this user' });
    rec.status = 'approved';
    res.json({ ok: true, application: rec });
  });

  app.post('/api/ecommerce/products', (req, res) => {
    if (!req.userId) return res.status(401).json({ error: 'Auth required' });
    const rec = db.sellerApplications.get(req.userId);
    if (!rec || rec.status !== 'approved') return res.status(403).json({ error: 'Only approved sellers can post products' });
    const { title, priceCents, stock, category } = req.body || {};
    if (!title || !priceCents) return res.status(400).json({ error: 'title and priceCents required' });
    const product = { id: `p_${crypto.randomUUID().slice(0, 8)}`, sellerId: req.userId, title, priceCents: parseInt(priceCents, 10), stock: parseInt(stock || 1, 10), approved: false, category: category || 'General', postedBy: rec.shopName };
    db.products.push(product);
    res.status(201).json({ product, note: 'Posted — products also flow into the feed/shorts after approval' });
  });

  app.post('/api/ecommerce/orders', (req, res) => {
    if (!req.userId) return res.status(401).json({ error: 'Auth required' });
    const { productId } = req.body || {};
    const product = db.products.find((p) => p.id === productId && p.approved);
    if (!product) return res.status(404).json({ error: 'Product not found or not approved' });
    if (product.stock <= 0) return res.status(409).json({ error: 'Out of stock' });
    const priceDiamonds = Math.ceil(product.priceCents / 10); // 10 points-diamonds parity: 1 diamond ≈ $0.10
    const wallet = getWallet(req.userId);
    if (wallet.diamonds < priceDiamonds) return res.status(402).json({ error: `Costs ${priceDiamonds} diamonds` });
    wallet.diamonds -= priceDiamonds;
    product.stock -= 1;
    pushTx(wallet, 'purchase', 'diamonds', -priceDiamonds, product.title);
    const order = { id: `o_${crypto.randomUUID().slice(0, 8)}`, productId, buyerId: req.userId, diamondsPaid: priceDiamonds, at: new Date().toISOString() };
    db.orders.push(order);
    res.status(201).json({ order, wallet: { diamonds: wallet.diamonds } });
  });

  // ---- SOUNDS / SETTINGS ENDPOINTS ----
  app.get('/api/settings/:userId', (req, res) => {
    const s = db.settings.get(req.params.userId) || defaultSettings();
    res.json(s);
  });

  app.put('/api/settings/:userId', (req, res) => {
    const current = db.settings.get(req.params.userId) || defaultSettings();
    const merged = { ...current, ...(req.body || {}), sounds: { ...current.sounds, ...((req.body || {}).sounds || {}) } };
    db.settings.set(req.params.userId, merged);
    res.json(merged);
  });

  function defaultSettings() {
    return {
      sounds: { notification: true, success: true, transaction: true, like: true, comment: true, celebrate: true, popups: true },
      autoClean: { enabled: true, clearCacheDays: 14, clearOfflineVideos: false },
      popups: { enabled: true, reminders: true, engagement: true },
    };
  }

  // ---- LIVE (real_me interop) ----
  app.post('/api/live/create', (req, res) => {
    if (!req.userId) return regstatus(res);
    const { title } = req.body || {};
    const callId = `live_${crypto.randomUUID().slice(0, 10)}`;
    const token = issueLiveToken(callId, 'host');
    res.status(201).json({ callId, hostToken: token, backends: ['realme-bridge', 'native'], title: title || 'Untitled live' });
  });

  app.post('/api/live/viewer/token', (req, res) => {
    const { callId } = req.body || {};
    if (!db.liveTokens.has(callId)) return res.status(404).json({ error: 'Live room not found' });
    const token = issueLiveToken(callId, 'viewer');
    res.json({ callId, viewerToken: token });
  });

  app.get('/api/live/rooms', (req, res) => {
    res.json({ rooms: [...db.liveTokens.entries()].map(([callId, v]) => ({ callId, role: v.role, startedAt: v.at })) });
  });

  function regstatus(res) { return res.status(401).json({ error: 'Auth required' }); }

  // ---- NOTIFICATION POPUP TOGGLES (admin) ----
  app.put('/api/admin/popups', (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    if (req.body?.enabled !== undefined) db.notificationsSenderOn = !!req.body.enabled;
    res.json({ enabled: db.notificationsSenderOn });
  });
}

// OAuth upsert shared by google/apple (falls back to local registry if DB is down)
async function upsertOAuthUser(email, displayName, provider) {
  const { generateToken } = require('./auth');
  const User = require('./models/User');
  try {
    let user = await User.findOne({ email });
    if (!user) user = await User.create({ email, username: displayName || email.split('@')[0], password: `oauth_${provider}_${crypto.randomUUID()}` });
    const token = generateToken(user);
    return { user: { ...user.toPublic(), token, provider } };
  } catch (e) {
    const id = `oauth_${crypto.createHash('sha1').update(email).digest('hex').slice(0, 12)}`;
    const user = db.usersIndex.get(id) || { id, email, username: displayName || email.split('@')[0], createdAt: new Date().toISOString(), banned: false, role: 'user', provider };
    db.usersIndex.set(id, user);
    return { user: { id: user.id, email: user.email, username: user.username, token: `oauth_${crypto.randomBytes(16).toString('hex')}`, provider, offline: true } };
  }
}

// used by ban/unban to know whether DB accounts are available
function getIsConnectedSafe() {
  try { return require('./db').getIsConnected(); } catch { return false; }
}

module.exports = { registerSystemRoutes, db, getWallet, ADMIN_CODE };
