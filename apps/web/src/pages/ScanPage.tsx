import { Camera, Upload, AlertCircle, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/lib/toast';

export function ScanPage() {
  const navigate = useNavigate();
  const { toast } = useToast();

  return (
    <div className="w-full flex flex-col gap-6 animate-fade-in">
      {/* 1. Header Toolbar */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate(-1)}
          className="touch-target px-3 -ml-2 text-xs font-semibold text-foreground hover:bg-surface-secondary rounded-xl transition-colors flex items-center gap-1.5"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </button>
        <span className="text-xs font-semibold text-primary">
          Scanner Studio
        </span>
      </div>

      {/* 2. Scanner Viewfinder Card */}
      <div className="w-full bg-surface border border-border rounded-2xl p-6 xs:p-8 flex flex-col items-center justify-center text-center shadow-subtle relative overflow-hidden min-h-[320px]">
        {/* Viewfinder Corners */}
        <div className="absolute inset-4 border border-dashed border-border pointer-events-none rounded-xl" />

        <div className="w-14 h-14 rounded-2xl bg-primary-soft text-primary flex items-center justify-center mb-4 shadow-sm">
          <Camera className="w-7 h-7" />
        </div>

        <h2 className="text-lg xs:text-xl font-bold text-foreground mb-1.5">
          Scanner Ready
        </h2>

        <p className="text-xs text-muted max-w-sm mb-6 leading-relaxed">
          The camera scanner with automatic edge detection and perspective correction will be connected in Module 05.
        </p>

        {/* Action Buttons */}
        <div className="w-full max-w-xs flex flex-col gap-2.5 z-10">
          <button
            onClick={() =>
              toast({
                title: 'Camera Scanner',
                description: 'Camera integration scheduled for Module 05',
                type: 'info',
              })
            }
            className="btn-primary w-full shadow-sm flex items-center justify-center gap-2"
          >
            <Camera className="w-4 h-4" />
            <span>Launch Camera Scanner</span>
          </button>

          <button
            onClick={() =>
              toast({
                title: 'File Upload',
                description: 'File upload engine scheduled for Module 04/05',
                type: 'info',
              })
            }
            className="btn-secondary w-full flex items-center justify-center gap-2"
          >
            <Upload className="w-4 h-4 text-muted" />
            <span>Import Images / PDF</span>
          </button>
        </div>
      </div>

      {/* 3. Notice */}
      <div className="bg-surface-secondary border border-border rounded-xl p-4 flex items-start gap-3">
        <AlertCircle className="w-4 h-4 text-primary shrink-0 mt-0.5" />
        <div className="text-xs text-muted leading-relaxed">
          <span className="font-semibold text-foreground">Client-Side Processing:</span> Real-time document boundary detection, perspective warping, shadow removal, and magic color filters operating 100% locally in your browser.
        </div>
      </div>
    </div>
  );
}
