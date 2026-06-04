import { useEffect, useState } from 'react';
import { postsApi } from '../api/posts.api';
import type { Post } from '../types';
import PageHeader from '../components/ui/PageHeader';
import DataTable, { type Column } from '../components/ui/DataTable';
import SearchInput from '../components/ui/SearchInput';
import Pagination from '../components/ui/Pagination';
import StatusBadge from '../components/ui/StatusBadge';
import ConfirmModal from '../components/ui/ConfirmModal';
import { Eye, EyeOff, Trash2 } from 'lucide-react';

export default function Posts() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [search, setSearch] = useState('');

  // Modals state
  const [selectedPost, setSelectedPost] = useState<Post | null>(null);
  const [hideModalOpen, setHideModalOpen] = useState(false);
  const [unhideModalOpen, setUnhideModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [reason, setReason] = useState('');

  const fetchPosts = async () => {
    setLoading(true);
    try {
      const res = await postsApi.getAll({ page, limit, search });
      setPosts(res.data);
      setTotal(res.total);
    } catch (err) {
      console.error('Không thể lấy danh sách bài viết:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPosts();
  }, [page, search]);

  const handleHide = async () => {
    if (!selectedPost) return;
    setActionLoading(true);
    try {
      await postsApi.hide(selectedPost._id, reason);
      setHideModalOpen(false);
      setReason('');
      fetchPosts();
    } catch (err) {
      console.error('Ẩn bài viết thất bại:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleUnhide = async () => {
    if (!selectedPost) return;
    setActionLoading(true);
    try {
      await postsApi.unhide(selectedPost._id);
      setUnhideModalOpen(false);
      fetchPosts();
    } catch (err) {
      console.error('Hiện bài viết thất bại:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedPost) return;
    setActionLoading(true);
    try {
      await postsApi.delete(selectedPost._id, reason);
      setDeleteModalOpen(false);
      setReason('');
      fetchPosts();
    } catch (err) {
      console.error('Xóa bài viết thất bại:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<Post>[] = [
    {
      key: 'author',
      header: 'Tác giả',
      render: (p) => (
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 overflow-hidden rounded-full bg-gradient-to-br from-indigo-500 to-purple-600">
            {p.author.avatar ? (
              <img src={p.author.avatar} alt="" className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-xs font-bold text-white">
                {p.author.name?.charAt(0).toUpperCase()}
              </div>
            )}
          </div>
          <div>
            <p className="font-semibold text-slate-800">{p.author.name}</p>
            <p className="text-xs text-slate-500">{p.author.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'content',
      header: 'Nội dung bài viết',
      render: (p) => (
        <div className="max-w-md">
          <p className="text-sm text-slate-700 line-clamp-2">{p.content || '(Bài viết không có nội dung văn bản)'}</p>
          {p.images && p.images.length > 0 && (
            <span className="mt-1 inline-flex items-center gap-1 rounded bg-slate-100 px-1.5 py-0.5 text-[10px] font-semibold text-slate-600">
              🖼️ {p.images.length} ảnh
            </span>
          )}
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Trạng thái hiển thị',
      render: (p) => (
        <StatusBadge
          status={p.isHidden ? 'banned' : 'active'}
          label={p.isHidden ? 'Đang ẩn' : 'Đang hiện'}
        />
      ),
    },
    {
      key: 'createdAt',
      header: 'Thời gian đăng',
      render: (p) => (
        <span className="text-xs text-slate-500">
          {new Date(p.createdAt).toLocaleString('vi-VN')}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Điều khiển',
      className: 'text-right',
      render: (p) => (
        <div className="flex justify-end gap-2.5">
          {p.isHidden ? (
            <button
              onClick={() => {
                setSelectedPost(p);
                setUnhideModalOpen(true);
              }}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-emerald-200/60 bg-emerald-50/50 text-emerald-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-emerald-100 hover:border-emerald-300 hover:shadow-sm cursor-pointer"
              title="Hiện bài viết trên Bảng tin"
            >
              <Eye className="h-4 w-4" />
            </button>
          ) : (
            <button
              onClick={() => {
                setSelectedPost(p);
                setReason('');
                setHideModalOpen(true);
              }}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-amber-200/60 bg-amber-50/50 text-amber-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-amber-100 hover:border-amber-300 hover:shadow-sm cursor-pointer"
              title="Ẩn bài viết khỏi Bảng tin"
            >
              <EyeOff className="h-4 w-4" />
            </button>
          )}
          <button
            onClick={() => {
              setSelectedPost(p);
              setReason('');
              setDeleteModalOpen(true);
            }}
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-red-200/60 bg-red-50/50 text-red-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-red-100 hover:border-red-300 hover:shadow-sm cursor-pointer"
            title="Xóa vĩnh viễn"
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
        <PageHeader title="Quản lý bài viết" description="Kiểm duyệt nội dung bài đăng của sinh viên trên bảng tin cộng đồng" />
        <div className="w-full md:w-80">
          <SearchInput
            placeholder="Tìm theo nội dung bài viết..."
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
          data={posts}
          keyExtractor={(p) => p._id}
          isLoading={loading}
          emptyMessage="Không tìm thấy bài viết nào."
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

      {/* Hide Confirm Modal */}
      <ConfirmModal
        open={hideModalOpen}
        onCancel={() => setHideModalOpen(false)}
        onConfirm={handleHide}
        title="Ẩn bài viết"
        message={
          <div className="space-y-4 text-left">
            <p className="text-slate-600">Bạn có chắc chắn muốn ẨN bài viết này? Bài viết sẽ bị ẩn khỏi bảng tin của sinh viên nhưng vẫn được lưu trữ trong quản trị.</p>
            <div className="bg-amber-50/50 p-4 rounded-xl border border-amber-100">
              <label className="block text-xs font-bold uppercase tracking-wider text-amber-800 mb-2">Lý do ẩn bài (Tùy chọn)</label>
              <textarea 
                rows={2} 
                value={reason} 
                onChange={(e) => setReason(e.target.value)} 
                placeholder="VD: Chứa nội dung không phù hợp..."
                className="w-full rounded-xl border border-amber-200 bg-white p-3 text-sm focus:border-amber-500 focus:outline-none focus:ring-4 focus:ring-amber-500/10 transition-all text-slate-700"
              />
              <p className="text-[11px] text-amber-600/80 mt-1.5 font-medium">* Lý do này sẽ được gửi thông báo đến người đăng bài</p>
            </div>
          </div>
        }
        confirmLabel="Ẩn bài đăng"
        variant="warning"
        loading={actionLoading}
      />

      {/* Unhide Confirm Modal */}
      <ConfirmModal
        open={unhideModalOpen}
        onCancel={() => setUnhideModalOpen(false)}
        onConfirm={handleUnhide}
        title="Hiển thị lại bài viết"
        message="Bạn có muốn công khai và hiển thị lại bài viết này trên bảng tin cộng đồng?"
        confirmLabel="Hiện bài đăng"
        variant="info"
        loading={actionLoading}
      />

      {/* Delete Confirm Modal */}
      <ConfirmModal
        open={deleteModalOpen}
        onCancel={() => setDeleteModalOpen(false)}
        onConfirm={handleDelete}
        title="Xóa vĩnh viễn"
        message={
          <div className="space-y-4 text-left">
            <p className="text-slate-600">Bạn có chắc chắn muốn XÓA VĨNH VIỄN bài đăng này? Hành động này sẽ xóa hoàn toàn hình ảnh, bình luận, lượt thích liên quan và KHÔNG THỂ khôi phục.</p>
            <div className="bg-red-50/50 p-4 rounded-xl border border-red-100">
              <label className="block text-xs font-bold uppercase tracking-wider text-red-800 mb-2">Lý do XÓA bài (Tùy chọn)</label>
              <textarea 
                rows={2} 
                value={reason} 
                onChange={(e) => setReason(e.target.value)} 
                placeholder="VD: Vi phạm nghiêm trọng tiêu chuẩn cộng đồng..."
                className="w-full rounded-xl border border-red-200 bg-white p-3 text-sm focus:border-red-500 focus:outline-none focus:ring-4 focus:ring-red-500/10 transition-all text-slate-700"
              />
              <p className="text-[11px] text-red-600/80 mt-1.5 font-medium">* Lý do này sẽ được gửi thông báo đến người đăng bài</p>
            </div>
          </div>
        }
        confirmLabel="Xóa vĩnh viễn"
        variant="danger"
        loading={actionLoading}
      />
    </div>
  );
}
