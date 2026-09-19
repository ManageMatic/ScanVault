import { Home, FileText, Camera, Wrench, Settings, ShieldCheck, HardDrive } from 'lucide-react';
import { NavLink } from 'react-router-dom';

export function DesktopSidebar() {
  const navItems = [
    { to: '/', label: 'Home Workspace', icon: Home },
    { to: '/documents', label: 'Document Vault', icon: FileText },
    { to: '/scan', label: 'Scanner Studio', icon: Camera, highlight: true },
    { to: '/tools', label: 'PDF Studio Tools', icon: Wrench },
    { to: '/settings', label: 'Settings & Storage', icon: Settings },
  ];

  return (
    <aside className="hidden lg:flex flex-col w-64 border-r border-border bg-surface h-screen sticky top-0 p-4 select-none shrink-0">
      {/* Brand Header */}
      <div className="flex items-center gap-3 px-3 py-3 mb-6">
        <div className="w-9 h-9 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary shadow-sm">
          <ShieldCheck className="w-5 h-5" />
        </div>
        <div>
          <h1 className="font-extrabold text-base text-foreground tracking-tight">
            ScanVault
          </h1>
          <p className="text-[11px] font-semibold text-primary">Document Workspace</p>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 flex flex-col gap-1.5" aria-label="Desktop Sidebar">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `touch-target w-full px-3.5 rounded-xl flex items-center gap-3 text-xs font-semibold transition-all ${
                  isActive
                    ? 'bg-primary text-primary-foreground shadow-md shadow-primary/20'
                    : item.highlight
                    ? 'bg-primary/10 text-primary hover:bg-primary/20'
                    : 'text-muted-foreground hover:text-foreground hover:bg-surface-secondary'
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
      <div className="p-3 bg-surface-secondary rounded-xl border border-border mt-auto">
        <div className="flex items-center gap-2 text-xs font-bold text-foreground mb-1">
          <HardDrive className="w-3.5 h-3.5 text-primary" />
          <span>Local Vault Status</span>
        </div>
        <p className="text-[11px] text-muted-foreground mb-2">
          Air-Gapped & Offline IndexedDB Storage
        </p>
        <div className="w-full bg-border rounded-full h-1.5 overflow-hidden">
          <div className="bg-primary h-full rounded-full w-1/4" />
        </div>
      </div>
    </aside>
  );
}
