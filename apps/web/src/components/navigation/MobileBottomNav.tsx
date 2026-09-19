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
      className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-[hsl(var(--surface))]/95 backdrop-blur-xl border-t border-border pb-safe select-none shadow-[0_-8px_30px_rgba(0,0,0,0.35)]"
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
                  `relative -top-3.5 touch-target-lg w-13 h-13 rounded-2xl bg-gradient-to-tr from-indigo-600 via-indigo-500 to-cyan-400 text-white shadow-lg shadow-indigo-500/35 border border-white/20 flex flex-col items-center justify-center transition-transform active:scale-95 ${
                    isActive ? 'ring-2 ring-indigo-400 ring-offset-2 ring-offset-[hsl(var(--background))]' : ''
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
                `touch-target flex-1 flex flex-col items-center justify-center py-1 transition-colors rounded-xl relative ${
                  isActive
                    ? 'text-indigo-400 font-bold'
                    : 'text-muted-foreground hover:text-foreground active:text-foreground'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  <Icon className={`w-5 h-5 transition-transform ${isActive ? 'scale-110 text-indigo-400' : ''}`} />
                  <span className="text-[10px] font-medium tracking-tight mt-1">
                    {item.label}
                  </span>
                  {isActive && (
                    <span className="absolute bottom-1 w-1 h-1 rounded-full bg-indigo-400 shadow-[0_0_8px_#818cf8]" />
                  )}
                </>
              )}
            </NavLink>
          );
        })}
      </div>
    </nav>
  );
}
