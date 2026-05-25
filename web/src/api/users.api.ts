import apiClient from './client';
import type { User, ApiResponse, PaginatedResponse, PaginationParams } from '../types';

export const usersApi = {
  getAll: async (params?: PaginationParams): Promise<PaginatedResponse<User>> => {
    const res = await apiClient.get<ApiResponse<PaginatedResponse<User>>>('/admin/users', { params });
    return res.data.data;
  },

  ban: async (id: string): Promise<User> => {
    const res = await apiClient.put<ApiResponse<User>>(`/admin/users/${id}/ban`);
    return res.data.data;
  },

  unban: async (id: string): Promise<User> => {
    const res = await apiClient.put<ApiResponse<User>>(`/admin/users/${id}/unban`);
    return res.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/admin/users/${id}`);
  },
};
