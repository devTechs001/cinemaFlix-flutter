const mongoose = require('mongoose');

const friendRequestSchema = new mongoose.Schema({
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  receiverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: ['pending', 'accepted', 'rejected'], default: 'pending' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

friendRequestSchema.index({ senderId: 1, receiverId: 1 }, { unique: true });
friendRequestSchema.index({ receiverId: 1, status: 1 });

module.exports = mongoose.model('FriendRequest', friendRequestSchema);
