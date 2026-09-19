import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Share2, Star, Trash2, Edit3, Download, FileText, Calendar, HardDrive, Layers } from 'lucide-react';
import { INITIAL_MOCK_DOCUMENTS, formatBytes } from '@/lib/mockData';
import { DocumentThumbnail } from '@/components/documents/DocumentThumbnail';
import { EmptyState } from '@/components/ui/EmptyState';
import { useToast } from '@/lib/toast';

export function DocumentDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { toast } = useToast();

  const doc = INITIAL_MOCK_DOCUMENTS.find((d) => d.id === id);

  if (!doc) {
    return (
      <EmptyState
        icon={FileText}
        title="Document Not Found"
        description="The document you are looking for might have been deleted or moved."
        actionLabel="Back to Documents"
        onAction={() => navigate('/documents')}
      />
    );
  }

  const formattedDate = new Date(doc.updatedAt).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  return (
    <div className="w-full flex flex-col gap-6 animate-fade-in">
      {/* 1. Header Toolbar */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate('/documents')}
          className="touch-target px-3 -ml-2 text-xs font-semibold text-foreground hover:bg-surface-secondary rounded-xl transition-colors flex items-center gap-1.5"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Documents</span>
        </button>

        <div className="flex items-center gap-1">
          <button
            onClick={() =>
              toast({
                title: doc.favorite ? 'Removed from favorites' : 'Saved to favorites',
                type: 'success',
              })
            }
            className={`touch-target p-2 rounded-xl transition-colors ${
              doc.favorite ? 'text-amber-500' : 'text-subtle hover:text-foreground'
            }`}
            aria-label="Toggle favorite"
          >
            <Star className={`w-4 h-4 ${doc.favorite ? 'fill-amber-500' : ''}`} />
          </button>

          <button
            onClick={() =>
              toast({
                title: 'Exporting PDF',
                description: 'Module 07 PDF Engine will handle actual export',
                type: 'info',
              })
            }
            className="touch-target p-2 text-subtle hover:text-foreground rounded-xl transition-colors"
            aria-label="Share document"
          >
            <Share2 className="w-4 h-4" />
          </button>

          <button
            onClick={() => {
              toast({ title: 'Document deleted', type: 'info' });
              navigate('/documents');
            }}
            className="touch-target p-2 text-destructive hover:bg-destructive-soft rounded-xl transition-colors"
            aria-label="Delete document"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* 2. Document Title Card */}
      <div className="w-full bg-surface border border-border rounded-xl p-4 xs:p-5 shadow-subtle flex flex-col gap-3">
        <div className="flex items-start gap-3.5">
          <DocumentThumbnail
            pageCount={doc.pageCount}
            color={doc.thumbnailColor}
            size="lg"
            className="hidden xs:flex"
          />

          <div className="flex-1 min-w-0">
            <span className="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider bg-primary-soft text-primary mb-1.5">
              PDF Document
            </span>
            <h2 className="text-base xs:text-lg font-bold text-foreground break-words">
              {doc.title}
            </h2>

            {/* Tags */}
            {doc.tags && (
              <div className="flex flex-wrap gap-1.5 mt-2">
                {doc.tags.map((tag) => (
                  <span
                    key={tag}
                    className="text-[10px] font-medium bg-surface-secondary text-muted px-2 py-0.5 rounded-md border border-border"
                  >
                    #{tag}
                  </span>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Metadata Grid */}
        <div className="grid grid-cols-3 gap-2 pt-3 border-t border-border text-center">
          <div className="bg-surface-secondary rounded-lg p-2">
            <div className="flex items-center justify-center gap-1 text-[11px] text-muted mb-0.5">
              <Layers className="w-3 h-3 text-primary" />
              <span>Pages</span>
            </div>
            <p className="text-xs font-semibold text-foreground">{doc.pageCount}</p>
          </div>

          <div className="bg-surface-secondary rounded-lg p-2">
            <div className="flex items-center justify-center gap-1 text-[11px] text-muted mb-0.5">
              <HardDrive className="w-3 h-3 text-blue-600" />
              <span>Size</span>
            </div>
            <p className="text-xs font-semibold text-foreground">{formatBytes(doc.sizeBytes)}</p>
          </div>

          <div className="bg-surface-secondary rounded-lg p-2">
            <div className="flex items-center justify-center gap-1 text-[11px] text-muted mb-0.5">
              <Calendar className="w-3 h-3 text-emerald-600" />
              <span>Date</span>
            </div>
            <p className="text-xs font-semibold text-foreground truncate">{formattedDate}</p>
          </div>
        </div>
      </div>

      {/* 3. Quick Action Buttons */}
      <div className="grid grid-cols-2 gap-3">
        <button
          onClick={() =>
            toast({
              title: 'PDF Viewer & Annotations',
              description: 'Module 11 will provide full markup & annotations',
              type: 'info',
            })
          }
          className="btn-primary flex items-center justify-center gap-2"
        >
          <Edit3 className="w-4 h-4" />
          <span>Annotate & Sign</span>
        </button>

        <button
          onClick={() =>
            toast({
              title: 'Export PDF',
              description: 'Preparing local PDF download...',
              type: 'success',
            })
          }
          className="btn-secondary flex items-center justify-center gap-2"
        >
          <Download className="w-4 h-4 text-primary" />
          <span>Download PDF</span>
        </button>
      </div>

      {/* 4. Document Pages Preview Grid */}
      <div className="flex flex-col gap-3 pt-2">
        <h3 className="text-sm font-bold text-foreground">
          Document Pages ({doc.pageCount})
        </h3>

        <div className="grid grid-cols-2 xs:grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
          {Array.from({ length: Math.min(doc.pageCount, 6) }).map((_, index) => (
            <div
              key={index}
              className="bg-surface border border-border rounded-xl p-3 flex flex-col items-center justify-between aspect-[3/4] shadow-subtle hover:border-primary/40 transition-colors"
            >
              <div className="w-full flex flex-col gap-1.5 opacity-30 pt-2">
                <div className="w-full h-1 rounded bg-muted" />
                <div className="w-5/6 h-1 rounded bg-muted" />
                <div className="w-4/6 h-1 rounded bg-muted" />
                <div className="w-full h-1 rounded bg-muted" />
              </div>

              <span className="text-[10px] font-semibold text-muted bg-surface-secondary px-2 py-0.5 rounded-md border border-border">
                Page {index + 1}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
