import { Home, FileText, Camera, Wrench, Settings } from 'lucide-react';
import { NavLink } from 'react-router-dom';

export function MobileBottomNav() {
  const navItems = [
    {
      to: '/',
      label: 'Home',
      icon: Home,
    },
    {
      to: '/documents',
      label: 'Vault',
      icon: FileText,
    },
    {
      to: '/scan',
      label: 'Scan',
      icon: Camera,
      isPrimary: true,
    },
    {
      to: '/tools',
      label: 'Tools',
      icon: Wrench,
    },
    {
      to: '/settings',
      label: 'Settings',
      icon: Settings,
    },
  ];

  return (
    <nav
      aria-label="Mobile Navigation"
      className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-surface/95 backdrop-blur-lg border-t border-border pb-safe select-none shadow-[0_-4px_20px_rgba(0,0,0,0.1)]"
    >
      <div className="w-full max-w-lg mx-auto px-2 h-16 flex items-center justify-around">
        {navItems.map((item) => {
          const Icon = item.icon;

          if (item.isPrimary) {
            return (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  `relative -top-3 touch-target-lg w-13 h-13 rounded-2xl bg-primary text-primary-foreground shadow-lg shadow-primary/30 flex flex-col items-center justify-center transition-transform active:scale-95 ${
                    isActive ? 'ring-2 ring-primary ring-offset-2 ring-offset-background' : ''
                  }`
                }
                aria-label="Scan Document"
              >
                <Icon className="w-6 h-6" />
                <span className="text-[10px] font-bold mt-0.5">Scan</span>
              </NavLink>
            );
          }

          return (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `touch-target flex-1 flex flex-col items-center justify-center py-1 transition-colors rounded-xl ${
                  isActive
                    ? 'text-primary font-bold'
                    : 'text-muted-foreground hover:text-foreground active:text-foreground'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  <Icon className={`w-5 h-5 transition-transform ${isActive ? 'scale-110' : ''}`} />
                  <span className="text-[10px] font-medium tracking-tight mt-1">
                    {item.label}
                  </span>
                </>
              )}
            </NavLink>
          );
        })}
      </div>
    </nav>
  );
}
