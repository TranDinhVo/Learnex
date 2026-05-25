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
        'group relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl transition-all duration-300 hover:border-white/20 hover:bg-white/10 hover:shadow-lg hover:shadow-indigo-500/5',
        className,
      )}
    >
      {/* Gradient glow on hover */}
      <div className="absolute -right-6 -top-6 h-24 w-24 rounded-full bg-gradient-to-br from-indigo-500/20 to-purple-600/20 opacity-0 blur-2xl transition-opacity duration-300 group-hover:opacity-100" />

      <div className="relative flex items-start justify-between">
        <div className="space-y-3">
          <p className="text-sm font-medium text-gray-400">{title}</p>
          <p className="text-3xl font-bold tracking-tight text-white">
            {typeof value === 'number' ? value.toLocaleString('vi-VN') : value}
          </p>
          {trend && (
            <div className="flex items-center gap-1.5">
              <span
                className={clsx(
                  'inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold',
                  trend.value >= 0
                    ? 'bg-emerald-500/15 text-emerald-400'
                    : 'bg-red-500/15 text-red-400',
                )}
              >
                {trend.value >= 0 ? '↑' : '↓'} {Math.abs(trend.value)}%
              </span>
              <span className="text-xs text-gray-500">{trend.label}</span>
            </div>
          )}
        </div>

        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-indigo-500/20 to-purple-600/20 text-indigo-400 transition-colors duration-300 group-hover:from-indigo-500/30 group-hover:to-purple-600/30">
          {icon}
        </div>
      </div>
    </div>
  );
}
