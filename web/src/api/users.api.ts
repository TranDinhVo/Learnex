import apiClient from "./client";
import type {
  User,
  ApiResponse,
  PaginatedResponse,
  PaginationParams,
} from "../types";

export const usersApi = {
  getAll: async (
    params?: PaginationParams,
  ): Promise<PaginatedResponse<User>> => {
    const res = await apiClient.get<ApiResponse<PaginatedResponse<User>>>(
      "/admin/users",
      { params },
    );
    return res.data.data;
  },

  ban: async (id: string): Promise<User> => {
    const res = await apiClient.put<ApiResponse<User>>(
      `/admin/users/${id}/ban`,
    );
    return res.data.data;
  },

  unban: async (id: string): Promise<User> => {
    const res = await apiClient.put<ApiResponse<User>>(
      `/admin/users/${id}/unban`,
    );
    return res.data.data;
  },

  updateRole: async (id: string, role: 'admin' | 'user'): Promise<User> => {
    const res = await apiClient.put<ApiResponse<User>>(`/admin/users/${id}/role`, { role });
    return res.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/admin/users/${id}`);
  },

  create: async (data: {
    email: string;
    password: string;
    full_name: string;
    username: string;
    role?: string;
    avatar?: File | null;
  }) => {
    // Support file upload via FormData
    let payload: any = data;
    let config = {};
    if ((data as any).avatar) {
      payload = new FormData();
      payload.append("email", (data as any).email);
      payload.append("password", (data as any).password);
      payload.append("full_name", (data as any).full_name);
      payload.append("username", (data as any).username);
      if ((data as any).role) payload.append("role", (data as any).role);
      payload.append("avatar", (data as any).avatar);
      config = { headers: { "Content-Type": "multipart/form-data" } };
    }

    const res = await apiClient.post(`/admin/users`, payload, config);
    return res.data.data;
  },

  getById: async (id: string) => {
    const res = await apiClient.get(`/admin/users/${id}`);
    return res.data.data;
  },

  update: async (
    id: string,
    data: Partial<{
      email: string;
      username: string;
      full_name: string;
      role: string;
      is_banned: boolean;
      password?: string;
      avatar?: File | null;
    }>,
  ) => {
    let payload: any = data;
    let config = {};
    if ((data as any).avatar) {
      payload = new FormData();
      if ((data as any).email) payload.append("email", (data as any).email);
      if ((data as any).username)
        payload.append("username", (data as any).username);
      if ((data as any).full_name)
        payload.append("full_name", (data as any).full_name);
      if ((data as any).role) payload.append("role", (data as any).role);
      if ((data as any).is_banned !== undefined)
        payload.append("is_banned", String((data as any).is_banned));
      if ((data as any).password)
        payload.append("password", (data as any).password);
      payload.append("avatar", (data as any).avatar);
      config = { headers: { "Content-Type": "multipart/form-data" } };
    }

    const res = await apiClient.put(`/admin/users/${id}`, payload, config);
    return res.data.data;
  },
};
