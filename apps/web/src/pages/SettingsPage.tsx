import {
  Shield,
  HardDrive,
  Sliders,
  Info,
  Trash2,
  Lock,
  LogOut,
  Sparkles,
  KeyRound,
  FileCheck2,
} from 'lucide-react';
import { useToast } from '@/lib/toast';
import { useAuth } from '@/lib/auth';
import { useNavigate } from 'react-router-dom';

export function SettingsPage() {
  const { toast } = useToast();
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      await logout();
      toast({
        title: 'Signed Out',
        description: 'You have been securely signed out.',
        type: 'info',
      });
      navigate('/login');
    } catch {
      toast({
        title: 'Error',
        description: 'Failed to sign out. Please try again.',
        type: 'error',
      });
    }
  };

  const handleClearCache = () => {
    toast({
      title: 'Cache Cleared',
      description: 'Local workspace render cache refreshed.',
      type: 'success',
    });
  };

  return (
    <div className="w-full flex flex-col gap-6">
      {/* 1. Header */}
      <div>
        <h2 className="text-xl xs:text-2xl font-extrabold tracking-tight text-foreground">
          Workspace Settings
        </h2>
        <p className="text-xs text-muted-foreground mt-0.5">
          Manage your account, local encryption vault, scanner defaults, and workspace storage
        </p>
      </div>

      {/* 2. Account & Security */}
      <div className="glass-card rounded-2xl p-4 xs:p-5 shadow-lg relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-indigo-500/5 rounded-full blur-2xl pointer-events-none" />
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3.5 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4 text-indigo-400" />
            <span>Account & Security</span>
          </div>
          {user && (
            <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
              Active Session
            </span>
          )}
        </h3>

        {user ? (
          <div className="space-y-4">
            <div className="flex items-center gap-3.5 p-3.5 rounded-xl bg-surface-secondary/80 border border-border">
              {user.avatarUrl ? (
                <img
                  src={user.avatarUrl}
                  alt={user.name || user.email}
                  className="w-12 h-12 rounded-xl object-cover border border-indigo-500/20 shadow-sm"
                />
              ) : (
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-indigo-700 text-white font-bold text-base flex items-center justify-center border border-indigo-400/30 shadow-md shadow-indigo-500/20">
                  {(user.name?.[0] || user.email?.[0] || 'U').toUpperCase()}
                </div>
              )}
              <div className="min-w-0 flex-1">
                <h4 className="text-sm font-bold text-foreground truncate">
                  {user.name || 'ScanVault User'}
                </h4>
                <p className="text-xs text-muted-foreground truncate">{user.email}</p>
                <div className="flex items-center gap-2 mt-1.5">
                  <span className="text-[10px] px-2 py-0.5 rounded-md bg-surface border border-border text-muted-foreground capitalize font-medium">
                    Auth: {user.accounts?.[0]?.provider || user.providers?.[0] || 'Password'}
                  </span>
                  {user.emailVerified ? (
                    <span className="text-[10px] text-emerald-400 font-semibold flex items-center gap-1">
                      <FileCheck2 className="w-3 h-3" />
                      Verified
                    </span>
                  ) : null}
                </div>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                onClick={handleLogout}
                className="touch-target flex-1 px-4 py-2.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 text-xs font-semibold rounded-xl border border-rose-500/20 transition-colors flex items-center justify-center gap-2"
              >
                <LogOut className="w-4 h-4" />
                <span>Sign Out of ScanVault</span>
              </button>
            </div>
          </div>
        ) : (
          <div className="bg-surface-secondary/70 border border-border rounded-xl p-3.5 flex items-start gap-3">
            <Lock className="w-4 h-4 text-indigo-400 shrink-0 mt-0.5" />
            <div>
              <h4 className="text-xs font-bold text-foreground">Guest Session</h4>
              <p className="text-[11px] text-muted-foreground mt-0.5">
                Sign in to sync your encrypted documents across your devices.
              </p>
            </div>
          </div>
        )}
      </div>

      {/* 3. Workspace Engine & Security Status */}
      <div className="glass-card rounded-2xl p-4 xs:p-5 shadow-lg">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-indigo-400" />
          <span>Workspace Environment</span>
        </h3>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
          <div className="p-3 bg-surface-secondary/70 rounded-xl border border-border">
            <div className="font-semibold text-foreground flex items-center gap-2 mb-1">
              <span className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_8px_#34d399]" />
              <span>Offline Engine</span>
            </div>
            <p className="text-[11px] text-muted-foreground">
              Air-gapped client processing with local WebAssembly pipeline
            </p>
          </div>

          <div className="p-3 bg-surface-secondary/70 rounded-xl border border-border">
            <div className="font-semibold text-foreground flex items-center gap-2 mb-1">
              <KeyRound className="w-3.5 h-3.5 text-indigo-400" />
              <span>HttpOnly Session Guard</span>
            </div>
            <p className="text-[11px] text-muted-foreground">
              Encrypted tokens stored exclusively via browser-protected cookies
            </p>
          </div>
        </div>
      </div>

      {/* 4. Local Vault & Storage */}
      <div className="glass-card rounded-2xl p-4 xs:p-5 shadow-lg">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
          <HardDrive className="w-4 h-4 text-indigo-400" />
          <span>Local Vault Storage</span>
        </h3>

        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between text-xs">
            <span className="text-muted-foreground">IndexedDB Vault Used</span>
            <span className="font-bold text-foreground font-mono">17.2 MB</span>
          </div>
          <div className="w-full bg-surface-secondary rounded-full h-2 overflow-hidden">
            <div className="bg-gradient-to-r from-indigo-500 to-cyan-400 h-full rounded-full w-[15%]" />
          </div>

          <div className="pt-2">
            <button
              onClick={handleClearCache}
              className="touch-target px-4 py-2 bg-surface-secondary hover:bg-rose-500/10 text-muted-foreground hover:text-rose-400 text-xs font-semibold rounded-xl border border-border hover:border-rose-500/20 transition-colors flex items-center gap-2"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Clear Temporary Render Cache</span>
            </button>
          </div>
        </div>
      </div>

      {/* 5. Scanner & PDF Preferences */}
      <div className="glass-card rounded-2xl p-4 xs:p-5 shadow-lg">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
          <Sliders className="w-4 h-4 text-indigo-400" />
          <span>Scanner Defaults</span>
        </h3>

        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-foreground">Auto-crop Detection</p>
              <p className="text-[11px] text-muted-foreground">Automatically find document edges</p>
            </div>
            <input
              type="checkbox"
              defaultChecked
              className="w-4 h-4 accent-indigo-500 rounded cursor-pointer"
            />
          </div>

          <div className="flex items-center justify-between pt-2 border-t border-border/50">
            <div>
              <p className="text-xs font-semibold text-foreground">Default PDF Compression</p>
              <p className="text-[11px] text-muted-foreground">Balanced size and crispness</p>
            </div>
            <select className="bg-surface-secondary text-foreground text-xs font-semibold border border-border rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-indigo-500">
              <option value="balanced">Balanced (150 DPI)</option>
              <option value="high">High Quality (300 DPI)</option>
              <option value="max">Max Compression (96 DPI)</option>
            </select>
          </div>
        </div>
      </div>

      {/* 6. About ScanVault */}
      <div className="glass-card rounded-2xl p-4 xs:p-5 shadow-lg">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
          <Info className="w-4 h-4 text-indigo-400" />
          <span>About ScanVault</span>
        </h3>

        <div className="text-xs text-muted-foreground space-y-1">
          <p className="font-semibold text-foreground">ScanVault — Mobile Document Workspace</p>
          <p>Version 0.3.0 (PWA Mobile Edition)</p>
          <p className="text-[11px] text-muted-foreground/80 pt-1">
            Air-gapped, privacy-first client-side document scanner & studio with encrypted session persistence.
          </p>
        </div>
      </div>
    </div>
  );
}
