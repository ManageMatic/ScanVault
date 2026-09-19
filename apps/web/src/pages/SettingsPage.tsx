import { useState } from 'react';
import {
  Shield,
  HardDrive,
  Sliders,
  Info,
  Lock,
  LogOut,
  FileCheck2,
  Database,
  CheckCircle2,
} from 'lucide-react';
import { useToast } from '@/lib/toast';
import { useAuth } from '@/lib/auth';
import { formatBytes } from '@/lib/mockData';
import {
  useStorageUsage,
  documentService,
  requestPersistentStorage,
} from '@/lib/db';
import { useNavigate } from 'react-router-dom';

export function SettingsPage() {
  const { toast } = useToast();
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const {
    usage,
    available,
    quota,
    percentUsed,
    isSupported,
    isPersisted,
    refresh: refreshStorage,
  } = useStorageUsage();

  const [isCleaning, setIsCleaning] = useState(false);

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

  const handleCleanOrphans = async () => {
    if (!user?.id) return;
    try {
      setIsCleaning(true);
      const res = await documentService.cleanupOrphanedData(user.id);
      await refreshStorage();
      toast({
        title: 'Maintenance Complete',
        description: `Removed ${res.orphanedFiles} orphaned files and ${res.orphanedThumbnails} unused thumbnails.`,
        type: 'success',
      });
    } catch (err) {
      toast({
        title: 'Cleanup failed',
        description: (err as Error).message,
        type: 'error',
      });
    } finally {
      setIsCleaning(false);
    }
  };

  const handleRequestPersist = async () => {
    try {
      const granted = await requestPersistentStorage();
      await refreshStorage();
      if (granted) {
        toast({
          title: 'Persistent Storage Granted',
          description: 'Your browser will not evict local documents during low-disk conditions.',
          type: 'success',
        });
      } else {
        toast({
          title: 'Persistence Request',
          description: 'Browser did not grant persistent storage. Documents remain saved in IndexedDB.',
          type: 'info',
        });
      }
    } catch {
      toast({ title: 'Could not request persistence', type: 'error' });
    }
  };

  return (
    <div className="w-full flex flex-col gap-6 animate-fade-in pb-12">
      {/* 1. Header */}
      <div>
        <h1 className="text-xl xs:text-2xl font-bold tracking-tight text-foreground">
          Settings
        </h1>
        <p className="text-xs text-muted mt-0.5">
          Manage your account, scanner defaults, and local IndexedDB storage
        </p>
      </div>

      {/* 2. Account Section */}
      <div className="bg-surface border border-border rounded-xl p-4 xs:p-5 shadow-subtle flex flex-col gap-4">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4 text-primary" />
            <span>Account & Security</span>
          </div>
          {user && (
            <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-primary-soft text-primary">
              Active Session
            </span>
          )}
        </h2>

        {user ? (
          <div className="space-y-4">
            <div className="flex items-center gap-3.5 p-3 rounded-lg bg-surface-secondary border border-border">
              {user.avatarUrl ? (
                <img
                  src={user.avatarUrl}
                  alt={user.name || user.email}
                  className="w-11 h-11 rounded-full object-cover border border-border"
                />
              ) : (
                <div className="w-11 h-11 rounded-full bg-primary text-white font-semibold text-sm flex items-center justify-center shadow-sm">
                  {(user.name?.[0] || user.email?.[0] || 'U').toUpperCase()}
                </div>
              )}
              <div className="min-w-0 flex-1">
                <h3 className="text-sm font-semibold text-foreground truncate">
                  {user.name || 'ScanVault User'}
                </h3>
                <p className="text-xs text-muted truncate">{user.email}</p>
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-surface border border-border text-muted capitalize">
                    Provider: {user.accounts?.[0]?.provider || user.providers?.[0] || 'Password'}
                  </span>
                  {user.emailVerified ? (
                    <span className="text-[10px] text-success font-semibold flex items-center gap-1">
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
                className="btn-secondary touch-target flex-1 text-destructive hover:bg-destructive-soft border-destructive/20 text-xs font-semibold flex items-center justify-center gap-2"
              >
                <LogOut className="w-4 h-4" />
                <span>Sign Out</span>
              </button>
            </div>
          </div>
        ) : (
          <div className="bg-surface-secondary border border-border rounded-lg p-3.5 flex items-start gap-3">
            <Lock className="w-4 h-4 text-primary shrink-0 mt-0.5" />
            <div>
              <h3 className="text-xs font-semibold text-foreground">Guest Mode</h3>
              <p className="text-[11px] text-muted mt-0.5">
                Sign in to manage and isolate your encrypted offline documents.
              </p>
            </div>
          </div>
        )}
      </div>

      {/* 3. Real Local Storage Telemetry */}
      <div className="bg-surface border border-border rounded-xl p-4 xs:p-5 shadow-subtle flex flex-col gap-4">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted flex items-center gap-2">
          <HardDrive className="w-4 h-4 text-primary" />
          <span>Local Device Storage (IndexedDB)</span>
        </h2>

        {isSupported ? (
          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between text-xs">
              <span className="text-muted">Storage Used</span>
              <span className="font-semibold text-foreground font-mono">
                {formatBytes(usage)} / {formatBytes(quota)} ({percentUsed}%)
              </span>
            </div>
            <div className="w-full bg-surface-secondary rounded-full h-2 overflow-hidden border border-border">
              <div
                className="bg-primary h-full rounded-full transition-all duration-300"
                style={{ width: `${Math.min(100, Math.max(2, percentUsed))}%` }}
              />
            </div>
            <div className="flex items-center justify-between text-[11px] text-muted">
              <span>{formatBytes(available)} available space</span>
              {isPersisted ? (
                <span className="text-emerald-600 font-semibold flex items-center gap-1">
                  <CheckCircle2 className="w-3 h-3" />
                  Storage Persisted
                </span>
              ) : (
                <button
                  onClick={handleRequestPersist}
                  className="text-primary font-semibold hover:underline"
                >
                  Request Persistent Storage
                </button>
              )}
            </div>

            <div className="pt-2 border-t border-border flex flex-wrap gap-2">
              <button
                onClick={handleCleanOrphans}
                disabled={isCleaning}
                className="touch-target px-3.5 py-2 bg-surface hover:bg-surface-secondary text-foreground text-xs font-semibold rounded-lg border border-border transition-colors flex items-center gap-2 shadow-subtle"
              >
                <Database className="w-3.5 h-3.5 text-primary" />
                <span>{isCleaning ? 'Cleaning...' : 'Purge Orphaned Blobs'}</span>
              </button>
            </div>
          </div>
        ) : (
          <div className="bg-surface-secondary border border-border rounded-lg p-3.5 text-xs text-muted">
            <p>Storage information isn't available in this browser.</p>
            <p className="text-[11px] mt-1 text-subtle">
              Your documents continue to be saved securely in browser IndexedDB.
            </p>
          </div>
        )}
      </div>

      {/* 4. Scanner Preferences */}
      <div className="bg-surface border border-border rounded-xl p-4 xs:p-5 shadow-subtle flex flex-col gap-3">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted flex items-center gap-2">
          <Sliders className="w-4 h-4 text-primary" />
          <span>Scanner Defaults</span>
        </h2>

        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-foreground">Auto-crop Detection</p>
              <p className="text-[11px] text-muted">Automatically find document edges</p>
            </div>
            <input
              type="checkbox"
              defaultChecked
              className="w-4 h-4 accent-primary rounded cursor-pointer"
            />
          </div>

          <div className="flex items-center justify-between pt-2 border-t border-border">
            <div>
              <p className="text-xs font-semibold text-foreground">Default PDF Compression</p>
              <p className="text-[11px] text-muted">Balanced size and crispness</p>
            </div>
            <select className="bg-surface-secondary text-foreground text-xs font-semibold border border-border rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-primary">
              <option value="balanced">Balanced (150 DPI)</option>
              <option value="high">High Quality (300 DPI)</option>
              <option value="max">Max Compression (96 DPI)</option>
            </select>
          </div>
        </div>
      </div>

      {/* 5. About ScanVault */}
      <div className="bg-surface border border-border rounded-xl p-4 xs:p-5 shadow-subtle flex flex-col gap-2">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted flex items-center gap-2">
          <Info className="w-4 h-4 text-primary" />
          <span>About ScanVault</span>
        </h2>

        <div className="text-xs text-muted space-y-1">
          <p className="font-semibold text-foreground">ScanVault — Mobile Document Workspace</p>
          <p>Version 0.4.0 (Module 04: Real Local Document Vault)</p>
          <p className="text-[11px] text-muted pt-1">
            Local-first, air-gapped document workspace. All document files and thumbnails are stored securely in your device's IndexedDB.
          </p>
        </div>
      </div>
    </div>
  );
}
