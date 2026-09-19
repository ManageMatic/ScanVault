import { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';
import type { AuthUser } from '@scanvault/shared';

interface AuthContextType {
  user: AuthUser | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  register: (email: string, password: string, name?: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const refreshUser = useCallback(async () => {
    try {
      const res = await fetch('/api/v1/auth/me', {
        credentials: 'include',
      });

      if (res.ok) {
        const data = await res.json();
        if (data.success && data.data?.user) {
          setUser(data.data.user);
        } else {
          setUser(null);
        }
      } else {
        setUser(null);
      }
    } catch {
      setUser(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    refreshUser();
  }, [refreshUser]);

  const login = async (email: string, password: string) => {
    try {
      const res = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ email, password }),
      });

      const data = await res.json();
      if (res.ok && data.success && data.data?.user) {
        setUser(data.data.user);
        return { success: true };
      } else {
        return {
          success: false,
          error: data.error?.message || 'Invalid email or password. Please try again.',
        };
      }
    } catch {
      return {
        success: false,
        error: 'Unable to connect to server. Please check your network connection.',
      };
    }
  };

  const register = async (email: string, password: string, name?: string) => {
    try {
      const res = await fetch('/api/v1/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ email, password, name }),
      });

      const data = await res.json();
      if (res.ok && data.success && data.data?.user) {
        setUser(data.data.user);
        return { success: true };
      } else {
        return {
          success: false,
          error: data.error?.message || 'Registration failed. Please check your details.',
        };
      }
    } catch {
      return {
        success: false,
        error: 'Unable to connect to server. Please check your network connection.',
      };
    }
  };

  const logout = async () => {
    try {
      await fetch('/api/v1/auth/logout', {
        method: 'POST',
        credentials: 'include',
      });
    } finally {
      setUser(null);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        login,
        register,
        logout,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
