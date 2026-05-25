import apiClient from './client';
import type {
  Notification,
  SendNotificationRequest,
  ApiResponse,
  PaginatedResponse,
  PaginationParams,
} from '../types';

export const notificationsApi = {
  send: async (data: SendNotificationRequest): Promise<Notification> => {
    const res = await apiClient.post<ApiResponse<Notification>>('/admin/notifications', data);
    return res.data.data;
  },

  getHistory: async (params?: PaginationParams): Promise<PaginatedResponse<Notification>> => {
    const res = await apiClient.get<ApiResponse<PaginatedResponse<Notification>>>('/admin/notifications', { params });
    return res.data.data;
  },
};
