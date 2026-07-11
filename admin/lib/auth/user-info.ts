import { isAdminUser, type UserInfo } from "@/lib/auth/admin-policy";
import { sanitizeEnvValue } from "@/lib/auth/env";

export type VerifiedUser = { sub: string; email: string; name: string };

type UserInfoSuccess = { ok: true; info: UserInfo; user: VerifiedUser };
type UserInfoFailure = {
  ok: false;
  reason:
    | "missing_endpoint"
    | "missing_token"
    | "http_error"
    | "invalid_json"
    | "missing_subject"
    | "request_error";
  status?: number;
  detail?: string;
};

export type UserInfoResult = UserInfoSuccess | UserInfoFailure;

type AdminIdentitySuccess = {
  ok: true;
  info: UserInfo;
  user: VerifiedUser;
};
type AdminIdentityFailure = {
  ok: false;
  reason: "not_admin" | "userinfo_unavailable" | "missing_subject";
  status?: number;
};

export type AdminIdentityResult = AdminIdentitySuccess | AdminIdentityFailure;

function requestErrorDetail(error: unknown) {
  if (!(error instanceof Error)) {
    return "Unknown request error";
  }

  const cause =
    error.cause && typeof error.cause === "object"
      ? (error.cause as { code?: unknown; message?: unknown })
      : undefined;
  const causeCode = typeof cause?.code === "string" ? cause.code : "";
  const causeMessage =
    typeof cause?.message === "string" ? cause.message : "";

  return [error.name, error.message, causeCode, causeMessage]
    .filter(Boolean)
    .join(": ");
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function configuredUserInfoEndpoint() {
  const explicit = sanitizeEnvValue(process.env.ASGARDEO_USERINFO_ENDPOINT);
  if (explicit) {
    return explicit;
  }

  const baseUrl =
    sanitizeEnvValue(process.env.ASGARDEO_BASE_URL) ||
    sanitizeEnvValue(process.env.NEXT_PUBLIC_ASGARDEO_BASE_URL);
  return baseUrl ? `${baseUrl.replace(/\/+$/, "")}/oauth2/userinfo` : "";
}

export function userFromInfo(info: UserInfo): VerifiedUser | null {
  const sub = typeof info.sub === "string" ? info.sub.trim() : "";
  if (!sub) {
    return null;
  }

  return {
    sub,
    email: typeof info.email === "string" ? info.email : "",
    name:
      [info.given_name, info.family_name]
        .filter((value) => typeof value === "string" && value.trim())
        .join(" ") ||
      (typeof info.name === "string" ? info.name : "") ||
      (typeof info.preferred_username === "string"
        ? info.preferred_username
        : "") ||
      (typeof info.username === "string" ? info.username : "") ||
      "",
  };
}

export async function fetchUserInfo(accessToken: string): Promise<UserInfoResult> {
  const endpoint = configuredUserInfoEndpoint();
  if (!endpoint) {
    return { ok: false, reason: "missing_endpoint" };
  }
  if (!accessToken) {
    return { ok: false, reason: "missing_token" };
  }

  const attempts = [0, 250, 750];
  let lastError = "";
  for (const delay of attempts) {
    if (delay) {
      await sleep(delay);
    }

    try {
      const res = await fetch(endpoint, {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        cache: "no-store",
      });
      if (!res.ok) {
        return { ok: false, reason: "http_error", status: res.status };
      }

      const text = await res.text();
      let info: UserInfo;
      try {
        info = JSON.parse(text) as UserInfo;
      } catch {
        return { ok: false, reason: "invalid_json", status: res.status };
      }

      const user = userFromInfo(info);
      if (!user) {
        return { ok: false, reason: "missing_subject", status: res.status };
      }

      return { ok: true, info, user };
    } catch (error) {
      lastError = requestErrorDetail(error);
    }
  }

  return { ok: false, reason: "request_error", detail: lastError };
}

export async function resolveAdminIdentity(
  accessToken: string,
): Promise<AdminIdentityResult> {
  const userInfo = await fetchUserInfo(accessToken);
  if (!userInfo.ok) {
    console.warn("[AUTH] Userinfo unavailable during admin check", {
      reason: userInfo.reason,
      status: userInfo.status,
      detail: userInfo.detail,
    });
    return {
      ok: false,
      reason: "userinfo_unavailable",
      status: userInfo.status,
    };
  }

  if (!isAdminUser(userInfo.info)) {
    console.warn("[AUTH] Administrator role missing from userinfo claims", {
      username: userInfo.info.username,
      email: userInfo.info.email,
      groups: userInfo.info.groups,
      roles: userInfo.info.roles,
      role: userInfo.info.role,
      applicationRoles: userInfo.info.applicationRoles,
      application_roles: userInfo.info.application_roles,
      wso2Roles: userInfo.info["http://wso2.org/claims/roles"],
      wso2Role: userInfo.info["http://wso2.org/claims/role"],
    });
    return { ok: false, reason: "not_admin" };
  }

  return { ok: true, info: userInfo.info, user: userInfo.user };
}
