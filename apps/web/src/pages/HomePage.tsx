import { useState, useEffect } from 'react';
import { Database, Server, Smartphone, CheckCircle2, XCircle, Loader2, RefreshCw } from 'lucide-react';
import { db } from '@/lib/db';
import type { HealthResponse } from '@scanvault/shared';

export function HomePage() {
  const [apiStatus, setApiStatus] = useState<'checking' | 'ok' | 'error'>('checking');
  const [apiDetails, setApiDetails] = useState<HealthResponse | null>(null);
  const [dbStatus, setDbStatus] = useState<'checking' | 'ok' | 'error'>('checking');
  const [isRefreshing, setIsRefreshing] = useState(false);

  const checkHealth = async () => {
    setIsRefreshing(true);
    setApiStatus('checking');
    setDbStatus('checking');

    // 1. Check Backend API through Vite Proxy
    try {
      const res = await fetch('/api/v1/health');
      if (res.ok) {
        const data: HealthResponse = await res.json();
        setApiDetails(data);
        setApiStatus('ok');
      } else {
        setApiStatus('error');
      }
    } catch {
      setApiStatus('error');
    }

    // 2. Check Dexie IndexedDB
    try {
      await db.open();
      const count = await db.documents.count();
      if (typeof count === 'number') {
        setDbStatus('ok');
      } else {
        setDbStatus('error');
      }
    } catch {
      setDbStatus('error');
    } finally {
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    checkHealth();
  }, []);

  return (
    <div className="w-full flex flex-col gap-6">
      {/* Hero Welcome Card */}
      <div className="w-full bg-gradient-to-b from-vault-card to-vault-bg border border-vault-border rounded-2xl p-5 xs:p-6 shadow-xl relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-brand-500/5 rounded-full blur-3xl pointer-events-none" />
        
        <div className="relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-brand-500/10 text-brand-400 border border-brand-500/20 mb-3">
            <span>✨</span> Module 01 Foundation
          </div>
          <h1 className="text-2xl xs:text-3xl font-extrabold tracking-tight text-white mb-2">
            ScanVault Web
          </h1>
          <p className="text-sm text-slate-400 leading-relaxed max-w-xl">
            Mobile-First Progressive Web App for document scanning, offline storage, OCR, and PDF management.
          </p>
        </div>
      </div>

      {/* Live Foundation Architecture Status Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Backend API Health Card */}
        <div className="bg-vault-card border border-vault-border rounded-xl p-4 flex flex-col justify-between shadow-md">
          <div className="flex items-start justify-between mb-3">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-lg bg-blue-500/10 border border-blue-500/20 text-blue-400 flex items-center justify-center">
                <Server className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white">Backend API</h3>
                <p className="text-[11px] text-slate-400">Express + Node 24</p>
              </div>
            </div>
            {apiStatus === 'checking' && <Loader2 className="w-4 h-4 text-blue-400 animate-spin" />}
            {apiStatus === 'ok' && <CheckCircle2 className="w-4 h-4 text-emerald-400" />}
            {apiStatus === 'error' && <XCircle className="w-4 h-4 text-red-400" />}
          </div>
          <div className="text-xs text-slate-400 bg-vault-surface/60 rounded-lg p-2.5 border border-vault-border/50">
            <div className="flex justify-between items-center mb-1">
              <span>Endpoint:</span>
              <span className="font-mono text-[10px] text-slate-300">/api/v1/health</span>
            </div>
            <div className="flex justify-between items-center">
              <span>Status:</span>
              <span className={apiStatus === 'ok' ? 'text-emerald-400 font-medium' : 'text-slate-400'}>
                {apiStatus === 'ok' ? `Connected (${apiDetails?.service})` : apiStatus === 'checking' ? 'Checking...' : 'Disconnected'}
              </span>
            </div>
          </div>
        </div>

        {/* Client IndexedDB (Dexie) Card */}
        <div className="bg-vault-card border border-vault-border rounded-xl p-4 flex flex-col justify-between shadow-md">
          <div className="flex items-start justify-between mb-3">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center">
                <Database className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white">Local Vault</h3>
                <p className="text-[11px] text-slate-400">IndexedDB (Dexie)</p>
              </div>
            </div>
            {dbStatus === 'checking' && <Loader2 className="w-4 h-4 text-emerald-400 animate-spin" />}
            {dbStatus === 'ok' && <CheckCircle2 className="w-4 h-4 text-emerald-400" />}
            {dbStatus === 'error' && <XCircle className="w-4 h-4 text-red-400" />}
          </div>
          <div className="text-xs text-slate-400 bg-vault-surface/60 rounded-lg p-2.5 border border-vault-border/50">
            <div className="flex justify-between items-center mb-1">
              <span>Database:</span>
              <span className="font-mono text-[10px] text-slate-300">ScanVaultLocalDB</span>
            </div>
            <div className="flex justify-between items-center">
              <span>Storage:</span>
              <span className={dbStatus === 'ok' ? 'text-emerald-400 font-medium' : 'text-slate-400'}>
                {dbStatus === 'ok' ? 'Ready (Offline Blobs)' : dbStatus === 'checking' ? 'Initializing...' : 'Failed'}
              </span>
            </div>
          </div>
        </div>

        {/* Mobile PWA Shell Card */}
        <div className="bg-vault-card border border-vault-border rounded-xl p-4 flex flex-col justify-between shadow-md">
          <div className="flex items-start justify-between mb-3">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-lg bg-purple-500/10 border border-purple-500/20 text-purple-400 flex items-center justify-center">
                <Smartphone className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white">Mobile PWA</h3>
                <p className="text-[11px] text-slate-400">Touch & Safe-Area</p>
              </div>
            </div>
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="text-xs text-slate-400 bg-vault-surface/60 rounded-lg p-2.5 border border-vault-border/50">
            <div className="flex justify-between items-center mb-1">
              <span>Touch Targets:</span>
              <span className="font-mono text-[10px] text-emerald-400">≥ 44px</span>
            </div>
            <div className="flex justify-between items-center">
              <span>Safe-Area CSS:</span>
              <span className="text-emerald-400 font-medium">Enabled</span>
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col xs:flex-row items-center gap-3">
        <button
          onClick={checkHealth}
          disabled={isRefreshing}
          className="touch-target w-full xs:w-auto px-5 bg-vault-surface hover:bg-vault-border active:scale-95 text-slate-200 font-medium text-xs rounded-xl border border-vault-border transition-all flex items-center justify-center gap-2"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-brand-400' : ''}`} />
          Run Health Diagnostics
        </button>
      </div>
    </div>
  );
}
