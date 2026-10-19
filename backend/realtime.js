// CinemaFlix realtime — WebSocket gateway on the same HTTP server (/ws).
// Rooms, presence (online stamps), typing indicators, chat relay and
// notification broadcasts per bugs.txt "sockets for real time messaging
// (online stamps, settings)".
//
// Message protocol (JSON):
//   client -> server:
//     { type: 'join', room }                    // attach to a room
//     { type: 'message', room, text }           // chat message
//     { type: 'typing', room }                  // typing indicator ping
//     { type: 'ping' }                          // keepalive / presence stamp
//   server -> client:
//     { type: 'welcome', userId, online }
//     { type: 'presence', online: [userId,...] }
//     { type: 'joined', room, userId }
//     { type: 'message', room, id, senderId, senderName, text, ts }
//     { type: 'typing', room, userName }
//     { type: 'notification', title, body }
//     { type: 'pong' }
const { WebSocketServer } = require('ws');

function attachRealtime(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  const sockets = new Map(); // ws -> { userId, userName, rooms:Set }
  const roomMembers = new Map(); // room -> Set<ws>

  function send(ws, payload) {
    if (ws.readyState === 1) ws.send(JSON.stringify(payload));
  }

  function broadcastRoom(room, payload, exceptWs) {
    const members = roomMembers.get(room) || new Set();
    for (const member of members) {
      if (member !== exceptWs) send(member, payload);
    }
  }

  function broadcastPresence() {
    const online = [...sockets.entries()]
      .filter(([, info]) => info.userId)
      .map(([ws, info]) => ({ userId: info.userId, userName: info.userName }));
    const payload = JSON.stringify({ type: 'presence', online, at: new Date().toISOString() });
    for (const [ws] of sockets) {
      if (ws.readyState === 1) ws.send(payload);
    }
  }

  wss.on('connection', (ws, req) => {
    // Identity: ?token=<jwt> (verified) or ?userId=<id>&userName=<n> (dev)
    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const token = url.searchParams.get('token');
    const jwt = require('jsonwebtoken');
    let identity = { userId: null, userName: 'guest' };
    if (token) {
      try {
        const decoded = jwt.verify(token, require('./auth').JWT_SECRET);
        identity = { userId: decoded.id, userName: decoded.username || decoded.id };
      } catch {
        identity = {
          userId: url.searchParams.get('userId') || null,
          userName: url.searchParams.get('userName') || 'guest',
        };
      }
    } else {
      identity = {
        userId: url.searchParams.get('userId') || null,
        userName: url.searchParams.get('userName') || 'guest',
      };
    }

    sockets.set(ws, { userId: identity.userId, userName: identity.userName, rooms: new Set() });
    send(ws, { type: 'welcome', userId: identity.userId, userName: identity.userName });
    broadcastPresence();

    ws.on('pong', () => send(ws, { type: 'pong' }));

    ws.on('message', (raw) => {
      let data;
      try {
        data = JSON.parse(raw.toString());
      } catch {
        return send(ws, { type: 'error', error: 'Invalid JSON' });
      }
      const info = sockets.get(ws);
      if (!info) return;

      switch (data.type) {
        case 'join': {
          const room = String(data.room || 'general');
          info.rooms.add(room);
          if (!roomMembers.has(room)) roomMembers.set(room, new Set());
          roomMembers.get(room).add(ws);
          send(ws, { type: 'joined', room, userId: info.userId });
          broadcastRoom(room, { type: 'presence', room, online: [...roomMembers.get(room)].map((m) => sockets.get(m)?.userId).filter(Boolean) });
          break;
        }
        case 'message': {
          const room = String(data.room || 'general');
          const payload = {
            type: 'message',
            room,
            id: `msg_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
            senderId: info.userId,
            senderName: info.userName,
            text: String(data.text || '').slice(0, 2000),
            ts: new Date().toISOString(),
          };
          broadcastRoom(room, payload); // includes sender for local echo consistency
          break;
        }
        case 'typing': {
          broadcastRoom(String(data.room || 'general'), { type: 'typing', room: data.room, userName: info.userName }, ws);
          break;
        }
        case 'ping':
          send(ws, { type: 'pong' });
          break;
        default:
          break;
      }
    });

    ws.on('close', () => {
      const info = sockets.get(ws);
      if (info) {
        for (const room of info.rooms) {
          roomMembers.get(room)?.delete(ws);
        }
      }
      sockets.delete(ws);
      broadcastPresence();
    });
  });

  // Push a broadcast notification from anywhere in the app:
  //   require('./realtime').broadcastNotification({ title, body })
  function broadcastNotification({ title, body }) {
    const payload = JSON.stringify({ type: 'notification', title, body, ts: new Date().toISOString() });
    for (const [ws] of sockets) {
      if (ws.readyState === 1) ws.send(payload);
    }
  }

  return { wss, broadcastNotification };
}

module.exports = { attachRealtime };
