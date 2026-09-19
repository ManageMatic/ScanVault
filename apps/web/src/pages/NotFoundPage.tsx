import { Link } from 'react-router-dom';
import { Home, FileQuestion } from 'lucide-react';

export function NotFoundPage() {
  return (
    <div className="flex-1 w-full flex items-center justify-center py-12 animate-fade-in">
      <div className="w-full max-w-md bg-surface border border-border rounded-2xl p-6 text-center shadow-subtle">
        <div className="w-14 h-14 bg-surface-secondary border border-border text-subtle rounded-2xl flex items-center justify-center mx-auto mb-4">
          <FileQuestion className="w-7 h-7" />
        </div>
        <h2 className="text-xl font-bold text-foreground mb-1">Page Not Found</h2>
        <p className="text-xs text-muted mb-6">
          The page or document location you are looking for does not exist.
        </p>
        <Link
          to="/"
          className="btn-primary w-full flex items-center justify-center gap-2"
        >
          <Home className="w-4 h-4" />
          <span>Back to Workspace</span>
        </Link>
      </div>
    </div>
  );
}
