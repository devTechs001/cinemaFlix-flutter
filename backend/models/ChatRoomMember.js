const mongoose = require('mongoose');

const chatRoomMemberSchema = new mongoose.Schema({
  roomId: { type: String, required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  joinedAt: { type: Date, default: Date.now },
});

chatRoomMemberSchema.index({ roomId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('ChatRoomMember', chatRoomMemberSchema);
