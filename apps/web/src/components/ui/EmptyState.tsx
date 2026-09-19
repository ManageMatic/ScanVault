import { LucideIcon } from 'lucide-react';

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
  actionIcon?: LucideIcon;
}

export function EmptyState({
  icon: Icon,
  title,
  description,
  actionLabel,
  onAction,
  actionIcon: ActionIcon,
}: EmptyStateProps) {
  return (
    <div className="w-full py-12 px-4 flex flex-col items-center justify-center text-center">
      <div className="w-14 h-14 rounded-2xl bg-surface-secondary border border-border flex items-center justify-center text-muted-foreground mb-4 shadow-sm">
        <Icon className="w-7 h-7" />
      </div>
      <h3 className="text-base font-bold text-foreground mb-1">{title}</h3>
      <p className="text-xs text-muted-foreground max-w-xs mb-6 leading-relaxed">
        {description}
      </p>
      {actionLabel && onAction && (
        <button
          onClick={onAction}
          className="touch-target-lg px-5 bg-primary text-primary-foreground hover:opacity-90 active:scale-95 text-xs font-semibold rounded-xl shadow-md transition-all flex items-center justify-center gap-2"
        >
          {ActionIcon && <ActionIcon className="w-4 h-4" />}
          {actionLabel}
        </button>
      )}
    </div>
  );
}
