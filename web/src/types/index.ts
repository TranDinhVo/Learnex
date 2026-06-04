// ==================== Auth ====================
export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  tokens: {
    accessToken: string;
    refreshToken: string;
  };
  user: User;
}

// ==================== User ====================
export interface User {
  _id: string;
  name: string;
  username: string;
  email: string;
  avatar?: string;
  role: 'user' | 'admin';
  isBanned: boolean;
  createdAt: string;
  updatedAt: string;
}

// ==================== Post ====================
export interface Post {
  _id: string;
  content: string;
  author: Pick<User, '_id' | 'name' | 'email' | 'avatar'>;
  images?: string[];
  likes: string[];
  comments: Comment[];
  isHidden: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Comment {
  _id: string;
  content: string;
  author: Pick<User, '_id' | 'name' | 'avatar'>;
  createdAt: string;
}

// ==================== Document ====================
export interface Document {
  _id: string;
  title: string;
  description?: string;
  fileUrl: string;
  fileType: string;
  uploadedBy: Pick<User, '_id' | 'name' | 'email' | 'avatar'>;
  status: 'pending' | 'approved' | 'rejected';
  downloads: number;
  createdAt: string;
  updatedAt: string;
}

// ==================== Room ====================
export interface Room {
  _id: string;
  name: string;
  description?: string;
  creator: Pick<User, '_id' | 'name' | 'email' | 'avatar'>;
  members: Pick<User, '_id' | 'name' | 'avatar'>[];
  maxMembers: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// ==================== Notification ====================
export interface Notification {
  _id: string;
  title: string;
  message: string;
  type: 'info' | 'warning' | 'success' | 'error';
  targetAudience: 'all' | 'specific';
  targetUsers?: string[];
  sentBy: Pick<User, '_id' | 'name'>;
  createdAt: string;
}

export interface SendNotificationRequest {
  title: string;
  message: string;
  type: 'info' | 'warning' | 'success' | 'error';
  targetAudience: 'all' | 'specific';
  targetUsers?: string[];
}

// ==================== Report ====================
export interface Report {
  _id: string;
  reporter: Pick<User, '_id' | 'name' | 'avatar'>;
  targetType: 'user' | 'post' | 'comment' | 'room';
  targetId: string;
  targetInfo: Record<string, unknown>;
  reason: string;
  status: 'pending' | 'resolved' | 'dismissed';
  createdAt: string;
}

// ==================== Dashboard ====================
export interface DashboardStats {
  totalUsers: number;
  totalPosts: number;
  totalDocuments: number;
  totalRooms: number;
  activeUsers: number;
  newUsersToday: number;
  newPostsToday: number;
  pendingDocuments: number;
  userGrowth: ChartDataPoint[];
  postActivity: ChartDataPoint[];
  documentStats: PieDataPoint[];
  roomActivity: ChartDataPoint[];
}

export interface ChartDataPoint {
  name: string;
  value: number;
  value2?: number;
}

export interface PieDataPoint {
  name: string;
  value: number;
  color: string;
}

// ==================== API Response ====================
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface PaginationParams {
  page?: number;
  limit?: number;
  search?: string;
  sort?: string;
  order?: 'asc' | 'desc';
}
