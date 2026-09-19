import { OAuth2Client } from 'google-auth-library';
import { env } from '../config/env.js';

export function isGoogleOAuthConfigured(): boolean {
  return Boolean(
    env.GOOGLE_CLIENT_ID &&
    env.GOOGLE_CLIENT_SECRET &&
    env.GOOGLE_CALLBACK_URL
  );
}

function getOAuthClient(): OAuth2Client {
  if (!isGoogleOAuthConfigured()) {
    throw new Error('Google OAuth is not configured. Please set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET.');
  }

  return new OAuth2Client({
    clientId: env.GOOGLE_CLIENT_ID,
    clientSecret: env.GOOGLE_CLIENT_SECRET,
    redirectUri: env.GOOGLE_CALLBACK_URL,
  });
}

/**
 * Generates the Google Authorization Code flow URL with state parameter
 */
export function generateGoogleAuthUrl(state: string): string {
  const client = getOAuthClient();

  return client.generateAuthUrl({
    access_type: 'offline',
    scope: [
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/userinfo.email',
      'openid',
    ],
    state,
    prompt: 'select_account',
  });
}

/**
 * Exchanges authorization code for Google token and verifies Google ID token payload
 */
export async function verifyGoogleCode(code: string): Promise<{
  providerAccountId: string;
  email: string;
  name: string | null;
  avatarUrl: string | null;
  emailVerified: boolean;
}> {
  const client = getOAuthClient();

  const { tokens } = await client.getToken(code);
  if (!tokens.id_token) {
    throw new Error('No id_token received from Google.');
  }

  const ticket = await client.verifyIdToken({
    idToken: tokens.id_token,
    audience: env.GOOGLE_CLIENT_ID,
  });

  const payload = ticket.getPayload();
  if (!payload || !payload.sub || !payload.email) {
    throw new Error('Invalid Google user profile payload.');
  }

  return {
    providerAccountId: payload.sub,
    email: payload.email.toLowerCase().trim(),
    name: payload.name || null,
    avatarUrl: payload.picture || null,
    emailVerified: Boolean(payload.email_verified),
  };
}
