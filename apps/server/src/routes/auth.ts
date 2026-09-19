import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { hashPassword, verifyPassword, generateToken, hashToken, normalizeEmail } from '../lib/auth.js';
import {
  createSession,
  destroySession,
  destroyAllUserSessions,
  setSessionCookie,
  clearSessionCookie,
  SESSION_COOKIE_NAME,
} from '../lib/session.js';
import {
  isGoogleOAuthConfigured,
  generateGoogleAuthUrl,
  verifyGoogleCode,
} from '../lib/googleOAuth.js';
import { requireAuth } from '../middleware/auth.js';
import { authRateLimiter } from '../middleware/rateLimiter.js';
import { ApiResponse, ApiSuccessResponse, ApiErrorResponse } from '@scanvault/shared';
import { env } from '../config/env.js';

export const authRouter = Router();

// Validation Schemas
const registerSchema = z.object({
  email: z.string().email('Please provide a valid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters long'),
  name: z.string().min(1, 'Name is required').max(100).optional(),
});

const loginSchema = z.object({
  email: z.string().email('Please provide a valid email address'),
  password: z.string().min(1, 'Password is required'),
});

const forgotPasswordSchema = z.object({
  email: z.string().email('Please provide a valid email address'),
});

const resetPasswordSchema = z
  .object({
    token: z.string().min(1, 'Reset token is required'),
    password: z.string().min(8, 'Password must be at least 8 characters long').optional(),
    newPassword: z.string().min(8, 'New password must be at least 8 characters long').optional(),
  })
  .refine((data) => data.password || data.newPassword, {
    message: 'Password is required and must be at least 8 characters long',
    path: ['password'],
  });

/**
 * POST /api/v1/auth/register
 */
authRouter.post('/register', authRateLimiter, async (req: Request, res: Response<ApiResponse<unknown>>) => {
  const parseResult = registerSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: parseResult.error.errors[0]?.message || 'Invalid registration details.',
      },
    });
    return;
  }

  const { email, password, name } = parseResult.data;
  const normalizedEmail = normalizeEmail(email);

  try {
    const existingUser = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (existingUser) {
      res.status(409).json({
        success: false,
        error: {
          code: 'EMAIL_ALREADY_EXISTS',
          message: 'An account with this email address already exists. Please log in.',
        },
      });
      return;
    }

    const passwordHash = await hashPassword(password);

    // Atomically create User and credentials Account
    const user = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          email: normalizedEmail,
          name: name || null,
          passwordHash,
        },
      });

      await tx.account.create({
        data: {
          userId: newUser.id,
          provider: 'credentials',
          providerAccountId: normalizedEmail,
        },
      });

      return newUser;
    });

    // Create session & set HttpOnly cookie
    const { rawToken, expiresAt } = await createSession(user.id);
    setSessionCookie(res, rawToken, expiresAt);

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: user.avatarUrl,
          emailVerified: user.emailVerified ? user.emailVerified.toISOString() : null,
          providers: ['credentials'],
          createdAt: user.createdAt.toISOString(),
        },
      },
    });
  } catch (error) {
    console.error('[ScanVault][Auth] Register error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Could not complete registration. Please try again.',
      },
    });
  }
});

/**
 * POST /api/v1/auth/login
 */
authRouter.post('/login', authRateLimiter, async (req: Request, res: Response<ApiResponse<unknown>>) => {
  const parseResult = loginSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: parseResult.error.errors[0]?.message || 'Invalid email or password.',
      },
    });
    return;
  }

  const { email, password } = parseResult.data;
  const normalizedEmail = normalizeEmail(email);

  try {
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      include: {
        accounts: {
          select: { provider: true },
        },
      },
    });

    if (!user || !user.passwordHash) {
      res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password.',
        },
      });
      return;
    }

    const isMatch = await verifyPassword(password, user.passwordHash);
    if (!isMatch) {
      res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password.',
        },
      });
      return;
    }

    // Create session & set HttpOnly cookie
    const { rawToken, expiresAt } = await createSession(user.id);
    setSessionCookie(res, rawToken, expiresAt);

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: user.avatarUrl,
          emailVerified: user.emailVerified ? user.emailVerified.toISOString() : null,
          providers: user.accounts.map((a) => a.provider),
          createdAt: user.createdAt.toISOString(),
        },
      },
    });
  } catch (error) {
    console.error('[ScanVault][Auth] Login error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Could not log in. Please try again.',
      },
    });
  }
});

