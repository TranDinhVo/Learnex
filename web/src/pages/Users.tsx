import { useEffect, useState } from 'react';
import { usersApi } from '../api/users.api';
import type { User } from '../types';
import PageHeader from '../components/ui/PageHeader';
import DataTable, { type Column } from '../components/ui/DataTable';
import SearchInput from '../components/ui/SearchInput';
import Pagination from '../components/ui/Pagination';
import StatusBadge from '../components/ui/StatusBadge';
import ConfirmModal from '../components/ui/ConfirmModal';
import { Shield, ShieldAlert, Trash2 } from 'lucide-react';

export default function Users() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [search, setSearch] = useState('');

  // Modals state
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [banModalOpen, setBanModalOpen] = useState(false);
  const [unbanModalOpen, setUnbanModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const res = await usersApi.getAll({ page, limit, search });
      setUsers(res.data);
      setTotal(res.total);
    } catch (err) {
      console.error('Không thể lấy danh sách người dùng:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, search]);

  const handleBan = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await usersApi.ban(selectedUser._id);
      setBanModalOpen(false);
      fetchUsers();
    } catch (err) {
      console.error('Banned error', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleUnban = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await usersApi.unban(selectedUser._id);
      setUnbanModalOpen(false);
      fetchUsers();
    } catch (err) {
      console.error('Unbanned error', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await usersApi.delete(selectedUser._id);
      setDeleteModalOpen(false);
      fetchUsers();
    } catch (err) {
      console.error('Delete error', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<User>[] = [
    {
      key: 'avatar',
      header: 'Thành viên',
      render: (u) => (
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 overflow-hidden rounded-full bg-gradient-to-br from-indigo-500 to-purple-600">
            {u.avatar ? (
              <img src={u.avatar} alt="" className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-xs font-bold text-white">
                {u.name?.charAt(0).toUpperCase()}
              </div>
            )}
          </div>
          <div>
            <p className="font-semibold text-slate-800">{u.name}</p>
            <p className="text-xs text-slate-500">{u.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'username',
      header: 'Tên đăng nhập',
      render: (u) => <span className="text-slate-500">@{u.username}</span>,
    },
    {
      key: 'role',
      header: 'Vai trò',
      render: (u) => (
        <StatusBadge
          status={u.role}
        />
      ),
    },
    {
      key: 'isBanned',
      header: 'Trạng thái',
      render: (u) => (
        <StatusBadge
          status={u.isBanned ? 'banned' : 'active'}
          label={u.isBanned ? 'Bị khóa' : 'Đang hoạt động'}
        />
      ),
    },
    {
      key: 'actions',
      header: 'Hành động',
      className: 'text-right',
      render: (u) => {
        if (u.role === 'admin') return <span className="text-xs text-gray-600">-</span>;
        return (
          <div className="flex justify-end gap-2.5">
            {u.isBanned ? (
              <button
                onClick={() => {
                  setSelectedUser(u);
                  setUnbanModalOpen(true);
                }}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-emerald-200/60 bg-emerald-50/50 text-emerald-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-emerald-100 hover:border-emerald-300 hover:shadow-sm cursor-pointer"
                title="Mở khóa tài khoản"
              >
                <Shield className="h-4 w-4" />
              </button>
            ) : (
              <button
                onClick={() => {
                  setSelectedUser(u);
                  setBanModalOpen(true);
                }}
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-amber-200/60 bg-amber-50/50 text-amber-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-amber-100 hover:border-amber-300 hover:shadow-sm cursor-pointer"
                title="Khóa tài khoản"
              >
                <ShieldAlert className="h-4 w-4" />
              </button>
            )}
            <button
              onClick={() => {
                setSelectedUser(u);
                setDeleteModalOpen(true);
              }}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-red-200/60 bg-red-50/50 text-red-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-red-100 hover:border-red-300 hover:shadow-sm cursor-pointer"
              title="Xóa vĩnh viễn"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        );
      },
    },
  ];

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
        <PageHeader title="Quản lý thành viên" description="Kiểm duyệt và khóa/mở khóa tài khoản sinh viên" />
        <div className="w-full md:w-80">
          <SearchInput
            placeholder="Tìm theo tên, email..."
            value={search}
            onChange={(val) => {
              setSearch(val);
              setPage(1);
            }}
          />
        </div>
      </div>

      <div className="shadow-xl shadow-slate-200/40 rounded-2xl overflow-hidden border border-slate-200/60">
        <DataTable
          columns={columns}
          data={users}
          keyExtractor={(u) => u._id}
          isLoading={loading}
          emptyMessage="Không tìm thấy người dùng nào."
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

      {/* Ban Confirm Modal */}
      <ConfirmModal
        open={banModalOpen}
        onCancel={() => setBanModalOpen(false)}
        onConfirm={handleBan}
        title="Khóa tài khoản"
        message={`Bạn có chắc muốn KHÓA tài khoản của ${selectedUser?.name}? Tài khoản này sẽ không thể đăng nhập hoặc tham gia phòng.`}
        confirmLabel="Khóa tài khoản"
        variant="danger"
        loading={actionLoading}
      />

      {/* Unban Confirm Modal */}
      <ConfirmModal
        open={unbanModalOpen}
        onCancel={() => setUnbanModalOpen(false)}
        onConfirm={handleUnban}
        title="Mở khóa tài khoản"
        message={`Bạn có chắc muốn MỞ KHÓA tài khoản của ${selectedUser?.name}?`}
        confirmLabel="Mở khóa"
        variant="info"
        loading={actionLoading}
      />

      {/* Delete Confirm Modal */}
      <ConfirmModal
        open={deleteModalOpen}
        onCancel={() => setDeleteModalOpen(false)}
        onConfirm={handleDelete}
        title="Xóa tài khoản"
        message={`Bạn có chắc muốn XÓA VĨNH VIỄN tài khoản của ${selectedUser?.name}? Hành động này KHÔNG THỂ khôi phục và sẽ xóa sạch mọi thông tin liên quan.`}
        confirmLabel="Xóa vĩnh viễn"
        variant="danger"
        loading={actionLoading}
      />
    </div>
  );
}
