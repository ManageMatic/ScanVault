import { ReactNode } from 'react';
import { MobileHeader } from '@/components/navigation/MobileHeader';
import { MobileBottomNav } from '@/components/navigation/MobileBottomNav';
import { DesktopSidebar } from '@/components/navigation/DesktopSidebar';

interface AppShellProps {
  children: ReactNode;
}

export function AppShell({ children }: AppShellProps) {
  return (
    <div className="min-h-screen w-full flex bg-background text-foreground selection:bg-primary/20">
      {/* Desktop Sidebar (visible >= 1024px) */}
      <DesktopSidebar />

      {/* Main Content Area */}
      <div className="flex-1 min-w-0 flex flex-col min-h-screen">
        {/* Mobile Header */}
        <MobileHeader />

        {/* Scrollable Page Viewport */}
        <main className="flex-1 w-full max-w-5xl mx-auto px-4 xs:px-5 py-5 xs:py-6 lg:pb-10 flex flex-col">
          {children}
          {/* Explicit mobile spacer to guarantee zero occlusion by fixed bottom nav and floating scan trigger */}
          <div className="h-28 xs:h-32 lg:hidden w-full shrink-0 select-none pointer-events-none" aria-hidden="true" />
        </main>

        {/* Mobile Bottom Navigation (fixed, visible < 1024px) */}
        <MobileBottomNav />
      </div>
    </div>
  );
}
