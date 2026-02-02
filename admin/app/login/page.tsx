"use client";

import { useEffect } from "react";
import { Library, Lock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth/auth-context";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const { isAuthenticated, isLoading, login } = useAuth();
  const router = useRouter();

  useEffect(() => {
    // Redirect to dashboard if already authenticated
    if (isAuthenticated && !isLoading) {
      router.push("/");
    }
  }, [isAuthenticated, isLoading, router]);

  const handleAsgardeoLogin = () => {
    login();
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#1E3A5F] flex items-center justify-center">
        <div className="text-white">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#1E3A5F] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-white/10 rounded-2xl mb-4">
            <Library className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white">Library Admin</h1>
          <p className="text-white/60 mt-2">Sign in to manage your library</p>
        </div>

        <div className="bg-white rounded-2xl shadow-xl p-8">
          <div className="space-y-6">
            <div className="text-center">
              <h2 className="text-xl font-semibold text-gray-900">
                Welcome Back
              </h2>
              <p className="text-gray-500 text-sm mt-1">
                Sign in with your administrator account
              </p>
            </div>

            <Button onClick={handleAsgardeoLogin} className="w-full" size="lg">
              <Lock className="w-4 h-4 mr-2" />
              Sign in with Asgardeo
            </Button>
          </div>
        </div>

        <p className="text-center text-white/40 text-sm mt-6">
          © 2025 Library Management System. All rights reserved.
        </p>
      </div>
    </div>
  );
}
