import apiClient from './client';
import type { ApiResponse } from '../types';

export interface SystemSetting {
  key: string;
  value: string;
  description: string | null;
  updated_at: string;
}

export const settingsApi = {
  getAll: async (): Promise<SystemSetting[]> => {
    const res = await apiClient.get<ApiResponse<SystemSetting[]>>('/admin/settings');
    return res.data.data;
  },

  update: async (settings: { key: string; value: string }[]): Promise<SystemSetting[]> => {
    const res = await apiClient.put<ApiResponse<SystemSetting[]>>('/admin/settings', { settings });
    return res.data.data;
  },
};
