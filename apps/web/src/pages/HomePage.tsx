import { useState } from 'react';
import { Search, Camera, Plus, ArrowRight, FolderPlus, Wrench, HardDrive } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { INITIAL_MOCK_DOCUMENTS, PDF_TOOLS } from '@/lib/mockData';
import type { MockDocument } from '@/types/ui';
import { DocumentCard } from '@/components/documents/DocumentCard';
import { DocumentActionSheet } from '@/components/documents/DocumentActionSheet';
import { EmptyState } from '@/components/ui/EmptyState';
import { useToast } from '@/lib/toast';
import { useAuth } from '@/lib/auth';

export function HomePage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { user } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
  const [documents, setDocuments] = useState<MockDocument[]>(INITIAL_MOCK_DOCUMENTS);
  const [selectedDoc, setSelectedDoc] = useState<MockDocument | null>(null);

  const greeting = (() => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  })();

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
    <div className="w-full flex flex-col gap-6 animate-fade-in">
      {/* 1. Header Greeting & User Bar */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl xs:text-2xl font-bold tracking-tight text-foreground">
            {greeting}{user?.name ? `, ${user.name.split(' ')[0]}` : ''}
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
          placeholder="Search documents, tags, or notes..."
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

          <Link
            to="/scan"
            className="btn-primary w-full xs:w-auto shrink-0 flex items-center justify-center gap-2 shadow-sm"
          >
            <Camera className="w-4 h-4" />
            <span>Scan Document</span>
          </Link>
        </div>
      )}

      {/* 4. Quick Actions Ribbon */}
      {!searchQuery && (
        <div className="grid grid-cols-2 xs:grid-cols-4 gap-3">
          <Link
            to="/scan"
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3.5 flex flex-col items-center justify-center text-center shadow-subtle transition-all active:scale-[0.98]"
          >
            <div className="w-9 h-9 rounded-xl bg-primary-soft text-primary flex items-center justify-center mb-1.5">
              <Plus className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">New Scan</span>
            <span className="text-[10px] text-muted">Camera/Upload</span>
          </Link>

          <Link
            to="/documents"
            className="bg-surface hover:bg-surface-secondary border border-border rounded-xl p-3.5 flex flex-col items-center justify-center text-center shadow-subtle transition-all active:scale-[0.98]"
          >
            <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center mb-1.5">
              <FolderPlus className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">All Vault</span>
            <span className="text-[10px] text-muted">5 Documents</span>
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

          <div className="bg-surface border border-border rounded-xl p-3.5 flex flex-col items-center justify-center text-center shadow-subtle">
            <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-1.5 font-mono text-xs font-bold">
              <HardDrive className="w-4 h-4" />
            </div>
            <span className="text-xs font-semibold text-foreground">Local Vault</span>
            <span className="text-[10px] text-muted">17 MB Used</span>
          </div>
        </div>
      )}

      {/* 5. Recent Documents Section */}
      <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold text-foreground tracking-tight">
            {searchQuery ? `Search Results (${filteredDocs.length})` : 'Recent Documents'}
          </h3>
          {!searchQuery && (
            <Link
              to="/documents"
              className="text-xs font-semibold text-primary hover:text-primary-hover flex items-center gap-1"
            >
              <span>View All</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          )}
        </div>

        {filteredDocs.length > 0 ? (
          <div className="flex flex-col gap-2.5">
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
