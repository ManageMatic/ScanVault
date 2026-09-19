import { useState } from 'react';
import { Search, Camera, Plus, ArrowRight, Sparkles, FolderPlus, Wrench } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { INITIAL_MOCK_DOCUMENTS, PDF_TOOLS } from '@/lib/mockData';
import type { MockDocument } from '@/types/ui';
import { DocumentCard } from '@/components/documents/DocumentCard';
import { DocumentActionSheet } from '@/components/documents/DocumentActionSheet';
import { EmptyState } from '@/components/ui/EmptyState';
import { useToast } from '@/lib/toast';

export function HomePage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [documents, setDocuments] = useState<MockDocument[]>(INITIAL_MOCK_DOCUMENTS);
  const [selectedDoc, setSelectedDoc] = useState<MockDocument | null>(null);

  const filteredDocs = documents.filter((doc) =>
    doc.title.toLowerCase().includes(searchQuery.toLowerCase().trim())
  );

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

  return (
    <div className="w-full flex flex-col gap-6">
      {/* 1. Mobile Search Bar Entry */}
      <div className="relative w-full">
        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search documents, tags, or notes..."
          className="touch-target w-full bg-surface border border-border rounded-xl pl-10 pr-4 text-xs xs:text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 transition-all shadow-sm"
        />
        {searchQuery && (
          <button
            onClick={() => setSearchQuery('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-muted-foreground hover:text-foreground font-medium p-1"
          >
            Clear
          </button>
        )}
      </div>

      {/* 2. Hero Scan Banner & Primary CTA */}
      {!searchQuery && (
        <div className="w-full bg-gradient-to-br from-surface via-surface to-primary-subtle/30 border border-border rounded-2xl p-5 xs:p-6 shadow-md relative overflow-hidden">
          <div className="relative z-10 flex flex-col xs:flex-row items-start xs:items-center justify-between gap-4">
            <div>
              <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-primary/10 text-primary border border-primary/20 mb-2">
                <Sparkles className="w-3 h-3" />
                Mobile Workspace
              </div>
              <h2 className="text-xl xs:text-2xl font-extrabold tracking-tight text-foreground">
                Capture & Organize
              </h2>
              <p className="text-xs text-muted-foreground mt-1 max-w-sm">
                Your documents, air-gapped and ready anytime offline.
              </p>
            </div>

            {/* Big Primary Scan Button */}
            <Link
              to="/scan"
              className="touch-target-lg w-full xs:w-auto px-6 bg-primary text-primary-foreground hover:opacity-90 active:scale-95 text-xs xs:text-sm font-bold rounded-xl shadow-lg shadow-primary/20 transition-all flex items-center justify-center gap-2.5 shrink-0"
            >
              <Camera className="w-5 h-5" />
              <span>Scan Document</span>
            </Link>
          </div>
        </div>
      )}

      {/* 3. Quick Action Ribbon */}
      {!searchQuery && (
        <div className="grid grid-cols-2 xs:grid-cols-4 gap-2.5">
          <Link
            to="/scan"
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3 flex flex-col items-center justify-center text-center transition-all active:scale-[0.98] shadow-sm"
          >
            <div className="w-9 h-9 rounded-xl bg-primary/10 text-primary flex items-center justify-center mb-1.5">
              <Plus className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">New Scan</span>
            <span className="text-[10px] text-muted-foreground">Camera/Upload</span>
          </Link>

          <Link
            to="/documents"
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3 flex flex-col items-center justify-center text-center transition-all active:scale-[0.98] shadow-sm"
          >
            <div className="w-9 h-9 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center mb-1.5">
              <FolderPlus className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">All Vault</span>
            <span className="text-[10px] text-muted-foreground">5 Documents</span>
          </Link>

          <Link
            to="/tools"
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3 flex flex-col items-center justify-center text-center transition-all active:scale-[0.98] shadow-sm"
          >
            <div className="w-9 h-9 rounded-xl bg-amber-500/10 text-amber-500 flex items-center justify-center mb-1.5">
              <Wrench className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">PDF Studio</span>
            <span className="text-[10px] text-muted-foreground">8 Utilities</span>
          </Link>

          <div className="bg-surface border border-border rounded-xl p-3 flex flex-col items-center justify-center text-center shadow-sm">
            <div className="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-1.5 font-mono text-xs font-bold">
              17MB
            </div>
            <span className="text-xs font-semibold text-foreground">Vault Size</span>
            <span className="text-[10px] text-muted-foreground">Local Storage</span>
          </div>
        </div>
      )}

      {/* 4. Recent Documents Section */}
      <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold text-foreground tracking-tight">
            {searchQuery ? `Search Results (${filteredDocs.length})` : 'Recent Documents'}
          </h3>
          {!searchQuery && (
            <Link
              to="/documents"
              className="text-xs font-semibold text-primary hover:underline flex items-center gap-1"
            >
              <span>View All</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          )}
        </div>

        {filteredDocs.length > 0 ? (
          <div className="flex flex-col gap-2">
            {filteredDocs.map((doc) => (
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
            title="No documents found"
            description={
              searchQuery
                ? `No documents match "${searchQuery}". Try a different keyword.`
                : 'Your vault is empty. Capture your first document now.'
            }
            actionLabel={searchQuery ? 'Clear Search' : 'Scan First Document'}
            onAction={() => (searchQuery ? setSearchQuery('') : navigate('/scan'))}
          />
        )}
      </div>

      {/* 5. Featured PDF Studio Tools */}
      {!searchQuery && (
        <div className="flex flex-col gap-3 pt-2">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-foreground tracking-tight">
              Featured PDF Tools
            </h3>
            <Link
              to="/tools"
              className="text-xs font-semibold text-primary hover:underline flex items-center gap-1"
            >
              <span>Explore All</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="grid grid-cols-1 xs:grid-cols-2 gap-2.5">
            {PDF_TOOLS.slice(0, 4).map((tool) => (
              <Link
                key={tool.id}
                to="/tools"
                className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3.5 flex items-start gap-3 transition-all active:scale-[0.99] shadow-sm"
              >
                <div className="w-8 h-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center shrink-0 mt-0.5">
                  <Wrench className="w-4 h-4" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between">
                    <h4 className="text-xs font-bold text-foreground truncate">
                      {tool.title}
                    </h4>
                    {tool.badge && (
                      <span className="text-[9px] font-bold text-primary bg-primary/10 px-1.5 py-0.2 rounded">
                        {tool.badge}
                      </span>
                    )}
                  </div>
                  <p className="text-[11px] text-muted-foreground mt-0.5 line-clamp-1">
                    {tool.description}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* Contextual Action Sheet */}
      <DocumentActionSheet
        document={selectedDoc}
        isOpen={!!selectedDoc}
        onClose={() => setSelectedDoc(null)}
        onOpenDoc={(doc) => navigate(`/documents/${doc.id}`)}
        onRename={(doc) =>
          toast({ title: 'Rename action', description: doc.title, type: 'info' })
        }
        onMove={(doc) =>
          toast({ title: 'Move to folder', description: doc.title, type: 'info' })
        }
        onToggleFavorite={handleToggleFavorite}
        onDuplicate={(doc) =>
          toast({ title: 'Document duplicated', description: doc.title, type: 'success' })
        }
        onShare={(doc) =>
          toast({ title: 'Ready to share PDF', description: doc.title, type: 'info' })
        }
        onDelete={handleDelete}
      />
    </div>
  );
}
