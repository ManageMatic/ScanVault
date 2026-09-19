import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Mail, ArrowLeft, ArrowRight, ShieldCheck, CheckCircle2, AlertCircle } from 'lucide-react';

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
    <div className="min-h-screen bg-[var(--color-bg)] flex flex-col justify-center px-4 py-8 sm:px-6 lg:px-8 selection:bg-[var(--color-primary-light)]">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <Link
          to="/login"
          className="inline-flex items-center gap-2 text-xs font-semibold text-[var(--color-text-muted)] hover:text-[var(--color-text)] mb-6 transition-colors group"
        >
          <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-0.5" />
          Back to sign in
        </Link>

        {/* Logo and Header */}
        <div className="flex justify-center">
          <div className="w-12 h-12 rounded-2xl bg-[var(--color-primary)]/10 border border-[var(--color-primary)]/20 flex items-center justify-center text-[var(--color-primary)] shadow-inner">
            <ShieldCheck className="w-6 h-6" />
          </div>
        </div>
        <h1 className="mt-4 text-center text-2xl font-bold tracking-tight text-[var(--color-text)]">
          Reset your password
        </h1>
        <p className="mt-1 text-center text-xs text-[var(--color-text-muted)] max-w-xs mx-auto">
          Enter your registered email address and we'll send you instructions to reset your password.
        </p>
      </div>

      <div className="mt-6 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="glass-card p-6 sm:p-8 rounded-3xl border border-[var(--color-border)] shadow-xl relative overflow-hidden">
          {error && (
            <div className="mb-5 p-3.5 rounded-xl bg-[var(--color-danger)]/10 border border-[var(--color-danger)]/20 text-[var(--color-danger)] text-xs flex items-center gap-2.5 animate-fade-in">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {submitted ? (
            <div className="text-center py-4 space-y-4">
              <div className="w-12 h-12 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-500 flex items-center justify-center mx-auto">
                <CheckCircle2 className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-base font-semibold text-[var(--color-text)]">Check your inbox</h3>
                <p className="text-xs text-[var(--color-text-muted)] mt-1.5 leading-relaxed">
                  If an account exists for <strong className="text-[var(--color-text)]">{email}</strong>, you will receive password reset instructions.
                </p>
              </div>

              {devResetToken && (
                <div className="p-3 bg-[var(--color-bg-subtle)] border border-[var(--color-border)] rounded-xl text-left text-xs text-[var(--color-text-muted)]">
                  <div className="font-medium text-[var(--color-primary)] mb-1">Development Mode Link:</div>
                  <Link
                    to={`/reset-password?token=${devResetToken}`}
                    className="text-[var(--color-primary)] underline break-all hover:opacity-80"
                  >
                    Click here to reset your password now
                  </Link>
                </div>
              )}

              <div className="pt-2">
                <Link
                  to="/login"
                  className="btn btn-secondary w-full text-xs font-semibold py-2.5"
                >
                  Return to Sign In
                </Link>
              </div>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wider mb-1.5">
                  Email Address
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-[var(--color-text-muted)] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="name@example.com"
                    autoComplete="email"
                    className="w-full pl-10 pr-3.5 py-2.5 rounded-xl bg-[var(--color-bg-subtle)] border border-[var(--color-border)] text-xs text-[var(--color-text)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-[var(--color-primary)] focus:ring-1 focus:ring-[var(--color-primary)] transition-colors"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="btn btn-primary w-full py-2.5 text-xs font-semibold flex items-center justify-center gap-2 shadow-lg shadow-[var(--color-primary)]/20 mt-2"
              >
                {loading ? (
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  <>
                    <span>Send Reset Instructions</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
