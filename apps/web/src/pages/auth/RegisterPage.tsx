import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { User, Mail, Lock, Eye, EyeOff, Loader2, AlertCircle } from 'lucide-react';
import { useAuth } from '@/lib/auth';
import { GoogleButton } from '@/components/auth/GoogleButton';
import { BrandLogo } from '@/components/ui/BrandLogo';

export function RegisterPage() {
  const navigate = useNavigate();
  const { register, isAuthenticated } = useAuth();

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    if (isAuthenticated) {
      navigate('/', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage('');

    if (password !== confirmPassword) {
      setErrorMessage('Passwords do not match.');
      return;
    }

    if (password.length < 8) {
      setErrorMessage('Password must be at least 8 characters long.');
      return;
    }

    setIsLoading(true);

    const result = await register(email, password, name.trim() || undefined);

    if (result.success) {
      navigate('/', { replace: true });
    } else {
      setErrorMessage(result.error || 'Registration failed. Please try again.');
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
            Create your ScanVault account
          </h1>
          <p className="text-xs xs:text-sm text-muted mt-1 leading-relaxed max-w-xs">
            Keep your documents organized, accessible, and ready when you need them.
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
        <form onSubmit={handleSubmit} className="flex flex-col gap-3.5">
          <div>
            <label className="block text-xs font-semibold text-foreground mb-1">
              Full Name
            </label>
            <div className="relative">
              <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
              <input
                type="text"
                autoComplete="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Alex Morgan"
                className="form-input pl-10"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-foreground mb-1">
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
            <label className="block text-xs font-semibold text-foreground mb-1">
              Password
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
            <label className="block text-xs font-semibold text-foreground mb-1">
              Confirm Password
            </label>
            <div className="relative">
              <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-subtle pointer-events-none" />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                autoComplete="new-password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Re-enter password"
                className="form-input pl-10"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="btn-primary w-full mt-2"
          >
            {isLoading ? (
              <div className="flex items-center gap-2">
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Creating Account...</span>
              </div>
            ) : (
              <span>Create account</span>
            )}
          </button>
        </form>

        {/* Divider */}
        <div className="relative flex items-center justify-center my-0.5">
          <div className="w-full border-t border-border" />
          <span className="absolute bg-surface px-3 text-[11px] font-medium uppercase tracking-wider text-muted">
            Or
          </span>
        </div>

        {/* Google OAuth Button */}
        <GoogleButton label="Sign up with Google" disabled={isLoading} />

        {/* Footer */}
        <div className="text-center text-xs text-muted pt-1">
          Already have an account?{' '}
          <Link to="/login" className="font-semibold text-primary hover:text-primary-hover hover:underline">
            Sign in
          </Link>
        </div>
      </div>
    </div>
  );
}
