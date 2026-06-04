import { useEffect, useState, useRef } from 'react';
import { notificationsApi } from '../api/notifications.api';
import { usersApi } from '../api/users.api';
import type { Notification, SendNotificationRequest, User } from '../types';
import PageHeader from '../components/ui/PageHeader';
import DataTable, { type Column } from '../components/ui/DataTable';
import Pagination from '../components/ui/Pagination';
import StatusBadge from '../components/ui/StatusBadge';
import ConfirmModal from '../components/ui/ConfirmModal';
import { Bell, Send, History, Search, X, User as UserIcon, Users } from 'lucide-react';

function UserSearchSelect({ selectedUsers, onChange }: { selectedUsers: User[], onChange: (users: User[]) => void }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const wrapperRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    const fetchUsers = async () => {
      if (!query.trim()) {
        setResults([]);
        return;
      }
      setLoading(true);
      try {
        const res = await usersApi.getAll({ search: query, limit: 10, page: 1 });
        // The API returns paginated array
        setResults((res.data || res as any) || []);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    const debounceId = setTimeout(fetchUsers, 400);
    return () => clearTimeout(debounceId);
  }, [query]);

  const handleSelect = (user: User) => {
    const userId = (user as any).id || user._id;
    if (!selectedUsers.find(u => ((u as any).id || u._id) === userId)) {
      onChange([...selectedUsers, user]);
    }
    setQuery('');
    setOpen(false);
  };

  const handleRemove = (id: string) => {
    onChange(selectedUsers.filter(u => ((u as any).id || u._id) !== id));
  };

  return (
    <div className="relative mt-2" ref={wrapperRef}>
      <div className="flex flex-wrap gap-2 mb-3">
        {selectedUsers.map(u => {
          const id = (u as any).id || u._id;
          return (
            <div key={id} className="flex items-center gap-1 bg-indigo-50 border border-indigo-100 text-indigo-700 px-3 py-1.5 rounded-lg text-sm font-medium shadow-sm transition-all hover:shadow">
              <UserIcon className="w-3 h-3 opacity-70" />
              <span>{u.username}</span>
              <button type="button" onClick={() => handleRemove(id)} className="ml-1 hover:text-red-500 cursor-pointer transition-colors">
                <X className="w-4 h-4" />
              </button>
            </div>
          );
        })}
      </div>
      <div className="relative group">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 group-focus-within:text-indigo-500 transition-colors" />
        <input
          type="text"
          placeholder="Tìm kiếm theo Tên hoặc Username..."
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          className="w-full pl-10 rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-sm transition-all focus:border-indigo-500 focus:bg-white focus:outline-none focus:ring-4 focus:ring-indigo-500/10"
        />
      </div>
      
      {open && query.trim() && (
        <div className="absolute z-10 w-full mt-2 bg-white border border-slate-200 rounded-xl shadow-2xl max-h-60 overflow-y-auto animate-in fade-in slide-in-from-top-2">
          {loading ? (
            <div className="p-4 text-center text-sm text-slate-500 font-medium">Đang tìm kiếm...</div>
          ) : results.length > 0 ? (
            results.map(u => {
              const id = (u as any).id || u._id;
              const name = u.name || (u as any).full_name;
              return (
                <div 
                  key={id} 
                  onClick={() => handleSelect(u)}
                  className="flex items-center gap-3 p-3 hover:bg-indigo-50 cursor-pointer border-b border-slate-100 last:border-0 transition-colors"
                >
                  <div className="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-100 to-indigo-50 flex items-center justify-center text-indigo-600 font-bold text-sm shadow-sm">
                    {u.username.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <div className="text-sm font-semibold text-slate-800">{name}</div>
                    <div className="text-xs text-slate-500 font-medium">@{u.username}</div>
                  </div>
                </div>
              );
            })
          ) : (
            <div className="p-4 text-center text-sm text-slate-500 font-medium">Không tìm thấy học viên nào</div>
          )}
        </div>
      )}
    </div>
  );
}

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
  const [targetAudience, setTargetAudience] = useState<'all' | 'specific'>('all');
  const [selectedUsers, setSelectedUsers] = useState<User[]>([]);
  
  const [submitLoading, setSubmitLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  
  const [showConfirm, setShowConfirm] = useState(false);

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

  const handlePreSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !message.trim()) return;
    if (targetAudience === 'specific' && selectedUsers.length === 0) {
      setErrorMessage('Vui lòng tìm và chọn ít nhất 1 học viên.');
      setSuccessMessage(null);
      return;
    }
    setErrorMessage(null);
    setShowConfirm(true);
  };

  const handleConfirmSubmit = async () => {
    setShowConfirm(false);
    setSubmitLoading(true);
    setSuccessMessage(null);
    setErrorMessage(null);

    const payload: SendNotificationRequest = {
      title: title.trim(),
      message: message.trim(),
      type,
      targetAudience,
      targetUsers: targetAudience === 'specific' ? selectedUsers.map(u => (u as any).id || u._id) : undefined,
    };

    try {
      await notificationsApi.send(payload);
      setSuccessMessage(`Đã gửi thông báo thành công tới ${targetAudience === 'all' ? 'tất cả học viên' : `${selectedUsers.length} học viên`}!`);
      setTitle('');
      setMessage('');
      setSelectedUsers([]);
      setTargetAudience('all');
      setPage(1);
      fetchHistory();
    } catch (err) {
      setErrorMessage('Gửi thông báo thất bại. Vui lòng thử lại.');
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
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-50 text-indigo-600 shadow-sm">
            <Bell className="h-4 w-4" />
          </div>
          <div>
            <p className="font-semibold text-slate-800">{n.title}</p>
            <p className="text-xs text-slate-500 line-clamp-1" title={n.message}>{n.message}</p>
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
      key: 'targetAudience',
      header: 'Đối tượng nhận',
      render: (n) => (
        <span className={`text-xs font-bold px-2.5 py-1 rounded-md ${n.targetAudience === 'specific' ? 'bg-amber-100 text-amber-700' : 'bg-slate-100 text-slate-600'}`}>
          {n.targetAudience === 'specific' ? 'Nhóm cụ thể' : 'Tất cả'}
        </span>
      ),
    },
    {
      key: 'createdAt',
      header: 'Thời gian gửi',
      render: (n) => (
        <span className="text-xs font-medium text-slate-500">
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
          <div className="p-2 bg-indigo-50 rounded-lg">
            <Send className="h-5 w-5 text-indigo-600" />
          </div>
          <h2 className="text-lg font-bold text-slate-800">Soạn thông báo mới</h2>
        </div>

        <form onSubmit={handlePreSubmit} className="space-y-6">
          {successMessage && (
            <div className="rounded-xl bg-emerald-50 border border-emerald-100 p-4 text-sm text-emerald-700 font-medium flex items-center gap-3">
              <span className="text-lg">✨</span> {successMessage}
            </div>
          )}
          {errorMessage && (
            <div className="rounded-xl bg-red-50 border border-red-100 p-4 text-sm text-red-700 font-medium flex items-center gap-3">
              <span className="text-lg">❌</span> {errorMessage}
            </div>
          )}

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
            <div>
              <label className="block text-xs font-bold uppercase text-slate-500 tracking-wider mb-2">Tiêu đề</label>
              <input
                type="text"
                required
                placeholder="Nhập tiêu đề thông báo (ví dụ: Bảo trì hệ thống)..."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-sm transition-all focus:border-indigo-500 focus:bg-white focus:outline-none focus:ring-4 focus:ring-indigo-500/10"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase text-slate-500 tracking-wider mb-2">Loại thông báo</label>
              <select
                value={type}
                onChange={(e) => setType(e.target.value as any)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-sm transition-all focus:border-indigo-500 focus:bg-white focus:outline-none focus:ring-4 focus:ring-indigo-500/10"
              >
                <option value="info">Thông tin (Info)</option>
                <option value="success">Thành công (Success)</option>
                <option value="warning">Cảnh báo (Warning)</option>
                <option value="error">Khẩn cấp/Lỗi (Error)</option>
              </select>
            </div>
          </div>
          
          <div className="bg-slate-50/50 p-5 rounded-xl border border-slate-100">
            <label className="block text-xs font-bold uppercase text-slate-500 tracking-wider mb-3">Đối tượng nhận thông báo</label>
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
              <label className="flex items-center gap-3 cursor-pointer group">
                <input 
                  type="radio" 
                  name="audience" 
                  checked={targetAudience === 'all'} 
                  onChange={() => setTargetAudience('all')}
                  className="w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500"
                />
                <div className="flex items-center gap-1.5 text-sm font-semibold text-slate-700 group-hover:text-indigo-600 transition-colors">
                  <Users className="w-4 h-4" /> Tất cả học viên
                </div>
              </label>
              <label className="flex items-center gap-3 cursor-pointer group">
                <input 
                  type="radio" 
                  name="audience" 
                  checked={targetAudience === 'specific'} 
                  onChange={() => setTargetAudience('specific')}
                  className="w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500"
                />
                <div className="flex items-center gap-1.5 text-sm font-semibold text-slate-700 group-hover:text-indigo-600 transition-colors">
                  <UserIcon className="w-4 h-4" /> Học viên cụ thể
                </div>
              </label>
            </div>

            {targetAudience === 'specific' && (
              <div className="mt-4 pt-4 border-t border-slate-200/60 animate-in fade-in slide-in-from-top-2">
                <label className="block text-xs font-bold text-slate-500 mb-1">Tìm và chọn học viên</label>
                <UserSearchSelect selectedUsers={selectedUsers} onChange={setSelectedUsers} />
              </div>
            )}
          </div>

          <div>
            <label className="block text-xs font-bold uppercase text-slate-500 tracking-wider mb-2">Nội dung thông điệp</label>
            <textarea
              required
              rows={4}
              placeholder="Nhập nội dung thông điệp chi tiết muốn gửi tới sinh viên..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3 text-sm transition-all focus:border-indigo-500 focus:bg-white focus:outline-none focus:ring-4 focus:ring-indigo-500/10"
            />
          </div>

          <div className="flex justify-end pt-2">
            <button
              type="submit"
              disabled={submitLoading || !title.trim() || !message.trim()}
              className="flex items-center gap-2 rounded-xl bg-indigo-600 px-6 py-3 font-bold text-white transition-all hover:bg-indigo-700 disabled:bg-slate-300 disabled:text-slate-500 disabled:cursor-not-allowed cursor-pointer hover:shadow-lg hover:shadow-indigo-500/30 active:scale-95 duration-200"
            >
              <Send className="h-4 w-4" />
              <span>{submitLoading ? 'Đang gửi...' : 'Gửi thông báo'}</span>
            </button>
          </div>
        </form>
      </div>

      {/* History log */}
      <div className="space-y-6">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-slate-100 rounded-lg">
            <History className="h-5 w-5 text-slate-600" />
          </div>
          <h2 className="text-lg font-bold text-slate-800">Lịch sử gửi thông báo</h2>
        </div>

        <div className="shadow-xl shadow-slate-200/40 rounded-2xl overflow-hidden border border-slate-200/60 bg-white">
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

      <ConfirmModal
        open={showConfirm}
        title="Xác nhận gửi thông báo"
        message={
          <div className="space-y-2">
            <p>Bạn có chắc chắn muốn phát sóng thông báo này không?</p>
            <div className="p-3 bg-slate-50 rounded-lg text-left text-sm mt-3 border border-slate-100">
              <div className="font-semibold text-slate-700">{title}</div>
              <div className="text-slate-500 line-clamp-2 mt-1">{message}</div>
              <div className="mt-2 pt-2 border-t border-slate-200 text-indigo-600 font-medium">
                👉 Gửi tới: {targetAudience === 'all' ? 'Tất cả hệ thống' : `${selectedUsers.length} học viên`}
              </div>
            </div>
          </div>
        }
        confirmLabel="Vâng, Gửi ngay"
        cancelLabel="Hủy bỏ"
        variant="info"
        onConfirm={handleConfirmSubmit}
        onCancel={() => setShowConfirm(false)}
      />
    </div>
  );
}
