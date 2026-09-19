import { useState } from 'react';
import {
  Search,
  Camera,
  ArrowRight,
  FolderPlus,
  Wrench,
  HardDrive,
  Upload,
} from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { PDF_TOOLS, formatBytes } from '@/lib/mockData';
import {
  useDocuments,
  useStorageUsage,
  fileRepository,
  type LocalDocument,
} from '@/lib/db';
import { DocumentCard } from '@/components/documents/DocumentCard';
import { DocumentActionSheet } from '@/components/documents/DocumentActionSheet';
import { ImportDocumentSheet } from '@/components/documents/ImportDocumentSheet';
import { Modal } from '@/components/ui/Modal';
import { EmptyState } from '@/components/ui/EmptyState';
import { useToast } from '@/lib/toast';
import { useAuth } from '@/lib/auth';

export function HomePage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { user } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDoc, setSelectedDoc] = useState<LocalDocument | null>(null);
  const [isImportSheetOpen, setIsImportSheetOpen] = useState(false);

  const [docToRename, setDocToRename] = useState<LocalDocument | null>(null);
  const [renameValue, setRenameValue] = useState('');

  const {
    documents: recentDocs,
    allCount,
    toggleFavorite,
    renameDocument,
    softDeleteDocument,
    duplicateDocument,
  } = useDocuments({
    tab: 'all',
    search: searchQuery,
    sortBy: 'opened-desc',
  });

  const { usage, isSupported } = useStorageUsage();

  const greeting = (() => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  })();

  const handleToggleFavorite = async (doc: LocalDocument) => {
    try {
      const isFav = await toggleFavorite(doc.id);
      toast({
        title: isFav ? 'Added to favorites' : 'Removed from favorites',
        description: doc.title,
        type: 'success',
      });
    } catch {
      toast({ title: 'Error updating favorite', type: 'error' });
    }
  };

  const handleSoftDelete = async (doc: LocalDocument) => {
    try {
      await softDeleteDocument(doc.id);
      toast({
        title: 'Document moved to Trash',
        description: doc.title,
        type: 'info',
      });
    } catch {
      toast({ title: 'Error moving document to trash', type: 'error' });
    }
  };

  const handleDuplicate = async (doc: LocalDocument) => {
    try {
      const copy = await duplicateDocument(doc.id);
      if (copy) {
        toast({
          title: 'Document duplicated',
          description: copy.title,
          type: 'success',
        });
      }
    } catch {
      toast({ title: 'Error duplicating document', type: 'error' });
    }
  };

  const handleDownload = async (doc: LocalDocument) => {
    try {
      const fileData = await fileRepository.getFileByDocumentId(doc.id);
      if (!fileData) {
        toast({ title: 'File data not found', type: 'error' });
        return;
      }
      const url = URL.createObjectURL(fileData.blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = doc.title;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      toast({ title: 'Download started', description: doc.title, type: 'success' });
    } catch {
      toast({ title: 'Download failed', type: 'error' });
    }
  };

  const handleRenameSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!docToRename || !renameValue.trim()) return;

    try {
      await renameDocument(docToRename.id, renameValue.trim());
      toast({
        title: 'Document renamed',
        description: renameValue.trim(),
        type: 'success',
      });
      setDocToRename(null);
    } catch (err) {
      toast({ title: 'Rename failed', description: (err as Error).message, type: 'error' });
    }
  };

  const displayedDocs = recentDocs.slice(0, 5);

  return (
    <div className="w-full flex flex-col gap-6 animate-fade-in">
      {/* 1. Header Greeting & User Bar */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl xs:text-2xl font-bold tracking-tight text-foreground">
            {greeting}
            {user?.name ? `, ${user.name.split(' ')[0]}` : ''}
          </h1>
          <p className="text-xs text-muted mt-0.5">
            Your documents are organized and ready offline
          </p>
        </div>
      </div>

      {/* 2. Mobile Search Bar Entry */}
      <div className="relative w-full">
        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search documents by title..."
          className="form-input pl-10 pr-12 text-xs xs:text-sm"
        />
        {searchQuery && (
          <button
            onClick={() => setSearchQuery('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-muted hover:text-foreground font-medium p-1"
          >
            Clear
          </button>
        )}
      </div>

      {/* 3. Hero Scan Banner (Primary CTA) */}
      {!searchQuery && (
        <div className="w-full bg-surface border border-border rounded-2xl p-5 xs:p-6 shadow-subtle flex flex-col xs:flex-row items-start xs:items-center justify-between gap-4">
          <div className="max-w-md">
            <span className="inline-block px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-primary-soft text-primary mb-2">
              Scanner Studio
            </span>
            <h2 className="text-lg xs:text-xl font-bold tracking-tight text-foreground">
              Capture & scan documents
            </h2>
            <p className="text-xs text-muted mt-1 leading-relaxed">
              Auto-crop edge detection, crisp PDF generation, and local encrypted storage.
            </p>
          </div>

          <div className="flex items-center gap-2 w-full xs:w-auto shrink-0">
            <button
              onClick={() => setIsImportSheetOpen(true)}
              className="btn-secondary flex-1 xs:flex-initial flex items-center justify-center gap-2 shadow-sm"
            >
              <Upload className="w-4 h-4 text-primary" />
              <span>Import File</span>
            </button>
            <Link
              to="/scan"
              className="btn-primary flex-1 xs:flex-initial flex items-center justify-center gap-2 shadow-sm"
            >
              <Camera className="w-4 h-4" />
              <span>Scan</span>
            </Link>
          </div>
        </div>
      )}

      {/* 4. Quick Actions Ribbon */}
      {!searchQuery && (
        <div className="grid grid-cols-2 xs:grid-cols-4 gap-3">
          <button
            onClick={() => setIsImportSheetOpen(true)}
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3.5 flex flex-col items-center justify-center text-center shadow-subtle transition-all active:scale-[0.98]"
          >
            <div className="w-9 h-9 rounded-xl bg-primary-soft text-primary flex items-center justify-center mb-1.5">
              <Upload className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">Import File</span>
            <span className="text-[10px] text-muted">PDF or Image</span>
          </button>

          <Link
            to="/documents"
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3.5 flex flex-col items-center justify-center text-center shadow-subtle transition-all active:scale-[0.98]"
          >
            <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center mb-1.5">
              <FolderPlus className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">All Vault</span>
            <span className="text-[10px] text-muted">{allCount} Documents</span>
          </Link>

          <Link
            to="/tools"
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3.5 flex flex-col items-center justify-center text-center shadow-subtle transition-all active:scale-[0.98]"
          >
            <div className="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center mb-1.5">
              <Wrench className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">PDF Tools</span>
            <span className="text-[10px] text-muted">8 Utilities</span>
          </Link>

          <Link
            to="/settings"
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3.5 flex flex-col items-center justify-center text-center shadow-subtle transition-all active:scale-[0.98]"
          >
            <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-1.5">
              <HardDrive className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">Local Vault</span>
            <span className="text-[10px] text-muted">
              {isSupported && usage > 0 ? `${formatBytes(usage)} Used` : 'Air-gapped'}
            </span>
          </Link>
        </div>
      )}

      {/* 5. Recent Documents Section */}
      <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold text-foreground tracking-tight">
            {searchQuery ? `Search Results (${recentDocs.length})` : 'Recent Documents'}
          </h3>
          {!searchQuery && allCount > 0 && (
            <Link
              to="/documents"
              className="text-xs font-semibold text-primary hover:text-primary-hover flex items-center gap-1"
            >
              <span>View All</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          )}
        </div>

        {displayedDocs.length > 0 ? (
          <div className="flex flex-col gap-2.5">
            {displayedDocs.map((doc) => (
              <DocumentCard
                key={doc.id}
                document={doc}
                onClick={() => navigate(`/documents/${doc.id}`)}
                onFavoriteToggle={() => handleToggleFavorite(doc)}
                onMoreClick={() => setSelectedDoc(doc)}
              />
            ))}
          </div>
        ) : (
          <EmptyState
            icon={Search}
            title={searchQuery ? 'No documents found' : 'No documents yet'}
            description={
              searchQuery
                ? `No documents match "${searchQuery}".`
                : 'Import a PDF or image, or scan your first document.'
            }
            actionLabel={searchQuery ? 'Clear Search' : 'Import Document'}
            actionIcon={searchQuery ? undefined : Upload}
            onAction={() => (searchQuery ? setSearchQuery('') : setIsImportSheetOpen(true))}
          />
        )}
      </div>

      {/* 6. Featured PDF Studio Tools */}
      {!searchQuery && (
        <div className="flex flex-col gap-3 pt-2">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-foreground tracking-tight">
              PDF Studio Tools
            </h3>
            <Link
              to="/tools"
              className="text-xs font-semibold text-primary hover:text-primary-hover flex items-center gap-1"
            >
              <span>Explore All</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="grid grid-cols-1 xs:grid-cols-2 gap-3">
            {PDF_TOOLS.slice(0, 4).map((tool) => (
              <Link
                key={tool.id}
                to="/tools"
                className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3.5 flex items-start gap-3 transition-all shadow-subtle"
              >
                <div className="w-8 h-8 rounded-lg bg-primary-soft text-primary flex items-center justify-center shrink-0 mt-0.5">
                  <Wrench className="w-4 h-4" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between">
                    <h4 className="text-xs font-bold text-foreground truncate">
                      {tool.title}
                    </h4>
                    {tool.badge && (
                      <span className="text-[9px] font-semibold text-primary bg-primary-soft px-1.5 py-0.5 rounded">
                        {tool.badge}
                      </span>
                    )}
                  </div>
                  <p className="text-[11px] text-muted mt-0.5 line-clamp-1">
                    {tool.description}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* Import Document Sheet */}
      <ImportDocumentSheet
        isOpen={isImportSheetOpen}
        onClose={() => setIsImportSheetOpen(false)}
      />

      {/* Rename Document Modal */}
      <Modal
        isOpen={!!docToRename}
        onClose={() => setDocToRename(null)}
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
              value={renameValue}
              onChange={(e) => setRenameValue(e.target.value)}
              className="form-input"
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setDocToRename(null)}
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

      {/* Contextual Action Sheet */}
      <DocumentActionSheet
        document={selectedDoc}
        isOpen={!!selectedDoc}
        onClose={() => setSelectedDoc(null)}
        onOpenDoc={(doc) => navigate(`/documents/${doc.id}`)}
        onRename={(doc) => {
          setDocToRename(doc);
          setRenameValue(doc.title);
        }}
        onToggleFavorite={handleToggleFavorite}
        onDuplicate={handleDuplicate}
        onDownload={handleDownload}
        onDelete={handleSoftDelete}
      />
    </div>
  );
}
