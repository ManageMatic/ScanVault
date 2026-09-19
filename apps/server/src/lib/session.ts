import { Response } from 'express';
import { prisma } from './prisma.js';
import { generateToken, hashToken } from './auth.js';
import { env } from '../config/env.js';

export const SESSION_COOKIE_NAME = 'scanvault_session';
export const SESSION_DURATION_DAYS = 30;
export const SESSION_DURATION_MS = SESSION_DURATION_DAYS * 24 * 60 * 60 * 1000;

export interface SafeUser {
  id: string;
  email: string;
  name: string | null;
  avatarUrl: string | null;
  emailVerified: string | null;
  providers?: string[];
  createdAt?: string;
}

/**
 * Creates a new authenticated session in PostgreSQL and returns the raw token for HttpOnly cookie
 */
export async function createSession(userId: string): Promise<{ rawToken: string; expiresAt: Date }> {
  const rawToken = generateToken();
  const tokenHash = hashToken(rawToken);
  const expiresAt = new Date(Date.now() + SESSION_DURATION_MS);

  await prisma.session.create({
    data: {
      userId,
      tokenHash,
      expiresAt,
    },
  });

  return { rawToken, expiresAt };
}

/**
 * Validates a raw session token against stored SHA-256 token hash and checks expiration
 */
export async function validateSession(rawToken: string) {
  const tokenHash = hashToken(rawToken);

  const session = await prisma.session.findUnique({
    where: { tokenHash },
    include: {
      user: {
        include: {
          accounts: {
            select: { provider: true },
          },
        },
      },
    },
  });

  if (!session) {
    return null;
  }

  // Check if session has expired
  if (session.expiresAt.getTime() < Date.now()) {
    // Delete expired session
    await prisma.session.delete({ where: { id: session.id } }).catch(() => {});
    return null;
  }

  const safeUser: SafeUser = {
    id: session.user.id,
    email: session.user.email,
    name: session.user.name,
    avatarUrl: session.user.avatarUrl,
    emailVerified: session.user.emailVerified ? session.user.emailVerified.toISOString() : null,
    providers: session.user.accounts.map((a) => a.provider),
    createdAt: session.user.createdAt.toISOString(),
  };

  return { session, user: safeUser };
}

/**
 * Destroys a session by raw token
 */
export async function destroySession(rawToken: string): Promise<void> {
  const tokenHash = hashToken(rawToken);
  await prisma.session.deleteMany({
    where: { tokenHash },
  }).catch(() => {});
}

/**
 * Invalidates all active sessions for a user (e.g. on password reset)
 */
export async function destroyAllUserSessions(userId: string): Promise<void> {
  await prisma.session.deleteMany({
    where: { userId },
  }).catch(() => {});
}

/**
 * Sets secure HttpOnly session cookie on the response
 */
export function setSessionCookie(res: Response, rawToken: string, expiresAt: Date): void {
  const isProduction = env.NODE_ENV === 'production';

  res.cookie(SESSION_COOKIE_NAME, rawToken, {
    httpOnly: true,
    secure: isProduction,
    sameSite: isProduction ? 'lax' : 'lax',
    expires: expiresAt,
    path: '/',
  });
}

/**
 * Clears the session cookie from the response
 */
export function clearSessionCookie(res: Response): void {
  const isProduction = env.NODE_ENV === 'production';

  res.clearCookie(SESSION_COOKIE_NAME, {
    httpOnly: true,
    secure: isProduction,
    sameSite: isProduction ? 'lax' : 'lax',
    path: '/',
  });
}
