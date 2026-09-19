import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from '@/lib/theme';
import { ToastProvider } from '@/lib/toast';
import { ErrorBoundary } from '@/components/ErrorBoundary';
import { AppShell } from '@/layouts/AppShell';

import { HomePage } from '@/pages/HomePage';
import { DocumentsPage } from '@/pages/DocumentsPage';
import { DocumentDetailPage } from '@/pages/DocumentDetailPage';
import { ScanPage } from '@/pages/ScanPage';
import { ToolsPage } from '@/pages/ToolsPage';
import { SettingsPage } from '@/pages/SettingsPage';
import { NotFoundPage } from '@/pages/NotFoundPage';

export function App() {
  return (
    <ErrorBoundary>
      <ThemeProvider>
        <ToastProvider>
          <BrowserRouter>
            <AppShell>
              <Routes>
                <Route path="/" element={<HomePage />} />
                <Route path="/documents" element={<DocumentsPage />} />
                <Route path="/documents/:id" element={<DocumentDetailPage />} />
                <Route path="/scan" element={<ScanPage />} />
                <Route path="/tools" element={<ToolsPage />} />
                <Route path="/settings" element={<SettingsPage />} />
                <Route path="*" element={<NotFoundPage />} />
              </Routes>
            </AppShell>
          </BrowserRouter>
        </ToastProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

export default App;
