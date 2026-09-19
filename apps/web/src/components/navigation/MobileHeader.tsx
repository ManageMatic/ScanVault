import { User } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '@/lib/auth';
import { BrandLogo } from '@/components/ui/BrandLogo';

export function MobileHeader() {
  const { user } = useAuth();

  return (
    <header className="sticky top-0 z-40 w-full bg-surface/95 backdrop-blur-md border-b border-border pt-safe select-none">
      <div className="w-full max-w-5xl mx-auto px-4 h-14 flex items-center justify-between">
        {/* Logo */}
        <Link to="/" className="active:opacity-80 transition-opacity">
          <BrandLogo size="sm" showText={true} />
        </Link>

        {/* Right Status / Profile */}
        <div className="flex items-center gap-2">
          {/* Offline Ready Status */}
          <div className="hidden xs:flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-surface-secondary text-muted border border-border">
            <span className="w-1.5 h-1.5 rounded-full bg-success" />
            <span>Offline Ready</span>
          </div>

          {/* User Profile / Settings Link */}
          <Link
            to="/settings"
            className="touch-target p-1 rounded-full hover:bg-surface-secondary transition-colors"
            aria-label="Account Settings"
          >
            {user?.avatarUrl ? (
              <img
                src={user.avatarUrl}
                alt={user.name || user.email}
                className="w-7 h-7 rounded-full object-cover border border-border"
              />
            ) : user ? (
              <div className="w-7 h-7 rounded-full bg-primary-soft text-primary font-semibold text-xs flex items-center justify-center border border-primary/20">
                {(user.name?.[0] || user.email?.[0] || 'U').toUpperCase()}
              </div>
            ) : (
              <div className="w-7 h-7 rounded-full bg-surface-secondary border border-border text-muted flex items-center justify-center">
                <User className="w-3.5 h-3.5" />
              </div>
            )}
          </Link>
        </div>
      </div>
    </header>
  );
}
