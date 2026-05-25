import apiClient from './client';
import type { DashboardStats, ApiResponse } from '../types';

export const dashboardApi = {
  getStats: async (): Promise<DashboardStats> => {
    const res = await apiClient.get<ApiResponse<DashboardStats>>('/admin/dashboard/stats');
    return res.data.data;
  },
};
