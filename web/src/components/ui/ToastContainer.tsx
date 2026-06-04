import { X } from "lucide-react";
import { useToastStore } from "../../stores/toastStore";

export default function ToastContainer() {
  const toasts = useToastStore((s) => s.toasts);
  const remove = useToastStore((s) => s.removeToast);

  if (!toasts || toasts.length === 0) return null;

  return (
    <div className="fixed right-4 top-4 z-50 flex flex-col items-end gap-3">
      {toasts.map((t) => (
        <div
          key={t.id}
          className="w-96 rounded-xl border border-slate-200 bg-white p-3 shadow-lg"
        >
          <div className="flex items-start gap-3">
            <div className="flex-1">
              {t.title && (
                <div className="mb-1 font-semibold text-slate-800">
                  {t.title}
                </div>
              )}
              <div className="text-sm text-slate-600">{t.message}</div>
            </div>
            <button
              onClick={() => remove(t.id)}
              className="text-slate-400 hover:text-slate-600"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
