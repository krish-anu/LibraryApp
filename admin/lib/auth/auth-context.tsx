"use client";

import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  ReactNode,
} from "react";

interface User {
  sub: string;
  email: string;
  name: string;
  picture?: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: () => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [asgardeoClient, setAsgardeoClient] = useState<any>(null);

  useEffect(() => {
    // Initialize Asgardeo on client-side only
    const initAuth = async () => {
      if (typeof window === "undefined") return;

      try {
        const { AsgardeoSPAClient } = await import("@asgardeo/auth-spa");

        const client = AsgardeoSPAClient.getInstance();
        if (!client) {
          setIsLoading(false);
          return;
        }

        // Respect env-configured redirect URL / scopes if provided
        const signInRedirect =
          process.env.NEXT_PUBLIC_ASGARDEO_SIGN_IN_REDIRECT_URL ||
          `${window.location.origin}/`;
        const signOutRedirect =
          process.env.NEXT_PUBLIC_ASGARDEO_SIGN_OUT_REDIRECT_URL ||
          `${window.location.origin}/`;
        const scopesEnv = process.env.NEXT_PUBLIC_ASGARDEO_SCOPES || "openid profile email";
        const scopes = scopesEnv.split(/[ ,]+/).filter(Boolean);

        await client.initialize({
          signInRedirectURL: signInRedirect,
          signOutRedirectURL: signOutRedirect,
          clientID: process.env.NEXT_PUBLIC_ASGARDEO_CLIENT_ID || '',
          baseUrl: process.env.NEXT_PUBLIC_ASGARDEO_BASE_URL || '',
          scope: scopes,
        });

        setAsgardeoClient(client);

        // Check if user is already authenticated
        const isAuth = await client.isAuthenticated();
        setIsAuthenticated(!!isAuth);

        if (isAuth) {
          const userInfo = await client.getBasicUserInfo();
          if (userInfo) {
            setUser({
              sub: userInfo.sub || "",
              email: userInfo.email || "",
              name: userInfo.displayName || userInfo.username || "",
              picture: userInfo.picture,
            });
          }
        }

        // Handle sign-in callback
        if (window.location.search.includes("code=")) {
          try {
            await client.signIn({ callOnlyOnRedirect: true });
            const userInfo = await client.getBasicUserInfo();
            if (userInfo) {
              setUser({
                sub: userInfo.sub || "",
                email: userInfo.email || "",
                name: userInfo.displayName || userInfo.username || "",
                picture: userInfo.picture,
              });
              setIsAuthenticated(true);
            }
            // Clean up URL
            window.history.replaceState(
              {},
              document.title,
              window.location.pathname,
            );
          } catch (e) {
            console.error("Sign-in callback error:", e);
          }
        }
      } catch (error) {
        console.error("Auth initialization error:", error);
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, []);

  const login = async () => {
    if (asgardeoClient) {
      try {
        await asgardeoClient.signIn();
      } catch (error) {
        console.error("Login error:", error);
      }
    }
  };

  const logout = async () => {
    if (asgardeoClient) {
      try {
        await asgardeoClient.signOut();
        setUser(null);
        setIsAuthenticated(false);
      } catch (error) {
        console.error("Logout error:", error);
      }
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated,
        isLoading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
