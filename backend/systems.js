// CinemaFlix Systems — admin, wallet, ads, gaming, ecommerce, settings, live
// tokens, realtime notifications and phone OTP. Two storage modes with an
// identical interface:
//   • mongoStore  — durable Mongoose models (backend/models/systems.js)
//   • memoryStore — in-memory Maps, used when the database is unavailable
// so the API is fully explorable in dev mode without a database.
const crypto = require('crypto');
const https = require('https');

const { verifyIdToken } = require('./oauth');
const models = require('./models/systems');

// Admin endpoints require the `x-admin-code` header to match ADMIN_CODE.
// No shared default: with ADMIN_CODE unset a random code is generated at
// boot and printed to the server console (see below).
const ADMIN_CODE = process.env.ADMIN_CODE || (() => {
  const generated = require('crypto').randomBytes(9).toString('base64url');
  console.warn(`[admin] ADMIN_CODE not set — generated one-time code: ${generated}`);
  console.warn('[admin] Set ADMIN_CODE in your environment to pick your own.');
  return generated;
})();
const OAUTH_DEV_MODE = process.env.OAUTH_DEV_MODE === 'true';

// ---------- in-memory stores (fallback mode) ----------
const memory = {
  wallets: new Map(),
  adEvents: [],
  sessions: [],
  products: [
    { id: 'p_001', sellerId: 'sys', title: 'CinemaFlix Hoodie', priceCents: 4900, stock: 20, approved: true, category: 'Merch' },
    { id: 'p_002', sellerId: 'sys', title: 'Vintage Film Poster Set', priceCents: 2500, stock: 50, approved: true, category: 'Decor' },
  ],
  sellerApplications: new Map(),
  orders: [],
  settings: new Map(),
  otps: new Map(),
  liveTokens: new Map(),
  liveRooms: new Map(),
  liveRequests: new Map(),
  usersIndex: new Map(),
  leaderboard: [],
};

// Mutable admin config in fallback mode
const memoryFlags = {
  ecommerce: true,
  gaming: true,
  ads: true,
  dating: true,
  live: true,
  shorts: true,
  walletPoints: true,
  chat: true,
};
const memoryMaintenance = {
  enabled: false,
  message: 'CinemaFlix is under maintenance. Please try again later.',
  allowAdmins: true,
  allowSpecific: [],
};

// ---------- live state durability (real_me companion bridge) ----------
// The real_me companion reads rooms from GET /api/live/rooms. Keep that
// view truthful across backend restarts by flushing room/request/token
// state to disk after every mutation and restoring on boot. Hosts mark
// themselves present with PUT /api/live/rooms/:id/heartbeat — rooms
// without a recent beat are pruned from the room list.
const fs = require('fs');
const path = require('path');
const LIVE_STATE_FILE = path.join(__dirname, 'data', 'live_state.json');
const LIVE_STALE_MS = Number(process.env.LIVE_STALE_MS || 90000);
const LIVE_MAX_AGE_MS = Number(process.env.LIVE_MAX_AGE_MS || 4 * 60 * 60 * 1000);
let liveFlushTimer = null;
let liveFlushPending = false;

function loadLiveState() {
  try {
    if (!fs.existsSync(LIVE_STATE_FILE)) return;
    const raw = JSON.parse(fs.readFileSync(LIVE_STATE_FILE, 'utf8'));
    for (const [k, v] of raw.rooms || []) memory.liveRooms.set(k, v);
    for (const [k, v] of raw.requests || []) memory.liveRequests.set(k, v);
    for (const [k, v] of raw.tokens || []) memory.liveTokens.set(k, v);
    const count = (raw.rooms || []).length;
    if (count) console.log(`[live] restored ${count} room(s) from ${LIVE_STATE_FILE}`);
  } catch (e) {
    console.warn(`[live] state restore failed: ${e.message}`);
  }
}

function persistLiveState() {
  liveFlushPending = true;
  if (liveFlushTimer) return; // debounce: one write per 250ms window
  liveFlushTimer = setTimeout(() => {
    liveFlushTimer = null;
    if (!liveFlushPending) return;
    liveFlushPending = false;
    try {
      fs.mkdirSync(path.dirname(LIVE_STATE_FILE), { recursive: true });
      fs.writeFileSync(LIVE_STATE_FILE, JSON.stringify({
        savedAt: new Date().toISOString(),
        rooms: [...memory.liveRooms.entries()],
        requests: [...memory.liveRequests.entries()],
        tokens: [...memory.liveTokens.entries()],
      }));
    } catch (e) {
      console.warn(`[live] state persist failed: ${e.message}`);
    }
  }, 250);
}

loadLiveState();

function dbConnected() {
  try { return require('./db').getIsConnected(); } catch { return false; }
}

// ---------- STORE: feature flags / maintenance ----------
async function getFeatureFlags() {
  if (!dbConnected()) return memoryFlags;
  const doc = await models.AdminConfig.findOne({ key: 'featureFlags' });
  return doc?.value || memoryFlags;
}

async function setFeatureFlags(partial) {
  if (!dbConnected()) { Object.assign(memoryFlags, partial); return memoryFlags; }
  const merged = { ...(await getFeatureFlags()), ...partial };
  await models.AdminConfig.updateOne({ key: 'featureFlags' }, { key: 'featureFlags', value: merged }, { upsert: true });
  return merged;
}

async function getMaintenance() {
  if (!dbConnected()) return memoryMaintenance;
  const doc = await models.AdminConfig.findOne({ key: 'maintenance' });
  return doc?.value || memoryMaintenance;
}

async function setMaintenance(partial) {
  if (!dbConnected()) { Object.assign(memoryMaintenance, partial); return memoryMaintenance; }
  const merged = { ...(await getMaintenance()), ...partial };
  await models.AdminConfig.updateOne({ key: 'maintenance' }, { key: 'maintenance', value: merged }, { upsert: true });
  return merged;
}

// ---------- STORE: users (oauth/phone fallback registry) ----------
async function upsertLocalUser({ idEmail, username, password }) {
  if (!dbConnected()) {
    const id = idEmail.startsWith('phone_') ? idEmail : `oauth_${crypto.createHash('sha1').update(idEmail).digest('hex').slice(0, 12)}`;
    const user = memory.usersIndex.get(id) || { id, email: idEmail, username: username || idEmail.split('@')[0], createdAt: new Date().toISOString(), banned: false, role: 'user' };
    memory.usersIndex.set(id, user);
    return { user, jwt: null };
  }
  const User = require('./models/User');
  let user = await User.findOne({ email: idEmail });
  if (!user) user = await User.create({ email: idEmail, username: username || idEmail.split('@')[0], password: password || `sys_${crypto.randomUUID()}` });
  return { user, jwt: require('./auth').generateToken(user) };
}

