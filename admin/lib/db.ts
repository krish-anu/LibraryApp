import { Pool, PoolClient } from "pg";

type DbSslMode = "verify" | "no-verify" | "disable";

function resolveSslMode(): DbSslMode {
  const raw = (process.env.DB_SSL_MODE || "").trim().toLowerCase();
  if (raw === "verify" || raw === "no-verify" || raw === "disable") {
    return raw;
  }
  // Default to strict TLS in production, relaxed verification in local dev.
  return process.env.NODE_ENV === "production" ? "verify" : "no-verify";
}

function resolveSslConfig() {
  const mode = resolveSslMode();
  if (mode === "disable") {
    return false;
  }

  const ca = (process.env.DB_SSL_CA_CERT || "").replace(/\\n/g, "\n").trim();
  return {
    rejectUnauthorized: mode === "verify",
    ...(ca ? { ca } : {}),
  };
}

// Use DATABASE_URL if available, otherwise fall back to individual env vars
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: resolveSslConfig(),
  // Connection pool settings
  max: 20,
  min: 2,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

export async function getClient(): Promise<PoolClient> {
  return pool.connect();
}

export async function query<T>(text: string, params?: unknown[]): Promise<T[]> {
  const client = await pool.connect();
  try {
    const result = await client.query(text, params);
    return result.rows as T[];
  } finally {
    client.release();
  }
}

export async function queryOne<T>(
  text: string,
  params?: unknown[],
): Promise<T | null> {
  const rows = await query<T>(text, params);
  return rows[0] || null;
}

export { pool };