/**
 * POST /api/v1/auth/logout
 */
authRouter.post('/logout', async (req: Request, res: Response<ApiSuccessResponse<unknown>>) => {
  const rawToken = req.cookies?.[SESSION_COOKIE_NAME];
  if (rawToken && typeof rawToken === 'string') {
    await destroySession(rawToken);
  }

  clearSessionCookie(res);

  res.status(200).json({
    success: true,
    data: {
      message: 'Logged out successfully.',
    },
  });
});

/**
 * GET /api/v1/auth/me
 */
authRouter.get('/me', requireAuth, (req: Request, res: Response<ApiSuccessResponse<unknown>>) => {
  res.status(200).json({
    success: true,
    data: {
      user: req.user,
    },
  });
});

/**
 * POST /api/v1/auth/forgot-password
 */
authRouter.post('/forgot-password', authRateLimiter, async (req: Request, res: Response<ApiResponse<unknown>>) => {
  const parseResult = forgotPasswordSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: parseResult.error.errors[0]?.message || 'Please provide a valid email.',
      },
    });
    return;
  }

  const { email } = parseResult.data;
  const normalizedEmail = normalizeEmail(email);

  try {
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    let devToken: string | undefined;

    if (user) {
      const rawResetToken = generateToken();
      const tokenHash = hashToken(rawResetToken);
      const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

      await prisma.passwordResetToken.create({
        data: {
          userId: user.id,
          tokenHash,
          expiresAt,
        },
      });

      if (process.env.NODE_ENV !== 'production') {
        devToken = rawResetToken;
      }

      // Development logging of password reset URL
      console.log(`\n🔑 [ScanVault Dev Password Reset Link for ${user.email}]:`);
      console.log(`   http://localhost:5173/reset-password?token=${rawResetToken}\n`);
    }

    // Return success message
    res.status(200).json({
      success: true,
      data: {
        message: 'If an account exists for this email, password reset instructions have been generated.',
      },
      ...(devToken ? { devResetToken: devToken } : {}),
    });
  } catch (error) {
    console.error('[ScanVault][Auth] Forgot-password error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Could not process password reset request.',
      },
    });
  }
});

/**
 * POST /api/v1/auth/reset-password
 */
authRouter.post('/reset-password', authRateLimiter, async (req: Request, res: Response<ApiResponse<unknown>>) => {
  const parseResult = resetPasswordSchema.safeParse(req.body);
  if (!parseResult.success) {
    res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: parseResult.error.errors[0]?.message || 'Invalid reset token or password.',
      },
    });
    return;
  }

  const { token, newPassword, password } = parseResult.data;
  const passwordToUse = (newPassword || password)!;
  const tokenHash = hashToken(token);

  try {
    const resetRecord = await prisma.passwordResetToken.findUnique({
      where: { tokenHash },
    });

    if (!resetRecord || resetRecord.usedAt !== null || resetRecord.expiresAt.getTime() < Date.now()) {
      res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_OR_EXPIRED_TOKEN',
          message: 'The password reset token is invalid, expired, or has already been used.',
        },
      });
      return;
    }

    const passwordHash = await hashPassword(passwordToUse);

    await prisma.$transaction(async (tx) => {
      // Update password
      await tx.user.update({
        where: { id: resetRecord.userId },
        data: { passwordHash },
      });

      // Mark token as used
      await tx.passwordResetToken.update({
        where: { id: resetRecord.id },
        data: { usedAt: new Date() },
      });
    });

    // Invalidate all active sessions for security
    await destroyAllUserSessions(resetRecord.userId);

    res.status(200).json({
      success: true,
      data: {
        message: 'Your password has been reset successfully. Please log in with your new password.',
      },
    });
  } catch (error) {
    console.error('[ScanVault][Auth] Reset-password error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Could not reset password. Please try again.',
      },
    });
  }
});