// ---------- STORE: wallets ----------
function getMemoryWallet(userId, username) {
  if (!memory.wallets.has(userId)) {
    memory.wallets.set(userId, {
      userId,
      username: username || 'user',
      diamonds: 100,
      points: 1000,
      usdCents: 0,
      transactions: [],
      createdAt: new Date().toISOString(),
    });
  }
  return memory.wallets.get(userId);
}

function pushTx(w, type, currency, amount, note) {
  w.transactions.unshift({ id: `tx_${crypto.randomUUID().slice(0, 8)}`, type, currency, amount, note: note || '', at: new Date().toISOString() });
  if (w.transactions.length > 200) w.transactions.pop();
}

/// Always resolves a wallet object, Mongo-backed when possible.
async function walletDoc(userId, username) {
  if (!dbConnected()) return getMemoryWallet(userId, username);
  let doc = await models.Wallet.findOne({ userId });
  if (!doc) {
    try {
      doc = await models.Wallet.create({ userId, username: username || 'user' });
    } catch {
      doc = await models.Wallet.findOne({ userId });
    }
  }
  if (!doc) return getMemoryWallet(userId, username); // race safeguard
  return doc;
}

function walletJSON(w) {
  const plain = w.toObject ? w.toObject() : w;
  delete plain._id;
  delete plain.__v;
  return {
    ...plain,
    transactions: (plain.transactions || []).slice(0, 50),
  };
}

// ---------- STORE: settings ----------
async function settingsDoc(userId) {
  if (!dbConnected()) {
    if (!memory.settings.has(userId)) memory.settings.set(userId, defaultSettings());
    return memory.settings.get(userId);
  }
  let doc = await models.UserSettings.findOne({ userId });
  if (!doc) doc = await models.UserSettings.create({ userId });
  const plain = doc.toObject();
  delete plain._id;
  delete plain.__v;
  return plain;
}

async function saveSettings(userId, partial) {
  const current = await settingsDoc(userId);
  const merged = {
    ...current,
    ...partial,
    sounds: { ...defaultSettings().sounds, ...(current.sounds || {}), ...((partial || {}).sounds || {}) },
    autoClean: { ...defaultSettings().autoClean, ...(current.autoClean || {}), ...((partial || {}).autoClean || {}) },
    popups: { ...defaultSettings().popups, ...(current.popups || {}), ...((partial || {}).popups || {}) },
  };
  if (!dbConnected()) { memory.settings.set(userId, merged); return merged; }
  await models.UserSettings.updateOne({ userId }, merged, { upsert: true });
  return merged;
}

function defaultSettings() {
  return {
    sounds: { notification: true, success: true, transaction: true, like: true, comment: true, celebrate: true, popups: true },
    autoClean: { enabled: true, clearCacheDays: 14, clearOfflineVideos: false },
    popups: { enabled: true, reminders: true, engagement: true },
  };
}

// ---------- STORE: products / sellers / orders ----------
async function listProducts({ includeUnapproved }) {
  if (!dbConnected()) {
    return memory.products.filter((p) => includeUnapproved || p.approved);
  }
  const docs = includeUnapproved
    ? await models.Product.find().sort({ createdAt: -1 })
    : await models.Product.find({ approved: true }).sort({ createdAt: -1 });
  return docs.map((d) => ({ ...d.toObject(), _id: undefined, __v: undefined }));
}

async function createProduct(product) {
  if (!dbConnected()) { memory.products.push(product); return product; }
  const doc = await models.Product.create(product);
  return { ...doc.toObject(), _id: undefined, __v: undefined };
}

async function findProduct(id) {
  if (!dbConnected()) return memory.products.find((p) => p.id === id && p.approved);
  const doc = await models.Product.findOne({ id, approved: true });
  return doc ? doc.toObject() : null;
}

async function updateProductStock(id, delta) {
  const p = await findProduct(id);
  if (p) {
    if (dbConnected()) {
      await models.Product.updateOne({ id }, { $inc: { stock: delta } });
    } else {
      p.stock += delta;
    }
  }
}

async function sellerApplication(userId) {
  if (!dbConnected()) return memory.sellerApplications.get(userId) || null;
  const doc = await models.SellerApplication.findOne({ userId });
  return doc ? doc.toObject() : null;
}

async function setSellerApplication(userId, rec) {
  rec.userId = userId;
  if (!dbConnected()) { memory.sellerApplications.set(userId, rec); return rec; }
  await models.SellerApplication.updateOne({ userId }, rec, { upsert: true });
  return { ...rec };
}

async function addOrder(order) {
  if (!dbConnected()) { memory.orders.push(order); return; }
  await models.Order.create(order);
}

// ---------- STORE: gaming ----------
async function saveGameSession(session) {
  if (!dbConnected()) { memory.sessions.push(session); memory.sessions = memory.sessions.slice(-500); return; }
  await models.GameSession.create(session);
  if (memory.sessions.length > 500) memory.sessions.length = 500; // dev-view cap
}

async function upsertLeaderboard(userId, username, diamondsWon, rounds) {
  if (!dbConnected()) {
    const entry = memory.leaderboard.find((e) => e.userId === userId);
    if (entry) { entry.rounds += rounds; entry.diamondsWon += diamondsWon; }
    else memory.leaderboard.push({ userId, username, diamondsWon, rounds });
    return;
  }
  await models.LeaderboardEntry.updateOne(
    { userId },
    { userId, username, $inc: { diamondsWon, rounds } },
    { upsert: true },
  );
}

async function listLeaderboard() {
  if (!dbConnected()) {
    return [...memory.leaderboard].sort((a, b) => b.diamondsWon - a.diamondsWon).slice(0, 20);
  }
  const docs = await models.LeaderboardEntry.find().sort({ diamondsWon: -1 }).limit(20);
  return docs.map((d) => d.toObject());
}

// ---------- STORE: ad events ----------
async function addAdEvent(event) {
  if (!dbConnected()) { memory.adEvents.push(event); memory.adEvents = memory.adEvents.slice(-1000); return; }
  await models.AdEvent.create(event);
  if (memory.adEvents.length > 1000) memory.adEvents.length = 1000;
}

async function adEventStats() {
  if (!dbConnected()) return memory.adEvents;
  const docs = await models.AdEvent.find().sort({ at: -1 }).limit(200);
  return docs.map((d) => ({ ...d.toObject(), at: d.at, _id: undefined, __v: undefined }));
}

