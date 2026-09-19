import { Folder as FolderIcon, ChevronRight } from 'lucide-react';
import type { MockFolder } from '@/types/ui';

interface FolderCardProps {
  folder: MockFolder;
  onClick?: () => void;
}

export function FolderCard({ folder, onClick }: FolderCardProps) {
  return (
    <div
      onClick={onClick}
      className="group w-full bg-surface border border-border hover:border-primary/40 rounded-xl p-3.5 flex items-center justify-between shadow-subtle hover:shadow-card transition-all cursor-pointer select-none"
    >
      <div className="flex items-center gap-3 min-w-0">
        <div className="w-10 h-10 rounded-xl bg-primary-soft text-primary flex items-center justify-center shrink-0 border border-primary/10">
          <FolderIcon className="w-5 h-5 fill-current opacity-80" />
        </div>
        <div className="min-w-0">
          <h4 className="text-xs xs:text-sm font-semibold text-foreground truncate group-hover:text-primary transition-colors">
            {folder.name}
          </h4>
          <p className="text-[11px] text-muted mt-0.5">
            {folder.documentCount} {folder.documentCount === 1 ? 'document' : 'documents'}
          </p>
        </div>
      </div>

      <ChevronRight className="w-4 h-4 text-subtle group-hover:text-foreground transition-colors shrink-0" />
    </div>
  );
}
