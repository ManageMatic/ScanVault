import crypto from 'crypto';
import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 12;

/**
 * Securely hashes a plain text password using bcrypt with 12 salt rounds
 */
export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

/**
 * Verifies a plain text password against a stored bcrypt hash
 */
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

/**
 * Generates a cryptographically secure random session or reset token (64 hex characters)
 */
export function generateToken(): string {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Produces a SHA-256 hash representation of a raw token for safe database storage
 */
export function hashToken(rawToken: string): string {
  return crypto.createHash('sha256').update(rawToken).digest('hex');
}

/**
 * Normalizes email address for consistent indexing and comparison
 */
export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}
