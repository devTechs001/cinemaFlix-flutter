const mongoose = require('mongoose');

const postSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  content: { type: String, required: true },
  movieId: { type: String, default: null },
  movieTitle: { type: String, default: null },
  imageUrl: { type: String, default: null },
  createdAt: { type: Date, default: Date.now, index: -1 },
});

postSchema.virtual('likesCount', {
  ref: 'PostLike',
  localField: '_id',
  foreignField: 'postId',
  count: true,
});

postSchema.virtual('commentsCount', {
  ref: 'PostComment',
  localField: '_id',
  foreignField: 'postId',
  count: true,
});

postSchema.set('toJSON', { virtuals: true });
postSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Post', postSchema);
