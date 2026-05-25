import apiClient from './client';
import type { Document, ApiResponse, PaginatedResponse, PaginationParams } from '../types';

export const documentsApi = {
  getAll: async (params?: PaginationParams): Promise<PaginatedResponse<Document>> => {
    const res = await apiClient.get<ApiResponse<PaginatedResponse<Document>>>('/admin/documents', { params });
    return res.data.data;
  },

  approve: async (id: string): Promise<Document> => {
    const res = await apiClient.put<ApiResponse<Document>>(`/admin/documents/${id}/approve`);
    return res.data.data;
  },

  reject: async (id: string): Promise<Document> => {
    const res = await apiClient.put<ApiResponse<Document>>(`/admin/documents/${id}/reject`);
    return res.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/admin/documents/${id}`);
  },
};
