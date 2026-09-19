import {
  FileText,
  Edit2,
  FolderInput,
  Star,
  Copy,
  Download,
  Trash2,
  RotateCcw,
} from 'lucide-react';
import type { LocalDocument } from '@/lib/db';
import { BottomSheet } from '@/components/ui/BottomSheet';
import { formatBytes } from '@/lib/mockData';

interface DocumentActionSheetProps {
  document: LocalDocument | null;
  isOpen: boolean;
  onClose: () => void;
  onOpenDoc: (doc: LocalDocument) => void;
  onRename?: (doc: LocalDocument) => void;
  onMove?: (doc: LocalDocument) => void;
  onToggleFavorite?: (doc: LocalDocument) => void;
  onDuplicate?: (doc: LocalDocument) => void;
  onDownload?: (doc: LocalDocument) => void;
  onDelete?: (doc: LocalDocument) => void;
  onRestore?: (doc: LocalDocument) => void;
  onPermanentDelete?: (doc: LocalDocument) => void;
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
  onDownload,
  onDelete,
  onRestore,
  onPermanentDelete,
}: DocumentActionSheetProps) {
  if (!document) return null;

  const isTrash = !!document.deletedAt;
  const fileSize = document.size ?? (document as unknown as { sizeBytes?: number }).sizeBytes ?? 0;

  const actions = isTrash
    ? [
        {
          id: 'restore',
          label: 'Restore Document',
          icon: RotateCcw,
          onClick: () => {
            onClose();
            onRestore?.(document);
          },
        },
        {
          id: 'permanent-delete',
          label: 'Delete Permanently',
          icon: Trash2,
          isDestructive: true,
          onClick: () => {
            onClose();
            onPermanentDelete?.(document);
          },
        },
      ]
    : [
        {
          id: 'open',
          label: 'Open Document',
          icon: FileText,
          onClick: () => {
            onClose();
            onOpenDoc(document);
          },
        },
        ...(onRename
          ? [
              {
                id: 'rename',
                label: 'Rename Document',
                icon: Edit2,
                onClick: () => {
                  onClose();
                  onRename(document);
                },
              },
            ]
          : []),
        ...(onMove
          ? [
              {
                id: 'move',
                label: 'Move to Folder',
                icon: FolderInput,
                onClick: () => {
                  onClose();
                  onMove(document);
                },
              },
            ]
          : []),
        ...(onToggleFavorite
          ? [
              {
                id: 'favorite',
                label: document.favorite ? 'Remove from Favorites' : 'Add to Favorites',
                icon: Star,
                iconClass: document.favorite ? 'fill-amber-500 text-amber-500' : '',
                onClick: () => {
                  onClose();
                  onToggleFavorite(document);
                },
              },
            ]
          : []),
        ...(onDuplicate
          ? [
              {
                id: 'duplicate',
                label: 'Duplicate Document',
                icon: Copy,
                onClick: () => {
                  onClose();
                  onDuplicate(document);
                },
              },
            ]
          : []),
        ...(onDownload
          ? [
              {
                id: 'download',
                label: 'Download / Save Copy',
                icon: Download,
                onClick: () => {
                  onClose();
                  onDownload(document);
                },
              },
            ]
          : []),
        ...(onDelete
          ? [
              {
                id: 'delete',
                label: 'Move to Trash',
                icon: Trash2,
                isDestructive: true,
                onClick: () => {
                  onClose();
                  onDelete(document);
                },
              },
            ]
          : []),
      ];

  return (
    <BottomSheet
      isOpen={isOpen}
      onClose={onClose}
      title={document.title}
      description={`${document.pageCount} ${document.pageCount === 1 ? 'page' : 'pages'} • ${formatBytes(fileSize)}`}
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
                  ? 'text-destructive hover:bg-destructive-soft'
                  : 'text-foreground hover:bg-surface-secondary'
              }`}
            >
              <div
                className={`p-2 rounded-lg ${
                  action.isDestructive
                    ? 'bg-destructive-soft text-destructive'
                    : 'bg-surface-secondary text-muted'
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
