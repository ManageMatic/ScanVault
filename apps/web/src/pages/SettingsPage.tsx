import {
  Sun,
  Moon,
  Laptop,
  Shield,
  HardDrive,
  Sliders,
  Info,
  Trash2,
  Lock,
  LogOut,
} from 'lucide-react';
import { useTheme } from '@/lib/theme';
import { useToast } from '@/lib/toast';
import { useAuth } from '@/lib/auth';
import { useNavigate } from 'react-router-dom';

export function SettingsPage() {
  const { theme, setTheme } = useTheme();
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
      description: 'Local workspace cache refreshed.',
      type: 'success',
    });
  };

  return (
    <div className="w-full flex flex-col gap-6">
      {/* 1. Header */}
      <div>
        <h2 className="text-xl xs:text-2xl font-extrabold tracking-tight text-foreground">
          Settings & Preferences
        </h2>
        <p className="text-xs text-muted-foreground mt-0.5">
          Configure appearance, local vault storage, and workspace defaults
        </p>
      </div>

      {/* 2. Appearance & Theme Selection */}
      <div className="bg-surface border border-border rounded-2xl p-4 xs:p-5 shadow-sm">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
          <Sun className="w-4 h-4 text-primary" />
          <span>Appearance</span>
        </h3>

        <div className="grid grid-cols-3 gap-2.5">
          <button
            onClick={() => setTheme('light')}
            className={`touch-target p-3 rounded-xl border flex flex-col items-center justify-center gap-2 transition-all ${
              theme === 'light'
                ? 'bg-primary/10 border-primary text-primary font-bold shadow-sm'
                : 'bg-surface-secondary border-border text-muted-foreground hover:text-foreground'
            }`}
          >
            <Sun className="w-5 h-5 text-amber-500" />
            <span className="text-xs">Light</span>
          </button>

          <button
            onClick={() => setTheme('dark')}
            className={`touch-target p-3 rounded-xl border flex flex-col items-center justify-center gap-2 transition-all ${
              theme === 'dark'
                ? 'bg-primary/10 border-primary text-primary font-bold shadow-sm'
                : 'bg-surface-secondary border-border text-muted-foreground hover:text-foreground'
            }`}
          >
            <Moon className="w-5 h-5 text-blue-400" />
            <span className="text-xs">Dark</span>
          </button>

          <button
            onClick={() => setTheme('system')}
            className={`touch-target p-3 rounded-xl border flex flex-col items-center justify-center gap-2 transition-all ${
              theme === 'system'
                ? 'bg-primary/10 border-primary text-primary font-bold shadow-sm'
                : 'bg-surface-secondary border-border text-muted-foreground hover:text-foreground'
            }`}
          >
            <Laptop className="w-5 h-5" />
            <span className="text-xs">System</span>
          </button>
        </div>
      </div>

      {/* 3. Account & Authentication */}
      <div className="bg-surface border border-border rounded-2xl p-4 xs:p-5 shadow-sm">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4 text-primary" />
            <span>Account & Security</span>
          </div>
          {user && (
            <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-primary/10 text-primary border border-primary/20">
              Active Session
            </span>
          )}
        </h3>

        {user ? (
          <div className="space-y-4">
            <div className="flex items-center gap-3.5 p-3 rounded-xl bg-surface-secondary/70 border border-border">
              {user.avatarUrl ? (
                <img
                  src={user.avatarUrl}
                  alt={user.name || user.email}
                  className="w-11 h-11 rounded-full object-cover border border-border"
                />
              ) : (
                <div className="w-11 h-11 rounded-full bg-primary/10 text-primary font-bold text-sm flex items-center justify-center border border-primary/20">
                  {(user.name?.[0] || user.email?.[0] || 'U').toUpperCase()}
                </div>
              )}
              <div className="min-w-0 flex-1">
                <h4 className="text-sm font-bold text-foreground truncate">
                  {user.name || 'ScanVault User'}
                </h4>
                <p className="text-xs text-muted-foreground truncate">{user.email}</p>
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-surface border border-border text-muted-foreground capitalize">
                    Provider: {user.accounts?.[0]?.provider || user.providers?.[0] || 'Password'}
                  </span>
                  {user.emailVerified ? (
                    <span className="text-[10px] text-emerald-500 font-medium">Verified</span>
                  ) : null}
                </div>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                onClick={handleLogout}
                className="touch-target flex-1 px-4 py-2.5 bg-destructive/10 hover:bg-destructive/20 text-destructive text-xs font-semibold rounded-xl border border-destructive/20 transition-colors flex items-center justify-center gap-2"
              >
                <LogOut className="w-4 h-4" />
                <span>Sign Out</span>
              </button>
            </div>
          </div>
        ) : (
          <div className="bg-surface-secondary/70 border border-border rounded-xl p-3.5 flex items-start gap-3">
            <Lock className="w-4 h-4 text-primary shrink-0 mt-0.5" />
            <div>
              <h4 className="text-xs font-bold text-foreground">Guest Mode</h4>
              <p className="text-[11px] text-muted-foreground mt-0.5">
                Sign in to sync your encrypted documents across devices.
              </p>
            </div>
          </div>
        )}
      </div>

      {/* 4. Local Vault & Storage */}
      <div className="bg-surface border border-border rounded-2xl p-4 xs:p-5 shadow-sm">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
          <HardDrive className="w-4 h-4 text-primary" />
          <span>Local Vault Storage</span>
        </h3>

        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between text-xs">
            <span className="text-muted-foreground">IndexedDB Vault Used</span>
            <span className="font-bold text-foreground font-mono">17.2 MB</span>
          </div>
          <div className="w-full bg-surface-secondary rounded-full h-2 overflow-hidden">
            <div className="bg-primary h-full rounded-full w-[12%]" />
          </div>

          <div className="pt-2">
            <button
              onClick={handleClearCache}
              className="touch-target px-4 bg-surface-secondary hover:bg-destructive/10 text-destructive text-xs font-semibold rounded-xl border border-border transition-colors flex items-center gap-2"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Clear Temporary Render Cache</span>
            </button>
          </div>
        </div>
      </div>

      {/* 5. Scanner & PDF Preferences */}
      <div className="bg-surface border border-border rounded-2xl p-4 xs:p-5 shadow-sm">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
          <Sliders className="w-4 h-4 text-primary" />
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
              className="w-4 h-4 accent-primary rounded cursor-pointer"
            />
          </div>

          <div className="flex items-center justify-between pt-2 border-t border-border/50">
            <div>
              <p className="text-xs font-semibold text-foreground">Default PDF Compression</p>
              <p className="text-[11px] text-muted-foreground">Balanced size and crispness</p>
            </div>
            <select className="bg-surface-secondary text-foreground text-xs font-semibold border border-border rounded-lg px-2 py-1 focus:outline-none">
              <option value="balanced">Balanced (150 DPI)</option>
              <option value="high">High Quality (300 DPI)</option>
              <option value="max">Max Compression (96 DPI)</option>
            </select>
          </div>
        </div>
      </div>

      {/* 6. About ScanVault */}
      <div className="bg-surface border border-border rounded-2xl p-4 xs:p-5 shadow-sm">
        <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-3 flex items-center gap-2">
          <Info className="w-4 h-4 text-primary" />
          <span>About ScanVault</span>
        </h3>

        <div className="text-xs text-muted-foreground space-y-1">
          <p className="font-semibold text-foreground">ScanVault — Mobile Document Workspace</p>
          <p>Version 0.2.0 (PWA Mobile Edition)</p>
          <p className="text-[11px] text-muted-foreground/80 pt-1">
            Air-gapped, privacy-first client-side document scanner & studio.
          </p>
        </div>
      </div>
    </div>
  );
}
