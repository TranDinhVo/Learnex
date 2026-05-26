import { useMutation, useQuery } from '@tanstack/react-query';
import { useAuthStore } from '../stores/authStore';
import { authApi } from '../api/auth.api';
import type { LoginRequest } from '../types';

export function useAuth() {
  const { token, user, isAuthenticated, setAuth, setUser, logout } = useAuthStore();

  const loginMutation = useMutation({
    mutationFn: (data: LoginRequest) => authApi.login(data),
    onSuccess: (res) => {
      setAuth(res.tokens.accessToken, res.user);
    },
  });

  const meQuery = useQuery({
    queryKey: ['me'],
    queryFn: authApi.getMe,
    enabled: !!token,
    retry: false,
    staleTime: 5 * 60 * 1000,
  });

  // Keep store in sync with fresh server data
  if (meQuery.data && meQuery.data._id !== user?._id) {
    setUser(meQuery.data);
  }

  return {
    user,
    token,
    isAuthenticated,
    login: loginMutation.mutateAsync,
    loginLoading: loginMutation.isPending,
    loginError: loginMutation.error,
    logout,
    meQuery,
  };
}
