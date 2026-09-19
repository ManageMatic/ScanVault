import { useState, useEffect } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { ShieldCheck, Mail, Lock, Eye, EyeOff, Loader2, AlertCircle } from 'lucide-react';
import { useAuth } from '@/lib/auth';
import { GoogleButton } from '@/components/auth/GoogleButton';

export function LoginPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { login, isAuthenticated } = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  const redirectTarget = searchParams.get('redirect') || '/';
  const urlError = searchParams.get('error');

  useEffect(() => {
    if (urlError === 'google_oauth_failed') {
      setErrorMessage('Google authentication could not be completed. Please try again.');
    } else if (urlError === 'google_oauth_denied') {
      setErrorMessage('Google sign-in was cancelled or denied.');
    } else if (urlError === 'oauth_state_mismatch') {
      setErrorMessage('Security verification expired. Please try signing in again.');
    }
  }, [urlError]);

  useEffect(() => {
    if (isAuthenticated) {
      navigate(redirectTarget, { replace: true });
    }
  }, [isAuthenticated, navigate, redirectTarget]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage('');
    setIsLoading(true);

    const result = await login(email, password);

    if (result.success) {
      navigate(redirectTarget, { replace: true });
    } else {
      setErrorMessage(result.error || 'Invalid email or password.');
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center p-4 xs:p-6 bg-background text-foreground">
      <div className="w-full max-w-md bg-surface border border-border rounded-2xl p-6 xs:p-8 shadow-xl flex flex-col gap-6 animate-scale-in">
        {/* Brand Header */}
        <div className="flex flex-col items-center text-center">
          <div className="w-12 h-12 rounded-2xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary mb-3 shadow-sm">
            <ShieldCheck className="w-7 h-7" />
          </div>
          <h1 className="text-xl xs:text-2xl font-extrabold tracking-tight text-foreground">
            Welcome to ScanVault
          </h1>
          <p className="text-xs text-muted-foreground mt-1">
            Sign in to access your offline-ready document vault
          </p>
        </div>

        {/* Error Alert */}
        {errorMessage && (
          <div className="w-full bg-destructive/10 border border-destructive/20 rounded-xl p-3.5 flex items-start gap-2.5 text-xs text-destructive">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <p className="flex-1 leading-relaxed">{errorMessage}</p>
          </div>
        )}

        {/* Email/Password Form */}
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <label className="block text-xs font-semibold text-foreground mb-1.5">
              Email Address
            </label>
            <div className="relative">
              <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
              <input
                type="email"
                required
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="touch-target w-full bg-surface-secondary border border-border rounded-xl pl-10 pr-4 text-xs xs:text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 transition-all"
              />
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-xs font-semibold text-foreground">
                Password
              </label>
              <Link
                to="/forgot-password"
                className="text-[11px] font-semibold text-primary hover:underline"
              >
                Forgot password?
              </Link>
            </div>
            <div className="relative">
              <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="touch-target w-full bg-surface-secondary border border-border rounded-xl pl-10 pr-10 text-xs xs:text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground p-1"
                aria-label={showPassword ? 'Hide password' : 'Show password'}
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="touch-target-lg w-full mt-2 bg-primary text-primary-foreground hover:opacity-90 active:scale-[0.99] text-xs xs:text-sm font-bold rounded-xl shadow-lg shadow-primary/20 transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:pointer-events-none select-none"
          >
            {isLoading ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Signing In...</span>
              </>
            ) : (
              <span>Sign In</span>
            )}
          </button>
        </form>

        {/* Divider */}
        <div className="relative flex items-center justify-center">
          <div className="w-full border-t border-border" />
          <span className="absolute bg-surface px-3 text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
            Or
          </span>
        </div>

        {/* Google OAuth Button */}
        <GoogleButton label="Continue with Google" disabled={isLoading} />

        {/* Register Link */}
        <div className="text-center text-xs text-muted-foreground pt-1">
          Don't have an account?{' '}
          <Link to="/register" className="font-bold text-primary hover:underline">
            Create an account
          </Link>
        </div>
      </div>
    </div>
  );
}
