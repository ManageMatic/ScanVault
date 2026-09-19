import { Home, FileText, Camera, Wrench, Settings, HardDrive } from 'lucide-react';
import { NavLink, Link } from 'react-router-dom';
import { BrandLogo } from '@/components/ui/BrandLogo';
import { useStorageUsage } from '@/lib/db';
import { formatBytes } from '@/lib/mockData';

export function DesktopSidebar() {
  const { usage, percentUsed, isSupported } = useStorageUsage();

  const navItems = [
    { to: '/', label: 'Home', icon: Home },
    { to: '/documents', label: 'Documents', icon: FileText },
    { to: '/tools', label: 'PDF Tools', icon: Wrench },
    { to: '/settings', label: 'Settings', icon: Settings },
  ];

  return (
    <aside className="hidden lg:flex flex-col w-64 border-r border-border bg-surface h-screen sticky top-0 p-5 select-none shrink-0">
      {/* Brand Header */}
      <div className="px-2 py-2 mb-6">
        <Link to="/" className="inline-block">
          <BrandLogo size="md" showText={true} />
        </Link>
      </div>

      {/* Primary Quick Scan Button */}
      <div className="mb-6 px-1">
        <Link
          to="/scan"
          className="btn-primary w-full shadow-sm flex items-center justify-center gap-2"
        >
          <Camera className="w-4 h-4" />
          <span>Scan Document</span>
        </Link>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 flex flex-col gap-1" aria-label="Desktop Sidebar">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `touch-target w-full px-3.5 rounded-xl flex items-center gap-3 text-xs font-semibold transition-all ${
                  isActive
                    ? 'bg-primary-soft text-primary'
                    : 'text-muted hover:text-foreground hover:bg-surface-secondary'
                }`
              }
            >
              <Icon className="w-4 h-4" />
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      {/* Bottom Vault Status */}
      <div className="p-3.5 bg-surface-secondary rounded-xl border border-border mt-auto">
        <div className="flex items-center justify-between text-xs font-semibold text-foreground mb-1">
          <div className="flex items-center gap-1.5">
            <HardDrive className="w-3.5 h-3.5 text-primary" />
            <span>Local Vault</span>
          </div>
          {isSupported && usage > 0 && (
            <span className="text-[10px] text-muted font-mono">{formatBytes(usage)}</span>
          )}
        </div>
        <p className="text-[11px] text-muted mb-2">
          Air-gapped offline storage
        </p>
        <div className="w-full bg-border rounded-full h-1.5 overflow-hidden">
          <div
            className="bg-primary h-full rounded-full transition-all duration-300"
            style={{ width: `${isSupported && percentUsed > 0 ? Math.max(5, percentUsed) : 15}%` }}
          />
        </div>
      </div>
    </aside>
  );
}
