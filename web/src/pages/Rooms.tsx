import { useEffect, useState } from 'react';
import { roomsApi } from '../api/rooms.api';
import type { Room } from '../types';
import PageHeader from '../components/ui/PageHeader';
import DataTable, { type Column } from '../components/ui/DataTable';
import SearchInput from '../components/ui/SearchInput';
import Pagination from '../components/ui/Pagination';
import StatusBadge from '../components/ui/StatusBadge';
import ConfirmModal from '../components/ui/ConfirmModal';
import { Trash2, DoorOpen, Users as UsersIcon } from 'lucide-react';

export default function Rooms() {
  const [rooms, setRooms] = useState<Room[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [search, setSearch] = useState('');

  // Modals state
  const [selectedRoom, setSelectedRoom] = useState<Room | null>(null);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [reason, setReason] = useState('');

  const fetchRooms = async () => {
    setLoading(true);
    try {
      const res = await roomsApi.getAll({ page, limit, search });
      setRooms(res.data);
      setTotal(res.total);
    } catch (err) {
      console.error('Không thể lấy danh sách phòng học:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRooms();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, search]);

  const handleDelete = async () => {
    if (!selectedRoom) return;
    setActionLoading(true);
    try {
      await roomsApi.delete(selectedRoom._id, reason);
      setDeleteModalOpen(false);
      setReason('');
      fetchRooms();
    } catch (err) {
      console.error('Xóa phòng học thất bại:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<Room>[] = [
    {
      key: 'name',
      header: 'Tên phòng học',
      render: (r) => (
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50 text-purple-600 border border-purple-100/50">
            <DoorOpen className="h-5 w-5" />
          </div>
          <div className="max-w-xs">
            <p className="font-semibold text-slate-800 truncate">{r.name}</p>
            <p className="text-xs text-slate-500 truncate">{r.description || 'Không có mô tả'}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'creator',
      header: 'Trưởng phòng',
      render: (r) => (
        <div className="flex items-center gap-2.5">
          <div className="h-7 w-7 overflow-hidden rounded-full bg-gradient-to-br from-indigo-500 to-purple-600">
            {r.creator.avatar ? (
              <img src={r.creator.avatar} alt="" className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-[10px] font-bold text-white">
                {r.creator.name?.charAt(0).toUpperCase()}
              </div>
            )}
          </div>
          <div>
            <p className="text-sm font-medium text-slate-700">{r.creator.name}</p>
            <p className="text-[10px] text-slate-400">{r.creator.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'members',
      header: 'Thành viên',
      render: (r) => (
        <div className="flex items-center gap-1.5 text-slate-600 text-sm">
          <UsersIcon className="h-4 w-4 text-slate-400" />
          <span className="font-medium">{(r.members || []).length} người</span>
        </div>
      ),
    },
    {
      key: 'privacy',
      header: 'Loại phòng',
      render: (r) => (
        <StatusBadge
          status={r.isPrivate ? 'banned' : 'active'}
          label={r.isPrivate ? 'Riêng tư' : 'Công khai'}
        />
      ),
    },
    {
      key: 'createdAt',
      header: 'Ngày tạo',
      render: (r) => (
        <span className="text-xs text-slate-500">
          {new Date(r.createdAt).toLocaleDateString('vi-VN')}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Gỡ phòng',
      className: 'text-right',
      render: (r) => (
        <div className="flex justify-end">
          <button
            onClick={() => {
              setSelectedRoom(r);
              setReason('');
              setDeleteModalOpen(true);
            }}
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-red-200/60 bg-red-50/50 text-red-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-red-100 hover:border-red-300 hover:shadow-sm cursor-pointer"
            title="Giải tán phòng học"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
        <PageHeader title="Quản lý phòng học" description="Giám sát danh sách các phòng học nhóm trực tuyến của học viên" />
        <div className="w-full md:w-80">
          <SearchInput
            placeholder="Tìm theo tên phòng học..."
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
          data={rooms}
          keyExtractor={(r) => r._id}
          isLoading={loading}
          emptyMessage="Không tìm thấy phòng học nào."
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

      {/* Delete Confirm Modal */}
      <ConfirmModal
        open={deleteModalOpen}
        onCancel={() => setDeleteModalOpen(false)}
        onConfirm={handleDelete}
        title="Giải tán phòng học"
        message={
          <div className="space-y-4 text-left">
            <p className="text-slate-600">Bạn có chắc chắn muốn GIẢI TÁN phòng học "{selectedRoom?.name}"? Mọi tin nhắn nhóm và danh sách thành viên sẽ bị xóa vĩnh viễn khỏi database.</p>
            <div className="bg-red-50/50 p-4 rounded-xl border border-red-100">
              <label className="block text-xs font-bold uppercase tracking-wider text-red-800 mb-2">Lý do giải tán (Tùy chọn)</label>
              <textarea 
                rows={2} 
                value={reason} 
                onChange={(e) => setReason(e.target.value)} 
                placeholder="VD: Phòng học không hoạt động, vi phạm quy định..."
                className="w-full rounded-xl border border-red-200 bg-white p-3 text-sm focus:border-red-500 focus:outline-none focus:ring-4 focus:ring-red-500/10 transition-all text-slate-700"
              />
              <p className="text-[11px] text-red-600/80 mt-1.5 font-medium">* Trưởng phòng và các thành viên đang tham gia sẽ nhận được thông báo này ngay lập tức</p>
            </div>
          </div>
        }
        confirmLabel="Giải tán phòng"
        variant="danger"
        loading={actionLoading}
      />
    </div>
  );
}
