import { createClient } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

export const redis = createClient({
  url: process.env.REDIS_URL,
});

redis.on('error', (err) => console.error('Redis Client Error:', err));
redis.on('connect', () => console.log('Redis connected successfully'));

export const connectRedis = async () => {
  try {
    await redis.connect();
  } catch (error) {
    console.error('❌ Failed to connect to Redis:', error);
    // Don't exit process for Redis in dev, just log
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }
};
