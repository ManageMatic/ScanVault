interface BrandLogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
}

export function BrandLogo({ size = 'md', showText = true }: BrandLogoProps) {
  const sizeClasses = {
    sm: { container: 'w-7 h-7', text: 'text-sm' },
    md: { container: 'w-9 h-9', text: 'text-base' },
    lg: { container: 'w-12 h-12', text: 'text-xl' },
  };

  const current = sizeClasses[size];

  return (
    <div className="flex items-center gap-2.5 select-none">
      {/* Custom Vector Document-Vault Logo */}
      <div className={`${current.container} shrink-0 drop-shadow-sm`}>
        <svg viewBox="0 0 100 100" fill="none" className="w-full h-full">
          {/* Rounded Indigo Background */}
          <rect width="100" height="100" rx="24" fill="#4F46E5" />
          
          {/* Back Sheet */}
          <rect x="34" y="20" width="40" height="52" rx="6" fill="#818CF8" fillOpacity="0.6" />
          
          {/* Front Sheet */}
          <rect x="24" y="28" width="42" height="52" rx="6" fill="#FFFFFF" />
          
          {/* Document Fold Corner */}
          <path d="M54 28V38H66" stroke="#E5E7EB" strokeWidth="2" fill="#F1F3F8" />
          
          {/* Content Lines */}
          <path d="M32 44H56" stroke="#4F46E5" strokeWidth="3.5" strokeLinecap="round" />
          <path d="M32 52H52" stroke="#98A2B3" strokeWidth="3" strokeLinecap="round" />
          <path d="M32 60H46" stroke="#98A2B3" strokeWidth="3" strokeLinecap="round" />
          
          {/* Verified Teal Badge */}
          <circle cx="68" cy="70" r="11" fill="#14B8A6" />
          <path d="M64 70L67 73L72 67" stroke="#FFFFFF" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>

      {showText && (
        <div className="flex items-center">
          <span className={`font-extrabold ${current.text} tracking-tight text-foreground`}>
            Scan<span className="text-primary">Vault</span>
          </span>
        </div>
      )}
    </div>
  );
}
