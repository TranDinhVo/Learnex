import { useEffect, useState } from 'react';
import { dashboardApi } from '../api/dashboard.api';
import type { DashboardStats } from '../types';
import PageHeader from '../components/ui/PageHeader';
import StatCard from '../components/ui/StatCard';
import { Users, FileText, FolderOpen, MessageSquare, Loader2 } from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts';

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const data = await dashboardApi.getStats();
        setStats(data);
      } catch (err) {
        console.error('Lỗi khi tải số liệu thống kê:', err);
        setError('Không thể kết nối đến máy chủ API để lấy số liệu.');
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-10 w-10 animate-spin text-indigo-500" />
          <p className="text-sm text-gray-400">Đang tải số liệu hệ thống...</p>
        </div>
      </div>
    );
  }

  if (error || !stats) {
    return (
      <div className="rounded-2xl border border-red-500/20 bg-red-500/5 p-6 text-center text-red-400">
        <h3 className="text-lg font-bold">Gặp lỗi khi tải dữ liệu</h3>
        <p className="mt-1 text-sm">{error || 'Vui lòng thử lại sau.'}</p>
      </div>
    );
  }

  // Pre-configured colors for pie chart
  const COLORS = ['#6366f1', '#a855f7', '#10b981', '#f43f5e'];

  return (
    <div className="space-y-8">
      <PageHeader title="Tổng quan hệ thống" description="Số liệu đo lường realtime toàn hệ sinh thái LearnEx" />

      {/* Grid of stats cards */}
      <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Tổng người dùng"
          value={stats.totalUsers}
          icon={<Users className="h-6 w-6" />}
          trend={{ value: stats.newUsersToday, label: 'hôm nay' }}
        />
        <StatCard
          title="Tổng bài viết"
          value={stats.totalPosts}
          icon={<FileText className="h-6 w-6" />}
          trend={{ value: stats.newPostsToday, label: 'hôm nay' }}
        />
        <StatCard
          title="Tài liệu chia sẻ"
          value={stats.totalDocuments}
          icon={<FolderOpen className="h-6 w-6" />}
          trend={{ value: stats.pendingDocuments, label: 'đang chờ duyệt' }}
        />
        <StatCard
          title="Phòng nhóm học"
          value={stats.totalRooms}
          icon={<MessageSquare className="h-6 w-6" />}
          trend={{ value: stats.activeUsers, label: 'đang trực tuyến' }}
        />
      </div>

      {/* Grid of Charts */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* User Growth Area Chart */}
        <div className="lg:col-span-2 rounded-2xl border border-slate-200/60 bg-white p-6 shadow-sm shadow-slate-100/60">
          <h3 className="mb-6 text-base font-bold text-slate-800">Xu hướng tăng trưởng người dùng</h3>
          <div className="h-80 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart
                data={stats.userGrowth || []}
                margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
              >
                <defs>
                  <linearGradient id="userGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.15}/>
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.03)" />
                <XAxis dataKey="name" stroke="#64748b" fontSize={11} tickLine={false} />
                <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#fff',
                    borderColor: '#e2e8f0',
                    borderRadius: '12px',
                    color: '#334155',
                    boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.05)',
                  }}
                />
                <Area type="monotone" dataKey="value" name="Người dùng" stroke="#6366f1" strokeWidth={2.5} fillOpacity={1} fill="url(#userGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Documents Pie Chart */}
        <div className="rounded-2xl border border-slate-200/60 bg-white p-6 shadow-sm shadow-slate-100/60 flex flex-col">
          <h3 className="mb-6 text-base font-bold text-slate-800">Tỷ lệ tài liệu học tập</h3>
          <div className="flex-1 flex items-center justify-center h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={stats.documentStats || [
                    { name: 'Toán', value: 12 },
                    { name: 'Tin học', value: 25 },
                    { name: 'Lý', value: 8 },
                    { name: 'Khác', value: 15 }
                  ]}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {(stats.documentStats || []).map((_, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#fff',
                    borderColor: '#e2e8f0',
                    borderRadius: '12px',
                    color: '#334155',
                    boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.05)',
                  }}
                />
                <Legend iconType="circle" wrapperStyle={{ fontSize: '12px', color: '#64748b' }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}
