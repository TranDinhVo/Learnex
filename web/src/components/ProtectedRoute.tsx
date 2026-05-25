import { Navigate, useLocation } from 'react-router-dom';
import { useAuthStore } from '../stores/authStore';

export default function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, user } = useAuthStore();
  const location = useLocation();

  if (!isAuthenticated || !user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (user.role !== 'admin') {
    return (
      <div className="flex h-screen items-center justify-center bg-gray-900">
        <div className="rounded-2xl border border-white/10 bg-white/5 p-8 text-center backdrop-blur-xl">
          <h2 className="mb-2 text-xl font-bold text-white">Truy cập bị từ chối</h2>
          <p className="text-gray-400">Bạn không có quyền truy cập trang quản trị.</p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
