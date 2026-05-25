import apiClient from './client';
import type { Room, ApiResponse, PaginatedResponse, PaginationParams } from '../types';

export const roomsApi = {
  getAll: async (params?: PaginationParams): Promise<PaginatedResponse<Room>> => {
    const res = await apiClient.get<ApiResponse<PaginatedResponse<Room>>>('/admin/rooms', { params });
    return res.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/admin/rooms/${id}`);
  },
};
