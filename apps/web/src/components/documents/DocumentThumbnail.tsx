import { FileText } from 'lucide-react';

interface DocumentThumbnailProps {
  pageCount?: number;
  color?: string;
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

export function DocumentThumbnail({
  pageCount = 1,
  className = '',
  size = 'md',
}: DocumentThumbnailProps) {
  const sizeClasses = {
    sm: 'w-10 h-13',
    md: 'w-12 h-16',
    lg: 'w-20 h-28',
  };

  return (
    <div
      className={`relative shrink-0 rounded-md border border-border bg-surface shadow-[0_1px_3px_rgba(0,0,0,0.06)] flex flex-col justify-between p-1.5 select-none ${sizeClasses[size]} ${className}`}
    >
      {/* Top simulated document fold / corner accent */}
      <div className="w-full flex items-center justify-between">
        <span className="text-[8px] font-bold text-primary uppercase tracking-tight">PDF</span>
        <div className="w-2 h-2 rounded-bl bg-surface-secondary border-b border-l border-border" />
      </div>

      {/* Simulated text lines */}
      <div className="w-full flex flex-col gap-1 my-auto opacity-30">
        <div className="w-full h-0.5 rounded bg-muted" />
        <div className="w-4/5 h-0.5 rounded bg-muted" />
        <div className="w-3/5 h-0.5 rounded bg-muted" />
      </div>

      {/* Bottom page count tag */}
      <div className="flex items-center justify-between text-[9px] text-muted font-medium pt-0.5">
        <FileText className="w-2.5 h-2.5 opacity-60" />
        <span>{pageCount}p</span>
      </div>
    </div>
  );
}
