import { create } from "zustand";

export type ToastType = "success" | "error" | "info";

export interface ToastItem {
  id: string;
  title?: string;
  message: string;
  type?: ToastType;
  timeout?: number; // ms
}

interface ToastState {
  toasts: ToastItem[];
  addToast: (t: Omit<ToastItem, "id">) => string;
  removeToast: (id: string) => void;
}

export const useToastStore = create<ToastState>((set, get) => ({
  toasts: [],
  addToast: (t) => {
    const id = `${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
    const toast: ToastItem = { id, ...t };
    set({ toasts: [...get().toasts, toast] });

    const timeout = t.timeout ?? 4000;
    if (timeout > 0) {
      setTimeout(() => {
        const exists = get().toasts.find((x) => x.id === id);
        if (exists) get().removeToast(id);
      }, timeout);
    }

    return id;
  },
  removeToast: (id) => set({ toasts: get().toasts.filter((t) => t.id !== id) }),
}));

export function useToast() {
  const addToast = useToastStore((s) => s.addToast);
  const removeToast = useToastStore((s) => s.removeToast);
  return { addToast, removeToast };
}
