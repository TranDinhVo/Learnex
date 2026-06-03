// ============================================================
// Database Table Interfaces
// ============================================================

export interface User {
  id: string;
  email: string;
  password_hash: string;
  full_name: string;
  username: string;
  avatar_url: string | null;
  bio: string | null;
  school: string | null;
  major: string | null;
  role: 'user' | 'admin';
  is_banned: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface RefreshToken {
  id: string;
  user_id: string;
  token: string;
  expires_at: Date;
  created_at: Date;
}

export interface Document {
  id: string;
  user_id: string;
  title: string;
  description: string | null;
  file_url: string;
  file_size: number | null;
  file_type: string | null;
  subject: string | null;
  tags: string[];
  summary: string | null;
  download_count: number;
  view_count: number;
  created_at: Date;
}

export interface Post {
  id: string;
  user_id: string;
  content: string | null;
  image_urls: string[] | null;
  document_id: string | null;
  is_deleted: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface Like {
  id: string;
  post_id: string;
  user_id: string;
  created_at: Date;
}

export interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  content: string;
  created_at: Date;
}

export interface SavedPost {
  id: string;
  post_id: string;
  user_id: string;
  created_at: Date;
}

export interface Friendship {
  id: string;
  requester_id: string;
  addressee_id: string;
  status: 'pending' | 'accepted' | 'rejected';
  created_at: Date;
}

export interface DirectMessage {
  id: string;
  sender_id: string;
  receiver_id: string;
  content: string | null;
  file_url: string | null;
  is_read: boolean;
  created_at: Date;
}

export interface Room {
  id: string;
  owner_id: string;
  name: string;
  description: string | null;
  avatar_url: string | null;
  privacy_mode: 'public' | 'private' | 'approval';
  created_at: Date;
}

export interface RoomJoinRequest {
  id: string;
  room_id: string;
  user_id: string;
  status: 'pending' | 'approved' | 'rejected';
  created_at: Date;
}

export interface RoomMember {
  id: string;
  room_id: string;
  user_id: string;
  role: 'owner' | 'moderator' | 'member';
  joined_at: Date;
}

export interface RoomMessage {
  id: string;
  room_id: string;
  sender_id: string | null;
  content: string | null;
  file_url: string | null;
  created_at: Date;
}

export interface RoomMessageRead {
  id: string;
  message_id: string;
  user_id: string;
  read_at: Date;
}

export interface Notification {
  id: string;
  user_id: string;
  type: 'like' | 'comment' | 'friend_request' | 'message' | 'room_invite' | 'call';
  title: string;
  body: string | null;
  ref_type: string | null;
  ref_id: string | null;
  is_read: boolean;
  created_at: Date;
}

export interface DocumentView {
  id: string;
  user_id: string;
  document_id: string;
  viewed_at: Date;
}

export interface Report {
  id: string;
  reporter_id: string;
  target_type: 'user' | 'post' | 'comment' | 'room';
  target_id: string;
  reason: string;
  status: 'pending' | 'resolved' | 'dismissed';
  created_at: Date;
  updated_at: Date;
}

export interface SystemSetting {
  key: string;
  value: string;
  description: string | null;
  updated_at: Date;
}

// ============================================================
// Auth Types
// ============================================================

export interface RegisterRequest {
  email: string;
  password: string;
  full_name: string;
  username: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface TokenPayload {
  userId: string;
  role: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

// ============================================================
// Request Types
// ============================================================

export interface UpdateProfileRequest {
  full_name?: string;
  bio?: string;
  school?: string;
  major?: string;
}

export interface CreatePostRequest {
  content?: string;
  image_urls?: string[];
  document_id?: string;
}

export interface CreateRoomRequest {
  name: string;
  description?: string;
  is_private?: boolean;
}

export interface SendMessageRequest {
  content?: string;
  file_url?: string;
}

// ============================================================
// Response Types
// ============================================================

export interface UserPublic {
  id: string;
  email: string;
  full_name: string;
  username: string;
  avatar_url: string | null;
  bio: string | null;
  school: string | null;
  major: string | null;
  role: string;
  created_at: Date;
}

export interface PaginationInfo {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface PaginatedResponse<T> {
  success: boolean;
  data: T[];
  pagination: PaginationInfo;
}

// ============================================================
// Express Extensions
// ============================================================

declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}
