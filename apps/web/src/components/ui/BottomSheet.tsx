import { useEffect, ReactNode, useRef } from 'react';
import { X } from 'lucide-react';

interface BottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  description?: string;
  children: ReactNode;
}

export function BottomSheet({ isOpen, onClose, title, description, children }: BottomSheetProps) {
  const sheetRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };

    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    } else {
      document.body.style.overflow = '';
    }

    return () => {
      document.body.style.overflow = '';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-slate-900/35 backdrop-blur-[2px] animate-fade-in transition-opacity"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Sheet Content */}
      <div
        ref={sheetRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={title ? 'bottom-sheet-title' : undefined}
        className="relative z-10 w-full max-w-lg bg-surface border-t border-border rounded-t-xl shadow-elevated animate-slide-up flex flex-col max-h-[85vh] overflow-hidden"
      >
        {/* Handle Bar */}
        <div className="w-full flex items-center justify-center pt-3 pb-2 cursor-grab active:cursor-grabbing">
          <div className="w-9 h-1 rounded-full bg-border" />
        </div>

        {/* Header */}
        {(title || description) && (
          <div className="px-5 pb-3 flex items-start justify-between border-b border-border">
            <div className="min-w-0 flex-1 pr-2">
              {title && (
                <h3 id="bottom-sheet-title" className="text-sm xs:text-base font-bold text-foreground truncate">
                  {title}
                </h3>
              )}
              {description && (
                <p className="text-xs text-muted mt-0.5">{description}</p>
              )}
            </div>
            <button
              onClick={onClose}
              className="touch-target p-1 text-subtle hover:text-foreground rounded-lg transition-colors -mr-2"
              aria-label="Close sheet"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        )}

        {/* Scrollable Body */}
        <div className="p-5 overflow-y-auto flex-1 overscroll-contain pb-safe">
          {children}
        </div>
      </div>
    </div>
  );
}
