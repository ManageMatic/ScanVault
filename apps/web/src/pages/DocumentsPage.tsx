import { useState } from 'react';
import {
  Search,
  LayoutList,
  LayoutGrid,
  FolderPlus,
  Star,
  Clock,
  Trash2,
  Files,
  Folder as FolderIcon,
  Plus,
  ArrowUpDown,
  Upload,
  ArrowLeft,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import type { ViewMode, DocumentTab } from '@/types/ui';
import {
  useDocuments,
  useFolders,
  fileRepository,
  type LocalDocument,
  type FolderWithCount,
  type DocumentSortOption,
} from '@/lib/db';
import { DocumentCard } from '@/components/documents/DocumentCard';
import { FolderCard } from '@/components/documents/FolderCard';
import { DocumentActionSheet } from '@/components/documents/DocumentActionSheet';
import { ImportDocumentSheet } from '@/components/documents/ImportDocumentSheet';
import { Modal } from '@/components/ui/Modal';
import { EmptyState } from '@/components/ui/EmptyState';
import { useToast } from '@/lib/toast';

export function DocumentsPage() {
  const navigate = useNavigate();
  const { toast } = useToast();

  const [activeTab, setActiveTab] = useState<DocumentTab>('all');
  const [selectedFolder, setSelectedFolder] = useState<FolderWithCount | null>(null);
  const [viewMode, setViewMode] = useState<ViewMode>('list');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<DocumentSortOption>('modified-desc');
  const [selectedDoc, setSelectedDoc] = useState<LocalDocument | null>(null);

  // Modals & Sheets
  const [isImportSheetOpen, setIsImportSheetOpen] = useState(false);
  const [isFolderModalOpen, setIsFolderModalOpen] = useState(false);
  const [newFolderName, setNewFolderName] = useState('');

  const [docToRename, setDocToRename] = useState<LocalDocument | null>(null);
  const [renameValue, setRenameValue] = useState('');

  const [docToMove, setDocToMove] = useState<LocalDocument | null>(null);
  const [targetFolderId, setTargetFolderId] = useState<string>('root');

  const [docToDeletePermanent, setDocToDeletePermanent] = useState<LocalDocument | null>(null);
  const [folderToDelete, setFolderToDelete] = useState<FolderWithCount | null>(null);

  // Queries & Mutations
  const {
    documents,
    allCount,
    favoritesCount,
    trashCount,
    renameDocument,
    toggleFavorite,
    moveToFolder,
    softDeleteDocument,
    restoreDocument,
    permanentlyDeleteDocument,
    duplicateDocument,
  } = useDocuments({
    tab: selectedFolder ? 'folder' : activeTab === 'folders' ? 'all' : activeTab,
    folderId: selectedFolder ? selectedFolder.id : undefined,
    search: searchQuery,
    sortBy,
  });

  const { folders, createFolder, deleteFolder } = useFolders();

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
        description: `"${doc.title}" can be restored from Trash`,
        type: 'info',
      });
    } catch {
      toast({ title: 'Error moving document to trash', type: 'error' });
    }
  };

  const handleRestore = async (doc: LocalDocument) => {
    try {
      await restoreDocument(doc.id);
      toast({
        title: 'Document restored',
        description: `"${doc.title}" restored to vault`,
        type: 'success',
      });
    } catch {
      toast({ title: 'Error restoring document', type: 'error' });
    }
  };

  const handlePermanentDelete = async () => {
    if (!docToDeletePermanent) return;
    try {
      await permanentlyDeleteDocument(docToDeletePermanent.id);
      toast({
        title: 'Permanently deleted',
        description: `"${docToDeletePermanent.title}" and its local files were removed`,
        type: 'success',
      });
      setDocToDeletePermanent(null);
    } catch {
      toast({ title: 'Error deleting document', type: 'error' });
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
      a.download = doc.title.endsWith('.pdf') || doc.title.endsWith('.png') || doc.title.endsWith('.jpg')
        ? doc.title
        : `${doc.title}.${doc.mimeType === 'application/pdf' ? 'pdf' : 'jpg'}`;
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

  const handleMoveSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!docToMove) return;

    try {
      const target = targetFolderId === 'root' ? null : targetFolderId;
      await moveToFolder(docToMove.id, target);
      toast({
        title: 'Document moved',
        description: targetFolderId === 'root' ? 'Moved to Root' : 'Moved to Folder',
        type: 'success',
      });
      setDocToMove(null);
    } catch (err) {
      toast({ title: 'Move failed', description: (err as Error).message, type: 'error' });
    }
  };

  const handleCreateFolder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newFolderName.trim()) return;

    try {
      await createFolder(newFolderName.trim());
      setNewFolderName('');
      setIsFolderModalOpen(false);
      toast({
        title: 'Folder created',
        description: newFolderName.trim(),
        type: 'success',
      });
    } catch (err) {
      toast({ title: 'Error creating folder', description: (err as Error).message, type: 'error' });
    }
  };

  const handleDeleteFolderConfirm = async () => {
    if (!folderToDelete) return;
    try {
      await deleteFolder(folderToDelete.id);
      toast({
        title: 'Folder deleted',
        description: `"${folderToDelete.name}" deleted. Contained documents moved to Root.`,
        type: 'info',
      });
      setFolderToDelete(null);
      if (selectedFolder?.id === folderToDelete.id) {
        setSelectedFolder(null);
      }
    } catch (err) {
      toast({ title: 'Error deleting folder', description: (err as Error).message, type: 'error' });
    }
  };

  const tabs: { id: DocumentTab; label: string; icon: typeof Files; count?: number }[] = [
    { id: 'all', label: 'All Docs', icon: Files, count: allCount },
    { id: 'folders', label: 'Folders', icon: FolderIcon, count: folders.length },
    { id: 'favorites', label: 'Favorites', icon: Star, count: favoritesCount },
    { id: 'recent', label: 'Recent', icon: Clock },
    { id: 'trash', label: 'Trash', icon: Trash2, count: trashCount },
  ];

  return (
    <div className="w-full flex flex-col gap-5 animate-fade-in">
      {/* 1. Header Toolbar */}
      <div className="flex items-center justify-between">
        <div className="min-w-0 flex-1">
          {selectedFolder ? (
            <div className="flex items-center gap-2">
              <button
                onClick={() => setSelectedFolder(null)}
                className="touch-target p-1 -ml-1 text-muted hover:text-foreground rounded-lg transition-colors"
                aria-label="Back to folders"
              >
                <ArrowLeft className="w-5 h-5" />
              </button>
              <div className="min-w-0">
                <h1 className="text-xl xs:text-2xl font-bold tracking-tight text-foreground truncate">
                  {selectedFolder.name}
                </h1>
                <p className="text-xs text-muted mt-0.5">
                  {documents.length} {documents.length === 1 ? 'document' : 'documents'} in this folder
                </p>
              </div>
            </div>
          ) : (
            <div>
              <h1 className="text-xl xs:text-2xl font-bold tracking-tight text-foreground">
                Documents
              </h1>
              <p className="text-xs text-muted mt-0.5">
                {allCount} offline documents stored locally
              </p>
            </div>
          )}
        </div>

        {/* Action Controls: Import, New Folder & View Toggle */}
        <div className="flex items-center gap-2 shrink-0">
          <button
            onClick={() => setIsImportSheetOpen(true)}
            className="btn-primary text-xs h-9 px-3.5 flex items-center gap-1.5 shadow-sm"
          >
            <Upload className="w-3.5 h-3.5" />
            <span className="hidden xs:inline">Import</span>
          </button>

          <button
            onClick={() => setIsFolderModalOpen(true)}
            className="touch-target px-3 bg-surface hover:bg-surface-secondary text-foreground text-xs font-semibold rounded-xl border border-border transition-all flex items-center gap-1.5 shadow-subtle h-9"
          >
            <FolderPlus className="w-3.5 h-3.5 text-primary" />
            <span className="hidden sm:inline">New Folder</span>
          </button>

          <div className="flex items-center bg-surface border border-border rounded-xl p-0.5 shadow-subtle">
            <button
              onClick={() => setViewMode('list')}
              className={`p-1.5 rounded-lg transition-colors ${
                viewMode === 'list'
                  ? 'bg-primary text-white shadow-sm'
                  : 'text-subtle hover:text-foreground'
              }`}
              aria-label="List view"
            >
              <LayoutList className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('grid')}
              className={`p-1.5 rounded-lg transition-colors ${
                viewMode === 'grid'
                  ? 'bg-primary text-white shadow-sm'
                  : 'text-subtle hover:text-foreground'
              }`}
              aria-label="Grid view"
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* 2. Search & Sort Controls */}
      <div className="flex items-center gap-2 w-full">
        <div className="relative flex-1">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={`Search ${activeTab === 'folders' && !selectedFolder ? 'folders' : 'documents'}...`}
            className="form-input pl-10 pr-10 text-xs xs:text-sm h-10"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-muted hover:text-foreground"
            >
              Clear
            </button>
          )}
        </div>

        {/* Sort Dropdown */}
        <div className="relative shrink-0">
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as DocumentSortOption)}
            className="h-10 bg-surface border border-border rounded-xl px-3 text-xs font-semibold text-foreground focus:outline-none focus:border-primary shadow-subtle cursor-pointer appearance-none pr-7"
            aria-label="Sort documents"
          >
            <option value="modified-desc">Newest</option>
            <option value="modified-asc">Oldest</option>
            <option value="opened-desc">Recently Opened</option>
            <option value="name-asc">Name (A-Z)</option>
            <option value="name-desc">Name (Z-A)</option>
            <option value="size-desc">Largest</option>
            <option value="size-asc">Smallest</option>
          </select>
          <ArrowUpDown className="w-3.5 h-3.5 text-muted absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
        </div>
      </div>

      {/* 3. Horizontal Navigation Tabs (Hidden when inside a folder view) */}
      {!selectedFolder && (
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-1 -mx-4 px-4 select-none">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => {
                  setActiveTab(tab.id);
                  setSelectedFolder(null);
                }}
                className={`touch-target px-3.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all flex items-center gap-2 shrink-0 ${
                  isActive
                    ? 'bg-primary text-white shadow-sm'
                    : 'bg-surface text-muted hover:text-foreground border border-border'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span>{tab.label}</span>
                {typeof tab.count === 'number' && (
                  <span
                    className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                      isActive
                        ? 'bg-white/20 text-white'
                        : 'bg-surface-secondary text-muted'
                    }`}
                  >
                    {tab.count}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      )}

      {/* 4. Tab Content */}
      {activeTab === 'folders' && !selectedFolder ? (
        folders.length > 0 ? (
          <div className="grid grid-cols-1 xs:grid-cols-2 sm:grid-cols-3 gap-3">
            {folders.map((folder) => (
              <div key={folder.id} className="relative group">
                <FolderCard
                  folder={folder}
                  onClick={() => setSelectedFolder(folder)}
                />
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setFolderToDelete(folder);
                  }}
                  className="absolute top-3 right-3 p-1.5 text-muted hover:text-destructive bg-surface hover:bg-destructive-soft rounded-lg border border-border opacity-0 group-hover:opacity-100 transition-opacity"
                  title="Delete Folder"
                  aria-label="Delete Folder"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <EmptyState
            icon={FolderIcon}
            title="No folders yet"
            description="Create folders to categorize your local PDFs and scanned images."
            actionLabel="Create Folder"
            actionIcon={Plus}
            onAction={() => setIsFolderModalOpen(true)}
          />
        )
      ) : activeTab === 'trash' ? (
        documents.length > 0 ? (
          <div className="flex flex-col gap-3">
            <div className="p-3 bg-amber-500/10 border border-amber-500/20 rounded-xl text-xs text-foreground flex items-center justify-between">
              <span>Items in Trash can be restored or permanently removed.</span>
            </div>
            <div
              className={
                viewMode === 'grid'
                  ? 'grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3'
                  : 'flex flex-col gap-2.5'
              }
            >
              {documents.map((doc) => (
                <DocumentCard
                  key={doc.id}
                  document={doc}
                  viewMode={viewMode}
                  onClick={() => setSelectedDoc(doc)}
                  onMoreClick={() => setSelectedDoc(doc)}
                />
              ))}
            </div>
          </div>
        ) : (
          <EmptyState
            icon={Trash2}
            title="Trash is empty"
            description="Deleted documents will appear here before being permanently erased."
          />
        )
      ) : (
        documents.length > 0 ? (
          <div
            className={
              viewMode === 'grid'
                ? 'grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3'
                : 'flex flex-col gap-2.5'
            }
          >
            {documents.map((doc) => (
              <DocumentCard
                key={doc.id}
                document={doc}
                viewMode={viewMode}
                onClick={() => navigate(`/documents/${doc.id}`)}
                onFavoriteToggle={() => handleToggleFavorite(doc)}
                onMoreClick={() => setSelectedDoc(doc)}
              />
            ))}
          </div>
        ) : (
          <EmptyState
            icon={Files}
            title={
              activeTab === 'favorites'
                ? 'No favorite documents'
                : searchQuery
                ? 'No documents found'
                : selectedFolder
                ? 'Folder is empty'
                : 'Your vault is empty'
            }
            description={
              activeTab === 'favorites'
                ? 'Star important documents to quickly access them in this tab.'
                : searchQuery
                ? `No documents match "${searchQuery}".`
                : selectedFolder
                ? 'Import or move documents into this folder.'
                : 'Import a PDF, image, or scan your first document to store it locally.'
            }
            actionLabel={
              activeTab === 'favorites'
                ? 'View All Documents'
                : 'Import Document'
            }
            actionIcon={activeTab === 'favorites' ? undefined : Upload}
            onAction={() =>
              activeTab === 'favorites'
                ? setActiveTab('all')
                : setIsImportSheetOpen(true)
            }
          />
        )
      )}

      {/* Import Document Sheet */}
      <ImportDocumentSheet
        isOpen={isImportSheetOpen}
        onClose={() => setIsImportSheetOpen(false)}
        folderId={selectedFolder?.id}
      />

      {/* New Folder Modal */}
      <Modal
        isOpen={isFolderModalOpen}
        onClose={() => setIsFolderModalOpen(false)}
        title="Create New Folder"
        description="Organize your documents by category or client."
      >
        <form onSubmit={handleCreateFolder} className="flex flex-col gap-4">
          <div>
            <label className="block text-xs font-semibold text-foreground mb-1.5">
              Folder Name
            </label>
            <input
              type="text"
              required
              autoFocus
              value={newFolderName}
              onChange={(e) => setNewFolderName(e.target.value)}
              placeholder="e.g., Invoices 2026"
              className="form-input"
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setIsFolderModalOpen(false)}
              className="btn-secondary text-xs h-10 px-4"
            >
              Cancel
            </button>
            <button type="submit" className="btn-primary text-xs h-10 px-5">
              Create Folder
            </button>
          </div>
        </form>
      </Modal>

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

      {/* Move Document Modal */}
      <Modal
        isOpen={!!docToMove}
        onClose={() => setDocToMove(null)}
        title="Move to Folder"
        description={`Select destination folder for "${docToMove?.title}".`}
      >
        <form onSubmit={handleMoveSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-2 max-h-60 overflow-y-auto">
            <label
              className={`p-3 rounded-xl border flex items-center gap-3 cursor-pointer transition-colors ${
                targetFolderId === 'root'
                  ? 'border-primary bg-primary-soft'
                  : 'border-border bg-surface hover:bg-surface-secondary'
              }`}
            >
              <input
                type="radio"
                name="targetFolder"
                value="root"
                checked={targetFolderId === 'root'}
                onChange={() => setTargetFolderId('root')}
                className="hidden"
              />
              <Files className="w-4 h-4 text-primary" />
              <span className="text-xs font-semibold text-foreground">Root (No Folder)</span>
            </label>

            {folders.map((folder) => (
              <label
                key={folder.id}
                className={`p-3 rounded-xl border flex items-center gap-3 cursor-pointer transition-colors ${
                  targetFolderId === folder.id
                    ? 'border-primary bg-primary-soft'
                    : 'border-border bg-surface hover:bg-surface-secondary'
                }`}
              >
                <input
                  type="radio"
                  name="targetFolder"
                  value={folder.id}
                  checked={targetFolderId === folder.id}
                  onChange={() => setTargetFolderId(folder.id)}
                  className="hidden"
                />
                <FolderIcon className="w-4 h-4 text-primary" />
                <span className="text-xs font-semibold text-foreground">{folder.name}</span>
              </label>
            ))}
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setDocToMove(null)}
              className="btn-secondary text-xs h-10 px-4"
            >
              Cancel
            </button>
            <button type="submit" className="btn-primary text-xs h-10 px-5">
              Move Document
            </button>
          </div>
        </form>
      </Modal>

      {/* Permanent Delete Confirmation Dialog */}
      <Modal
        isOpen={!!docToDeletePermanent}
        onClose={() => setDocToDeletePermanent(null)}
        title="Delete Permanently?"
        description="This document and its local files will be permanently removed from this device. This action cannot be undone."
      >
        <div className="flex items-center justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={() => setDocToDeletePermanent(null)}
            className="btn-secondary text-xs h-10 px-4"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={handlePermanentDelete}
            className="touch-target px-5 h-10 bg-destructive hover:bg-destructive/90 text-white text-xs font-semibold rounded-xl transition-all shadow-sm"
          >
            Delete Permanently
          </button>
        </div>
      </Modal>

      {/* Delete Folder Confirmation Dialog */}
      <Modal
        isOpen={!!folderToDelete}
        onClose={() => setFolderToDelete(null)}
        title={`Delete folder "${folderToDelete?.name}"?`}
        description="Documents inside this folder will be safely moved to the Root folder. No documents will be deleted."
      >
        <div className="flex items-center justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={() => setFolderToDelete(null)}
            className="btn-secondary text-xs h-10 px-4"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={handleDeleteFolderConfirm}
            className="touch-target px-5 h-10 bg-destructive hover:bg-destructive/90 text-white text-xs font-semibold rounded-xl transition-all shadow-sm"
          >
            Delete Folder
          </button>
        </div>
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
        onMove={(doc) => {
          setDocToMove(doc);
          setTargetFolderId(doc.folderId || 'root');
        }}
        onToggleFavorite={handleToggleFavorite}
        onDuplicate={handleDuplicate}
        onDownload={handleDownload}
        onDelete={handleSoftDelete}
        onRestore={handleRestore}
        onPermanentDelete={(doc) => setDocToDeletePermanent(doc)}
      />
    </div>
  );
}
