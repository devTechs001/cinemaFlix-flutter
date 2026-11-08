const mongoose = require('mongoose');

const postSaveSchema = new mongoose.Schema({
  postId: { type: mongoose.Schema.Types.ObjectId, ref: 'Post', required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now },
});

postSaveSchema.index({ postId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('PostSave', postSaveSchema);
