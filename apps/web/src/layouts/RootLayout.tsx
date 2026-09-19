import { ReactNode } from 'react';
import { ShieldCheck } from 'lucide-react';

interface RootLayoutProps {
  children: ReactNode;
}

export function RootLayout({ children }: RootLayoutProps) {
  return (
    <div className="min-h-screen w-full flex flex-col bg-vault-bg text-slate-100 selection:bg-brand-500/30">
      {/* Mobile-First Header with Safe Area Inset */}
      <header className="sticky top-0 z-40 w-full bg-vault-card/80 backdrop-blur-md border-b border-vault-border pt-safe">
        <div className="w-full max-w-5xl mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-brand-500/10 border border-brand-500/30 flex items-center justify-center text-brand-400 shadow-sm">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <span className="font-bold text-base tracking-tight bg-gradient-to-r from-white to-slate-300 bg-clip-text text-transparent">
                ScanVault
              </span>
              <span className="hidden xs:inline-block ml-2 text-[10px] font-semibold uppercase tracking-wider text-brand-400 bg-brand-500/10 px-1.5 py-0.5 rounded border border-brand-500/20">
                PWA
              </span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
              Air-Gapped Ready
            </span>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 w-full max-w-5xl mx-auto px-4 py-6 flex flex-col">
        {children}
      </main>

      {/* Mobile-Friendly Footer */}
      <footer className="w-full border-t border-vault-border bg-vault-card/40 py-4 pb-safe mt-auto text-center text-xs text-slate-500">
        <div className="max-w-5xl mx-auto px-4 flex flex-col xs:flex-row items-center justify-between gap-2">
          <p>© {new Date().getFullYear()} ScanVault — Mobile Document Workspace</p>
          <p className="text-[11px] text-slate-600">Module 01: Web Foundation</p>
        </div>
      </footer>
    </div>
  );
}
