import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ScannerProvider, useScanner } from '../lib/scanner/ScannerContext';
import { CameraPreview } from '../components/scanner/CameraPreview';
import { CornerEditor } from '../components/scanner/CornerEditor';
import { PageEditor } from '../components/scanner/PageEditor';
import { PageManager } from '../components/scanner/PageManager';
import { SaveScanModal } from '../components/scanner/SaveScanModal';
import { useToast } from '../lib/toast';

function ScannerStudio() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const {
    step,
    goToStep,
    addAnotherPage,
    setActivePageIndex,
    retakeCurrentPage,
  } = useScanner();

  const [isSaveModalOpen, setIsSaveModalOpen] = useState(false);

  const handleClose = () => {
    navigate(-1);
  };

  const handleSaved = (docId: string) => {
    setIsSaveModalOpen(false);
    toast({
      title: 'Scan Saved Successfully',
      description: 'Document has been stored in your local vault.',
      type: 'success',
    });
    navigate(`/documents/${docId}`);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black text-white flex flex-col overflow-hidden">
      {step === 'camera' && (
        <CameraPreview
          onClose={handleClose}
          onOpenPageManager={() => goToStep('page-manager')}
          onFinishScan={() => setIsSaveModalOpen(true)}
        />
      )}

      {step === 'editing-corners' && (
        <CornerEditor onCancel={retakeCurrentPage} />
      )}

      {step === 'page-preview' && (
        <PageEditor
          onAddAnotherPage={addAnotherPage}
          onOpenPageManager={() => goToStep('page-manager')}
          onFinishScan={() => setIsSaveModalOpen(true)}
          onRetake={retakeCurrentPage}
        />
      )}

      {step === 'page-manager' && (
        <PageManager
          onBack={() => goToStep('page-preview')}
          onAddAnotherPage={addAnotherPage}
          onSelectPageToEdit={(idx) => {
            setActivePageIndex(idx);
            goToStep('page-preview');
          }}
          onFinishScan={() => setIsSaveModalOpen(true)}
        />
      )}

      <SaveScanModal
        isOpen={isSaveModalOpen}
        onClose={() => setIsSaveModalOpen(false)}
        onSaved={handleSaved}
      />
    </div>
  );
}

export function ScanPage() {
  return (
    <ScannerProvider>
      <ScannerStudio />
    </ScannerProvider>
  );
}
