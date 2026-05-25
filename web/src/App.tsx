import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import ProtectedRoute from './components/ProtectedRoute';
import AdminLayout from './components/Layout/AdminLayout';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        
        {/* Protected Admin Routes */}
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <AdminLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="users" element={<Users />} />
          
          {/* Fallback routes for under construction views */}
          <Route
            path="posts"
            element={
              <div className="rounded-2xl border border-slate-200/60 bg-white p-8 text-center text-slate-500 shadow-sm">
                Tính năng Quản lý bài viết đang phát triển.
              </div>
            }
          />
          <Route
            path="documents"
            element={
              <div className="rounded-2xl border border-slate-200/60 bg-white p-8 text-center text-slate-500 shadow-sm">
                Tính năng Quản lý tài liệu đang phát triển.
              </div>
            }
          />
          <Route
            path="rooms"
            element={
              <div className="rounded-2xl border border-slate-200/60 bg-white p-8 text-center text-slate-500 shadow-sm">
                Tính năng Quản lý phòng học đang phát triển.
              </div>
            }
          />
          <Route
            path="notifications"
            element={
              <div className="rounded-2xl border border-slate-200/60 bg-white p-8 text-center text-slate-500 shadow-sm">
                Tính năng Gửi thông báo hệ thống đang phát triển.
              </div>
            }
          />
        </Route>

        {/* Fallback to dashboard */}
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
