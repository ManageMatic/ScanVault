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
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { INITIAL_MOCK_DOCUMENTS, INITIAL_MOCK_FOLDERS } from '@/lib/mockData';
import type { MockDocument, MockFolder, DocumentTab, ViewMode } from '@/types/ui';
import { DocumentCard } from '@/components/documents/DocumentCard';
import { FolderCard } from '@/components/documents/FolderCard';
import { DocumentActionSheet } from '@/components/documents/DocumentActionSheet';
import { Modal } from '@/components/ui/Modal';
import { EmptyState } from '@/components/ui/EmptyState';
import { useToast } from '@/lib/toast';

export function DocumentsPage() {
  const navigate = useNavigate();
  const { toast } = useToast();

  const [activeTab, setActiveTab] = useState<DocumentTab>('all');
  const [viewMode, setViewMode] = useState<ViewMode>('list');
  const [searchQuery, setSearchQuery] = useState('');
  const [documents, setDocuments] = useState<MockDocument[]>(INITIAL_MOCK_DOCUMENTS);
  const [folders, setFolders] = useState<MockFolder[]>(INITIAL_MOCK_FOLDERS);
  const [selectedDoc, setSelectedDoc] = useState<MockDocument | null>(null);

  // New folder modal state
  const [isFolderModalOpen, setIsFolderModalOpen] = useState(false);
  const [newFolderName, setNewFolderName] = useState('');

  // Filter documents based on activeTab and searchQuery
  const filteredDocuments = documents.filter((doc) => {
    const matchesSearch = doc.title.toLowerCase().includes(searchQuery.toLowerCase().trim());
    if (!matchesSearch) return false;

    if (activeTab === 'favorites') return doc.favorite;
    if (activeTab === 'recent') return true;
    if (activeTab === 'trash') return false;
    return true;
  });

  const handleToggleFavorite = (doc: MockDocument) => {
    setDocuments((prev) =>
      prev.map((d) => (d.id === doc.id ? { ...d, favorite: !d.favorite } : d))
    );
    toast({
      title: doc.favorite ? 'Removed from favorites' : 'Added to favorites',
      description: doc.title,
      type: 'success',
    });
  };

  const handleDelete = (doc: MockDocument) => {
    setDocuments((prev) => prev.filter((d) => d.id !== doc.id));
    toast({
      title: 'Document moved to trash',
      description: doc.title,
      type: 'info',
    });
  };

  const handleCreateFolder = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newFolderName.trim()) return;

    const newFolder: MockFolder = {
      id: `folder-${Date.now()}`,
      name: newFolderName.trim(),
      documentCount: 0,
      color: '#4F46E5',
      createdAt: new Date().toISOString(),
    };

    setFolders((prev) => [...prev, newFolder]);
    setNewFolderName('');
    setIsFolderModalOpen(false);
    toast({
      title: 'Folder created',
      description: newFolder.name,
      type: 'success',
    });
  };

  const tabs: { id: DocumentTab; label: string; icon: typeof Files; count?: number }[] = [
    { id: 'all', label: 'All Docs', icon: Files, count: documents.length },
    { id: 'folders', label: 'Folders', icon: FolderIcon, count: folders.length },
    { id: 'favorites', label: 'Favorites', icon: Star, count: documents.filter((d) => d.favorite).length },
    { id: 'recent', label: 'Recent', icon: Clock },
    { id: 'trash', label: 'Trash', icon: Trash2 },
  ];

  return (
    <div className="w-full flex flex-col gap-5 animate-fade-in">
      {/* 1. Header Toolbar */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl xs:text-2xl font-bold tracking-tight text-foreground">
            Documents
          </h1>
          <p className="text-xs text-muted mt-0.5">
            {documents.length} offline documents stored locally
          </p>
        </div>

        {/* Action Controls: New Folder & View Toggle */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsFolderModalOpen(true)}
            className="touch-target px-3.5 bg-surface hover:bg-surface-secondary text-foreground text-xs font-semibold rounded-xl border border-border transition-all flex items-center gap-1.5 shadow-subtle"
          >
            <FolderPlus className="w-4 h-4 text-primary" />
            <span className="hidden xs:inline">New Folder</span>
          </button>

          <div className="flex items-center bg-surface border border-border rounded-xl p-0.5 shadow-subtle">
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded-lg transition-colors ${
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
              className={`p-2 rounded-lg transition-colors ${
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

      {/* 2. Search Filter */}
      <div className="relative w-full">
        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder={`Search ${activeTab === 'folders' ? 'folders' : 'documents'}...`}
          className="form-input pl-10 text-xs xs:text-sm"
        />
      </div>

      {/* 3. Horizontal Navigation Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-1 -mx-4 px-4 select-none">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
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

      {/* 4. Tab Content */}
      {activeTab === 'folders' ? (
        folders.length > 0 ? (
          <div className="grid grid-cols-1 xs:grid-cols-2 gap-3">
            {folders.map((folder) => (
              <FolderCard
                key={folder.id}
                folder={folder}
                onClick={() =>
                  toast({
                    title: `Folder: ${folder.name}`,
                    description: `${folder.documentCount} documents inside`,
                    type: 'info',
                  })
                }
              />
            ))}
          </div>
        ) : (
          <EmptyState
            icon={FolderIcon}
            title="No folders yet"
            description="Create folders to group and categorize your scanned documents."
            actionLabel="Create Folder"
            actionIcon={Plus}
            onAction={() => setIsFolderModalOpen(true)}
          />
        )
      ) : activeTab === 'trash' ? (
        <EmptyState
          icon={Trash2}
          title="Trash is empty"
          description="Deleted documents will appear here before being permanently removed."
        />
      ) : (
        filteredDocuments.length > 0 ? (
          <div
            className={
              viewMode === 'grid'
                ? 'grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3'
                : 'flex flex-col gap-2.5'
            }
          >
            {filteredDocuments.map((doc) => (
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
            title={activeTab === 'favorites' ? 'No favorite documents' : 'No documents found'}
            description={
              activeTab === 'favorites'
                ? 'Star important documents to quickly access them in this tab.'
                : searchQuery
                ? `No documents match "${searchQuery}".`
                : 'Your vault is empty. Scan your first document now.'
            }
            actionLabel={activeTab === 'favorites' ? 'View All Documents' : 'Scan Document'}
            onAction={() => (activeTab === 'favorites' ? setActiveTab('all') : navigate('/scan'))}
          />
        )
      )}

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
            <button
              type="submit"
              className="btn-primary text-xs h-10 px-5"
            >
              Create Folder
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
        onRename={(doc) =>
          toast({ title: 'Rename document', description: doc.title, type: 'info' })
        }
        onMove={(doc) =>
          toast({ title: 'Move to folder', description: doc.title, type: 'info' })
        }
        onToggleFavorite={handleToggleFavorite}
        onDuplicate={(doc) =>
          toast({ title: 'Document duplicated', description: doc.title, type: 'success' })
        }
        onShare={(doc) =>
          toast({ title: 'Sharing PDF', description: doc.title, type: 'info' })
        }
        onDelete={handleDelete}
      />
    </div>
  );
}
