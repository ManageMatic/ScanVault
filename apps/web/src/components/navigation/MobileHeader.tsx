import { ShieldCheck, User } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '@/lib/auth';

export function MobileHeader() {
  const { user } = useAuth();

  return (
    <header className="sticky top-0 z-40 w-full bg-[hsl(var(--surface))]/90 backdrop-blur-md border-b border-border pt-safe select-none">
      <div className="w-full max-w-5xl mx-auto px-4 h-14 flex items-center justify-between">
        {/* Logo & Workspace Title */}
        <Link to="/" className="flex items-center gap-2.5 active:opacity-80 transition-opacity">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-indigo-500 to-indigo-700 border border-indigo-400/30 flex items-center justify-center text-white shadow-md shadow-indigo-500/20">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-extrabold text-base tracking-tight text-foreground">
                ScanVault
              </span>
              <span className="text-[10px] font-bold uppercase tracking-wider text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded border border-indigo-500/20">
                PWA
              </span>
            </div>
          </div>
        </Link>

        {/* Right Action Items */}
        <div className="flex items-center gap-2">
          {/* Offline Air-Gapped Status */}
          <div className="hidden xs:flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
            <span>Offline Ready</span>
          </div>

          {/* User Profile / Settings Shortcut */}
          <Link
            to="/settings"
            className="touch-target p-1.5 rounded-xl bg-surface-secondary border border-border text-muted-foreground hover:text-foreground transition-colors flex items-center gap-2"
            aria-label="Account Settings"
          >
            {user?.avatarUrl ? (
              <img
                src={user.avatarUrl}
                alt={user.name || user.email}
                className="w-6 h-6 rounded-lg object-cover"
              />
            ) : user ? (
              <div className="w-6 h-6 rounded-lg bg-indigo-500/20 text-indigo-400 font-bold text-xs flex items-center justify-center border border-indigo-500/30">
                {(user.name?.[0] || user.email?.[0] || 'U').toUpperCase()}
              </div>
            ) : (
              <User className="w-4 h-4 text-muted-foreground" />
            )}
          </Link>
        </div>
      </div>
    </header>
  );
}
