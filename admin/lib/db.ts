import { Pool, PoolClient, type PoolConfig } from "pg";

type DbSslMode = "verify" | "no-verify" | "disable";

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

function resolveSslMode(): DbSslMode {
  const raw = sanitizeEnvValue(
    process.env.DB_SSL_MODE || process.env.DB_SSLMODE,
  ).toLowerCase();

  if (raw === "verify" || raw === "no-verify" || raw === "disable") {
    return raw;
  }
  if (raw === "require" || raw === "prefer" || raw === "allow") {
    return "no-verify";
  }

  // Default to strict TLS in production, relaxed verification in local dev.
  return process.env.NODE_ENV === "production" ? "verify" : "no-verify";
}

function resolveSslConfig(): PoolConfig["ssl"] {
  const mode = resolveSslMode();
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
    return {
      connectionString: normalizeConnectionString(connectionString),
      ssl: resolveSslConfig(),
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
