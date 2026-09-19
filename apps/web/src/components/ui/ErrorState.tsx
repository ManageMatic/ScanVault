import { AlertTriangle, RotateCcw } from 'lucide-react';

interface ErrorStateProps {
  title?: string;
  message?: string;
  onRetry?: () => void;
}

export function ErrorState({
  title = 'Something went wrong',
  message = 'An error occurred while loading this section.',
  onRetry,
}: ErrorStateProps) {
  return (
    <div className="w-full py-12 px-4 flex flex-col items-center justify-center text-center">
      <div className="w-14 h-14 rounded-2xl bg-destructive/10 border border-destructive/20 flex items-center justify-center text-destructive mb-4 shadow-sm">
        <AlertTriangle className="w-7 h-7" />
      </div>
      <h3 className="text-base font-bold text-foreground mb-1">{title}</h3>
      <p className="text-xs text-muted-foreground max-w-xs mb-6 leading-relaxed">
        {message}
      </p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="touch-target-lg px-5 bg-surface-secondary hover:bg-border active:scale-95 text-xs font-semibold text-foreground rounded-xl border border-border transition-all flex items-center justify-center gap-2 shadow-sm"
        >
          <RotateCcw className="w-3.5 h-3.5" />
          Try Again
        </button>
      )}
    </div>
  );
}
