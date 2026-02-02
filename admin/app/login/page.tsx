"use client";

import { useState } from "react";
import { Library, Lock, Mail } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function LoginPage() {
  const [isLoading, setIsLoading] = useState(false);

  const handleAsgardeoLogin = () => {
    setIsLoading(true);
    // Redirect to Asgardeo login
    const clientId = process.env.NEXT_PUBLIC_ASGARDEO_CLIENT_ID;
    const baseUrl = process.env.NEXT_PUBLIC_ASGARDEO_BASE_URL;
    const redirectUri = `${window.location.origin}/api/auth/callback`;

    const authUrl =
      `${baseUrl}/oauth2/authorize?` +
      `response_type=code&` +
      `client_id=${clientId}&` +
      `redirect_uri=${encodeURIComponent(redirectUri)}&` +
      `scope=openid profile email`;

    window.location.href = authUrl;
  };

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

            <Button
              onClick={handleAsgardeoLogin}
              isLoading={isLoading}
              className="w-full"
              size="lg"
            >
              <Lock className="w-4 h-4 mr-2" />
              Sign in with Asgardeo
            </Button>

            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-white text-gray-500">or</span>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email
                </label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="email"
                    placeholder="admin@library.com"
                    className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                    disabled
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="password"
                    placeholder="••••••••"
                    className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                    disabled
                  />
                </div>
              </div>
              <Button variant="secondary" className="w-full" disabled>
                Sign in with Email (Coming Soon)
              </Button>
            </div>
          </div>
        </div>

        <p className="text-center text-white/40 text-sm mt-6">
          © 2025 Library Management System. All rights reserved.
        </p>
      </div>
    </div>
  );
}
