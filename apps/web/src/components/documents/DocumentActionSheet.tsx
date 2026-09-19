import {
  FileText,
  Edit2,
  FolderInput,
  Star,
  Copy,
  Share2,
  Trash2,
} from 'lucide-react';
import type { MockDocument } from '@/types/ui';
import { BottomSheet } from '@/components/ui/BottomSheet';
import { formatBytes } from '@/lib/mockData';

interface DocumentActionSheetProps {
  document: MockDocument | null;
  isOpen: boolean;
  onClose: () => void;
  onOpenDoc: (doc: MockDocument) => void;
  onRename: (doc: MockDocument) => void;
  onMove: (doc: MockDocument) => void;
  onToggleFavorite: (doc: MockDocument) => void;
  onDuplicate: (doc: MockDocument) => void;
  onShare: (doc: MockDocument) => void;
  onDelete: (doc: MockDocument) => void;
}

export function DocumentActionSheet({
  document,
  isOpen,
  onClose,
  onOpenDoc,
  onRename,
  onMove,
  onToggleFavorite,
  onDuplicate,
  onShare,
  onDelete,
}: DocumentActionSheetProps) {
  if (!document) return null;

  const actions = [
    {
      id: 'open',
      label: 'Open Document',
      icon: FileText,
      onClick: () => {
        onClose();
        onOpenDoc(document);
      },
    },
    {
      id: 'rename',
      label: 'Rename Document',
      icon: Edit2,
      onClick: () => {
        onClose();
        onRename(document);
      },
    },
    {
      id: 'move',
      label: 'Move to Folder',
      icon: FolderInput,
      onClick: () => {
        onClose();
        onMove(document);
      },
    },
    {
      id: 'favorite',
      label: document.favorite ? 'Remove from Favorites' : 'Add to Favorites',
      icon: Star,
      iconClass: document.favorite ? 'fill-amber-400 text-amber-400' : '',
      onClick: () => {
        onClose();
        onToggleFavorite(document);
      },
    },
    {
      id: 'duplicate',
      label: 'Duplicate Document',
      icon: Copy,
      onClick: () => {
        onClose();
        onDuplicate(document);
      },
    },
    {
      id: 'share',
      label: 'Share / Export PDF',
      icon: Share2,
      onClick: () => {
        onClose();
        onShare(document);
      },
    },
    {
      id: 'delete',
      label: 'Delete Document',
      icon: Trash2,
      isDestructive: true,
      onClick: () => {
        onClose();
        onDelete(document);
      },
    },
  ];

  return (
    <BottomSheet
      isOpen={isOpen}
      onClose={onClose}
      title={document.title}
      description={`${document.pageCount} pages • ${formatBytes(document.sizeBytes)}`}
    >
      <div className="flex flex-col gap-1 -mx-2">
        {actions.map((action) => {
          const Icon = action.icon;
          return (
            <button
              key={action.id}
              onClick={action.onClick}
              className={`touch-target-lg w-full px-4 rounded-xl flex items-center gap-3.5 text-xs font-semibold transition-all active:scale-[0.98] ${
                action.isDestructive
                  ? 'text-destructive hover:bg-destructive/10'
                  : 'text-foreground hover:bg-surface-secondary'
              }`}
            >
              <div
                className={`p-2 rounded-lg ${
                  action.isDestructive
                    ? 'bg-destructive/10 text-destructive'
                    : 'bg-surface-secondary text-muted-foreground'
                }`}
              >
                <Icon className={`w-4 h-4 ${action.iconClass || ''}`} />
              </div>
              <span className="flex-1 text-left">{action.label}</span>
            </button>
          );
        })}
      </div>
    </BottomSheet>
  );
}
