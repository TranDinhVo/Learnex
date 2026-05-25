import apiClient from './client';
import type { Post, ApiResponse, PaginatedResponse, PaginationParams } from '../types';

export const postsApi = {
  getAll: async (params?: PaginationParams): Promise<PaginatedResponse<Post>> => {
    const res = await apiClient.get<ApiResponse<PaginatedResponse<Post>>>('/admin/posts', { params });
    return res.data.data;
  },

  hide: async (id: string): Promise<Post> => {
    const res = await apiClient.put<ApiResponse<Post>>(`/admin/posts/${id}/hide`);
    return res.data.data;
  },

  unhide: async (id: string): Promise<Post> => {
    const res = await apiClient.put<ApiResponse<Post>>(`/admin/posts/${id}/unhide`);
    return res.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/admin/posts/${id}`);
  },
};
