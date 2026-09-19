import { useState, useEffect } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Mail, Lock, Eye, EyeOff, Loader2, AlertCircle } from 'lucide-react';
import { useAuth } from '@/lib/auth';
import { GoogleButton } from '@/components/auth/GoogleButton';
import { BrandLogo } from '@/components/ui/BrandLogo';

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
      <div className="w-full max-w-md bg-surface border border-border sm:rounded-2xl p-6 xs:p-8 sm:shadow-card flex flex-col gap-6 animate-fade-in">
        {/* Brand Header */}
        <div className="flex flex-col items-center text-center">
          <div className="mb-4">
            <BrandLogo size="lg" showText={false} />
          </div>
          <h1 className="text-xl xs:text-2xl font-bold tracking-tight text-foreground">
            Welcome back
          </h1>
          <p className="text-xs xs:text-sm text-muted mt-1">
            Sign in to continue to your documents
          </p>
        </div>

        {/* Error Alert */}
        {errorMessage && (
          <div className="w-full bg-destructive-soft border border-destructive/20 rounded-xl p-3.5 flex items-start gap-2.5 text-xs text-destructive">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <p className="flex-1 leading-relaxed font-medium">{errorMessage}</p>
          </div>
        )}

        {/* Form Inputs */}
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <label className="block text-xs font-semibold text-foreground mb-1.5">
              Email Address
            </label>
            <div className="relative">
              <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
              <input
                type="email"
                required
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="form-input pl-10"
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
                className="text-xs font-medium text-primary hover:text-primary-hover hover:underline"
              >
                Forgot password?
              </Link>
            </div>
            <div className="relative">
              <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="form-input pl-10 pr-10"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-subtle hover:text-foreground p-1 transition-colors"
                aria-label={showPassword ? 'Hide password' : 'Show password'}
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="btn-primary w-full mt-1"
          >
            {isLoading ? (
              <div className="flex items-center gap-2">
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Signing In...</span>
              </div>
            ) : (
              <span>Sign in</span>
            )}
          </button>
        </form>

        {/* Divider */}
        <div className="relative flex items-center justify-center my-1">
          <div className="w-full border-t border-border" />
          <span className="absolute bg-surface px-3 text-[11px] font-medium uppercase tracking-wider text-muted">
            Or
          </span>
        </div>

        {/* Google OAuth Button */}
        <GoogleButton label="Continue with Google" disabled={isLoading} />

        {/* Register Footer */}
        <div className="text-center text-xs text-muted pt-1">
          Don't have an account?{' '}
          <Link to="/register" className="font-semibold text-primary hover:text-primary-hover hover:underline">
            Create account
          </Link>
        </div>
      </div>
    </div>
  );
}
