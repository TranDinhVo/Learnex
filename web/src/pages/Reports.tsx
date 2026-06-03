import { useEffect, useState, useCallback } from 'react';
import { reportsApi } from '../api/reports.api';
import type { Report } from '../types';
import PageHeader from '../components/ui/PageHeader';
import DataTable, { type Column } from '../components/ui/DataTable';
import Pagination from '../components/ui/Pagination';
import StatusBadge from '../components/ui/StatusBadge';
import ConfirmModal from '../components/ui/ConfirmModal';
import { CheckCircle, XCircle } from 'lucide-react';

export default function Reports() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);

  // Modals state
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [resolveModalOpen, setResolveModalOpen] = useState(false);
  const [dismissModalOpen, setDismissModalOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchReports = useCallback(async () => {
    setLoading(true);
    try {
      const res = await reportsApi.getAll({ page, limit });
      setReports(res.data);
      setTotal(res.total);
    } catch (err) {
      console.error('Không thể lấy danh sách báo cáo:', err);
    } finally {
      setLoading(false);
    }
  }, [page, limit]);

  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  const handleResolve = async () => {
    if (!selectedReport) return;
    setActionLoading(true);
    try {
      await reportsApi.updateStatus(selectedReport._id, 'resolved');
      setResolveModalOpen(false);
      fetchReports();
    } catch (err) {
      console.error('Lỗi khi giải quyết báo cáo', err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDismiss = async () => {
    if (!selectedReport) return;
    setActionLoading(true);
    try {
      await reportsApi.updateStatus(selectedReport._id, 'dismissed');
      setDismissModalOpen(false);
      fetchReports();
    } catch (err) {
      console.error('Lỗi khi bỏ qua báo cáo', err);
    } finally {
      setActionLoading(false);
    }
  };

  const getTargetTypeLabel = (type: string) => {
    switch (type) {
      case 'user': return 'Người dùng';
      case 'post': return 'Bài viết';
      case 'comment': return 'Bình luận';
      case 'room': return 'Phòng học';
      default: return type;
    }
  };

  const columns: Column<Report>[] = [
    {
      key: 'reporter',
      header: 'Người báo cáo',
      render: (r) => (
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 overflow-hidden rounded-full bg-slate-200">
            {r.reporter.avatar ? (
              <img src={r.reporter.avatar} alt="" className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-xs font-bold text-slate-500">
                {r.reporter.name?.charAt(0).toUpperCase()}
              </div>
            )}
          </div>
          <div>
            <p className="font-semibold text-slate-800">{r.reporter.name}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'target',
      header: 'Đối tượng vi phạm',
      render: (r) => {
        const targetName = (r.targetInfo?.name as string) || (r.targetInfo?.content as string) || r.targetId;
        return (
          <div>
            <span className="inline-block px-2 py-1 text-xs font-medium bg-indigo-50 text-indigo-700 rounded mb-1">
              {getTargetTypeLabel(r.targetType)}
            </span>
            <p className="text-sm text-slate-600 truncate max-w-[200px]" title={targetName}>
              {targetName}
            </p>
          </div>
        );
      },
    },
    {
      key: 'reason',
      header: 'Lý do báo cáo',
      render: (r) => <p className="text-sm text-slate-700 max-w-[250px] line-clamp-2">{r.reason}</p>,
    },
    {
      key: 'status',
      header: 'Trạng thái',
      render: (r) => {
        let statusColor: 'pending' | 'active' | 'banned' | 'inactive' = 'pending';
        let statusLabel = 'Chờ xử lý';
        if (r.status === 'resolved') {
          statusColor = 'active';
          statusLabel = 'Đã giải quyết';
        } else if (r.status === 'dismissed') {
          statusColor = 'banned';
          statusLabel = 'Đã bỏ qua';
        }
        return <StatusBadge status={statusColor} label={statusLabel} />;
      },
    },
    {
      key: 'createdAt',
      header: 'Thời gian',
      render: (r) => <span className="text-sm text-slate-500">{new Date(r.createdAt).toLocaleString('vi-VN')}</span>,
    },
    {
      key: 'actions',
      header: 'Hành động',
      className: 'text-right',
      render: (r) => {
        if (r.status !== 'pending') return <span className="text-xs text-gray-500">-</span>;
        return (
          <div className="flex justify-end gap-2">
            <button
              onClick={() => {
                setSelectedReport(r);
                setResolveModalOpen(true);
              }}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-emerald-200/60 bg-emerald-50/50 text-emerald-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-emerald-100 cursor-pointer"
              title="Đánh dấu đã giải quyết"
            >
              <CheckCircle className="h-4 w-4" />
            </button>
            <button
              onClick={() => {
                setSelectedReport(r);
                setDismissModalOpen(true);
              }}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200/60 bg-slate-50/50 text-slate-600 transition-all duration-300 hover:scale-110 active:scale-95 hover:bg-slate-100 cursor-pointer"
              title="Bỏ qua báo cáo"
            >
              <XCircle className="h-4 w-4" />
            </button>
          </div>
        );
      },
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Báo cáo vi phạm" 
        description="Xem và xử lý các báo cáo về người dùng, bài viết, hoặc phòng học có nội dung không phù hợp." 
      />

      <div className="shadow-xl shadow-slate-200/40 rounded-2xl overflow-hidden border border-slate-200/60 bg-white">
        <DataTable
          columns={columns}
          data={reports}
          keyExtractor={(r) => r._id}
          isLoading={loading}
          emptyMessage="Không có báo cáo vi phạm nào."
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

      <ConfirmModal
        open={resolveModalOpen}
        onCancel={() => setResolveModalOpen(false)}
        onConfirm={handleResolve}
        title="Đánh dấu đã giải quyết"
        message={`Bạn có chắc chắn đã xử lý xong vi phạm này và muốn đóng báo cáo?`}
        confirmLabel="Đã giải quyết"
        variant="info"
        loading={actionLoading}
      />

      <ConfirmModal
        open={dismissModalOpen}
        onCancel={() => setDismissModalOpen(false)}
        onConfirm={handleDismiss}
        title="Bỏ qua báo cáo"
        message={`Bạn có chắc chắn báo cáo này không hợp lệ và muốn bỏ qua?`}
        confirmLabel="Bỏ qua"
        variant="danger"
        loading={actionLoading}
      />
    </div>
  );
}
