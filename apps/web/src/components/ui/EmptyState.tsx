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
      <div className="w-13 h-13 rounded-2xl bg-surface-secondary border border-border flex items-center justify-center text-muted mb-3.5 shadow-subtle">
        <Icon className="w-6 h-6 text-subtle" />
      </div>
      <h3 className="text-base font-bold text-foreground mb-1">{title}</h3>
      <p className="text-xs xs:text-sm text-muted max-w-xs mb-5 leading-relaxed">
        {description}
      </p>
      {actionLabel && onAction && (
        <button
          onClick={onAction}
          className="btn-primary touch-target-lg px-5 text-xs font-semibold flex items-center justify-center gap-2"
        >
          {ActionIcon && <ActionIcon className="w-4 h-4" />}
          {actionLabel}
        </button>
      )}
    </div>
  );
}
