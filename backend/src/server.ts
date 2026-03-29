import dotenv from 'dotenv';
dotenv.config();

import http from 'http';
import app from './app';
import { checkDatabaseConnection } from './config/database';
import { connectRedis } from './config/redis';
// import { setupWebSocket } from './websocket'; // To be implemented later

// --- Handle Uncaught Exceptions ---
process.on('uncaughtException', (err) => {
  console.log('UNCAUGHT EXCEPTION! 💥 Shutting down...');
  console.log(err.name, err.message);
  process.exit(1);
});

const PORT = process.env.PORT || 8080;
const server = http.createServer(app);

const startServer = async () => {
  // 1. Connect to Database & Redis before starting server
  await checkDatabaseConnection();
  await connectRedis();

  // 2. Setup WebSocket (if needed in future)
  // setupWebSocket(server);

  // 3. Start HTTP Server
  server.listen(PORT, () => {
    console.log(`LearnEx Backend is running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV}`);
  });
};

startServer();

// --- Handle Unhandled Rejections ---
process.on('unhandledRejection', (err: any) => {
  console.log('UNHANDLED REJECTION! 💥 Shutting down...');
  console.log(err.name, err.message);
  server.close(() => {
    process.exit(1);
  });
});
