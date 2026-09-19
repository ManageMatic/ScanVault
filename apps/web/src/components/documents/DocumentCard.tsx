import { Star, MoreVertical } from 'lucide-react';
import type { MockDocument } from '@/types/ui';
import { DocumentThumbnail } from './DocumentThumbnail';
import { formatBytes } from '@/lib/mockData';

interface DocumentCardProps {
  document: MockDocument;
  viewMode?: 'list' | 'grid';
  onClick?: () => void;
  onFavoriteToggle?: (e: React.MouseEvent) => void;
  onMoreClick?: (e: React.MouseEvent) => void;
}

export function DocumentCard({
  document,
  viewMode = 'list',
  onClick,
  onFavoriteToggle,
  onMoreClick,
}: DocumentCardProps) {
  const formattedDate = new Date(document.updatedAt).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
  });

  if (viewMode === 'grid') {
    return (
      <div
        onClick={onClick}
        className="group relative bg-surface border border-border hover:border-primary/40 rounded-xl p-3 flex flex-col justify-between shadow-subtle hover:shadow-card transition-all cursor-pointer select-none"
      >
        {/* Top Header in Grid: Favorite & More */}
        <div className="flex items-center justify-between w-full mb-2">
          <button
            onClick={(e) => {
              e.stopPropagation();
              onFavoriteToggle?.(e);
            }}
            className={`p-1.5 rounded-lg transition-colors ${
              document.favorite ? 'text-amber-500' : 'text-subtle hover:text-muted'
            }`}
            aria-label={document.favorite ? 'Remove from favorites' : 'Add to favorites'}
          >
            <Star className={`w-4 h-4 ${document.favorite ? 'fill-amber-500' : ''}`} />
          </button>

          <button
            onClick={(e) => {
              e.stopPropagation();
              onMoreClick?.(e);
            }}
            className="p-1.5 text-subtle hover:text-foreground rounded-lg transition-colors"
            aria-label="Document options"
          >
            <MoreVertical className="w-4 h-4" />
          </button>
        </div>

        {/* Center Thumbnail */}
        <div className="w-full flex justify-center py-2">
          <DocumentThumbnail
            pageCount={document.pageCount}
            color={document.thumbnailColor}
            size="lg"
          />
        </div>

        {/* Bottom Details */}
        <div className="w-full mt-2 min-w-0">
          <h4 className="text-xs font-semibold text-foreground truncate group-hover:text-primary transition-colors">
            {document.title}
          </h4>
          <div className="flex items-center justify-between mt-1 text-[11px] text-muted">
            <span>{formatBytes(document.sizeBytes)}</span>
            <span>{formattedDate}</span>
          </div>
        </div>
      </div>
    );
  }

  // List View (Default on Mobile)
  return (
    <div
      onClick={onClick}
      className="group relative w-full bg-surface border border-border hover:border-primary/40 rounded-xl p-3 flex items-center gap-3.5 shadow-subtle hover:shadow-card transition-all cursor-pointer select-none min-w-0"
    >
      <DocumentThumbnail
        pageCount={document.pageCount}
        color={document.thumbnailColor}
        size="md"
      />

      <div className="flex-1 min-w-0">
        <h4 className="text-xs xs:text-sm font-semibold text-foreground truncate group-hover:text-primary transition-colors">
          {document.title}
        </h4>
        <div className="flex flex-wrap items-center gap-x-2 gap-y-0.5 mt-0.5 text-[11px] text-muted">
          <span>{document.pageCount} {document.pageCount === 1 ? 'page' : 'pages'}</span>
          <span>•</span>
          <span>{formatBytes(document.sizeBytes)}</span>
          <span>•</span>
          <span>{formattedDate}</span>
        </div>
      </div>

      <div className="flex items-center gap-0.5 shrink-0">
        <button
          onClick={(e) => {
            e.stopPropagation();
            onFavoriteToggle?.(e);
          }}
          className={`touch-target p-2 rounded-lg transition-colors ${
            document.favorite ? 'text-amber-500' : 'text-subtle hover:text-muted'
          }`}
          aria-label={document.favorite ? 'Remove from favorites' : 'Add to favorites'}
        >
          <Star className={`w-4 h-4 ${document.favorite ? 'fill-amber-500' : ''}`} />
        </button>

        <button
          onClick={(e) => {
            e.stopPropagation();
            onMoreClick?.(e);
          }}
          className="touch-target p-2 text-subtle hover:text-foreground rounded-lg transition-colors"
          aria-label="Document options"
        >
          <MoreVertical className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
