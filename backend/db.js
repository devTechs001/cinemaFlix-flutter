const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/cinemaflix';

let isConnected = false;

async function connectDB() {
  if (isConnected) return;
  try {
    await mongoose.connect(MONGO_URI);
    isConnected = true;
    console.log('MongoDB connected:', MONGO_URI);
  } catch (e) {
    console.warn('MongoDB connection failed:', e.message);
    console.warn('Running without database — some features will be unavailable');
  }
}

function getIsConnected() {
  return isConnected && mongoose.connection.readyState === 1;
}

module.exports = { connectDB, getIsConnected };
