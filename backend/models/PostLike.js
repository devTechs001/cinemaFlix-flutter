const mongoose = require('mongoose');

const postLikeSchema = new mongoose.Schema({
  postId: { type: mongoose.Schema.Types.ObjectId, ref: 'Post', required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now },
});

postLikeSchema.index({ postId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('PostLike', postLikeSchema);
