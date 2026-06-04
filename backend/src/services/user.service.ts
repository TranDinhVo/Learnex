import { db } from "../config/database";
import { AppError } from "../utils/AppError";
import { UserPublic } from "../models/types";
import { PaginationParams } from "../utils/pagination";
import { uploadFile } from "../config/cloudinary";
import { cloudinaryService } from "./cloudinary.service";
import bcrypt from "bcryptjs";

const SALT_ROUNDS = 10;

const USER_PUBLIC_FIELDS = [
  "id",
  "email",
  "full_name",
  "username",
  "avatar_url",
  "bio",
  "school",
  "major",
  "role",
  "created_at",
];

async function getUserStats(userId: string): Promise<{
  friends_count: number;
  documents_count: number;
  posts_count: number;
}> {
  const [{ count: friendsCount }] = await db("friendships")
    .where(function () {
      this.where({ requester_id: userId }).orWhere({ addressee_id: userId });
    })
    .andWhere({ status: "accepted" })
    .count("* as count");

  const [{ count: documentsCount }] = await db("documents")
    .where({ user_id: userId })
    .count("* as count");

  const [{ count: postsCount }] = await db("posts")
    .where({ user_id: userId, is_deleted: false })
    .count("* as count");

  return {
    friends_count: parseInt(friendsCount as string, 10) || 0,
    documents_count: parseInt(documentsCount as string, 10) || 0,
    posts_count: parseInt(postsCount as string, 10) || 0,
  };
}

