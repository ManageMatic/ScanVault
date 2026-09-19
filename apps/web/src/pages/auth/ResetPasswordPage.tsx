import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Lock, Eye, EyeOff, CheckCircle2, AlertCircle, Loader2 } from 'lucide-react';
import { BrandLogo } from '@/components/ui/BrandLogo';

export const ResetPasswordPage = () => {
  const [searchParams] = useSearchParams();
  const token = searchParams.get('token') || '';
  const navigate = useNavigate();

  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!token) {
      setError('Invalid or missing reset token. Please request a new password reset link.');
      return;
    }

    if (password.length < 8) {
      setError('Password must be at least 8 characters long.');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/v1/auth/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token, password }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Failed to reset password');
      }

      setSuccess(true);
      setTimeout(() => {
        navigate('/login');
      }, 2500);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred while resetting password.');
    } finally {
      setLoading(false);
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
            Create a new password
          </h1>
          <p className="text-xs xs:text-sm text-muted mt-1 leading-relaxed max-w-xs">
            Please choose a password with at least 8 characters.
          </p>
        </div>

        {error && (
          <div className="w-full bg-destructive-soft border border-destructive/20 rounded-xl p-3.5 flex items-start gap-2.5 text-xs text-destructive">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <p className="flex-1 leading-relaxed font-medium">{error}</p>
          </div>
        )}

        {!token && (
          <div className="w-full bg-warning-soft border border-warning/20 rounded-xl p-3.5 flex items-start gap-2.5 text-xs text-warning">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <p className="flex-1 leading-relaxed">No reset token provided. Please use the link sent to your email.</p>
          </div>
        )}

        {success ? (
          <div className="text-center py-3 space-y-4">
            <div className="w-12 h-12 rounded-full bg-success-soft text-success flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-foreground">Password Reset Complete</h3>
              <p className="text-xs text-muted mt-1">
                Your password has been updated. Redirecting you to sign in...
              </p>
            </div>
            <div className="pt-2">
              <Link to="/login" className="btn-primary w-full">
                Sign in now
              </Link>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div>
              <label className="block text-xs font-semibold text-foreground mb-1.5">
                New Password
              </label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  autoComplete="new-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="At least 8 characters"
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

            <div>
              <label className="block text-xs font-semibold text-foreground mb-1.5">
                Confirm New Password
              </label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  autoComplete="new-password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Repeat new password"
                  className="form-input pl-10"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading || !token}
              className="btn-primary w-full mt-1 disabled:opacity-50"
            >
              {loading ? (
                <div className="flex items-center gap-2">
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>Updating Password...</span>
                </div>
              ) : (
                <span>Reset password</span>
              )}
            </button>
          </form>
        )}
      </div>
    </div>
  );
};
