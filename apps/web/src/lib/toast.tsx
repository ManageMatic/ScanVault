import { createContext, useContext, useState, ReactNode, useCallback } from 'react';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';

export type ToastType = 'success' | 'error' | 'info';

export interface ToastMessage {
  id: string;
  title: string;
  description?: string;
  type: ToastType;
  duration?: number;
}

interface ToastContextType {
  toast: (message: Omit<ToastMessage, 'id'>) => void;
  dismiss: (id: string) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  const dismiss = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const toast = useCallback(
    ({ title, description, type = 'info', duration = 3500 }: Omit<ToastMessage, 'id'>) => {
      const id = Math.random().toString(36).substring(2, 9);
      const newToast: ToastMessage = { id, title, description, type, duration };

      setToasts((prev) => [...prev, newToast]);

      if (duration > 0) {
        setTimeout(() => {
          dismiss(id);
        }, duration);
      }
    },
    [dismiss]
  );

  return (
    <ToastContext.Provider value={{ toast, dismiss }}>
      {children}

      {/* Floating Mobile-First Toast Stack */}
      <div
        aria-live="polite"
        className="fixed bottom-20 xs:bottom-24 lg:bottom-6 right-4 left-4 xs:left-auto xs:w-96 z-50 flex flex-col gap-2 pointer-events-none pb-safe"
      >
        {toasts.map((t) => (
          <div
            key={t.id}
            className="pointer-events-auto w-full bg-surface border border-border shadow-elevated rounded-xl p-3.5 flex items-start gap-3 animate-slide-up transition-all"
          >
            <div className="shrink-0 mt-0.5">
              {t.type === 'success' && <CheckCircle2 className="w-4 h-4 text-success" />}
              {t.type === 'error' && <AlertCircle className="w-4 h-4 text-destructive" />}
              {t.type === 'info' && <Info className="w-4 h-4 text-primary" />}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-foreground truncate">{t.title}</p>
              {t.description && (
                <p className="text-[11px] text-muted mt-0.5 line-clamp-2">
                  {t.description}
                </p>
              )}
            </div>
            <button
              onClick={() => dismiss(t.id)}
              className="shrink-0 p-1 text-subtle hover:text-foreground rounded-lg transition-colors"
              aria-label="Dismiss notification"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast(): ToastContextType {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
}
