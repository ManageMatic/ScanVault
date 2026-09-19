import { Camera, Upload, AlertCircle, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/lib/toast';

export function ScanPage() {
  const navigate = useNavigate();
  const { toast } = useToast();

  return (
    <div className="w-full flex flex-col gap-6">
      {/* 1. Header Toolbar */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate(-1)}
          className="touch-target px-3 -ml-2 text-xs font-semibold text-foreground hover:bg-surface-secondary rounded-xl transition-colors flex items-center gap-1.5"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </button>
        <span className="text-xs font-bold uppercase tracking-wider text-primary">
          Scanner Studio
        </span>
      </div>

      {/* 2. Scanner Viewfinder Placeholder Card */}
      <div className="w-full bg-surface border border-border rounded-2xl p-6 xs:p-8 flex flex-col items-center justify-center text-center shadow-lg relative overflow-hidden min-h-[320px]">
        {/* Viewfinder Corners */}
        <div className="absolute inset-4 border-2 border-dashed border-border pointer-events-none rounded-xl" />

        <div className="w-16 h-16 rounded-3xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary mb-4 shadow-sm animate-pulse">
          <Camera className="w-8 h-8" />
        </div>

        <h2 className="text-lg xs:text-xl font-extrabold text-foreground mb-2">
          Scanner Ready
        </h2>

        <p className="text-xs text-muted-foreground max-w-sm mb-6 leading-relaxed">
          The high-performance camera scanner with automatic edge detection and perspective correction will be connected in <strong className="text-primary font-semibold">Module 05</strong>.
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
            className="touch-target-lg w-full bg-primary text-primary-foreground hover:opacity-90 active:scale-95 text-xs xs:text-sm font-bold rounded-xl shadow-lg shadow-primary/20 transition-all flex items-center justify-center gap-2"
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
            className="touch-target-lg w-full bg-surface-secondary hover:bg-border text-foreground active:scale-95 text-xs font-semibold rounded-xl border border-border transition-all flex items-center justify-center gap-2"
          >
            <Upload className="w-4 h-4 text-primary" />
            <span>Import Images / PDF</span>
          </button>
        </div>
      </div>

      {/* 3. Upcoming Scanner Features Notice */}
      <div className="bg-surface-secondary/60 border border-border rounded-xl p-4 flex items-start gap-3">
        <AlertCircle className="w-4 h-4 text-primary shrink-0 mt-0.5" />
        <div className="text-xs text-muted-foreground leading-relaxed">
          <span className="font-semibold text-foreground">Upcoming Scanner Engine:</span> Real-time document boundary detection, perspective warping, shadow removal, and magic color filters operating 100% locally in browser.
        </div>
      </div>
    </div>
  );
}
