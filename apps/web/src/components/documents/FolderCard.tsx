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
      className="group w-full bg-surface border border-border hover:border-primary/50 rounded-xl p-3.5 flex items-center justify-between shadow-sm hover:shadow transition-all cursor-pointer active:scale-[0.99] select-none"
    >
      <div className="flex items-center gap-3 min-w-0">
        <div
          className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-sm"
          style={{
            backgroundColor: `${folder.color || '#008378'}15`,
            color: folder.color || '#008378',
            border: `1px solid ${folder.color || '#008378'}30`,
          }}
        >
          <FolderIcon className="w-5 h-5 fill-current" />
        </div>
        <div className="min-w-0">
          <h4 className="text-xs xs:text-sm font-semibold text-foreground truncate group-hover:text-primary transition-colors">
            {folder.name}
          </h4>
          <p className="text-[11px] text-muted-foreground mt-0.5">
            {folder.documentCount} {folder.documentCount === 1 ? 'document' : 'documents'}
          </p>
        </div>
      </div>

      <ChevronRight className="w-4 h-4 text-muted-foreground group-hover:text-foreground transition-colors shrink-0" />
    </div>
  );
}
