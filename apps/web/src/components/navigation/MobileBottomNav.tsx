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
      label: 'Documents',
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
      className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-surface/98 backdrop-blur-md border-t border-border pb-safe select-none shadow-[0_-2px_8px_rgba(16,24,40,0.04)]"
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
                  `relative -top-3.5 touch-target-lg w-12 h-12 rounded-xl bg-primary text-white shadow-md shadow-primary/25 flex flex-col items-center justify-center transition-transform active:scale-95 ${
                    isActive ? 'ring-2 ring-primary ring-offset-2 ring-offset-surface' : ''
                  }`
                }
                aria-label="Scan Document"
              >
                <Icon className="w-5 h-5" />
                <span className="text-[10px] font-bold mt-0.5 leading-none">Scan</span>
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
                    ? 'text-primary font-semibold'
                    : 'text-muted hover:text-foreground active:text-foreground'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  <Icon className={`w-5 h-5 transition-transform ${isActive ? 'scale-105' : ''}`} />
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
