import apiClient from './client';
import type { LoginRequest, LoginResponse, User, ApiResponse } from '../types';

export const authApi = {
  login: async (data: LoginRequest): Promise<LoginResponse> => {
    const res = await apiClient.post<ApiResponse<LoginResponse>>('/auth/login', data);
    return res.data.data;
  },

  getMe: async (): Promise<User> => {
    const res = await apiClient.get<ApiResponse<User>>('/users/me');
    return res.data.data;
  },
};
