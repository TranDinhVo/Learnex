import clsx from 'clsx';

type StatusVariant =
  | 'active'
  | 'inactive'
  | 'banned'
  | 'pending'
  | 'approved'
  | 'rejected'
  | 'hidden'
  | 'visible'
  | 'info'
  | 'warning'
  | 'success'
  | 'error'
  | 'admin'
  | 'user';

interface StatusBadgeProps {
  status: StatusVariant;
  label?: string;
}

const config: Record<StatusVariant, { bg: string; text: string; dot: string; defaultLabel: string }> = {
  active:   { bg: 'bg-emerald-50',  text: 'text-emerald-700',  dot: 'bg-emerald-500',  defaultLabel: 'Hoạt động' },
  inactive: { bg: 'bg-slate-100',   text: 'text-slate-600',    dot: 'bg-slate-400',    defaultLabel: 'Không hoạt động' },
  banned:   { bg: 'bg-rose-50',     text: 'text-rose-700',     dot: 'bg-rose-500',     defaultLabel: 'Bị cấm' },
  pending:  { bg: 'bg-amber-50',    text: 'text-amber-700',    dot: 'bg-amber-500',    defaultLabel: 'Chờ duyệt' },
  approved: { bg: 'bg-emerald-50',  text: 'text-emerald-700',  dot: 'bg-emerald-500',  defaultLabel: 'Đã duyệt' },
  rejected: { bg: 'bg-rose-50',     text: 'text-rose-700',     dot: 'bg-rose-500',     defaultLabel: 'Từ chối' },
  hidden:   { bg: 'bg-orange-50',   text: 'text-orange-700',   dot: 'bg-orange-500',   defaultLabel: 'Đã ẩn' },
  visible:  { bg: 'bg-emerald-50',  text: 'text-emerald-700',  dot: 'bg-emerald-500',  defaultLabel: 'Hiển thị' },
  info:     { bg: 'bg-sky-50',      text: 'text-sky-700',      dot: 'bg-sky-500',      defaultLabel: 'Thông tin' },
  warning:  { bg: 'bg-amber-50',    text: 'text-amber-700',    dot: 'bg-amber-500',    defaultLabel: 'Cảnh báo' },
  success:  { bg: 'bg-emerald-50',  text: 'text-emerald-700',  dot: 'bg-emerald-500',  defaultLabel: 'Thành công' },
  error:    { bg: 'bg-rose-50',     text: 'text-rose-700',     dot: 'bg-rose-500',     defaultLabel: 'Lỗi' },
  admin:    { bg: 'bg-violet-50',   text: 'text-violet-700',   dot: 'bg-violet-500',   defaultLabel: 'Admin' },
  user:     { bg: 'bg-indigo-50',   text: 'text-indigo-700',   dot: 'bg-indigo-500',   defaultLabel: 'Học viên' },
};

export default function StatusBadge({ status, label }: StatusBadgeProps) {
  const c = config[status] ?? config.info;
  return (
    <span
      className={clsx(
        'inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold',
        c.bg,
        c.text,
      )}
    >
      <span className={clsx('h-1.5 w-1.5 rounded-full', c.dot)} />
      {label ?? c.defaultLabel}
    </span>
  );
}
