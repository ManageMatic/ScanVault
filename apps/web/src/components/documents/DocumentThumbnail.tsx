import { FileText } from 'lucide-react';

interface DocumentThumbnailProps {
  pageCount?: number;
  color?: string;
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

export function DocumentThumbnail({
  pageCount = 1,
  color = '#008378',
  className = '',
  size = 'md',
}: DocumentThumbnailProps) {
  const sizeClasses = {
    sm: 'w-10 h-13',
    md: 'w-14 h-18',
    lg: 'w-24 h-32',
  };

  return (
    <div
      className={`relative shrink-0 rounded-lg overflow-hidden border border-border/80 bg-surface-secondary shadow-sm flex flex-col items-center justify-between p-1.5 select-none ${sizeClasses[size]} ${className}`}
      style={{
        borderTop: `3px solid ${color}`,
      }}
    >
      {/* Decorative Document Page Lines */}
      <div className="w-full flex flex-col gap-1 pt-1 opacity-40">
        <div className="w-3/4 h-0.5 rounded-full bg-foreground" />
        <div className="w-full h-0.5 rounded-full bg-foreground" />
        <div className="w-1/2 h-0.5 rounded-full bg-foreground" />
      </div>

      <FileText className="w-4 h-4 text-muted-foreground/60 my-auto" />

      {/* Page count pill */}
      <span className="text-[9px] font-bold text-muted-foreground bg-surface/90 px-1 py-0.2 rounded border border-border/40">
        {pageCount}p
      </span>
    </div>
  );
}
