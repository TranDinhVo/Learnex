import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { db } from '@/config/database';
import { redis } from '@/config/redis';
import { AppError } from '@/utils/AppError';
import { User, AuthTokens, TokenPayload, UserPublic } from '@/module/common/common.type';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-key';
const ACCESS_TOKEN_EXPIRY = '24h';
const REFRESH_TOKEN_EXPIRY = '7d';
const SALT_ROUNDS = 10;

function generateAccessToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: ACCESS_TOKEN_EXPIRY });
}

function generateRefreshToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: REFRESH_TOKEN_EXPIRY });
}

function sanitizeUser(user: User): UserPublic {
  return {
    id: user.id,
    email: user.email,
    full_name: user.full_name,
    username: user.username,
    avatar_url: user.avatar_url,
    bio: user.bio,
    school: user.school,
    major: user.major,
    role: user.role,
    created_at: user.created_at,
  };
}

export const authService = {
  async register(email: string, password: string, fullName: string, username: string): Promise<{ user: UserPublic; tokens: AuthTokens }> {
    // Check if email already exists
    const existingEmail = await db('users').where({ email }).first();
    if (existingEmail) {
      throw new AppError('Email is already registered.', 400);
    }

    // Check if username already exists
    const existingUsername = await db('users').where({ username }).first();
    if (existingUsername) {
      throw new AppError('Username is already taken.', 400);
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const [user] = await db('users')
      .insert({
        email,
        password_hash: passwordHash,
        full_name: fullName,
        username,
      })
      .returning('*');

    const tokenPayload: TokenPayload = { userId: user.id, role: user.role };
    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    // Store refresh token in DB
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await db('refresh_tokens').insert({
      user_id: user.id,
      token: refreshToken,
      expires_at: expiresAt,
    });

    return {
      user: sanitizeUser(user),
      tokens: { accessToken, refreshToken },
    };
  },

  async login(email: string, password: string): Promise<{ user: UserPublic; tokens: AuthTokens }> {
    const user = await db('users').where({ email }).first();
    if (!user) {
      throw new AppError('Invalid email or password.', 401);
    }

    if (user.is_banned) {
      throw new AppError('Your account has been banned. Contact support.', 403);
    }

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      throw new AppError('Invalid email or password.', 401);
    }

    const tokenPayload: TokenPayload = { userId: user.id, role: user.role };
    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await db('refresh_tokens').insert({
      user_id: user.id,
      token: refreshToken,
      expires_at: expiresAt,
    });

    return {
      user: sanitizeUser(user),
      tokens: { accessToken, refreshToken },
    };
  },

  async refreshToken(token: string): Promise<AuthTokens> {
    // Verify the refresh token
    let decoded: TokenPayload;
    try {
      decoded = jwt.verify(token, JWT_REFRESH_SECRET) as TokenPayload;
    } catch {
      throw new AppError('Invalid or expired refresh token.', 401);
    }

    // Check if token exists in DB
    const storedToken = await db('refresh_tokens')
      .where({ token })
      .andWhere('expires_at', '>', new Date())
      .first();

    if (!storedToken) {
      throw new AppError('Refresh token not found or expired.', 401);
    }

    // Check user still exists and is not banned
    const user = await db('users').where({ id: decoded.userId }).first();
    if (!user || user.is_banned) {
      throw new AppError('User not found or account is banned.', 401);
    }

    // Delete old refresh token
    await db('refresh_tokens').where({ token }).del();

    // Generate new tokens
    const tokenPayload: TokenPayload = { userId: user.id, role: user.role };
    const accessToken = generateAccessToken(tokenPayload);
    const newRefreshToken = generateRefreshToken(tokenPayload);

    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await db('refresh_tokens').insert({
      user_id: user.id,
      token: newRefreshToken,
      expires_at: expiresAt,
    });

    return { accessToken, refreshToken: newRefreshToken };
  },

  async logout(refreshToken: string): Promise<void> {
    await db('refresh_tokens').where({ token: refreshToken }).del();
  },

  async forgotPassword(email: string): Promise<void> {
    const user = await db('users').where({ email }).first();
    if (!user) {
      // Don't reveal if email exists
      return;
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Store OTP in Redis with 10 minute expiry
    await redis.setEx(`otp:${email}`, 600, otp);

    // In production, send email with OTP
    // For now, log it (dev only)
    console.log(`[DEV] OTP for ${email}: ${otp}`);
  },

  async verifyOtp(email: string, otp: string): Promise<{ resetToken: string }> {
    const storedOtp = await redis.get(`otp:${email}`);
    if (!storedOtp || storedOtp !== otp) {
      throw new AppError('Invalid or expired OTP.', 400);
    }

    // Delete OTP after verification
    await redis.del(`otp:${email}`);

    // Generate a temporary reset token
    const resetToken = uuidv4();
    await redis.setEx(`reset:${resetToken}`, 600, email); // 10 min expiry

    return { resetToken };
  },

  async resetPassword(resetToken: string, newPassword: string): Promise<void> {
    const email = await redis.get(`reset:${resetToken}`);
    if (!email) {
      throw new AppError('Invalid or expired reset token.', 400);
    }

    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);

    const updated = await db('users')
      .where({ email })
      .update({ password_hash: passwordHash });

    if (!updated) {
      throw new AppError('User not found.', 404);
    }

    // Delete reset token
    await redis.del(`reset:${resetToken}`);

    // Revoke all existing refresh tokens for this user
    const user = await db('users').where({ email }).first();
    if (user) {
      await db('refresh_tokens').where({ user_id: user.id }).del();
    }
  },

  async changePassword(userId: string, currentPassword: string, newPassword: string): Promise<void> {
    const user = await db('users').where({ id: userId }).first();
    if (!user) {
      throw new AppError('User not found.', 404);
    }

    const isPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isPasswordValid) {
      throw new AppError('Current password is incorrect.', 400);
    }

    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await db('users').where({ id: userId }).update({ password_hash: passwordHash });
  },
};