/**
 * GET /api/v1/auth/google
 * Initiates Google OAuth Authorization Code flow
 */
authRouter.get('/google', (_req: Request, res: Response) => {
  if (!isGoogleOAuthConfigured()) {
    res.status(503).json({
      success: false,
      error: {
        code: 'GOOGLE_OAUTH_NOT_CONFIGURED',
        message: 'Google OAuth is not configured on this server.',
      },
    } as ApiErrorResponse);
    return;
  }

  const state = generateToken();
  console.log('[ScanVault][OAuth] Initiation: generating auth URL...');

  // Set short-lived state cookie (10 minutes)
  res.cookie('scanvault_oauth_state', state, {
    httpOnly: true,
    secure: env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 10 * 60 * 1000,
    path: '/',
  });

  const authUrl = generateGoogleAuthUrl(state);
  res.redirect(authUrl);
});

/**
 * GET /api/v1/auth/google/callback
 * Google OAuth redirect callback
 */
authRouter.get('/google/callback', async (req: Request, res: Response) => {
  const { code, state, error: googleError } = req.query;
  const clientUrl = env.CLIENT_URL || 'http://localhost:5173';

  console.log('[ScanVault][OAuth] Callback reached');

  if (googleError) {
    console.warn('[ScanVault][OAuth] Google returned authorization error:', googleError);
    res.redirect(`${clientUrl}/login?error=google_oauth_denied`);
    return;
  }

  const storedState = req.cookies?.['scanvault_oauth_state'];
  res.clearCookie('scanvault_oauth_state', { path: '/' });

  if (!state || !storedState || state !== storedState || typeof code !== 'string') {
    console.warn('[ScanVault][OAuth] State validation failed or code missing');
    res.redirect(`${clientUrl}/login?error=oauth_state_mismatch`);
    return;
  }

  console.log('[ScanVault][OAuth] State validated successfully');

  try {
    console.log('[ScanVault][OAuth] Exchanging code for Google identity...');
    const googleProfile = await verifyGoogleCode(code);
    console.log('[ScanVault][OAuth] Google identity received for user');

    let user = await prisma.user.findFirst({
      where: {
        accounts: {
          some: {
            provider: 'google',
            providerAccountId: googleProfile.providerAccountId,
          },
        },
      },
    });

    if (!user) {
      // Check if user exists by verified email
      const existingUserByEmail = await prisma.user.findUnique({
        where: { email: googleProfile.email },
      });

      if (existingUserByEmail) {
        // Link Google account
        user = existingUserByEmail;
        await prisma.account.create({
          data: {
            userId: user.id,
            provider: 'google',
            providerAccountId: googleProfile.providerAccountId,
          },
        });
        console.log('[ScanVault][OAuth] Linked Google account to existing user');
      } else {
        // Create new User + Google Account in a transaction
        user = await prisma.$transaction(async (tx) => {
          const newUser = await tx.user.create({
            data: {
              email: googleProfile.email,
              name: googleProfile.name,
              avatarUrl: googleProfile.avatarUrl,
              emailVerified: googleProfile.emailVerified ? new Date() : null,
            },
          });

          await tx.account.create({
            data: {
              userId: newUser.id,
              provider: 'google',
              providerAccountId: googleProfile.providerAccountId,
            },
          });

          return newUser;
        });
        console.log('[ScanVault][OAuth] Created new user with Google identity');
      }
    } else {
      console.log('[ScanVault][OAuth] ScanVault account resolved from Google identity');
    }

    // Create session & set HttpOnly cookie
    const { rawToken, expiresAt } = await createSession(user.id);
    setSessionCookie(res, rawToken, expiresAt);
    console.log('[ScanVault][OAuth] ScanVault session created & HttpOnly cookie set');

    // Redirect to frontend client home
    console.log(`[ScanVault][OAuth] Redirecting to frontend: ${clientUrl}/`);
    res.redirect(`${clientUrl}/`);
  } catch (error) {
    console.error('[ScanVault][OAuth] Callback exchange error:', error);
    res.redirect(`${clientUrl}/login?error=google_oauth_failed`);
  }
});
