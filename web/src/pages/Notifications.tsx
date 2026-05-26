import { useEffect, useState } from 'react';
import { notificationsApi } from '../api/notifications.api';
import type { Notification, SendNotificationRequest } from '../types';
import PageHeader from '../components/ui/PageHeader';
import DataTable, { type Column } from '../components/ui/DataTable';
import Pagination from '../components/ui/Pagination';
import StatusBadge from '../components/ui/StatusBadge';
import { Bell, Send, History } from 'lucide-react';

export default function Notifications() {
  const [history, setHistory] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [limit] = useState(5);

  // Form state
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [type, setType] = useState<'info' | 'warning' | 'success' | 'error'>('info');
  const [submitLoading, setSubmitLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const fetchHistory = async () => {
    setLoading(true);
    try {
      const res = await notificationsApi.getHistory({ page, limit });
      setHistory(res.data);
      setTotal(res.total);
    } catch (err) {
      console.error('Không thể lấy lịch sử thông báo:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, [page]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !message.trim()) return;

    setSubmitLoading(true);
    setSuccessMessage(null);
    setErrorMessage(null);

    const payload: SendNotificationRequest = {
      title: title.trim(),
      message: message.trim(),
      type,
      targetAudience: 'all',
    };

    try {
      await notificationsApi.send(payload);
      setSuccessMessage('Đã gửi thông báo hệ thống thành công tới tất cả học viên!');
      setTitle('');
      setMessage('');
      setPage(1);
      fetchHistory();
    } catch (err) {
      setErrorMessage('Gửi thông báo hệ thống thất bại. Vui lòng thử lại.');
      console.error('Send notification error', err);
    } finally {
      setSubmitLoading(false);
    }
  };

  const columns: Column<Notification>[] = [
    {
      key: 'title',
      header: 'Tiêu đề thông báo',
      render: (n) => (
        <div className="flex items-center gap-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-50 text-indigo-600">
            <Bell className="h-4 w-4" />
          </div>
          <div>
            <p className="font-semibold text-slate-800">{n.title}</p>
            <p className="text-xs text-slate-500 line-clamp-1">{n.message}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'type',
      header: 'Loại',
      render: (n) => {
        let status: 'active' | 'pending' | 'banned' = 'active';
        let label = 'Thông tin';

        if (n.type === 'warning') {
          status = 'pending';
          label = 'Cảnh báo';
        } else if (n.type === 'error') {
          status = 'banned';
          label = 'Lỗi hệ thống';
        } else if (n.type === 'success') {
          status = 'active';
          label = 'Thành công';
        }

        return <StatusBadge status={status} label={label} />;
      },
    },
    {
      key: 'target',
      header: 'Đối tượng nhận',
      render: () => <span className="text-xs font-semibold text-slate-600 bg-slate-100 px-2 py-0.5 rounded">Tất cả</span>,
    },
    {
      key: 'createdAt',
      header: 'Thời gian gửi',
      render: (n) => (
        <span className="text-xs text-slate-500">
          {new Date(n.createdAt).toLocaleString('vi-VN')}
        </span>
      ),
    },
  ];

  return (
    <div className="space-y-10">
      <PageHeader title="Gửi thông báo hệ thống" description="Phát sóng thông báo hoặc cảnh báo thời gian thực tới toàn bộ học viên LearnEx" />

      {/* Composition Form */}
      <div className="rounded-2xl border border-slate-200/60 bg-white p-6 shadow-xl shadow-slate-200/30">
        <div className="mb-6 flex items-center gap-2">
          <Send className="h-5 w-5 text-indigo-600" />
          <h2 className="text-lg font-bold text-slate-800">Soạn thông báo mới</h2>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {successMessage && (
            <div className="rounded-lg bg-emerald-50 border border-emerald-100 p-4 text-sm text-emerald-600 font-medium">
              ✨ {successMessage}
            </div>
          )}
          {errorMessage && (
            <div className="rounded-lg bg-red-50 border border-red-100 p-4 text-sm text-red-600 font-medium">
              ❌ {errorMessage}
            </div>
          )}

          <div className="grid grid-cols-1 gap-5 md:grid-cols-3">
            <div className="md:col-span-2">
              <label className="block text-xs font-bold uppercase text-slate-500 tracking-wider mb-2">Tiêu đề</label>
              <input
                type="text"
                required
                placeholder="Nhập tiêu đề thông báo (ví dụ: Bảo trì hệ thống)..."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-sm transition-all focus:border-indigo-500 focus:bg-white focus:outline-none"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase text-slate-500 tracking-wider mb-2">Loại thông báo</label>
              <select
                value={type}
                onChange={(e) => setType(e.target.value as any)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-sm transition-all focus:border-indigo-500 focus:bg-white focus:outline-none"
              >
                <option value="info">Thông tin (Info)</option>
                <option value="success">Thành công (Success)</option>
                <option value="warning">Cảnh báo (Warning)</option>
                <option value="error">Khẩn cấp/Lỗi (Error)</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 tracking-wider mb-2">Nội dung thông điệp</label>
            <textarea
              required
              rows={4}
              placeholder="Nhập nội dung thông điệp chi tiết muốn gửi tới sinh viên..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-sm transition-all focus:border-indigo-500 focus:bg-white focus:outline-none"
            />
          </div>

          <div className="flex justify-end">
            <button
              type="submit"
              disabled={submitLoading || !title.trim() || !message.trim()}
              className="flex items-center gap-2 rounded-xl bg-indigo-600 px-6 py-3 font-semibold text-white transition-all hover:bg-indigo-700 disabled:bg-slate-300 disabled:cursor-not-allowed cursor-pointer hover:shadow-lg active:scale-95 duration-200"
            >
              <Send className="h-4 w-4" />
              <span>{submitLoading ? 'Đang gửi...' : 'Gửi thông báo ngay'}</span>
            </button>
          </div>
        </form>
      </div>

      {/* History log */}
      <div className="space-y-6">
        <div className="flex items-center gap-2">
          <History className="h-5 w-5 text-indigo-600" />
          <h2 className="text-lg font-bold text-slate-800">Lịch sử gửi thông báo</h2>
        </div>

        <div className="shadow-xl shadow-slate-200/40 rounded-2xl overflow-hidden border border-slate-200/60">
          <DataTable
            columns={columns}
            data={history}
            keyExtractor={(n) => n._id}
            isLoading={loading}
            emptyMessage="Không tìm thấy lịch sử thông báo nào."
          />
        </div>

        {total > limit && (
          <div className="flex justify-end pt-4">
            <Pagination
              currentPage={page}
              totalPages={Math.ceil(total / limit)}
              onPageChange={setPage}
            />
          </div>
        )}
      </div>
    </div>
  );
}
