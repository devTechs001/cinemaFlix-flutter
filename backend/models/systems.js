// Durable Mongoose models backing the systems module. Every read/write in
// systems.js goes through the store abstraction which prefers these models
// when the DB is connected and falls back to in-memory Maps otherwise.
const mongoose = require('mongoose');

// Explicit sub-Schema: the transaction subdoc contains a field literally
// named `type`, which collides with mongoose's magic `type` key when using
// the inline `[ {...} ]` syntax (it silently becomes a String cast).
const txSchema = new mongoose.Schema(
  {
    id: String,
    type: String,
    currency: String,
    amount: Number,
    note: String,
    at: String,
  },
  { _id: false },
);

const walletSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  username: { type: String, default: 'user' },
  diamonds: { type: Number, default: 100 },
  points: { type: Number, default: 1000 },
  usdCents: { type: Number, default: 0 },
  transactions: { type: [txSchema], default: [] },
  createdAt: { type: Date, default: Date.now },
});

const gameSessionSchema = new mongoose.Schema({
  userId: String,
  gameId: String,
  stake: Number,
  reward: Number,
  at: Date,
});

const leaderboardSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  username: { type: String, required: true },
  diamondsWon: { type: Number, default: 0 },
  rounds: { type: Number, default: 0 },
});

const productSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  sellerId: String,
  title: { type: String, required: true },
  priceCents: { type: Number, required: true },
  stock: { type: Number, default: 1 },
  approved: { type: Boolean, default: false },
  category: { type: String, default: 'General' },
  postedBy: String,
  createdAt: { type: Date, default: Date.now },
});

const sellerApplicationSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  shopName: String,
  category: { type: String, default: 'General' },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  at: { type: Date, default: Date.now },
});

const orderSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  productId: String,
  buyerId: String,
  diamondsPaid: Number,
  at: { type: Date, default: Date.now },
});

const userSettingsSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  sounds: {
    notification: { type: Boolean, default: true },
    success: { type: Boolean, default: true },
    transaction: { type: Boolean, default: true },
    like: { type: Boolean, default: true },
    comment: { type: Boolean, default: true },
    celebrate: { type: Boolean, default: true },
    popups: { type: Boolean, default: true },
  },
  autoClean: {
    enabled: { type: Boolean, default: true },
    clearCacheDays: { type: Number, default: 14 },
    clearOfflineVideos: { type: Boolean, default: false },
  },
  popups: {
    enabled: { type: Boolean, default: true },
    reminders: { type: Boolean, default: true },
    engagement: { type: Boolean, default: true },
  },
}, { minimize: false });

const adminConfigSchema = new mongoose.Schema({
  key: { type: String, required: true, unique: true },
  value: { type: mongoose.Schema.Types.Mixed, required: true },
});

const adEventSchema = new mongoose.Schema(
  {
    adId: String,
    userId: String,
    type: { type: String, enum: ['impression', 'click'] },
    at: { type: Date, default: Date.now },
  },
  { _id: false },
);

module.exports = {
  Wallet: mongoose.models.Wallet || mongoose.model('Wallet', walletSchema),
  GameSession: mongoose.models.GameSession || mongoose.model('GameSession', gameSessionSchema),
  LeaderboardEntry: mongoose.models.LeaderboardEntry || mongoose.model('LeaderboardEntry', leaderboardSchema),
  Product: mongoose.models.Product || mongoose.model('Product', productSchema),
  SellerApplication: mongoose.models.SellerApplication || mongoose.model('SellerApplication', sellerApplicationSchema),
  Order: mongoose.models.Order || mongoose.model('Order', orderSchema),
  UserSettings: mongoose.models.UserSettings || mongoose.model('UserSettings', userSettingsSchema),
  AdminConfig: mongoose.models.AdminConfig || mongoose.models.AdmConfig || mongoose.model('AdminConfig', adminConfigSchema),
  AdEvent: mongoose.models.AdEvent || mongoose.model('AdEvent', adEventSchema),
};
