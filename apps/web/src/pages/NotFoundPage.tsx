import { Link } from 'react-router-dom';
import { Home, FileQuestion } from 'lucide-react';

export function NotFoundPage() {
  return (
    <div className="flex-1 w-full flex items-center justify-center py-12">
      <div className="w-full max-w-md bg-vault-card border border-vault-border rounded-2xl p-6 text-center shadow-xl">
        <div className="w-14 h-14 bg-slate-800 border border-slate-700 text-slate-400 rounded-full flex items-center justify-center mx-auto mb-4">
          <FileQuestion className="w-7 h-7" />
        </div>
        <h2 className="text-xl font-bold text-white mb-1">Page Not Found</h2>
        <p className="text-xs text-slate-400 mb-6">
          The page or vault location you are looking for does not exist.
        </p>
        <Link
          to="/"
          className="touch-target w-full bg-brand-500 hover:bg-brand-600 active:scale-95 text-white text-xs font-semibold rounded-xl transition-all flex items-center justify-center gap-2 shadow-lg shadow-brand-500/20"
        >
          <Home className="w-4 h-4" />
          Back to Workspace
        </Link>
      </div>
    </div>
  );
}
