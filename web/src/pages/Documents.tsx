import { useEffect, useState } from 'react';
import { documentsApi } from '../api/documents.api';
import type { Document } from '../types';
import PageHeader from '../components/ui/PageHeader';
import DataTable, { type Column } from '../components/ui/DataTable';
import SearchInput from '../components/ui/SearchInput';
import Pagination from '../components/ui/Pagination';
import StatusBadge from '../components/ui/StatusBadge';
import ConfirmModal from '../components/ui/ConfirmModal';
import { Check, X, Trash2, FileText, Download } from 'lucide-react';

export default function Documents() {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [search, setSearch] = useState('');

  // Modals state
  const [selectedDoc, setSelectedDoc] = useState<Document | null>(null);
  const [approveModalOpen, setApproveModalOpen] = useState(false);
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [reason, setReason] = useState('');

  const fetchDocuments = async () => {
    setLoading(true);
    try {
      const res = await documentsApi.getAll({ page, limit, search });
      setDocuments(res.data);
      setTotal(res.total);
    } catch (err) {
      console.error('Không thể lấy danh sách tài liệu:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDocuments();
  }, [page, search]);

  const handleApprove = async () => {
    if (!selectedDoc) return;
    setActionLoading(true);
    try {
      await documentsApi.approve(selectedDoc._id);
      setApproveModalOpen(false);
      fetchDocuments();
    } catch (err) {
      console.error('Duyệt tài liệu thất bại:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!selectedDoc) return;
    setActionLoading(true);
    try {
      await documentsApi.reject(selectedDoc._id, reason);
      setRejectModalOpen(false);
      setReason('');
      fetchDocuments();
    } catch (err) {
      console.error('Từ chối tài liệu thất bại:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedDoc) return;
    setActionLoading(true);
    try {
      await documentsApi.delete(selectedDoc._id, reason);
      setDeleteModalOpen(false);
      setReason('');
      fetchDocuments();
    } catch (err) {
      console.error('Xóa tài liệu thất bại:', err);
    } finally {
      setActionLoading(false);
    }
  };

  const columns: Column<Document>[] = [
    {
      key: 'title',
      header: 'Tài liệu',
      render: (d) => (
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600 border border-indigo-100/50">
            <FileText className="h-5 w-5" />
          </div>
          <div className="max-w-xs">
            <p className="font-semibold text-slate-800 truncate">{d.title}</p>
            <p className="text-xs text-slate-500 truncate">{d.description || 'Không có mô tả'}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'uploadedBy',
      header: 'Người đăng',
      render: (d) => (
        <div className="flex items-center gap-2.5">
          <div className="h-7 w-7 overflow-hidden rounded-full bg-gradient-to-br from-indigo-500 to-purple-600">
            {d.uploadedBy.avatar ? (
              <img src={d.uploadedBy.avatar} alt="" className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-[10px] font-bold text-white">
                {d.uploadedBy.name?.charAt(0).toUpperCase()}
              </div>
            )}
          </div>
          <span className="text-sm font-medium text-slate-700">{d.uploadedBy.name}</span>
        </div>
      ),
    },
    {
      key: 'fileType',
      header: 'Định dạng',
      render: (d) => (
        <span className="inline-flex items-center rounded-md bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-600 uppercase">
          {d.fileType}
        </span>
      ),
    },
    {
      key: 'downloads',
      header: 'Tải xuống',
      render: (d) => (
        <div className="flex items-center gap-1 text-slate-600 text-sm">
          <Download className="h-3.5 w-3.5" />
          <span>{d.downloads} lượt</span>
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Trạng thái kiểm duyệt',
      render: (d) => {
        let badgeStatus: 'active' | 'pending' | 'banned' = 'pending';
        let badgeLabel = 'Đang chờ duyệt';
        
        if (d.status === 'approved') {
          badgeStatus = 'active';
          badgeLabel = 'Đã duyệt';
        } else if (d.status === 'rejected') {
          badgeStatus = 'banned';
          badgeLabel = 'Bị từ chối';
        }
        
        return <StatusBadge status={badgeStatus} label={badgeLabel} />;
      },
    },
    {
      key: 'actions',
      header: 'Hành động',
      className: 'text-right',
      render: (d) => (
        <div className="flex justify-end gap-2.5">
          {d.status !== 'approved' && (
            <button
              onClick={() => {
                setSelectedDoc(d);
                setApproveModalOpen(true);
              }}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-emerald-200/60 bg-emerald-50/50 text-emerald-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-emerald-100 hover:border-emerald-300 hover:shadow-sm cursor-pointer"
              title="Duyệt tài liệu"
            >
              <Check className="h-4 w-4" />
            </button>
          )}
          {d.status !== 'rejected' && (
            <button
              onClick={() => {
                setSelectedDoc(d);
                setReason('');
                setRejectModalOpen(true);
              }}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-amber-200/60 bg-amber-50/50 text-amber-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-amber-100 hover:border-amber-300 hover:shadow-sm cursor-pointer"
              title="Từ chối tài liệu"
            >
              <X className="h-4 w-4" />
            </button>
          )}
          <button
            onClick={() => {
              setSelectedDoc(d);
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
        <PageHeader title="Quản lý tài liệu" description="Phê duyệt hoặc từ chối giáo trình học tập do sinh viên đăng tải" />
        <div className="w-full md:w-80">
          <SearchInput
            placeholder="Tìm theo tiêu đề tài liệu..."
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
          data={documents}
          keyExtractor={(d) => d._id}
          isLoading={loading}
          emptyMessage="Không tìm thấy tài liệu nào."
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

      {/* Approve Confirm Modal */}
      <ConfirmModal
        open={approveModalOpen}
        onCancel={() => setApproveModalOpen(false)}
        onConfirm={handleApprove}
        title="Phê duyệt tài liệu"
        message={`Bạn có chắc chắn muốn PHÊ DUYỆT tài liệu "${selectedDoc?.title}"? Tài liệu sẽ hiển thị công khai để tất cả sinh viên tải xuống.`}
        confirmLabel="Phê duyệt"
        variant="info"
        loading={actionLoading}
      />

      {/* Reject Confirm Modal */}
      <ConfirmModal
        open={rejectModalOpen}
        onCancel={() => setRejectModalOpen(false)}
        onConfirm={handleReject}
        title="Từ chối tài liệu"
        message={
          <div className="space-y-4 text-left">
            <p className="text-slate-600">Bạn có muốn TỪ CHỐI tài liệu "{selectedDoc?.title}"? Tài liệu này sẽ bị chuyển trạng thái bị loại và không xuất hiện trên kho chung.</p>
            <div className="bg-amber-50/50 p-4 rounded-xl border border-amber-100">
              <label className="block text-xs font-bold uppercase tracking-wider text-amber-800 mb-2">Lý do từ chối (Tùy chọn)</label>
              <textarea 
                rows={2} 
                value={reason} 
                onChange={(e) => setReason(e.target.value)} 
                placeholder="VD: Nội dung mờ, không đạt yêu cầu..."
                className="w-full rounded-xl border border-amber-200 bg-white p-3 text-sm focus:border-amber-500 focus:outline-none focus:ring-4 focus:ring-amber-500/10 transition-all text-slate-700"
              />
              <p className="text-[11px] text-amber-600/80 mt-1.5 font-medium">* Lý do này sẽ được gửi thông báo đến người đăng</p>
            </div>
          </div>
        }
        confirmLabel="Từ chối"
        variant="warning"
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
            <p className="text-slate-600">Bạn có chắc muốn XÓA VĨNH VIỄN tài liệu "{selectedDoc?.title}"? Hành động này sẽ gỡ tệp khỏi hệ thống lưu trữ Cloudinary và cơ sở dữ liệu.</p>
            <div className="bg-red-50/50 p-4 rounded-xl border border-red-100">
              <label className="block text-xs font-bold uppercase tracking-wider text-red-800 mb-2">Lý do XÓA tài liệu (Tùy chọn)</label>
              <textarea 
                rows={2} 
                value={reason} 
                onChange={(e) => setReason(e.target.value)} 
                placeholder="VD: Vi phạm bản quyền..."
                className="w-full rounded-xl border border-red-200 bg-white p-3 text-sm focus:border-red-500 focus:outline-none focus:ring-4 focus:ring-red-500/10 transition-all text-slate-700"
              />
              <p className="text-[11px] text-red-600/80 mt-1.5 font-medium">* Lý do này sẽ được gửi thông báo đến người đăng</p>
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
