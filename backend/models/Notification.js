const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  actorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  type: { type: String, enum: ['like', 'comment', 'follow', 'friend_request', 'friend_accepted', 'gift', 'system', 'movie', 'chat', 'live', 'review'], required: true },
  title: { type: String, required: true },
  body: { type: String, required: true },
  referenceId: { type: String, default: null },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now, index: -1 },
});

module.exports = mongoose.model('Notification', notificationSchema);
