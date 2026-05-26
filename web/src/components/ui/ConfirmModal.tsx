import { type ReactNode } from 'react';
import { AlertTriangle } from 'lucide-react';

interface ConfirmModalProps {
  open: boolean;
  title: string;
  message: string | ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'warning' | 'info';
  loading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function ConfirmModal({
  open,
  title,
  message,
  confirmLabel = 'Xác nhận',
  cancelLabel = 'Hủy',
  variant = 'danger',
  loading = false,
  onConfirm,
  onCancel,
}: ConfirmModalProps) {
  if (!open) return null;

  const variantColors = {
    danger: 'from-red-500 to-red-600 shadow-red-500/25',
    warning: 'from-amber-500 to-amber-600 shadow-amber-500/25',
    info: 'from-indigo-500 to-purple-600 shadow-indigo-500/25',
  };

  const iconColors = {
    danger: 'bg-red-500/15 text-red-400',
    warning: 'bg-amber-500/15 text-amber-400',
    info: 'bg-indigo-500/15 text-indigo-400',
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity duration-300"
        onClick={onCancel}
      />

      {/* Modal */}
      <div className="relative w-full max-w-md animate-modal-in rounded-2xl border border-slate-200/80 bg-white p-6 shadow-2xl">
        <div className="flex flex-col items-center text-center">
          <div
            className={`mb-4 flex h-14 w-14 items-center justify-center rounded-full ${iconColors[variant]}`}
          >
            <AlertTriangle className="h-7 w-7" />
          </div>

          <h3 className="mb-2 text-lg font-bold text-slate-800">{title}</h3>
          <div className="mb-6 text-sm font-medium text-slate-500">{message}</div>

          <div className="flex w-full gap-3">
            <button
              onClick={onCancel}
              disabled={loading}
              className="flex-1 rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm font-semibold text-slate-600 transition-all hover:bg-slate-100 disabled:opacity-50 cursor-pointer"
            >
              {cancelLabel}
            </button>
            <button
              onClick={onConfirm}
              disabled={loading}
              className={`flex-1 rounded-xl bg-gradient-to-r ${variantColors[variant]} px-4 py-2.5 text-sm font-medium text-white shadow-lg transition-all hover:opacity-90 disabled:opacity-50`}
            >
              {loading ? (
                <span className="inline-flex items-center gap-2">
                  <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                  </svg>
                  Đang xử lý...
                </span>
              ) : (
                confirmLabel
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
