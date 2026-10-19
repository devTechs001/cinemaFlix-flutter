const express = require('express');
const http = require('http');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const { connectDB, getIsConnected } = require('./db');
const { generateToken, authMiddleware, requireAuth } = require('./auth');
const { registerSystemRoutes } = require('./systems');

const User = require('./models/User');
const Post = require('./models/Post');
const PostLike = require('./models/PostLike');
const PostComment = require('./models/PostComment');
const PostSave = require('./models/PostSave');
const Follow = require('./models/Follow');
const FriendRequest = require('./models/FriendRequest');
const NotificationModel = require('./models/Notification');
const Gift = require('./models/Gift');
const ChatRoomMember = require('./models/ChatRoomMember');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(authMiddleware);

connectDB();
// Bridge object handed to the system routes now; populated with the real
// broadcast function once the WS server attaches at listen() time.
const realtimeBridge = { broadcastNotification: () => {} };
registerSystemRoutes(app, realtimeBridge);

// ---------- AUTH ----------

app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, username } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) return res.status(409).json({ error: 'Email already registered' });
    const user = await User.create({
      email: email.toLowerCase(),
      username: username || email.split('@')[0],
      password,
    });
    const token = generateToken(user);
    res.status(201).json({ user: { ...user.toPublic(), token } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const match = await user.comparePassword(password);
    if (!match) return res.status(401).json({ error: 'Invalid credentials' });
    const token = generateToken(user);
    res.json({ user: { ...user.toPublic(), token } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- USERS ----------

app.get('/api/users', async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const { search, exclude, limit = '20' } = req.query;
    const query = {};
    if (search) query.username = { $regex: search, $options: 'i' };
    if (exclude) query._id = { $ne: exclude };
    const users = await User.find(query).select('-password').limit(parseInt(limit)).sort({ createdAt: -1 });
    const enriched = await Promise.all(users.map(async (u) => {
      const [followersCount, followingCount, postsCount] = await Promise.all([
        Follow.countDocuments({ followingId: u._id }),
        Follow.countDocuments({ followerId: u._id }),
        Post.countDocuments({ userId: u._id }),
      ]);
      return { ...u.toPublic(), followersCount, followingCount, postsCount };
    }));
    res.json(enriched);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/users/:id', async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    const [followersCount, followingCount, postsCount] = await Promise.all([
      Follow.countDocuments({ followingId: user._id }),
      Follow.countDocuments({ followerId: user._id }),
      Post.countDocuments({ userId: user._id }),
    ]);
    let isFollowing = false;
    if (req.userId) {
      const follow = await Follow.findOne({ followerId: req.userId, followingId: user._id });
      isFollowing = !!follow;
    }
    res.json({ ...user.toPublic(), followersCount, followingCount, postsCount, isFollowing });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/users/:id', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    if (req.params.id !== req.userId) return res.status(403).json({ error: 'Not authorized' });
    const { username, avatarUrl } = req.body;
    const updates = {};
    if (username) updates.username = username;
    if (avatarUrl !== undefined) updates.avatarUrl = avatarUrl;
    const user = await User.findByIdAndUpdate(req.params.id, updates, { new: true }).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user.toPublic());
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- POSTS ----------

app.get('/api/posts', async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const { userId, page = '1', limit = '20' } = req.query;
    const query = userId ? { userId } : {};
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const posts = await Post.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const enriched = await Promise.all(posts.map(async (post) => {
      const user = await User.findById(post.userId).select('username avatarUrl');
      const [likesCount, commentsCount] = await Promise.all([
        PostLike.countDocuments({ postId: post._id }),
        PostComment.countDocuments({ postId: post._id }),
      ]);
      let liked = false, saved = false;
      if (req.userId) {
        const [like, save] = await Promise.all([
          PostLike.findOne({ postId: post._id, userId: req.userId }),
          PostSave.findOne({ postId: post._id, userId: req.userId }),
        ]);
        liked = !!like;
        saved = !!save;
      }
      return {
        ...post,
        id: post._id.toString(),
        userId: post.userId.toString(),
        username: user?.username || 'Unknown',
        avatarUrl: user?.avatarUrl || null,
        likesCount,
        commentsCount,
        liked,
        saved,
      };
    }));

    res.json({ posts: enriched, total: enriched.length });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/posts', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const { content, movieId, movieTitle, imageUrl } = req.body;
    if (!content) return res.status(400).json({ error: 'Content is required' });
    const post = await Post.create({ userId: req.userId, content, movieId, movieTitle, imageUrl });
    const user = await User.findById(req.userId).select('username avatarUrl');
    res.status(201).json({
      ...post.toJSON(),
      id: post._id.toString(),
      userId: post.userId.toString(),
      username: user?.username || 'Unknown',
      avatarUrl: user?.avatarUrl || null,
      likesCount: 0,
      commentsCount: 0,
      liked: false,
      saved: false,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.delete('/api/posts/:id', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    await Post.deleteOne({ _id: req.params.id, userId: req.userId });
    res.status(204).send();
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- LIKES ----------

app.post('/api/posts/:id/like', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const postId = req.params.id;
    const existing = await PostLike.findOne({ postId, userId: req.userId });
    if (existing) {
      await PostLike.deleteOne({ postId, userId: req.userId });
      res.json({ liked: false });
    } else {
      await PostLike.create({ postId, userId: req.userId });
      const post = await Post.findById(postId).select('userId');
      if (post && post.userId.toString() !== req.userId) {
        const actor = await User.findById(req.userId).select('username');
        await NotificationModel.create({
          userId: post.userId, actorId: req.userId, type: 'like',
          title: 'New Like', body: `${actor?.username || 'Someone'} liked your post`,
          referenceId: postId,
        });
      }
      res.json({ liked: true });
    }
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- COMMENTS ----------

app.get('/api/posts/:id/comments', async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const comments = await PostComment.find({ postId: req.params.id }).sort({ createdAt: -1 }).lean();
    const enriched = await Promise.all(comments.map(async (c) => {
      const user = await User.findById(c.userId).select('username avatarUrl');
      return { ...c, id: c._id.toString(), userId: c.userId.toString(), username: user?.username || 'Unknown', avatarUrl: user?.avatarUrl || null };
    }));
    res.json(enriched);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/posts/:id/comments', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const { content } = req.body;
    if (!content) return res.status(400).json({ error: 'Content is required' });
    const comment = await PostComment.create({ postId: req.params.id, userId: req.userId, content });
    const user = await User.findById(req.userId).select('username avatarUrl');
    const post = await Post.findById(req.params.id).select('userId');
    if (post && post.userId.toString() !== req.userId) {
      const actor = await User.findById(req.userId).select('username');
      await NotificationModel.create({
        userId: post.userId, actorId: req.userId, type: 'comment',
        title: 'New Comment', body: `${actor?.username || 'Someone'} commented on your post`,
        referenceId: req.params.id,
      });
    }
    res.status(201).json({
      ...comment.toJSON(),
      id: comment._id.toString(),
      userId: comment.userId.toString(),
      username: user?.username || 'Unknown',
      avatarUrl: user?.avatarUrl || null,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- SAVES ----------

app.post('/api/posts/:id/save', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const postId = req.params.id;
    const existing = await PostSave.findOne({ postId, userId: req.userId });
    if (existing) {
      await PostSave.deleteOne({ postId, userId: req.userId });
      res.json({ saved: false });
    } else {
      await PostSave.create({ postId, userId: req.userId });
      res.json({ saved: true });
    }
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- FOLLOWS ----------

app.post('/api/users/:id/follow', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const targetId = req.params.id;
    if (req.userId === targetId) return res.status(400).json({ error: 'Cannot follow yourself' });
    const existing = await Follow.findOne({ followerId: req.userId, followingId: targetId });
    if (existing) {
      await Follow.deleteOne({ followerId: req.userId, followingId: targetId });
      res.json({ following: false });
    } else {
      await Follow.create({ followerId: req.userId, followingId: targetId });
      const actor = await User.findById(req.userId).select('username');
      await NotificationModel.create({
        userId: targetId, actorId: req.userId, type: 'follow',
        title: 'New Follower', body: `${actor?.username || 'Someone'} started following you`,
      });
      res.json({ following: true });
    }
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/users/:id/follow-status', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const follow = await Follow.findOne({ followerId: req.userId, followingId: req.params.id });
    res.json({ following: !!follow });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/users/:id/followers', async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const follows = await Follow.find({ followingId: req.params.id }).lean();
    const users = await Promise.all(follows.map(async (f) => {
      const u = await User.findById(f.followerId).select('username avatarUrl');
      return { id: f.followerId.toString(), username: u?.username || 'Unknown', avatarUrl: u?.avatarUrl || null };
    }));
    res.json(users);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/users/:id/following', async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const follows = await Follow.find({ followerId: req.params.id }).lean();
    const users = await Promise.all(follows.map(async (f) => {
      const u = await User.findById(f.followingId).select('username avatarUrl');
      return { id: f.followingId.toString(), username: u?.username || 'Unknown', avatarUrl: u?.avatarUrl || null };
    }));
    res.json(users);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- FRIEND REQUESTS ----------

app.post('/api/friend-requests', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const { receiverId } = req.body;
    if (req.userId === receiverId) return res.status(400).json({ error: 'Cannot friend yourself' });
    const existing = await FriendRequest.findOne({
      $or: [
        { senderId: req.userId, receiverId },
        { senderId: receiverId, receiverId: req.userId },
      ],
    });
    if (existing) return res.status(409).json({ error: 'Friend request already exists' });
    const request = await FriendRequest.create({ senderId: req.userId, receiverId });
    const sender = await User.findById(req.userId).select('username avatarUrl');
    const receiver = await User.findById(receiverId).select('username avatarUrl');
    await NotificationModel.create({
      userId: receiverId, actorId: req.userId, type: 'friend_request',
      title: 'Friend Request', body: `${sender?.username || 'Someone'} sent you a friend request`,
      referenceId: request._id.toString(),
    });
    res.status(201).json({
      ...request.toJSON(),
      id: request._id.toString(),
      senderId: request.senderId.toString(),
      receiverId: request.receiverId.toString(),
      sender: { username: sender?.username, avatarUrl: sender?.avatarUrl },
      receiver: { username: receiver?.username, avatarUrl: receiver?.avatarUrl },
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/friend-requests/:id', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const { status } = req.body;
    if (!['accepted', 'rejected'].includes(status)) return res.status(400).json({ error: 'Invalid status' });
    const request = await FriendRequest.findById(req.params.id);
    if (!request) return res.status(404).json({ error: 'Request not found' });
    if (request.receiverId.toString() !== req.userId) return res.status(403).json({ error: 'Not authorized' });
    request.status = status;
    request.updatedAt = new Date();
    await request.save();
    if (status === 'accepted') {
      await Follow.findOneAndUpdate({ followerId: request.senderId, followingId: request.receiverId }, {}, { upsert: true });
      await Follow.findOneAndUpdate({ followerId: request.receiverId, followingId: request.senderId }, {}, { upsert: true });
      const actor = await User.findById(req.userId).select('username');
      await NotificationModel.create({
        userId: request.senderId, actorId: req.userId, type: 'friend_accepted',
        title: 'Friend Request Accepted', body: `${actor?.username || 'Someone'} accepted your friend request`,
      });
    }
    res.json(request.toJSON());
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/friend-requests/pending', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const requests = await FriendRequest.find({ receiverId: req.userId, status: 'pending' }).sort({ createdAt: -1 }).lean();
    const enriched = await Promise.all(requests.map(async (r) => {
      const sender = await User.findById(r.senderId).select('username avatarUrl');
      return { ...r, id: r._id.toString(), senderId: r.senderId.toString(), receiverId: r.receiverId.toString(), sender: { username: sender?.username, avatarUrl: sender?.avatarUrl } };
    }));
    res.json(enriched);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- NOTIFICATIONS ----------

app.get('/api/notifications', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const notifications = await NotificationModel.find({ userId: req.userId }).sort({ createdAt: -1 }).limit(50).lean();
    const enriched = await Promise.all(notifications.map(async (n) => {
      let actor = null;
      if (n.actorId) {
        const u = await User.findById(n.actorId).select('username avatarUrl');
        actor = u ? { username: u.username, avatarUrl: u.avatarUrl } : null;
      }
      return { ...n, id: n._id.toString(), userId: n.userId.toString(), actorId: n.actorId?.toString(), actor };
    }));
    const unreadCount = enriched.filter(n => !n.read).length;
    res.json({ notifications: enriched, unread_count: unreadCount });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/notifications/:id/read', requireAuth, async (req, res) => {
  try {
    await NotificationModel.findOneAndUpdate({ _id: req.params.id, userId: req.userId }, { read: true });
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/notifications/read-all', requireAuth, async (req, res) => {
  try {
    await NotificationModel.updateMany({ userId: req.userId, read: false }, { read: true });
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- GIFTS ----------

app.post('/api/gifts', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const { receiverId, postId, giftType, cost, message } = req.body;
    const gift = await Gift.create({ senderId: req.userId, receiverId, postId, giftType, cost, message });
    const actor = await User.findById(req.userId).select('username');
    await NotificationModel.create({
      userId: receiverId, actorId: req.userId, type: 'gift',
      title: 'Gift Received', body: `${actor?.username || 'Someone'} sent you a ${giftType} gift!`,
    });
    res.status(201).json(gift.toJSON());
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- CHAT ROOMS ----------

app.post('/api/chat/rooms/join', requireAuth, async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const { roomId } = req.body;
    const existing = await ChatRoomMember.findOne({ roomId, userId: req.userId });
    if (existing) return res.json({ joined: true, message: 'Already joined' });
    await ChatRoomMember.create({ roomId, userId: req.userId });
    res.json({ joined: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/chat/rooms/:id/members', async (req, res) => {
  if (!getIsConnected()) return res.status(503).json({ error: 'Database not connected' });
  try {
    const members = await ChatRoomMember.find({ roomId: req.params.id }).lean();
    const enriched = await Promise.all(members.map(async (m) => {
      const u = await User.findById(m.userId).select('username avatarUrl');
      return { id: m.userId.toString(), username: u?.username || 'Unknown', avatarUrl: u?.avatarUrl || null };
    }));
    res.json(enriched);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ---------- MOVIE ENDPOINTS (keep existing) ----------

const { getMovies, getMovieById, getGenres, getTags } = require('./movies');

app.get('/api/movies', (req, res) => {
  const { page = '1', limit = '20', genre, search, tag } = req.query;
  const result = getMovies({ page: parseInt(page), limit: Math.min(parseInt(limit), 50), genre, search, tag });
  res.json(result);
});

app.get('/api/movies/:id', (req, res) => {
  const movie = getMovieById(req.params.id);
  if (!movie) return res.status(404).json({ error: 'Movie not found' });
  res.json(movie);
});

app.get('/api/genres', (req, res) => res.json(getGenres()));
app.get('/api/tags', (req, res) => res.json(getTags()));

app.get('/api/movies/genre/:genre', (req, res) => {
  const { page = '1', limit = '20' } = req.query;
  const result = getMovies({ genre: req.params.genre, page: parseInt(page), limit: parseInt(limit) });
  res.json(result);
});

// ---------- VIDEO STREAMING ----------

const VIDEOS_DIR = path.join(__dirname, 'videos');

app.get('/api/videos', (req, res) => {
  if (!fs.existsSync(VIDEOS_DIR)) return res.json({ videos: [] });
  const files = fs.readdirSync(VIDEOS_DIR).filter(f => f.endsWith('.mp4'));
  const videos = files.map(f => {
    const stat = fs.statSync(path.join(VIDEOS_DIR, f));
    return { filename: f, size: stat.size, path: `/api/video/${f}` };
  });
  res.json({ videos });
});

app.get('/api/video/:filename', (req, res) => {
  const filename = path.basename(req.params.filename);
  const filepath = path.join(VIDEOS_DIR, filename);
  if (fs.existsSync(filepath)) {
    const stat = fs.statSync(filepath);
    const fileSize = stat.size;
    const range = req.headers.range;
    if (range) {
      const parts = range.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
      const chunkSize = end - start + 1;
      const file = fs.createReadStream(filepath, { start, end });
      const head = { 'Content-Range': `bytes ${start}-${end}/${fileSize}`, 'Accept-Ranges': 'bytes', 'Content-Length': chunkSize, 'Content-Type': 'video/mp4' };
      res.writeHead(206, head);
      file.pipe(res);
    } else {
      const head = { 'Content-Length': fileSize, 'Content-Type': 'video/mp4' };
      res.writeHead(200, head);
      fs.createReadStream(filepath).pipe(res);
    }
    return;
  }
  const { resolveVideoUrl } = require('./video-sources');
  res.redirect(resolveVideoUrl(filename));
});

// ---------- HEALTH ----------

app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    db: getIsConnected() ? 'connected' : 'disconnected',
    movies: require('./movies').movies.length,
    videosDir: fs.existsSync(VIDEOS_DIR) ? fs.readdirSync(VIDEOS_DIR).filter(f => f.endsWith('.mp4')).length : 0,
  });
});

app.get('/', (req, res) => {
  res.json({
    name: 'CinemaFlix Backend',
    version: '2.0.0',
    endpoints: {
      auth: { register: '/api/auth/register', login: '/api/auth/login' },
      movies: '/api/movies',
      movieById: '/api/movies/:id',
      genres: '/api/genres',
      tags: '/api/tags',
      videos: '/api/videos',
      videoStream: '/api/video/:filename',
      users: '/api/users',
      userById: '/api/users/:id',
      posts: '/api/posts',
      postLike: '/api/posts/:id/like',
      postComments: '/api/posts/:id/comments',
      postSave: '/api/posts/:id/save',
      follow: '/api/users/:id/follow',
      friendRequests: '/api/friend-requests',
      notifications: '/api/notifications',
      gifts: '/api/gifts',
      chatRooms: '/api/chat/rooms/join',
      health: '/api/health',
    },
  });
});

const server = http.createServer(app);
const realtime = require('./realtime').attachRealtime(server);
realtimeBridge.broadcastNotification = realtime.broadcastNotification;

server.listen(port, '0.0.0.0', () => {
  console.log(`CinemaFlix Backend running on http://0.0.0.0:${port}`);
  console.log(`CinemaFlix Realtime WS available on ws://0.0.0.0:${port}/ws`);
  realtime.broadcastNotification({ title: 'CinemaFlix', body: 'Realtime service (re)started' });
  if (!fs.existsSync(VIDEOS_DIR)) fs.mkdirSync(VIDEOS_DIR, { recursive: true });
});
