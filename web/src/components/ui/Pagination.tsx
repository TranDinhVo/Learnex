import { ChevronLeft, ChevronRight } from 'lucide-react';
import clsx from 'clsx';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

export default function Pagination({ currentPage, totalPages, onPageChange }: PaginationProps) {
  if (totalPages <= 1) return null;

  const getPages = () => {
    const pages: (number | '...')[] = [];
    const delta = 2;
    const left = Math.max(2, currentPage - delta);
    const right = Math.min(totalPages - 1, currentPage + delta);

    pages.push(1);
    if (left > 2) pages.push('...');
    for (let i = left; i <= right; i++) pages.push(i);
    if (right < totalPages - 1) pages.push('...');
    if (totalPages > 1) pages.push(totalPages);

    return pages;
  };

  const btnBase =
    'flex h-9 min-w-[2.25rem] items-center justify-center rounded-lg text-sm font-medium transition-all duration-200';

  return (
    <div className="flex items-center justify-center gap-1.5 pt-4">
      <button
        onClick={() => onPageChange(currentPage - 1)}
        disabled={currentPage === 1}
        className={clsx(btnBase, 'px-2 text-gray-400 hover:bg-white/10 hover:text-white disabled:opacity-30 disabled:hover:bg-transparent')}
      >
        <ChevronLeft className="h-4 w-4" />
      </button>

      {getPages().map((page, i) =>
        page === '...' ? (
          <span key={`dots-${i}`} className="px-1 text-gray-600">
            …
          </span>
        ) : (
          <button
            key={page}
            onClick={() => onPageChange(page as number)}
            className={clsx(
              btnBase,
              page === currentPage
                ? 'bg-gradient-to-r from-indigo-500 to-purple-600 text-white shadow-lg shadow-indigo-500/25'
                : 'text-gray-400 hover:bg-white/10 hover:text-white',
            )}
          >
            {page}
          </button>
        ),
      )}

      <button
        onClick={() => onPageChange(currentPage + 1)}
        disabled={currentPage === totalPages}
        className={clsx(btnBase, 'px-2 text-gray-400 hover:bg-white/10 hover:text-white disabled:opacity-30 disabled:hover:bg-transparent')}
      >
        <ChevronRight className="h-4 w-4" />
      </button>
    </div>
  );
}
