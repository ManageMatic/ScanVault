interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className = '' }: SkeletonProps) {
  return (
    <div
      className={`animate-pulse rounded-lg bg-surface-secondary/70 border border-border/40 ${className}`}
    />
  );
}

export function DocumentCardSkeleton() {
  return (
    <div className="w-full bg-surface border border-border rounded-xl p-3 flex items-center gap-3">
      <Skeleton className="w-12 h-14 rounded-lg shrink-0" />
      <div className="flex-1 min-w-0 space-y-2">
        <Skeleton className="w-3/4 h-3.5 rounded" />
        <Skeleton className="w-1/2 h-2.5 rounded" />
      </div>
      <Skeleton className="w-8 h-8 rounded-lg shrink-0" />
    </div>
  );
}
