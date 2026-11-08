// CinemaFlix OAuth — verifies Google/Apple idTokens against the provider's
// JWKS before trusting the email payload. Production-grade; the previous
// dev-simulated path is kept only when OAUTH_DEV_MODE=true so the demo app
// keeps working without provider credentials.
//
// Node's crypto can import JWKs directly, so no extra dependencies needed.
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

const PROVIDERS = {
  google: {
    issuerRE: '^https://accounts\\.google\\.com$',
    jwksUrl: 'https://www.googleapis.com/oauth2/v3/certs',
    clientIdEnv: 'GOOGLE_CLIENT_ID',
  },
  apple: {
    issuerRE: '^https://appleid\\.apple\\.com$',
    jwksUrl: 'https://appleid.apple.com/auth/keys',
    clientIdEnv: 'APPLE_CLIENT_ID',
  },
};

const jwksCache = new Map(); // provider -> { keys, fetchedAt }
const JWKS_TTL_MS = 60 * 60 * 1000; // 1 hour

async function fetchJwks(provider) {
  const cached = jwksCache.get(provider.name);
  if (cached && Date.now() - cached.fetchedAt < JWKS_TTL_MS) return cached.keys;
  const res = await fetch(provider.jwksUrl, { signal: AbortSignal.timeout(8000) });
  if (!res.ok) throw new Error(`JWKS fetch failed (${res.status})`);
  const body = (await res.json());
  const keys = Array.isArray(body.keys) ? body.keys : [];
  jwksCache.set(provider.name, { keys, fetchedAt: Date.now() });
  return keys;
}

function jwkToPublicKey(jwk) {
  return crypto.createPublicKey({ key: jwk, format: 'jwk' });
}

/// Returns { ok, email, displayName, provider, mode: 'verified'|'dev' }
/// or throws on an invalid token in production mode.
async function verifyIdToken(providerName, idToken, clientIdOptional) {
  const provider = PROVIDERS[providerName];
  if (!provider) throw new Error(`Unknown oauth provider: ${providerName}`);

  const devMode = process.env.OAUTH_DEV_MODE === 'true';
  if (!idToken && devMode) {
    return { mode: 'dev' }; // caller supplies email/displayName itself
  }
  if (!idToken) {
    throw new Error('idToken required (set OAUTH_DEV_MODE=true for simulated sign-in)');
  }

  // Decode WITHOUT verification to find the matching JWKS key.
  const decodedAny = jwt.decode(idToken, { complete: true });
  if (!decodedAny || typeof decodedAny !== 'object') throw new Error('Malformed idToken');
  const { kid, alg } = decodedAny.header || {};
  if (alg !== 'RS256') throw new Error(`Unsupported idToken alg: ${alg}`);

  const keys = await fetchJwks(provider);
  const jwk = keys.find((k) => k.kid === kid);
  if (!jwk) throw new Error('No matching JWKS key (kid not found)');

  const audience = process.env[provider.clientIdEnv] || clientIdOptional || null;
  const verified = jwt.verify(idToken, jwkToPublicKey(jwk), {
    algorithms: ['RS256'],
    issuer: new RegExp(provider.issuerRE),
    ...(audience ? { audience } : {}),
  });

  const email = verified.email;
  if (!email) throw new Error('idToken has no email claim');
  return {
    mode: 'verified',
    email: String(email).toLowerCase(),
    displayName: verified.name || (email.emailVerified !== false ? email.email?.split('@')[0] : null),
    emailVerified: verified.email_verified !== false,
  };
}

module.exports = { verifyIdToken };
