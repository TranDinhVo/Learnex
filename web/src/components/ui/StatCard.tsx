import { type ReactNode } from 'react';
import clsx from 'clsx';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  trend?: { value: number; label: string };
  className?: string;
}

export default function StatCard({ title, value, icon, trend, className }: StatCardProps) {
  return (
    <div
      className={clsx(
        'group relative overflow-hidden rounded-2xl border border-slate-200/60 bg-white p-6 shadow-sm shadow-slate-100/60 transition-all duration-300 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-slate-200/50',
        className,
      )}
    >
      {/* Subtle background glow on hover */}
      <div className="absolute -right-6 -top-6 h-24 w-24 rounded-full bg-gradient-to-br from-indigo-500/5 to-purple-600/5 opacity-0 blur-2xl transition-opacity duration-300 group-hover:opacity-100" />

      <div className="relative flex items-start justify-between">
        <div className="space-y-3">
          <p className="text-sm font-semibold text-slate-500">{title}</p>
          <p className="text-3xl font-extrabold tracking-tight text-slate-800">
            {typeof value === 'number' ? value.toLocaleString('vi-VN') : value}
          </p>
          {trend && (
            <div className="flex items-center gap-1.5">
              <span
                className={clsx(
                  'inline-flex items-center rounded-full px-2 py-0.5 text-xs font-bold border',
                  trend.value >= 0
                    ? 'bg-emerald-50 border-emerald-100 text-emerald-600'
                    : 'bg-red-50 border-red-100 text-red-600',
                )}
              >
                {trend.value >= 0 ? '↑' : '↓'} {Math.abs(trend.value)}%
              </span>
              <span className="text-xs font-medium text-slate-400">{trend.label}</span>
            </div>
          )}
        </div>

        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-indigo-500/10 to-purple-600/10 text-indigo-600 transition-all duration-300 group-hover:from-indigo-500/20 group-hover:to-purple-600/20">
          {icon}
        </div>
      </div>
    </div>
  );
}
