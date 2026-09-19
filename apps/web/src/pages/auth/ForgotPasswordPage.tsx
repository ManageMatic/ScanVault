import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Mail, ArrowLeft, CheckCircle2, AlertCircle, Loader2 } from 'lucide-react';
import { BrandLogo } from '@/components/ui/BrandLogo';

export const ForgotPasswordPage = () => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [devResetToken, setDevResetToken] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) {
      setError('Please enter your email address');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/v1/auth/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Failed to process password reset');
      }

      setSubmitted(true);
      if (data.devResetToken) {
        setDevResetToken(data.devResetToken);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred. Please try again.');
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
            Forgot your password?
          </h1>
          <p className="text-xs xs:text-sm text-muted mt-1 leading-relaxed max-w-xs">
            Enter your email and we'll help you get back into your account.
          </p>
        </div>

        {error && (
          <div className="w-full bg-destructive-soft border border-destructive/20 rounded-xl p-3.5 flex items-start gap-2.5 text-xs text-destructive">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <p className="flex-1 leading-relaxed font-medium">{error}</p>
          </div>
        )}

        {submitted ? (
          <div className="text-center py-3 space-y-4">
            <div className="w-12 h-12 rounded-full bg-success-soft text-success flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-foreground">Check your email</h3>
              <p className="text-xs text-muted mt-1 leading-relaxed">
                If an account exists for <strong className="text-foreground">{email}</strong>, we've sent password reset instructions.
              </p>
            </div>

            {devResetToken && (
              <div className="p-3 bg-surface-secondary border border-border rounded-xl text-left text-xs text-muted">
                <div className="font-semibold text-primary mb-1">Development Mode Reset Link:</div>
                <Link
                  to={`/reset-password?token=${devResetToken}`}
                  className="text-primary hover:underline break-all"
                >
                  Click here to set a new password
                </Link>
              </div>
            )}

            <div className="pt-2">
              <Link
                to="/login"
                className="btn-secondary w-full"
              >
                Return to sign in
              </Link>
            </div>
          </div>
        ) : (
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

            <button
              type="submit"
              disabled={loading}
              className="btn-primary w-full mt-1"
            >
              {loading ? (
                <div className="flex items-center gap-2">
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>Sending Link...</span>
                </div>
              ) : (
                <span>Send reset link</span>
              )}
            </button>

            <Link
              to="/login"
              className="inline-flex items-center justify-center gap-2 text-xs font-medium text-muted hover:text-foreground pt-2 transition-colors"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Back to sign in</span>
            </Link>
          </form>
        )}
      </div>
    </div>
  );
};
