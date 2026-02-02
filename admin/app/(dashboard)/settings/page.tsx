"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Settings } from "@/lib/types";
import { Save, BookOpen, Building, User } from "lucide-react";

interface SettingsFormData {
  loan_period_days: number;
  max_books_per_user: number;
  grace_period_days: number;
  daily_fine_rate: number;
  max_fine_cap: number;
  block_on_unpaid_fines: boolean;
  fine_threshold: number;
  send_notifications: boolean;
  notification_days_before_due: number;
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<SettingsFormData>({
    loan_period_days: 14,
    max_books_per_user: 5,
    grace_period_days: 2,
    daily_fine_rate: 0.5,
    max_fine_cap: 25.0,
    block_on_unpaid_fines: true,
    fine_threshold: 10.0,
    send_notifications: true,
    notification_days_before_due: 3,
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState<"fines" | "library" | "profile">(
    "fines",
  );

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      const res = await fetch("/api/settings");
      const json = await res.json();
      if (json.data) {
        setSettings(json.data);
      }
    } catch (error) {
      console.error("Error fetching settings:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const res = await fetch("/api/settings", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(settings),
      });

      if (res.ok) {
        alert("Settings saved successfully!");
      } else {
        alert("Failed to save settings");
      }
    } catch (error) {
      console.error("Error saving settings:", error);
      alert("Failed to save settings");
    } finally {
      setSaving(false);
    }
  };

  const tabs = [
    { key: "fines", label: "Fine Rules", icon: BookOpen },
    { key: "library", label: "Library Info", icon: Building },
    { key: "profile", label: "Admin Profile", icon: User },
  ] as const;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#1E3A5F]" />
      </div>
    );
  }

  return (
    <div>
      <Header
        title="Settings"
        subtitle="Configure library rules and preferences"
      />

      <div className="p-8">
        <div className="flex gap-6">
          {/* Sidebar Tabs */}
          <div className="w-64 shrink-0">
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-2">
              {tabs.map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg text-left transition-colors ${
                    activeTab === tab.key
                      ? "bg-[#1E3A5F] text-white"
                      : "text-gray-700 hover:bg-gray-100"
                  }`}
                >
                  <tab.icon className="w-5 h-5" />
                  <span className="font-medium">{tab.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Settings Content */}
          <div className="flex-1">
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
              {activeTab === "fines" && (
                <div className="space-y-6">
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900 mb-4">
                      Loan & Fine Rules
                    </h2>
                    <div className="grid grid-cols-2 gap-4">
                      <Input
                        label="Default Loan Period (days)"
                        type="number"
                        value={settings.loan_period_days}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            loan_period_days: parseInt(e.target.value) || 0,
                          })
                        }
                      />
                      <Input
                        label="Max Books Per User"
                        type="number"
                        value={settings.max_books_per_user}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            max_books_per_user: parseInt(e.target.value) || 0,
                          })
                        }
                      />
                      <Input
                        label="Grace Period (days)"
                        type="number"
                        value={settings.grace_period_days}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            grace_period_days: parseInt(e.target.value) || 0,
                          })
                        }
                      />
                      <Input
                        label="Daily Fine Rate ($)"
                        type="number"
                        step="0.01"
                        value={settings.daily_fine_rate}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            daily_fine_rate: parseFloat(e.target.value) || 0,
                          })
                        }
                      />
                      <Input
                        label="Maximum Fine Cap ($)"
                        type="number"
                        step="0.01"
                        value={settings.max_fine_cap}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            max_fine_cap: parseFloat(e.target.value) || 0,
                          })
                        }
                      />
                      <Input
                        label="Fine Threshold for Blocking ($)"
                        type="number"
                        step="0.01"
                        value={settings.fine_threshold}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            fine_threshold: parseFloat(e.target.value) || 0,
                          })
                        }
                      />
                    </div>
                  </div>

                  <div className="border-t border-gray-200 pt-6">
                    <h3 className="text-md font-semibold text-gray-900 mb-4">
                      Blocking Rules
                    </h3>
                    <label className="flex items-center gap-3">
                      <input
                        type="checkbox"
                        checked={settings.block_on_unpaid_fines}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            block_on_unpaid_fines: e.target.checked,
                          })
                        }
                        className="w-4 h-4 text-[#1E3A5F] border-gray-300 rounded focus:ring-blue-500"
                      />
                      <span className="text-gray-700">
                        Block borrowing when user has unpaid fines above
                        threshold
                      </span>
                    </label>
                  </div>

                  <div className="border-t border-gray-200 pt-6">
                    <h3 className="text-md font-semibold text-gray-900 mb-4">
                      Notifications
                    </h3>
                    <div className="space-y-4">
                      <label className="flex items-center gap-3">
                        <input
                          type="checkbox"
                          checked={settings.send_notifications}
                          onChange={(e) =>
                            setSettings({
                              ...settings,
                              send_notifications: e.target.checked,
                            })
                          }
                          className="w-4 h-4 text-[#1E3A5F] border-gray-300 rounded focus:ring-blue-500"
                        />
                        <span className="text-gray-700">
                          Send due date reminder notifications
                        </span>
                      </label>
                      {settings.send_notifications && (
                        <Input
                          label="Days Before Due Date to Notify"
                          type="number"
                          value={settings.notification_days_before_due}
                          onChange={(e) =>
                            setSettings({
                              ...settings,
                              notification_days_before_due:
                                parseInt(e.target.value) || 0,
                            })
                          }
                          className="max-w-xs"
                        />
                      )}
                    </div>
                  </div>
                </div>
              )}

              {activeTab === "library" && (
                <div className="space-y-6">
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">
                    Library Information
                  </h2>
                  <Input
                    label="Library Name"
                    defaultValue="City Central Library"
                    placeholder="Enter library name"
                  />
                  <Input
                    label="Address"
                    defaultValue="123 Main Street, City, State 12345"
                    placeholder="Enter library address"
                  />
                  <div className="grid grid-cols-2 gap-4">
                    <Input
                      label="Phone"
                      defaultValue="(555) 123-4567"
                      placeholder="Enter phone number"
                    />
                    <Input
                      label="Email"
                      type="email"
                      defaultValue="contact@library.com"
                      placeholder="Enter email address"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Operating Hours
                    </label>
                    <textarea
                      rows={3}
                      defaultValue="Monday - Friday: 9:00 AM - 8:00 PM&#10;Saturday: 10:00 AM - 6:00 PM&#10;Sunday: Closed"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                    />
                  </div>
                </div>
              )}

              {activeTab === "profile" && (
                <div className="space-y-6">
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">
                    Admin Profile
                  </h2>
                  <div className="flex items-center gap-4 mb-6">
                    <div className="w-20 h-20 bg-[#1E3A5F] rounded-full flex items-center justify-center text-white text-2xl font-bold">
                      A
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">
                        Admin User
                      </h3>
                      <p className="text-sm text-gray-500">
                        Library Administrator
                      </p>
                    </div>
                  </div>
                  <Input
                    label="Full Name"
                    defaultValue="Admin User"
                    placeholder="Enter your name"
                  />
                  <Input
                    label="Email"
                    type="email"
                    defaultValue="admin@library.com"
                    placeholder="Enter your email"
                  />
                  <Input
                    label="Phone"
                    defaultValue="(555) 987-6543"
                    placeholder="Enter your phone"
                  />
                  <div className="border-t border-gray-200 pt-6">
                    <h3 className="text-md font-semibold text-gray-900 mb-4">
                      Change Password
                    </h3>
                    <div className="space-y-4">
                      <Input
                        label="Current Password"
                        type="password"
                        placeholder="Enter current password"
                      />
                      <Input
                        label="New Password"
                        type="password"
                        placeholder="Enter new password"
                      />
                      <Input
                        label="Confirm New Password"
                        type="password"
                        placeholder="Confirm new password"
                      />
                    </div>
                  </div>
                </div>
              )}

              <div className="flex justify-end pt-6 border-t border-gray-200 mt-6">
                <Button onClick={handleSave} isLoading={saving}>
                  <Save className="w-4 h-4 mr-2" />
                  Save Changes
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
