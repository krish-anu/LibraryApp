export type UserInfo = Record<string, unknown>;

const DEFAULT_ADMIN_GROUPS = "admin,library-admin,library_admin,Library Administrator";

const ROLE_CLAIMS = [
  "groups",
  "roles",
  "role",
  "app_roles",
  "appRoles",
  "application_roles",
  "applicationRoles",
  "assigned_roles",
  "assignedRoles",
  "permissions",
  "scope",
  "http://wso2.org/claims/role",
  "http://wso2.org/claims/roles",
  "http://wso2.org/claims/groups",
  "http://wso2.org/claims/applicationRoles",
  "http://wso2.org/claims/application_roles",
];

export function csvEnv(name: string, fallback = "") {
  return new Set(
    (process.env[name] || fallback)
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean),
  );
}

export function claimValues(value: unknown): Set<string> {
  const values = new Set<string>();
  const addValue = (raw: string) => {
    const normalized = raw.trim().toLowerCase();
    if (!normalized) {
      return;
    }
    values.add(normalized);
    normalized
      .split(/[/:|]/)
      .map((part) => part.trim())
      .filter(Boolean)
      .forEach((part) => values.add(part));
  };

  if (typeof value === "string") {
    value
      .replaceAll(",", " ")
      .split(/\s+/)
      .forEach(addValue);
    return values;
  }
  if (Array.isArray(value)) {
    value.forEach((entry) => {
      claimValues(entry).forEach((part) => values.add(part));
    });
    return values;
  }
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    ["value", "name", "display", "displayName"].forEach((key) => {
      const item = record[key];
      if (typeof item === "string" && item.trim()) {
        addValue(item);
      }
    });
  }
  return values;
}

export function isAdminUser(info: UserInfo) {
  const allowedEmails = csvEnv("ADMIN_EMAILS");
  const userIdentifiers = ["email", "username", "preferred_username"]
    .map((claim) => info[claim])
    .filter((value): value is string => typeof value === "string")
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);
  if (userIdentifiers.some((identifier) => allowedEmails.has(identifier))) {
    return true;
  }

  const allowedGroups = csvEnv("ADMIN_GROUPS", DEFAULT_ADMIN_GROUPS);
  const claims = new Set<string>();
  ROLE_CLAIMS.forEach((claim) => {
    claimValues(info[claim]).forEach((value) => claims.add(value));
  });

  return [...claims].some((claim) => allowedGroups.has(claim));
}
