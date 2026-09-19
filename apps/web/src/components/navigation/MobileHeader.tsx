import { ShieldCheck, Moon, Sun, Laptop } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTheme } from '@/lib/theme';

export function MobileHeader() {
  const { theme, setTheme } = useTheme();

  const cycleTheme = () => {
    if (theme === 'dark') setTheme('light');
    else if (theme === 'light') setTheme('system');
    else setTheme('dark');
  };

  return (
    <header className="sticky top-0 z-40 w-full bg-surface/90 backdrop-blur-md border-b border-border pt-safe select-none">
      <div className="w-full max-w-5xl mx-auto px-4 h-14 flex items-center justify-between">
        {/* Logo & Workspace Title */}
        <Link to="/" className="flex items-center gap-2.5 active:opacity-80 transition-opacity">
          <div className="w-8 h-8 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary shadow-sm">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <span className="font-extrabold text-base tracking-tight text-foreground">
              ScanVault
            </span>
            <span className="hidden xs:inline-block ml-2 text-[10px] font-bold uppercase tracking-wider text-primary bg-primary/10 px-1.5 py-0.5 rounded border border-primary/20">
              Workspace
            </span>
          </div>
        </Link>

        {/* Right Action Icons */}
        <div className="flex items-center gap-1.5">
          {/* Offline Air-Gapped Pill */}
          <div className="hidden xs:flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-success/10 text-success border border-success/20">
            <span className="w-1.5 h-1.5 rounded-full bg-success animate-pulse" />
            Air-Gapped
          </div>

          {/* Quick Theme Toggle */}
          <button
            onClick={cycleTheme}
            className="touch-target p-2 text-muted-foreground hover:text-foreground hover:bg-surface-secondary rounded-xl transition-colors"
            aria-label={`Toggle theme (Current: ${theme})`}
          >
            {theme === 'dark' && <Moon className="w-4 h-4" />}
            {theme === 'light' && <Sun className="w-4 h-4 text-amber-500" />}
            {theme === 'system' && <Laptop className="w-4 h-4" />}
          </button>
        </div>
      </div>
    </header>
  );
}
