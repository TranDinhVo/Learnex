import apiClient from './client';
import type { Report, ApiResponse, PaginatedResponse, PaginationParams } from '../types';

export const reportsApi = {
  getAll: async (params?: PaginationParams): Promise<PaginatedResponse<Report>> => {
    const res = await apiClient.get<ApiResponse<PaginatedResponse<Report>>>('/reports', { params });
    return res.data.data;
  },

  updateStatus: async (id: string, status: 'resolved' | 'dismissed'): Promise<Report> => {
    const res = await apiClient.put<ApiResponse<Report>>(`/reports/${id}/status`, { status });
    return res.data.data;
  },
};
