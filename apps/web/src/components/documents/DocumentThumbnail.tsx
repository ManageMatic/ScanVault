import { useState, useEffect } from 'react';
import { FileText, Image as ImageIcon } from 'lucide-react';
import { thumbnailRepository } from '@/lib/db';

interface DocumentThumbnailProps {
  thumbnailId?: string | null;
  mimeType?: string;
  pageCount?: number;
  color?: string;
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

export function DocumentThumbnail({
  thumbnailId,
  mimeType,
  pageCount = 1,
  className = '',
  size = 'md',
}: DocumentThumbnailProps) {
  const [thumbUrl, setThumbUrl] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    let url: string | null = null;

    if (thumbnailId) {
      thumbnailRepository.getThumbnailById(thumbnailId).then((thumb) => {
        if (active && thumb) {
          url = URL.createObjectURL(thumb.blob);
          setThumbUrl(url);
        }
      });
    } else {
      setThumbUrl(null);
    }

    return () => {
      active = false;
      if (url) {
        URL.revokeObjectURL(url);
      }
    };
  }, [thumbnailId]);

  const sizeClasses = {
    sm: 'w-10 h-13',
    md: 'w-12 h-16',
    lg: 'w-20 h-28',
  };

  const isImage = mimeType?.startsWith('image/');
  const isPdf = mimeType === 'application/pdf' || !isImage;

  if (thumbUrl) {
    return (
      <div
        className={`relative shrink-0 rounded-md border border-border bg-surface-secondary overflow-hidden shadow-[0_1px_3px_rgba(0,0,0,0.06)] flex items-center justify-center ${sizeClasses[size]} ${className}`}
      >
        <img
          src={thumbUrl}
          alt="Document thumbnail"
          className="w-full h-full object-cover"
          loading="lazy"
        />
      </div>
    );
  }

  return (
    <div
      className={`relative shrink-0 rounded-md border border-border bg-surface shadow-[0_1px_3px_rgba(0,0,0,0.06)] flex flex-col justify-between p-1.5 select-none ${sizeClasses[size]} ${className}`}
    >
      {/* Top simulated document fold / corner accent */}
      <div className="w-full flex items-center justify-between">
        <span className="text-[8px] font-bold text-primary uppercase tracking-tight">
          {isPdf ? 'PDF' : 'IMG'}
        </span>
        <div className="w-2 h-2 rounded-bl bg-surface-secondary border-b border-l border-border" />
      </div>

      {/* Simulated document lines / icon */}
      <div className="w-full flex flex-col items-center justify-center gap-1 my-auto opacity-40">
        {isPdf ? (
          <>
            <div className="w-full h-0.5 rounded bg-muted" />
            <div className="w-4/5 h-0.5 rounded bg-muted" />
            <div className="w-3/5 h-0.5 rounded bg-muted" />
          </>
        ) : (
          <ImageIcon className="w-4 h-4 text-muted" />
        )}
      </div>

      {/* Bottom page count tag */}
      <div className="flex items-center justify-between text-[9px] text-muted font-medium pt-0.5">
        <FileText className="w-2.5 h-2.5 opacity-60" />
        <span>{pageCount}p</span>
      </div>
    </div>
  );
}
