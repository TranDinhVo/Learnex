import { type ReactNode } from 'react';
import clsx from 'clsx';

export interface Column<T> {
  key: string;
  header: string;
  render?: (item: T) => ReactNode;
  className?: string;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  keyExtractor: (item: T) => string;
  isLoading?: boolean;
  emptyMessage?: string;
  onRowClick?: (item: T) => void;
}

function SkeletonRow({ cols }: { cols: number }) {
  return (
    <tr className="border-b border-white/5">
      {Array.from({ length: cols }).map((_, i) => (
        <td key={i} className="px-5 py-4">
          <div className="h-4 w-3/4 animate-pulse rounded bg-gray-700/50" />
        </td>
      ))}
    </tr>
  );
}

export default function DataTable<T>({
  columns,
  data,
  keyExtractor,
  isLoading,
  emptyMessage = 'Không có dữ liệu',
  onRowClick,
}: DataTableProps<T>) {
  return (
    <div className="overflow-x-auto rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl">
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="border-b border-white/10 bg-white/5">
            {columns.map((col) => (
              <th
                key={col.key}
                className={clsx(
                  'px-5 py-4 text-xs font-semibold uppercase tracking-wider text-gray-400',
                  col.className,
                )}
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {isLoading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <SkeletonRow key={i} cols={columns.length} />
            ))
          ) : data.length === 0 ? (
            <tr>
              <td
                colSpan={columns.length}
                className="px-5 py-16 text-center text-gray-500"
              >
                <div className="flex flex-col items-center gap-2">
                  <svg className="h-12 w-12 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                  </svg>
                  {emptyMessage}
                </div>
              </td>
            </tr>
          ) : (
            data.map((item, idx) => (
              <tr
                key={keyExtractor(item)}
                onClick={() => onRowClick?.(item)}
                className={clsx(
                  'border-b border-white/5 transition-colors duration-150',
                  idx % 2 === 0 ? 'bg-transparent' : 'bg-white/[0.02]',
                  onRowClick && 'cursor-pointer',
                  'hover:bg-white/[0.06]',
                )}
              >
                {columns.map((col) => (
                  <td
                    key={col.key}
                    className={clsx('px-5 py-4 text-gray-300', col.className)}
                  >
                    {col.render
                      ? col.render(item)
                      : String((item as Record<string, unknown>)[col.key] ?? '')}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}
