const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true },
  username: { type: String, default: 'Cinema Fan' },
  password: { type: String, required: true },
  avatarUrl: { type: String, default: null },
  bio: { type: String, default: '' },
  website: { type: String, default: '' },
  location: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now },
});

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = async function (candidate) {
  return bcrypt.compare(candidate, this.password);
};

userSchema.methods.toPublic = function () {
  return {
    id: this._id.toString(),
    email: this.email,
    username: this.username,
    avatarUrl: this.avatarUrl,
    bio: this.bio || '',
    website: this.website || '',
    location: this.location || '',
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('User', userSchema);
