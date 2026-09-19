import { Files } from 'lucide-react';

interface BrandLogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
}

export function BrandLogo({ size = 'md', showText = true }: BrandLogoProps) {
  const sizeClasses = {
    sm: { container: 'w-7 h-7 rounded-lg', icon: 'w-4 h-4', text: 'text-sm' },
    md: { container: 'w-9 h-9 rounded-xl', icon: 'w-5 h-5', text: 'text-base' },
    lg: { container: 'w-12 h-12 rounded-2xl', icon: 'w-6 h-6', text: 'text-xl' },
  };

  const current = sizeClasses[size];

  return (
    <div className="flex items-center gap-2.5 select-none">
      <div
        className={`${current.container} bg-primary flex items-center justify-center text-white shadow-sm shrink-0`}
      >
        <Files className={current.icon} />
      </div>
      {showText && (
        <div className="flex flex-col">
          <span className={`font-bold ${current.text} tracking-tight text-foreground leading-tight`}>
            ScanVault
          </span>
        </div>
      )}
    </div>
  );
}