// ---------- SMS (phone OTP provider) ----------
const OTP_TTL_MS = 5 * 60 * 1000;

function requestPhoneOtp(phone) {
  const code = String(Math.floor(100000 + Math.random() * 900000));
  memory.otps.set(phone, { code, expires: Date.now() + OTP_TTL_MS, attempts: 0 });
  return code;
}

function verifyPhoneOtp(phone, code) {
  const rec = memory.otps.get(phone);
  if (!rec) return { ok: false, error: 'No OTP requested for this phone' };
  if (Date.now() > rec.expires) { memory.otps.delete(phone); return { ok: false, error: 'OTP expired' }; }
  rec.attempts += 1;
  if (rec.attempts > 5) { memory.otps.delete(phone); return { ok: false, error: 'Too many attempts' }; }
  if (rec.code !== String(code)) return { ok: false, error: 'Invalid code' };
  memory.otps.delete(phone);
  return { ok: true, phone };
}

/// Sends via Twilio when configured; resolves to a devCode otherwise.
function sendSms(phone, text) {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_FROM_NUMBER;
  if (!sid || !token || !from) return Promise.resolve(null); // dev fallback
  const payload = new URLSearchParams({ To: phone, From: from, Body: text }).toString();
  return new Promise((resolve) => {
    const req = https.request(
      {
        hostname: 'api.twilio.com',
        path: `/2010-04-01/Accounts/${sid}/Messages.json`,
        method: 'POST',
        auth: `${sid}:${token}`,
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': Buffer.byteLength(payload) },
        timeout: 8000,
      },
      (res) => resolve(res.statusCode >= 200 && res.statusCode < 300),
    );
    req.on('error', () => resolve(false));
    req.on('timeout', () => { req.destroy(); resolve(false); });
    req.write(payload);
    req.end();
  });
}  // ---------- LIVE tokens (real_me interop) ----------
  function issueLiveToken(callId, role) {
    const token = `dev_${role}_${crypto.randomBytes(16).toString('hex')}`;
    const prev = memory.liveTokens.get(callId) || {};
    memory.liveTokens.set(callId, { ...prev, token, role, at: new Date().toISOString() });
    persistLiveState();
    return token;
  }

function requireAdmin(req) {
  return (req.headers['x-admin-code'] || req.query.adminCode) === ADMIN_CODE;
}