export const userService = {
  async getMe(userId: string): Promise<any> {
    const user = await db("users")
      .select(USER_PUBLIC_FIELDS)
      .where({ id: userId })
      .first();

    if (!user) {
      throw new AppError("User not found.", 404);
    }

    const stats = await getUserStats(userId);
    return { ...user, ...stats };
  },

  async updateProfile(
    userId: string,
    data: { full_name?: string; bio?: string; school?: string; major?: string },
    file?: Express.Multer.File,
  ): Promise<UserPublic> {
    const updateData: Record<string, any> = {};
    if (data.full_name !== undefined) updateData.full_name = data.full_name;
    if (data.bio !== undefined) updateData.bio = data.bio;
    if (data.school !== undefined) updateData.school = data.school;
    if (data.major !== undefined) updateData.major = data.major;

    // Handle avatar upload if file provided
    if (file) {
      // delete old avatar (if exists) by using known public_id
      try {
        await cloudinaryService.deleteFile(`learnex/avatars/avatar_${userId}`);
      } catch (e) {
        // ignore delete errors
      }
      const avatarUrl = await cloudinaryService.uploadAvatar(
        file.buffer,
        userId,
      );
      updateData.avatar_url = avatarUrl;
    }

    if (Object.keys(updateData).length === 0) {
      throw new AppError("No fields to update.", 400);
    }

    const [user] = await db("users")
      .where({ id: userId })
      .update(updateData)
      .returning(USER_PUBLIC_FIELDS);

    if (!user) {
      throw new AppError("User not found.", 404);
    }

    return user;
  },

  async uploadAvatar(
    userId: string,
    file: Express.Multer.File,
  ): Promise<UserPublic> {
    // delete existing avatar
    try {
      await cloudinaryService.deleteFile(`learnex/avatars/avatar_${userId}`);
    } catch (e) {
      // ignore
    }

    const avatarUrl = await cloudinaryService.uploadAvatar(file.buffer, userId);

    const [user] = await db("users")
      .where({ id: userId })
      .update({ avatar_url: avatarUrl })
      .returning(USER_PUBLIC_FIELDS);

    if (!user) {
      throw new AppError("User not found.", 404);
    }

    return user;
  },

  async getUserById(userId: string): Promise<any> {
    const user = await db("users")
      .select(USER_PUBLIC_FIELDS)
      .where({ id: userId })
      .first();

    if (!user) {
      throw new AppError("User not found.", 404);
    }

    const stats = await getUserStats(userId);
    return { ...user, ...stats };
  },

  async searchUsers(
    query: string,
    pagination: PaginationParams,
  ): Promise<{ data: UserPublic[]; total: number }> {
    const searchTerm = `%${query}%`;

    const baseQuery = db("users")
      .select(USER_PUBLIC_FIELDS)
      .where(function () {
        this.whereILike("full_name", searchTerm)
          .orWhereILike("username", searchTerm)
          .orWhereILike("email", searchTerm);
      });

    const [{ count }] = await baseQuery
      .clone()
      .clearSelect()
      .count("* as count");
    const total = parseInt(count as string, 10);

    const data = await baseQuery
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit)
      .orderBy("full_name", "asc");

    return { data, total };
  },

  // Admin: create a new user (by admin)
  async createUserByAdmin(
    data: {
      email: string;
      password: string;
      full_name: string;
      username: string;
      role?: string;
    },
    file?: Express.Multer.File,
  ): Promise<UserPublic> {
    const { email, password, full_name, username, role } = data;

    // Validate uniqueness
    const existingEmail = await db("users").where({ email }).first();
    if (existingEmail) throw new AppError("Email is already registered.", 400);

    const existingUsername = await db("users").where({ username }).first();
    if (existingUsername) throw new AppError("Username is already taken.", 400);

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const [user] = await db("users")
      .insert({
        email,
        password_hash: passwordHash,
        full_name,
        username,
        role: role || "user",
      })
      .returning(USER_PUBLIC_FIELDS);

    // If admin provided avatar file, upload and update
    if (file) {
      try {
        const avatarUrl = await cloudinaryService.uploadAvatar(
          file.buffer,
          user.id,
        );
        const [updated] = await db("users")
          .where({ id: user.id })
          .update({ avatar_url: avatarUrl })
          .returning(USER_PUBLIC_FIELDS);
        return updated;
      } catch (e) {
        return user; // return created user even if avatar upload fails
      }
    }

    return user;
  },

  // Admin: update any user's profile / role / ban status
  async adminUpdateUser(
    userId: string,
    data: {
      email?: string;
      username?: string;
      full_name?: string;
      bio?: string;
      school?: string;
      major?: string;
      role?: string;
      is_banned?: boolean;
      password?: string;
    },
    file?: Express.Multer.File,
  ): Promise<UserPublic> {
    const updateData: Record<string, any> = {};
    if (data.email !== undefined) updateData.email = data.email;
    if (data.username !== undefined) updateData.username = data.username;
    if (data.full_name !== undefined) updateData.full_name = data.full_name;
    if (data.bio !== undefined) updateData.bio = data.bio;
    if (data.school !== undefined) updateData.school = data.school;
    if (data.major !== undefined) updateData.major = data.major;
    if (data.role !== undefined) updateData.role = data.role;
    if (data.is_banned !== undefined) updateData.is_banned = data.is_banned;

    // Handle password change by admin
    if (data.password) {
      const pwdHash = await bcrypt.hash(data.password, SALT_ROUNDS);
      updateData.password_hash = pwdHash;
    }

    // Handle avatar file upload by admin
    if (file) {
      try {
        await cloudinaryService.deleteFile(`learnex/avatars/avatar_${userId}`);
      } catch (e) {
        // ignore
      }
      const avatarUrl = await cloudinaryService.uploadAvatar(
        file.buffer,
        userId,
      );
      updateData.avatar_url = avatarUrl;
    }

    if (Object.keys(updateData).length === 0) {
      throw new AppError("No fields to update.", 400);
    }

    // Check uniqueness for email/username if provided
    if (updateData.email) {
      const ex = await db("users")
        .where({ email: updateData.email })
        .andWhereNot({ id: userId })
        .first();
      if (ex)
        throw new AppError("Email is already registered by another user.", 400);
    }
    if (updateData.username) {
      const ex = await db("users")
        .where({ username: updateData.username })
        .andWhereNot({ id: userId })
        .first();
      if (ex)
        throw new AppError("Username is already taken by another user.", 400);
    }

    const [user] = await db("users")
      .where({ id: userId })
      .update(updateData)
      .returning(USER_PUBLIC_FIELDS);

    if (!user) {
      throw new AppError("User not found.", 404);
    }

    return user;
  },
};
