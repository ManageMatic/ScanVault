import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Star,
  Trash2,
  Download,
  FileText,
  Calendar,
  HardDrive,
  Layers,
  Edit2,
  Image as ImageIcon,
  Loader2,
} from 'lucide-react';
import { formatBytes } from '@/lib/mockData';
import {
  useDocument,
  documentRepository,
} from '@/lib/db';
import { Modal } from '@/components/ui/Modal';
import { EmptyState } from '@/components/ui/EmptyState';
import { useToast } from '@/lib/toast';
import { useAuth } from '@/lib/auth';

export function DocumentDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { toast } = useToast();
  const { user } = useAuth();
  const userId = user?.id || '';

  const { document: doc, file, fileUrl, isLoading, error, refetch } = useDocument(id);

  const [isRenameModalOpen, setIsRenameModalOpen] = useState(false);
  const [renameTitle, setRenameTitle] = useState('');

  if (isLoading) {
    return (
      <div className="py-20 flex flex-col items-center justify-center gap-3 text-center">
        <Loader2 className="w-8 h-8 text-primary animate-spin" />
        <p className="text-sm font-semibold text-foreground">Loading document...</p>
      </div>
    );
  }

  if (error || !doc) {
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

  const isImage = doc.mimeType?.startsWith('image/');
  const isPdf = doc.mimeType === 'application/pdf';

  const formattedDate = new Date(doc.updatedAt).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  const handleToggleFavorite = async () => {
    try {
      const newFav = await documentRepository.toggleFavorite(doc.id, userId);
      toast({
        title: newFav ? 'Saved to favorites' : 'Removed from favorites',
        type: 'success',
      });
      refetch();
    } catch {
      toast({ title: 'Error toggling favorite', type: 'error' });
    }
  };

  const handleDownload = () => {
    if (!file) {
      toast({ title: 'File data not available', type: 'error' });
      return;
    }
    const url = URL.createObjectURL(file.blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = doc.title;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    toast({ title: 'Download started', description: doc.title, type: 'success' });
  };

  const handleDelete = async () => {
    try {
      await documentRepository.softDeleteDocument(doc.id, userId);
      toast({
        title: 'Document moved to Trash',
        description: doc.title,
        type: 'info',
      });
      navigate('/documents');
    } catch {
      toast({ title: 'Error deleting document', type: 'error' });
    }
  };

  const handleRenameSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!renameTitle.trim()) return;

    try {
      await documentRepository.renameDocument(doc.id, userId, renameTitle.trim());
      toast({
        title: 'Document renamed',
        description: renameTitle.trim(),
        type: 'success',
      });
      setIsRenameModalOpen(false);
      refetch();
    } catch (err) {
      toast({ title: 'Rename failed', description: (err as Error).message, type: 'error' });
    }
  };

  return (
    <div className="w-full flex flex-col gap-6 animate-fade-in pb-12">
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
            onClick={() => {
              setRenameTitle(doc.title);
              setIsRenameModalOpen(true);
            }}
            className="touch-target p-2 text-subtle hover:text-foreground rounded-xl transition-colors"
            aria-label="Rename document"
          >
            <Edit2 className="w-4 h-4" />
          </button>

          <button
            onClick={handleToggleFavorite}
            className={`touch-target p-2 rounded-xl transition-colors ${
              doc.favorite ? 'text-amber-500' : 'text-subtle hover:text-foreground'
            }`}
            aria-label="Toggle favorite"
          >
            <Star className={`w-4 h-4 ${doc.favorite ? 'fill-amber-500' : ''}`} />
          </button>

          <button
            onClick={handleDownload}
            className="touch-target p-2 text-subtle hover:text-foreground rounded-xl transition-colors"
            aria-label="Download document"
          >
            <Download className="w-4 h-4" />
          </button>

          <button
            onClick={handleDelete}
            className="touch-target p-2 text-destructive hover:bg-destructive-soft rounded-xl transition-colors"
            aria-label="Delete document"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* 2. Document Title & Metadata Card */}
      <div className="w-full bg-surface border border-border rounded-xl p-4 xs:p-5 shadow-subtle flex flex-col gap-3">
        <div className="flex items-start gap-3.5">
          <div className="p-3 rounded-xl bg-primary-soft text-primary shrink-0">
            {isImage ? <ImageIcon className="w-6 h-6" /> : <FileText className="w-6 h-6" />}
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <span className="inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider bg-primary-soft text-primary">
                {isPdf ? 'PDF Document' : 'Image Document'}
              </span>
              <span className="text-[10px] font-medium text-muted bg-surface-secondary px-2 py-0.5 rounded border border-border">
                {doc.source}
              </span>
            </div>

            <h2 className="text-base xs:text-lg font-bold text-foreground break-words">
              {doc.title}
            </h2>

            {/* Tags */}
            {doc.tags && doc.tags.length > 0 && (
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
            <p className="text-xs font-semibold text-foreground">{formatBytes(doc.size)}</p>
          </div>

          <div className="bg-surface-secondary rounded-lg p-2">
            <div className="flex items-center justify-center gap-1 text-[11px] text-muted mb-0.5">
              <Calendar className="w-3 h-3 text-emerald-600" />
              <span>Modified</span>
            </div>
            <p className="text-xs font-semibold text-foreground truncate">{formattedDate}</p>
          </div>
        </div>
      </div>

      {/* 3. Document Content Preview */}
      <div className="flex flex-col gap-3">
        <h3 className="text-sm font-bold text-foreground">Document Preview</h3>

        {isImage && fileUrl ? (
          <div className="w-full bg-surface border border-border rounded-xl overflow-hidden p-2 flex items-center justify-center shadow-subtle min-h-[300px]">
            <img
              src={fileUrl}
              alt={doc.title}
              className="max-h-[500px] w-auto max-w-full object-contain rounded-lg"
            />
          </div>
        ) : (
          <div className="w-full bg-surface border border-border rounded-xl p-8 flex flex-col items-center justify-center text-center gap-3 shadow-subtle">
            <div className="w-16 h-16 rounded-2xl bg-primary-soft text-primary flex items-center justify-center">
              <FileText className="w-8 h-8" />
            </div>
            <div className="max-w-sm">
              <h4 className="text-sm font-bold text-foreground">{doc.title}</h4>
              <p className="text-xs text-muted mt-1 leading-relaxed">
                PDF binary stored securely in local IndexedDB. Full multi-page rendering engine will be active in Module 07.
              </p>
            </div>
            <button
              onClick={handleDownload}
              className="btn-primary text-xs flex items-center gap-2 mt-2 shadow-sm"
            >
              <Download className="w-4 h-4" />
              <span>Download PDF File</span>
            </button>
          </div>
        )}
      </div>

      {/* Rename Modal */}
      <Modal
        isOpen={isRenameModalOpen}
        onClose={() => setIsRenameModalOpen(false)}
        title="Rename Document"
        description="Enter a new title for this document."
      >
        <form onSubmit={handleRenameSubmit} className="flex flex-col gap-4">
          <div>
            <label className="block text-xs font-semibold text-foreground mb-1.5">
              Document Title
            </label>
            <input
              type="text"
              required
              autoFocus
              value={renameTitle}
              onChange={(e) => setRenameTitle(e.target.value)}
              className="form-input"
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setIsRenameModalOpen(false)}
              className="btn-secondary text-xs h-10 px-4"
            >
              Cancel
            </button>
            <button type="submit" className="btn-primary text-xs h-10 px-5">
              Save
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