// ---------- ROUTES ----------
function registerSystemRoutes(app, realtime) {
  const notify = realtime?.broadcastNotification ?? (() => {});

  // ---- AUTH EXTENSIONS ----
  app.post('/api/auth/oauth/google', async (req, res) => {
    try {
      const result = await verifyGoogleApple(req, 'google');
      const user = await upsertOAuthUser(result.email, result.displayName, 'google');
      res.json(user);
    } catch (e) {
      res.status(401).json({ error: e.message || 'OAuth verification failed' });
    }
  });

  app.post('/api/auth/oauth/apple', async (req, res) => {
    try {
      const result = await verifyGoogleApple(req, 'apple');
      const user = await upsertOAuthUser(result.email, result.displayName, 'apple');
      res.json(user);
    } catch (e) {
      res.status(401).json({ error: e.message || 'OAuth verification failed' });
    }
  });

  async function verifyGoogleApple(req, provider) {
    const { idToken, email, displayName } = req.body || {};
    if (!idToken && OAUTH_DEV_MODE && email) {
      // Controlled dev fallback — must be enabled with OAUTH_DEV_MODE=true.
      console.warn(`[oauth:${provider}] DEV MODE: accepting unverified email ${email}`);
      return { email: email.toLowerCase(), displayName };
    }
    const verified = await verifyIdToken(provider, idToken, req.body?.clientId);
    if (verified.mode === 'dev') {
      // No idToken but dev mode enabled — still needs an email to enroll.
      if (!email) throw new Error('email required in dev mode');
      console.warn(`[oauth:${provider}] DEV MODE: simulated sign-in for ${email}`);
      return { email: email.toLowerCase(), displayName };
    }
    if (!verified.emailVerified) throw new Error('Provider email not verified');
    return verified;
  }

  app.post('/api/auth/phone/request-otp', async (req, res) => {
    const { phone } = req.body || {};
    if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) return res.status(400).json({ error: 'valid phone required (+E.164)' });
    const code = requestPhoneOtp(phone);
    const sent = await sendSms(phone, `CinemaFlix verification code: ${code}. Expires in 5 minutes.`);
    // Only return the code when no SMS provider is configured (dev convenience).
    res.json({ sent: true, ...(sent ? {} : { devCode: code, via: 'dev' }) });
  });

  app.post('/api/auth/phone/verify-otp', async (req, res) => {
    const { phone, code, username } = req.body || {};
    const result = verifyPhoneOtp(phone, code);
    if (!result.ok) return res.status(400).json({ error: result.error });
    const userId = `phone_${crypto.createHash('sha1').update(phone).digest('hex').slice(0, 12)}`;
    const { user, jwt } = await upsertLocalUser({
      idEmail: `${phone.replace(/[^0-9]/g, '')}@phone.cinemaflix`,
      username: username || `CineFan_${phone.slice(-4)}`,
    });
    const token = jwt || `phone_${crypto.randomBytes(16).toString('hex')}`;
    const id = user._id ? user._id.toString() : user.id;
    res.json({ user: { id, email: user.email ?? user.email, username: user.username, token, via: jwt ? 'db' : 'memory' } });
  });

  // ---- ADMIN / DEV SYSTEM ----
  app.get('/api/admin/stats', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    res.json({
      users: memory.usersIndex.size + (dbConnected() ? await countUsers() : 0),
      wallets: dbConnected() ? await models.Wallet.countDocuments() : memory.wallets.size,
      orders: dbConnected() ? await models.Order.countDocuments() : memory.orders.length,
      adImpressions: (await adEventStats()).filter((e) => e.type === 'impression').length,
      adClicks: (await adEventStats()).filter((e) => e.type === 'click').length,
      gamingSessions: dbConnected() ? await models.GameSession.countDocuments() : memory.sessions.length,
      sellers: dbConnected() ? await models.SellerApplication.countDocuments() : memory.sellerApplications.size,
      products: dbConnected() ? await models.Product.countDocuments() : memory.products.length,
      featureFlags: await getFeatureFlags(),
      maintenance: await getMaintenance(),
      storage: dbConnected() ? 'mongo' : 'memory',
      uptimeSec: Math.round(process.uptime()),
    });
  });

  async function countUsers() {
    const User = require('./models/User');
    return User.countDocuments();
  }

  app.get('/api/admin/feature-flags', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    res.json(await getFeatureFlags());
  });

  app.put('/api/admin/feature-flags', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    res.json(await setFeatureFlags(req.body || {}));
  });

  app.get('/api/admin/maintenance', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    res.json(await getMaintenance());
  });

  app.put('/api/admin/maintenance', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    const { enabled, message, allowAdmins, allowSpecific } = req.body || {};
    const patch = {};
    if (enabled !== undefined) patch.enabled = !!enabled;
    if (message !== undefined) patch.message = String(message);
    if (allowAdmins !== undefined) patch.allowAdmins = !!allowAdmins;
    if (Array.isArray(allowSpecific)) patch.allowSpecific = allowSpecific;
    const saved = await setMaintenance(patch);
    if (saved.enabled) {
      notify({ title: 'Maintenance', body: saved.message });
    }
    res.json(saved);
  });

  app.put('/api/admin/users/:id/ban', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    let status = 'not-found';
    if (dbConnected()) {
      const User = require('./models/User');
      const user = await User.findById(req.params.id);
      if (user) { user.set('banned', true); await user.save(); status = 'banned'; }
    }
    const local = memory.usersIndex.get(req.params.id);
    if (local) { local.banned = true; status = 'banned'; }
    res.json({ ok: true, status, found: status !== 'not-found', userId: req.params.id });
  });

  app.put('/api/admin/users/:id/unban', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    let status = 'not-found';
    if (dbConnected()) {
      const User = require('./models/User');
      const user = await User.findById(req.params.id);
      if (user) { user.set('banned', false); await user.save(); status = 'unbanned'; }
    }
    const local = memory.usersIndex.get(req.params.id);
    if (local) { local.banned = false; status = 'unbanned'; }
    res.json({ ok: true, status, found: status !== 'not-found', userId: req.params.id });
  });

  // ---- ADMIN: full-system management lists (admin code required) ----
  app.get('/api/admin/users', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    if (dbConnected()) {
      const docs = await require('./models/User').find().select('-password').sort({ createdAt: -1 }).limit(200);
      return res.json({
        users: docs.map((d) => ({ id: d._id.toString(), username: d.username, email: d.email, banned: !!d.banned, createdAt: d.createdAt })),
      });
    }
    res.json({
      users: [...memory.usersIndex.values()].map((u) => ({ id: u.id, username: u.username, email: u.email, banned: !!u.banned, createdAt: u.createdAt })),
    });
  });

  app.get('/api/admin/sellers', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    if (dbConnected()) {
      const docs = await models.SellerApplication.find().sort({ at: -1 });
      return res.json({ sellers: docs.map((d) => { const o = d.toObject(); o._id = undefined; o.__v = undefined; return o; }) });
    }
    res.json({ sellers: [...memory.sellerApplications.entries()].map(([userId, rec]) => ({ userId, ...rec })) });
  });

  app.get('/api/admin/orders', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    if (dbConnected()) {
      const docs = await models.Order.find().sort({ at: -1 }).limit(100);
      return res.json({ orders: docs.map((d) => { const o = d.toObject(); o._id = undefined; o.__v = undefined; return o; }) });
    }
    res.json({ orders: [...memory.orders].slice(-100).reverse() });
  });

  // Public status any client reads at boot (no admin rights needed)
  app.get('/api/app/config', async (req, res) => {
    const maintenance = await getMaintenance();
    const flags = await getFeatureFlags();
    res.json({
      version: process.env.APP_VERSION || '1.0.0',
      minSupported: process.env.APP_MIN_VERSION || '1.0.0',
      maintenance: { enabled: maintenance.enabled, message: maintenance.message },
      featureFlags: flags,
      adsEnabled: flags.ads,
      storage: dbConnected() ? 'mongo' : 'memory',
    });
  });

  // ---- WALLET (wire gifts/points/payments here) ----
  app.get('/api/wallet/:userId', async (req, res) => {
    const wallet = await walletDoc(req.params.userId, req.query.username);
    res.json(walletJSON(wallet));
  });

  app.post('/api/wallet/:userId/spend', async (req, res) => {
    const { currency, amount, note } = req.body || {};
    const amt = parseInt(amount, 10);
    if (!['diamonds', 'points'].includes(currency) || !Number.isFinite(amt) || amt <= 0) {
      return res.status(400).json({ error: 'currency (diamonds|points) and positive amount required' });
    }
    const wallet = await walletDoc(req.params.userId);
    if (wallet[currency] < amt) return res.status(402).json({ error: `Insufficient ${currency}` });
    wallet[currency] -= amt;
    pushTx(wallet, 'spend', currency, -amt, note);
    await saveWallet(wallet);
    res.json(walletJSON(wallet));
  });

  // Admin flag `walletPoints` switches point earning/conversion off
  // platform-wide (diamonds keep working).
  const pointsGate = async (req, res, next) => {
    const flags = await getFeatureFlags();
    if (flags.walletPoints === false) return res.status(403).json({ error: 'Wallet points are disabled by admin' });
    next();
  };

  app.post('/api/wallet/:userId/earn', pointsGate, async (req, res) => {
    const { currency, amount, note } = req.body || {};
    const amt = parseInt(amount, 10);
    if (!['diamonds', 'points', 'usdCents'].includes(currency) || !Number.isFinite(amt) || amt <= 0) {
      return res.status(400).json({ error: 'currency (diamonds|points|usdCents) and positive amount required' });
    }
    const wallet = await walletDoc(req.params.userId);
    wallet[currency] += amt;
    pushTx(wallet, 'earn', currency, amt, note);
    await saveWallet(wallet);
    res.json(walletJSON(wallet));
  });

  app.post('/api/wallet/:userId/convert', pointsGate, async (req, res) => {
    const { from, amount } = req.body || {};
    const amt = parseInt(amount, 10);
    const RATES = { points: 10, diamonds: 1 }; // 1 diamond = 10 points
    if (!RATES[from] || !Number.isFinite(amt) || amt <= 0) return res.status(400).json({ error: 'from (points|diamonds) and positive amount required' });
    const wallet = await walletDoc(req.params.userId);
    if (from === 'points') {
      if (wallet.points < amt) return res.status(402).json({ error: 'Insufficient points' });
      const diamonds = Math.floor(amt / RATES.points);
      if (diamonds <= 0) return res.status(400).json({ error: 'Not enough points to convert' });
      wallet.points -= amt;
      wallet.diamonds += diamonds;
      pushTx(wallet, 'convert', 'points→diamonds', diamonds, `${amt} points → ${diamonds} diamonds`);
      await saveWallet(wallet);
      res.json(walletJSON(wallet));
    } else {
      if (wallet.diamonds < amt) return res.status(402).json({ error: 'Insufficient diamonds' });
      wallet.diamonds -= amt;
      wallet.points += amt * RATES.points;
      pushTx(wallet, 'convert', 'diamonds→points', -amt, `${amt} diamonds → ${amt * RATES.points} points`);
      await saveWallet(wallet);
      res.json(walletJSON(wallet));
    }
  });

  app.post('/api/wallet/:userId/gift', async (req, res) => {
    const { toUserId, currency, amount, note } = req.body || {};
    const amt = parseInt(amount, 10);
    const from = await walletDoc(req.params.userId);
    const to = await walletDoc(toUserId);
    if (!['diamonds', 'points'].includes(currency) || !Number.isFinite(amt) || amt <= 0) {
      return res.status(400).json({ error: 'currency (diamonds|points) and positive amount required' });
    }
    if (from[currency] < amt) return res.status(402).json({ error: `Insufficient ${currency}` });
    from[currency] -= amt;
    to[currency] += amt;
    pushTx(from, 'gift-out', currency, -amt, note || `Gift to ${to.username}`);
    pushTx(to, 'gift-in', currency, amt, note || `Gift from ${from.username}`);
    await Promise.all([saveWallet(from), saveWallet(to)]);
    res.json({ from: walletJSON(from), to: walletJSON(to) });
  });

  async function saveWallet(w) {
    if (!dbConnected()) return; // in-memory object already mutated
    if (typeof w.save === 'function') return w.save(); // mongoose doc path
    // Plain-object path (defensive): mirror fields through an update
    await models.Wallet.updateOne(
      { userId: w.userId },
      { username: w.username, diamonds: w.diamonds, points: w.points, usdCents: w.usdCents, transactions: w.transactions },
      { upsert: true },
    );
  }

  // ---- ADS ----
  app.get('/api/ads', async (req, res) => {
    const flags = await getFeatureFlags();
    if (!flags.ads) return res.json({ ads: [] });
    const { context = 'general' } = req.query; // general | shorts | between-movies
    const ads = dbConnected() ? await staticAdList() : memory.adCatalog();
    res.json({ context, ads });
  });

  function staticAdList() {
    // Ad catalog is app-defined copy; enlisting them from the default memory set keeps it simple.
    return memory.adCatalog();
  }

  memory.adCatalog = () => [
    { id: 'ad_001', advertiser: 'StreamFlix VPN', tagline: 'Stream anywhere, unblock everything', cta: 'Try Free', banner: '🎬', cpmCents: 45 },
    { id: 'ad_002', advertiser: 'PopcornBox', tagline: 'Movie night kits delivered weekly', cta: 'Get 20% Off', banner: '🍿', cpmCents: 60 },
    { id: 'ad_003', advertiser: 'CineAudio+', tagline: 'Dolby-grade sound for your headphones', cta: 'Listen Now', banner: '🎧', cpmCents: 38 },
  ];

  app.post('/api/ads/:id/impression', async (req, res) => {
    const event = { adId: req.params.id, userId: req.userId || null, type: 'impression', at: new Date() };
    await addAdEvent(event);
    res.json({ ok: true });
  });

  app.post('/api/ads/:id/click', async (req, res) => {
    await addAdEvent({ adId: req.params.id, userId: req.userId || null, type: 'click', at: new Date() });
    let rewarded = false;
    let points = 0;
    if (req.userId) {
      points = 2;
      rewarded = true;
      const wallet = await walletDoc(req.userId);
      wallet.points += points;
      pushTx(wallet, 'ad-reward', 'points', points, 'Ad interaction');
      await saveWallet(wallet);
    }
    res.json({ ok: true, rewarded, points });
  });

  app.get('/api/admin/ads/stats', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    res.json({ events: await adEventStats(), partners: memory.adCatalog() });
  });

  // ---- GAMING ----
  app.get('/api/games', async (req, res) => {
    const flags = await getFeatureFlags();
    if (!flags.gaming) return res.status(403).json({ error: 'Gaming disabled by admin' });
    res.json({ games: listGames() });
  });

  function listGames() {
    return [
      { id: 'quiz_blitz', name: 'CineQuiz Blitz', entryDiamonds: 2, description: 'Answer movie trivia fast for diamonds' },
      { id: 'spin_reel', name: 'Reel Spinner', entryDiamonds: 5, description: 'Spin the reel — win diamonds up to 10x' },
      { id: 'guess_frames', name: 'Guess the Frames', entryDiamonds: 3, description: 'Guess the movie from blurred frames' },
    ];
  }

  app.post('/api/games/:id/play', async (req, res) => {
    const flags = await getFeatureFlags();
    if (!flags.gaming) return res.status(403).json({ error: 'Gaming disabled by admin' });
    const game = listGames().find((g) => g.id === req.params.id);
    if (!game) return res.status(404).json({ error: 'Game not found' });
    if (!req.userId) return res.status(401).json({ error: 'Auth required to play' });
    const wallet = await walletDoc(req.userId, req.body?.username);
    if (wallet.diamonds < game.entryDiamonds) return res.status(402).json({ error: 'Insufficient diamonds' });
    wallet.diamonds -= game.entryDiamonds;
    // Weighted pseudo reward: 60% lose stake, up to 10x on high rolls.
    const roll = Math.random();
    let multiplier = 0;
    if (roll < 0.25) multiplier = 0.5;
    else if (roll < 0.4) multiplier = 1;
    else if (roll < 0.46) multiplier = 3;
    else if (roll < 0.49) multiplier = 10;
    const reward = Math.floor(game.entryDiamonds * multiplier);
    if (reward > 0) wallet.diamonds += reward;
    pushTx(wallet, 'game', 'diamonds', reward > 0 ? reward : -game.entryDiamonds, `${game.name}`);
    await saveWallet(wallet);
    await saveGameSession({ userId: req.userId, gameId: game.id, stake: game.entryDiamonds, reward, at: new Date() });
    await upsertLeaderboard(req.userId, wallet.username || req.body?.username || 'player', Math.max(reward - game.entryDiamonds, 0), 1);
    res.json({ outcome: reward > 0 ? 'win' : 'lose', reward, multiplier, wallet: { ...walletJSON(wallet), transactions: walletJSON(wallet).transactions.slice(0, 20) } });
  });

  app.get('/api/games/leaderboard', async (req, res) => {
    res.json({ leaderboard: await listLeaderboard() });
  });

  // ---- ECOMMERCE (admin-approved sellers) ----
  // Admin feature flag `ecommerce` switches the marketplace off wholesale.
  // Admins bypass the gate so they can keep managing listings either way.
  const marketplaceGate = async (req, res, next) => {
    if (requireAdmin(req)) return next();
    const flags = await getFeatureFlags();
    if (flags.ecommerce === false) return res.status(403).json({ error: 'Marketplace is disabled by admin' });
    next();
  };

  app.get('/api/ecommerce/products', marketplaceGate, async (req, res) => {
    const includeUnapproved = req.query.all === 'true' && requireAdmin(req);
    res.json({ products: await listProducts({ includeUnapproved }) });
  });

  // Own products incl. unapproved/rejected — powers the seller dashboard.
  app.get('/api/ecommerce/seller/products', async (req, res) => {
    if (!req.userId) return res.status(401).json({ error: 'Auth required' });
    const all = await listProducts({ includeUnapproved: true });
    res.json({ products: all.filter((p) => p.sellerId === req.userId) });
  });

  app.post('/api/ecommerce/seller/apply', marketplaceGate, async (req, res) => {
    if (!req.userId) return res.status(401).json({ error: 'Auth required' });
    const { shopName, category } = req.body || {};
    if (!shopName) return res.status(400).json({ error: 'shopName required' });
    await setSellerApplication(req.userId, { shopName, category: category || 'General', status: 'pending', at: new Date().toISOString() });
    res.json({ ok: true, status: 'pending', message: 'Application submitted — an admin must approve you before the seller nav appears' });
  });

  app.get('/api/ecommerce/seller/status', async (req, res) => {
    const rec = await sellerApplication(req.userId || '');
    res.json({ application: rec ? { ...rec, approved: rec.status === 'approved' } : { status: 'none', approved: false } });
  });

  app.put('/api/ecommerce/seller/:userId/approve', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    const prev = await sellerApplication(req.params.userId);
    if (!prev) return res.status(404).json({ error: 'No application from this user' });
    const saved = await setSellerApplication(req.params.userId, { ...prev, status: 'approved' });
    notify({ title: 'Seller approved', body: `${saved.shopName || 'A shop'} can now post products` });
    res.json({ ok: true, application: saved });
  });

  app.put('/api/ecommerce/seller/:userId/reject', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    const prev = await sellerApplication(req.params.userId);
    if (!prev) return res.status(404).json({ error: 'No application from this user' });
    const saved = await setSellerApplication(req.params.userId, { ...prev, status: 'rejected' });
    res.json({ ok: true, application: saved });
  });

  app.put('/api/ecommerce/products/:id/approve', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    if (dbConnected()) {
      const doc = await models.Product.findOne({ id: req.params.id });
      if (!doc) return res.status(404).json({ error: 'Product not found' });
      doc.approved = true;
      doc.rejected = false;
      await doc.save();
    } else {
      const product = memory.products.find((p) => p.id === req.params.id);
      if (!product) return res.status(404).json({ error: 'Product not found' });
      product.approved = true;
      product.rejected = false;
    }
    notify({ title: 'Product approved', body: 'A new listing is now in the marketplace' });
    res.json({ ok: true, productId: req.params.id });
  });

  app.put('/api/ecommerce/products/:id/reject', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    if (dbConnected()) {
      const doc = await models.Product.findOne({ id: req.params.id });
      if (!doc) return res.status(404).json({ error: 'Product not found' });
      doc.approved = false;
      doc.rejected = true;
      await doc.save();
    } else {
      const product = memory.products.find((p) => p.id === req.params.id);
      if (!product) return res.status(404).json({ error: 'Product not found' });
      product.approved = false;
      product.rejected = true;
    }
    res.json({ ok: true, productId: req.params.id });
  });

  app.post('/api/ecommerce/products', marketplaceGate, async (req, res) => {
    if (!req.userId) return res.status(401).json({ error: 'Auth required' });
    const rec = await sellerApplication(req.userId);
    if (!rec || rec.status !== 'approved') return res.status(403).json({ error: 'Only approved sellers can post products' });
    const { title, priceCents, stock, category } = req.body || {};
    if (!title || !priceCents) return res.status(400).json({ error: 'title and priceCents required' });
    const product = await createProduct({
      id: `p_${crypto.randomUUID().slice(0, 8)}`,
      sellerId: req.userId,
      title,
      priceCents: parseInt(priceCents, 10),
      stock: parseInt(stock || 1, 10),
      approved: false,
      category: category || 'General',
      postedBy: rec.shopName,
    });
    res.status(201).json({ product, note: 'Posted — awaiting admin approval before the marketplace/feed shows it' });
  });

  app.post('/api/ecommerce/orders', marketplaceGate, async (req, res) => {
    if (!req.userId) return res.status(401).json({ error: 'Auth required' });
    const { productId } = req.body || {};
    const product = await findProduct(productId);
    if (!product) return res.status(404).json({ error: 'Product not found or not approved' });
    if (product.stock <= 0) return res.status(409).json({ error: 'Out of stock' });
    const priceDiamonds = Math.ceil(product.priceCents / 10); // 1 diamond ≈ $0.10
    const wallet = await walletDoc(req.userId);
    if (wallet.diamonds < priceDiamonds) return res.status(402).json({ error: `Costs ${priceDiamonds} diamonds` });
    wallet.diamonds -= priceDiamonds;
    pushTx(wallet, 'purchase', 'diamonds', -priceDiamonds, product.title);
    await saveWallet(wallet);
    await updateProductStock(productId, -1);
    const order = { id: `o_${crypto.randomUUID().slice(0, 8)}`, productId, buyerId: req.userId, diamondsPaid: priceDiamonds, at: new Date().toISOString() };
    await addOrder(order);
    res.status(201).json({ order, wallet: { diamonds: wallet.diamonds } });
  });

  // ---- SOUNDS / SETTINGS ENDPOINTS ----
  app.get('/api/settings/:userId', async (req, res) => {
    res.json(await settingsDoc(req.params.userId));
  });

  app.put('/api/settings/:userId', async (req, res) => {
    res.json(await saveSettings(req.params.userId, req.body || {}));
  });

  // ---- LIVE (real_me interop) ----
  // Rooms registry keeps rich metadata (host, title, status, counters) and
  // powers the join-request/approval flow + creator insights. Requests follow
  // the same dual-storage pattern; live stays memory-first like liveTokens.
  function liveRoom(callId) {
    return memory.liveRooms.get(callId) || null;
  }

  function activeLiveRooms() {
    return [...memory.liveRooms.values()].filter((r) => r.status === 'live');
  }

  function liveRoomJSON(r) {
    if (!r) return null;
    return {
      callId: r.callId,
      title: r.title,
      hostId: r.hostId,
      hostName: r.hostName,
      status: r.status,
      requiresApproval: !!r.requiresApproval,
      viewers: r.viewers || 0,
      reactions: r.reactions || 0,
      gifts: r.gifts || 0,
      startedAt: r.startedAt,
      endedAt: r.endedAt || null,
      heartbeatAt: r.heartbeatAt || r.startedAt || null,
    };
  }

  // Admin feature flag `live` blocks NEW room creation only — existing
  // rooms stay readable so real_me companion maintenance is unaffected.
  const liveGate = async (req, res, next) => {
    const flags = await getFeatureFlags();
    if (flags.live === false) return res.status(403).json({ error: 'Live streaming is disabled by admin' });
    next();
  };
  app.post('/api/live/create', liveGate, async (req, res) => {
    if (!req.userId) return res.status(401).json({ error: 'Auth required' });
    const { title, requires_approval: requiresApprovalBody } = req.body || {};
    const callId = `live_${crypto.randomUUID().slice(0, 10)}`;
    const room = {
      callId,
      hostId: req.userId,
      hostName: req.userName || req.headers['x-user-name'] || 'Host',
      title: title || 'Untitled live',
      status: 'live',
      requiresApproval: requiresApprovalBody === true || req.headers['x-requires-approval'] === 'true',
      viewers: 0,
      reactions: 0,
      gifts: 0,
      startedAt: new Date().toISOString(),
      heartbeatAt: new Date().toISOString(),
      endedAt: null,
    };
    memory.liveRooms.set(callId, room);
    persistLiveState();
    const token = issueLiveToken(callId, 'host');
    res.status(201).json({
      callId, hostToken: token,
      token, call_id: callId, call_type: 'live-stream',
      backends: ['realme-bridge', 'native'], title: room.title,
      requiresApproval: room.requiresApproval,
    });
  });

  const roomListHandler = async (req, res) => {
    // Maintenance pass — a live room must be actively kept alive by its
    // host client (heartbeat every ~15s). Prune rooms whose host stopped
    // beating (LIVE_STALE_MS) or that exceeded the max stream age so the
    // real_me companion only ever sees genuinely live rooms.
    const now = Date.now();
    let pruned = false;
    for (const r of [...memory.liveRooms.values()]) {
      if (r.status !== 'live') continue;
      const lastBeat = Date.parse(r.heartbeatAt || r.startedAt || '') || now;
      const started = Date.parse(r.startedAt || '');
      const tooOld = Number.isFinite(started) && now - started > LIVE_MAX_AGE_MS;
      if (now - lastBeat > LIVE_STALE_MS || tooOld) {
        r.status = 'ended';
        r.endedAt = new Date().toISOString();
        // 'stale' rooms can be revived by a returning host heartbeat;
        // 'age' (max stream age) and host-ended rooms stay terminal.
        r.endedReason = tooOld ? 'age' : 'stale';
        pruned = true;
        console.log(`[live] pruned room ${r.callId} (${tooOld ? 'max age exceeded' : 'host heartbeat stale'})`);
      }
    }
    if (pruned) persistLiveState();
    res.json({ rooms: activeLiveRooms().map(liveRoomJSON) });
  };
  app.get('/api/live/rooms', roomListHandler);
  app.get('/api/live/list', roomListHandler);

  // Host heartbeat: marks the room as alive for the real_me companion.
  // (Optional `viewers` lets the host report its count; otherwise the
  // server keeps its own, bumped by viewer-token issuance.)
  app.put('/api/live/rooms/:callId/heartbeat', async (req, res) => {
    const room = liveRoom(req.params.callId);
    if (!room) return res.status(404).json({ error: 'Live room not found' });
    if (room.status !== 'live') {
      // Self-healing: a stale-pruned room returns to life when its host
      // resumes beating (app backgrounded / network blip). Host-ended
      // and max-age rooms remain terminal.
      const started = Date.parse(room.startedAt || '');
      const tooOld = Number.isFinite(started) && Date.now() - started > LIVE_MAX_AGE_MS;
      const revivable = room.endedReason === 'stale' && !tooOld;
      if (!revivable) return res.status(409).json({ error: 'Room is not live anymore' });
      room.status = 'live';
      room.endedAt = null;
      room.endedReason = null;
      console.log(`[live] revived room ${room.callId} (host heartbeat returned)`);
    }
    room.heartbeatAt = new Date().toISOString();
    const viewers = Number(req.body?.viewers);
    if (Number.isFinite(viewers) && viewers >= 0) room.viewers = Math.round(viewers);
    persistLiveState();
    res.json({ ok: true, heartbeatAt: room.heartbeatAt, viewers: room.viewers || 0 });
  });

  app.get('/api/live/rooms/:callId', async (req, res) => {
    const room = liveRoom(req.params.callId);
    if (!room) return res.status(404).json({ error: 'Live room not found' });
    res.json({ room: liveRoomJSON(room) });
  });

  // Host toggles whether viewers must request approval to enter.
  app.put('/api/live/rooms/:callId/approval', async (req, res) => {
    const room = liveRoom(req.params.callId);
    if (!room) return res.status(404).json({ error: 'Live room not found' });
    if (room.hostId && req.userId && room.hostId !== req.userId) return res.status(403).json({ error: 'Only the room owner can change approval settings' });
    if (req.body?.requiresApproval !== undefined) room.requiresApproval = !!req.body.requiresApproval;
    persistLiveState();
    res.json({ room: liveRoomJSON(room) });
  });

  app.post('/api/live/rooms/:callId/join-request', async (req, res) => {
    const room = liveRoom(req.params.callId);
    if (!room) return res.status(404).json({ error: 'Live room not found' });
    if (room.status !== 'live') return res.status(409).json({ error: 'Room is not live anymore' });
    if (!room.requiresApproval) return res.status(200).json({ approved: true, message: 'Room is open — join directly' });
    const viewerId = req.userId || req.headers['x-user-id'] || req.body?.userId || `guest_${crypto.randomUUID().slice(0, 8)}`;
    const viewerName = req.body?.userName || req.headers['x-user-name'] || 'Viewer';
    // Idempotent: reuse the viewer's pending request if one exists.
    const existing = [...memory.liveRequests.values()].find(
      (r) => r.callId === room.callId && r.userId === viewerId && r.status === 'pending',
    );
    if (existing) return res.json({ requestId: existing.id, status: 'pending', message: 'Join request already pending' });
    const request = {
      id: `r_${crypto.randomUUID().slice(0, 10)}`,
      callId: room.callId,
      userId: viewerId,
      userName: viewerName,
      status: 'pending',
      at: new Date().toISOString(),
    };
    memory.liveRequests.set(request.id, request);
    persistLiveState();
    notify({ title: 'New join request', body: `${viewerName} wants to join "${room.title}"` });
    res.status(202).json({ requestId: request.id, status: 'pending' });
  });

  app.get('/api/live/rooms/:callId/requests', async (req, res) => {
    const room = liveRoom(req.params.callId);
    if (!room) return res.status(404).json({ error: 'Live room not found' });
    if (room.hostId && req.userId && room.hostId !== req.userId) return res.status(403).json({ error: 'Only the room owner can view join requests' });
    const statusFilter = req.query.status;
    const all = [...memory.liveRequests.values()].filter(
      (r) => r.callId === room.callId && (!statusFilter || r.status === statusFilter),
    );
    res.json({ requests: all });
  });

  const decideJoinRequest = (decision) => async (req, res) => {
    const request = memory.liveRequests.get(req.params.requestId);
    if (!request) return res.status(404).json({ error: 'Join request not found' });
    if (request.status !== 'pending') return res.status(409).json({ error: `Request already ${request.status}` });
    const room = liveRoom(request.callId);
    if (room?.hostId && req.userId && room.hostId !== req.userId) return res.status(403).json({ error: 'Only the room owner can decide join requests' });
    request.status = decision;
    request.decidedAt = new Date().toISOString();
    persistLiveState();
    let viewerToken;
    if (decision === 'approved') {
      viewerToken = issueLiveToken(request.callId, 'viewer');
      notify({ title: 'Join approved', body: `You were approved to join "${room?.title || 'a live room'}"` });
    }
    res.json({ request, ...(viewerToken ? { viewerToken } : {}) });
  };
  app.put('/api/live/requests/:requestId/approve', decideJoinRequest('approved'));
  app.put('/api/live/requests/:requestId/reject', decideJoinRequest('rejected'));

  const viewerTokenHandler = async (req, res) => {
    const body = req.body || {};
    const callId = body.callId ?? body.call_id ?? body.id;
    const viewerId = req.userId || body.userId || `guest_${crypto.randomUUID().slice(0, 8)}`;
    const room = liveRoom(callId);
    if (!memory.liveTokens.has(callId)) return res.status(404).json({ error: 'Live room not found' });
    if (room && room.status !== 'live') return res.status(409).json({ error: 'Room is not live anymore' });
    if (room && room.requiresApproval) {
      const approvedReq = [...memory.liveRequests.values()].find(
        (r) => r.callId === callId && r.userId === viewerId && r.status === 'approved',
      );
      if (!approvedReq) return res.status(403).json({ error: 'Approval required — send a join request first' });
    }
    if (room) room.viewers = (room.viewers || 0) + 1;
    const token = issueLiveToken(callId, 'viewer');
    res.json({ callId, viewerToken: token, token, call_type: 'live-stream' });
  };
  app.post('/api/live/viewer/token', viewerTokenHandler);
  app.post('/api/live/join', viewerTokenHandler);

  const endLiveHandler = async (req, res) => {
    const callId = req.params.callId || req.body?.callId || req.body?.call_id;
    const room = liveRoom(callId);
    if (!room && !memory.liveTokens.has(callId)) return res.status(404).json({ error: 'Live room not found' });
    if (room) {
      if (room.hostId && req.userId && room.hostId !== req.userId) return res.status(403).json({ error: 'Only the room owner can end the room' });
      room.status = 'ended';
      room.endedAt = new Date().toISOString();
      room.endedReason = 'host'; // never revivable via heartbeat
      notify({ title: 'Live ended', body: `"${room.title}" has ended` });
    } else {
      memory.liveTokens.delete(callId);
    }
    persistLiveState();
    res.json({ ok: true, room: liveRoomJSON(room) });
  };
  app.post('/api/live/end', endLiveHandler);
  app.post('/api/live/rooms/:callId/end', endLiveHandler);

  // ---- CREATOR INSIGHTS (analytics wired to the wallet) ----
  app.get('/api/creator/insights', async (req, res) => {
    const hostId = req.query.userId || req.userId || req.headers['x-user-id'];
    if (!hostId) return res.status(400).json({ error: 'userId required' });
    const rooms = [...memory.liveRooms.values()].filter((r) => r.hostId === hostId);
    const totals = rooms.reduce(
      (acc, r) => ({
        rooms: acc.rooms + 1,
        viewers: acc.viewers + (r.viewers || 0),
        reactions: acc.reactions + (r.reactions || 0),
        gifts: acc.gifts + (r.gifts || 0),
      }),
      { rooms: 0, viewers: 0, reactions: 0, gifts: 0 },
    );
    const durationMs = rooms.reduce((acc, r) => {
      const start = Date.parse(r.startedAt || r.createdAt || new Date());
      const end = r.endedAt ? Date.parse(r.endedAt) : Date.now();
      return acc + Math.max(0, end - start);
    }, 0);
    const wallet = await walletDoc(hostId);
    const topRooms = rooms
      .sort((a, b) => (b.viewers || 0) - (a.viewers || 0))
      .slice(0, 5)
      .map(liveRoomJSON);
    res.json({
      hostId,
      ...totals,
      liveRooms: rooms.filter((r) => r.status === 'live').length,
      avgViewersPerRoom: totals.rooms ? +(totals.viewers / totals.rooms).toFixed(1) : 0,
      totalMinutes: Math.round(durationMs / 60000),
      wallet: walletJSON(wallet),
      topRooms,
    });
  });

  // ---- NOTIFICATION POPUP TOGGLES (admin) + ability to push instantly ----
  app.put('/api/admin/popups', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    if (req.body?.enabled !== undefined) notify({ title: 'Popups', body: `Popups ${req.body.enabled ? 'enabled' : 'disabled'} by admin` });
    res.json({ ok: true });
  });

  app.post('/api/admin/announce', async (req, res) => {
    if (!requireAdmin(req)) return res.status(403).json({ error: 'Admin code required' });
    const { title, body } = req.body || {};
    if (!title) return res.status(400).json({ error: 'title required' });
    notify({ title, body: body || '' });
    res.json({ ok: true });
  });
}

module.exports = { registerSystemRoutes, memory, ADMIN_CODE, OAUTH_DEV_MODE, getFeatureFlags };
