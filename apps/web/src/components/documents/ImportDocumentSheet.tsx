import { useState, useRef } from 'react';
import { FileText, Image as ImageIcon, Loader2, UploadCloud, AlertCircle } from 'lucide-react';
import { BottomSheet } from '@/components/ui/BottomSheet';
import { documentService } from '@/lib/db';
import { useAuth } from '@/lib/auth';
import { useToast } from '@/lib/toast';
import type { LocalDocument } from '@/lib/db';

interface ImportDocumentSheetProps {
  isOpen: boolean;
  onClose: () => void;
  folderId?: string | null;
  onImportSuccess?: (doc: LocalDocument) => void;
}

export function ImportDocumentSheet({
  isOpen,
  onClose,
  folderId,
  onImportSuccess,
}: ImportDocumentSheetProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const [isImporting, setIsImporting] = useState(false);
  const [importStatus, setImportStatus] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  const pdfInputRef = useRef<HTMLInputElement>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelected = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Reset input so re-selecting same file triggers change
    e.target.value = '';

    if (!user?.id) {
      toast({
        title: 'Authentication Required',
        description: 'Please log in to save documents to your local vault.',
        type: 'error',
      });
      return;
    }

    try {
      setError(null);
      setIsImporting(true);
      setImportStatus('Preparing document...');

      await new Promise((resolve) => setTimeout(resolve, 50)); // Allow UI state update

      setImportStatus('Saving to local vault...');
      const createdDoc = await documentService.importDocumentFile(file, user.id, {
        folderId: folderId || null,
      });

      setImportStatus('Complete!');
      toast({
        title: 'Document imported',
        description: `"${createdDoc.title}" saved locally`,
        type: 'success',
      });

      onClose();
      onImportSuccess?.(createdDoc);
    } catch (err: unknown) {
      const msg = (err as Error).message || 'Failed to import document';
      setError(msg);
      toast({
        title: 'Import Failed',
        description: msg,
        type: 'error',
      });
    } finally {
      setIsImporting(false);
      setImportStatus('');
    }
  };

  return (
    <BottomSheet
      isOpen={isOpen}
      onClose={() => {
        if (!isImporting) {
          setError(null);
          onClose();
        }
      }}
      title="Import Document"
      description="Select a file to save offline in your encrypted local vault."
    >
      <div className="flex flex-col gap-3 -mx-2 pt-1">
        {/* Hidden File Inputs */}
        <input
          ref={pdfInputRef}
          type="file"
          accept="application/pdf,.pdf"
          className="hidden"
          id="pdf-upload-input"
          aria-label="Upload PDF document"
          onChange={handleFileSelected}
          disabled={isImporting}
        />
        <input
          ref={imageInputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp"
          className="hidden"
          id="image-upload-input"
          aria-label="Upload image document"
          onChange={handleFileSelected}
          disabled={isImporting}
        />

        {error && (
          <div className="mx-2 p-3 rounded-xl bg-destructive-soft border border-destructive/20 flex items-start gap-2.5 text-destructive text-xs">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        {isImporting ? (
          <div className="py-8 flex flex-col items-center justify-center gap-3 text-center">
            <Loader2 className="w-8 h-8 text-primary animate-spin" />
            <div>
              <p className="text-sm font-semibold text-foreground">{importStatus}</p>
              <p className="text-xs text-muted mt-0.5">Storing local Blobs in IndexedDB...</p>
            </div>
          </div>
        ) : (
          <>
            {/* Import PDF Option */}
            <button
              onClick={() => pdfInputRef.current?.click()}
              className="touch-target-lg w-full px-4 rounded-xl flex items-center gap-3.5 text-xs font-semibold text-foreground hover:bg-surface-secondary transition-all active:scale-[0.98] border border-border bg-surface shadow-subtle"
            >
              <div className="p-2.5 rounded-xl bg-primary-soft text-primary">
                <FileText className="w-5 h-5" />
              </div>
              <div className="flex-1 text-left">
                <p className="text-sm font-bold text-foreground">Import PDF</p>
                <p className="text-[11px] text-muted font-normal">
                  Select a PDF file (.pdf) up to 100 MB
                </p>
              </div>
              <UploadCloud className="w-4 h-4 text-muted" />
            </button>

            {/* Import Image Option */}
            <button
              onClick={() => imageInputRef.current?.click()}
              className="touch-target-lg w-full px-4 rounded-xl flex items-center gap-3.5 text-xs font-semibold text-foreground hover:bg-surface-secondary transition-all active:scale-[0.98] border border-border bg-surface shadow-subtle"
            >
              <div className="p-2.5 rounded-xl bg-emerald-50 text-emerald-600">
                <ImageIcon className="w-5 h-5" />
              </div>
              <div className="flex-1 text-left">
                <p className="text-sm font-bold text-foreground">Import Image</p>
                <p className="text-[11px] text-muted font-normal">
                  JPEG, PNG, or WebP photo or scan
                </p>
              </div>
              <UploadCloud className="w-4 h-4 text-muted" />
            </button>
          </>
        )}
      </div>
    </BottomSheet>
  );
}
