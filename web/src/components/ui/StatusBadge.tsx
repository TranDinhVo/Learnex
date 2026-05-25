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
  | 'error';

interface StatusBadgeProps {
  status: StatusVariant;
  label?: string;
}

const config: Record<StatusVariant, { bg: string; text: string; dot: string; defaultLabel: string }> = {
  active:   { bg: 'bg-emerald-500/15', text: 'text-emerald-400', dot: 'bg-emerald-400', defaultLabel: 'Hoạt động' },
  inactive: { bg: 'bg-gray-500/15',    text: 'text-gray-400',    dot: 'bg-gray-400',    defaultLabel: 'Không hoạt động' },
  banned:   { bg: 'bg-red-500/15',     text: 'text-red-400',     dot: 'bg-red-400',     defaultLabel: 'Bị cấm' },
  pending:  { bg: 'bg-amber-500/15',   text: 'text-amber-400',   dot: 'bg-amber-400',   defaultLabel: 'Chờ duyệt' },
  approved: { bg: 'bg-emerald-500/15', text: 'text-emerald-400', dot: 'bg-emerald-400', defaultLabel: 'Đã duyệt' },
  rejected: { bg: 'bg-red-500/15',     text: 'text-red-400',     dot: 'bg-red-400',     defaultLabel: 'Từ chối' },
  hidden:   { bg: 'bg-orange-500/15',  text: 'text-orange-400',  dot: 'bg-orange-400',  defaultLabel: 'Đã ẩn' },
  visible:  { bg: 'bg-emerald-500/15', text: 'text-emerald-400', dot: 'bg-emerald-400', defaultLabel: 'Hiển thị' },
  info:     { bg: 'bg-blue-500/15',    text: 'text-blue-400',    dot: 'bg-blue-400',    defaultLabel: 'Thông tin' },
  warning:  { bg: 'bg-amber-500/15',   text: 'text-amber-400',   dot: 'bg-amber-400',   defaultLabel: 'Cảnh báo' },
  success:  { bg: 'bg-emerald-500/15', text: 'text-emerald-400', dot: 'bg-emerald-400', defaultLabel: 'Thành công' },
  error:    { bg: 'bg-red-500/15',     text: 'text-red-400',     dot: 'bg-red-400',     defaultLabel: 'Lỗi' },
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
