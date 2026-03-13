import { Pool, PoolClient, type PoolConfig } from "pg";

type DbSslMode = "verify" | "no-verify" | "disable";
type ResolvedSslMode = {
  mode: DbSslMode;
  source: "env" | "url" | "supabase-pooler-default" | "default";
};

function sanitizeEnvValue(value?: string | null): string {
  if (!value) {
    return "";
  }

  const trimmed = value.trim();
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1).trim();
  }

  return trimmed;
}

function normalizeConnectionString(value: string): string {
  return value.replace(/^postgresql\+[^:]+:\/\//i, "postgresql://");
}

function parseSslMode(rawValue?: string | null): DbSslMode | null {
  const raw = sanitizeEnvValue(rawValue).toLowerCase();

  if (raw === "verify" || raw === "no-verify" || raw === "disable") {
    return raw;
  }
  if (raw === "require" || raw === "prefer" || raw === "allow") {
    return "no-verify";
  }
  if (raw === "verify-ca" || raw === "verify-full") {
    return "verify";
  }

  return null;
}

function resolveSslMode(connectionString?: string): ResolvedSslMode {
  const envMode = parseSslMode(process.env.DB_SSL_MODE || process.env.DB_SSLMODE);
  if (envMode) {
    return { mode: envMode, source: "env" };
  }

  if (connectionString) {
    try {
      const url = new URL(connectionString);
      const urlMode = parseSslMode(url.searchParams.get("sslmode") || "");
      if (urlMode) {
        return { mode: urlMode, source: "url" };
      }

      // Supabase transaction pooler connections frequently present a cert chain
      // that Node's strict verifier rejects in serverless runtimes.
      if (url.hostname.toLowerCase().endsWith(".pooler.supabase.com")) {
        return { mode: "no-verify", source: "supabase-pooler-default" };
      }
    } catch {
      // Fall through to the default mode when the URL cannot be parsed.
    }
  }

  // Default to strict TLS in production, relaxed verification in local dev.
  return {
    mode: process.env.NODE_ENV === "production" ? "verify" : "no-verify",
    source: "default",
  };
}

function resolveSslConfig(connectionString?: string): PoolConfig["ssl"] {
  const { mode } = resolveSslMode(connectionString);
  if (mode === "disable") {
    return false;
  }

  const ca = sanitizeEnvValue(process.env.DB_SSL_CA_CERT).replace(
    /\\n/g,
    "\n",
  );
  return {
    rejectUnauthorized: mode === "verify",
    ...(ca ? { ca } : {}),
  };
}

function resolvePoolConfig(): PoolConfig {
  const connectionString = sanitizeEnvValue(process.env.DATABASE_URL);

  if (connectionString) {
    const normalizedConnectionString = normalizeConnectionString(connectionString);
    return {
      connectionString: normalizedConnectionString,
      ssl: resolveSslConfig(normalizedConnectionString),
    };
  }

  const host = sanitizeEnvValue(process.env.DB_HOST);
  const port = sanitizeEnvValue(process.env.DB_PORT);
  const database = sanitizeEnvValue(process.env.DB_NAME);
  const user = sanitizeEnvValue(process.env.DB_USER);
  const password = sanitizeEnvValue(process.env.DB_PASSWORD);

  if (!host || !port || !database || !user || !password) {
    throw new Error(
      "Database configuration is incomplete. Set DATABASE_URL or DB_HOST, DB_PORT, DB_NAME, DB_USER, and DB_PASSWORD.",
    );
  }

  const parsedPort = Number.parseInt(port, 10);
  if (!Number.isFinite(parsedPort) || parsedPort <= 0) {
    throw new Error(`Invalid DB_PORT value: ${port}`);
  }

  return {
    host,
    port: parsedPort,
    database,
    user,
    password,
    ssl: resolveSslConfig(),
  };
}

const pool = new Pool({
  ...resolvePoolConfig(),
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
