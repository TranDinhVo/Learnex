import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import { errorHandler } from './middleware/errorHandler';
import { AppError } from './utils/AppError';
import { sendResponse } from './utils/response';

import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import postRoutes from './routes/post.routes';
import documentRoutes from './routes/document.routes';
import friendRoutes from './routes/friend.routes';
import messageRoutes from './routes/message.routes';
import roomRoutes from './routes/room.routes';
import searchRoutes from './routes/search.routes';
import uploadRoutes from './routes/upload.routes';

const app = express();

// Security Middleware
app.use(helmet());
app.use(
  cors({
    origin: process.env.CORS_ORIGINS?.split(',') || 'http://localhost:5173',
    credentials: true,
  })
);

// Utility Middleware
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));
app.use(compression());
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Health Check Route
app.get('/api/health', (req: Request, res: Response) => {
  sendResponse(res, 200, { status: 'OK', timestamp: new Date() }, 'LearnEx API is running');
});

// App Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/friends', friendRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/upload', uploadRoutes);

// Unhandled Routes
app.use((req: Request, res: Response, next: NextFunction) => {
  next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});

// Global Error Handler
app.use(errorHandler);

export default app;
