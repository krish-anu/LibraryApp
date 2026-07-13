"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Save, BookOpen, Building, User, RefreshCw } from "lucide-react";

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
  sheet_sync_enabled: boolean;
  sheet_sync_interval_days: number;
  sheet_spreadsheet_id: string;
  sheet_books_tab: string;
  sheet_blogs_tab: string;
  sheet_videos_tab: string;
  sheet_last_sync_at?: string | null;
  sheet_last_sync_status?: string | null;
  sheet_last_sync_message?: string | null;
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
    sheet_sync_enabled: false,
    sheet_sync_interval_days: 30,
    sheet_spreadsheet_id: "",
    sheet_books_tab: "Books",
    sheet_blogs_tab: "Blogs",
    sheet_videos_tab: "Videos",
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [activeTab, setActiveTab] = useState<
    "fines" | "library" | "sync" | "profile"
  >("fines");

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      const res = await fetch("/api/settings");
      const json = await res.json();
      if (json.data) {
        setSettings((current) => ({ ...current, ...json.data }));
      }
    } catch (error) {
      console.error("Error fetching settings:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleManualSync = async () => {
    setSyncing(true);
    try {
      const saveRes = await fetch("/api/settings", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(settings),
      });
      if (!saveRes.ok) {
        const error = await saveRes
          .json()
          .catch(() => ({ error: "Failed to save sync settings" }));
        alert(error.error || "Failed to save sync settings");
        return;
      }

      const res = await fetch("/api/content-sync/run", { method: "POST" });
      const json = await res.json();
      if (!res.ok) {
        alert(json.error || "Failed to run sheet sync");
        await fetchSettings();
        return;
      }
      alert(json.data?.message || "Sheet sync completed");
      await fetchSettings();
    } catch (error) {
      console.error("Error running sheet sync:", error);
      alert("Failed to run sheet sync");
    } finally {
      setSyncing(false);
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
        const error = await res
          .json()
          .catch(() => ({ error: "Failed to save settings" }));
        alert(error.error || "Failed to save settings");
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
    { key: "sync", label: "Sheet Sync", icon: RefreshCw },
    { key: "profile", label: "Admin Profile", icon: User },
  ] as const;

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
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

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        <div className="flex flex-col gap-6 xl:flex-row">
          {/* Sidebar Tabs */}
          <div className="shrink-0 xl:w-64">
            <div className="overflow-x-auto rounded-xl border border-gray-100 bg-white p-2 shadow-sm">
              <div className="flex min-w-max gap-2 xl:min-w-0 xl:flex-col">
                {tabs.map((tab) => (
                  <button
                    key={tab.key}
                    onClick={() => setActiveTab(tab.key)}
                    className={`flex items-center gap-3 rounded-lg px-4 py-3 text-left transition-colors xl:w-full ${
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
                    <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                      <Input
                        label="Default Loan Period (days)"
                        type="number"
                        min="1"
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
                        min="1"
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
                        min="0"
                        value={settings.grace_period_days}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            grace_period_days: parseInt(e.target.value) || 0,
                          })
                        }
                      />
                      <Input
                        label="Daily Fine Rate (LKR)"
                        type="number"
                        step="0.01"
                        min="0.01"
                        value={settings.daily_fine_rate}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            daily_fine_rate: parseFloat(e.target.value) || 0,
                          })
                        }
                      />
                      <Input
                        label="Maximum Fine Cap (LKR)"
                        type="number"
                        step="0.01"
                        min="0.01"
                        value={settings.max_fine_cap}
                        onChange={(e) =>
                          setSettings({
                            ...settings,
                            max_fine_cap: parseFloat(e.target.value) || 0,
                          })
                        }
                      />
                      <Input
                        label="Fine Threshold for Blocking (LKR)"
                        type="number"
                        step="0.01"
                        min="0"
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
                          min="0"
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
                  <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
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

              {activeTab === "sync" && (
                <div className="space-y-6">
                  <div>
                    <h2 className="mb-2 text-lg font-semibold text-gray-900">
                      Google Sheet Sync
                    </h2>
                    <p className="text-sm text-gray-500">
                      Import and update books, blogs, and YouTube videos from
                      three tabs in one Google Sheet.
                    </p>
                  </div>

                  <div className="rounded-lg border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800">
                    The spreadsheet must be published or shared so the API can
                    read CSV exports. Use tab names exactly as they appear in
                    Google Sheets.
                  </div>

                  <label className="flex items-center gap-3">
                    <input
                      type="checkbox"
                      checked={settings.sheet_sync_enabled}
                      onChange={(e) =>
                        setSettings({
                          ...settings,
                          sheet_sync_enabled: e.target.checked,
                        })
                      }
                      className="h-4 w-4 rounded border-gray-300 text-[#1E3A5F] focus:ring-blue-500"
                    />
                    <span className="text-gray-700">
                      Enable automatic scheduled sync
                    </span>
                  </label>

                  <Input
                    label="Google Spreadsheet ID"
                    value={settings.sheet_spreadsheet_id || ""}
                    onChange={(e) =>
                      setSettings({
                        ...settings,
                        sheet_spreadsheet_id: e.target.value,
                      })
                    }
                    placeholder="1AbC..."
                  />

                  <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
                    <Input
                      label="Books Tab Name"
                      value={settings.sheet_books_tab || ""}
                      onChange={(e) =>
                        setSettings({
                          ...settings,
                          sheet_books_tab: e.target.value,
                        })
                      }
                      placeholder="Books"
                    />
                    <Input
                      label="Blogs Tab Name"
                      value={settings.sheet_blogs_tab || ""}
                      onChange={(e) =>
                        setSettings({
                          ...settings,
                          sheet_blogs_tab: e.target.value,
                        })
                      }
                      placeholder="Blogs"
                    />
                    <Input
                      label="Videos Tab Name"
                      value={settings.sheet_videos_tab || ""}
                      onChange={(e) =>
                        setSettings({
                          ...settings,
                          sheet_videos_tab: e.target.value,
                        })
                      }
                      placeholder="Videos"
                    />
                  </div>

                  <Input
                    label="Automatic Sync Interval (days)"
                    type="number"
                    min="1"
                    max="365"
                    value={settings.sheet_sync_interval_days}
                    onChange={(e) =>
                      setSettings({
                        ...settings,
                        sheet_sync_interval_days: parseInt(e.target.value) || 30,
                      })
                    }
                    className="max-w-xs"
                  />

                  <div className="rounded-lg border border-gray-200 bg-gray-50 p-4">
                    <h3 className="mb-3 font-semibold text-gray-900">
                      Last Sync
                    </h3>
                    <div className="grid grid-cols-1 gap-3 text-sm md:grid-cols-3">
                      <div>
                        <p className="font-medium text-gray-500">Time</p>
                        <p className="text-gray-900">
                          {settings.sheet_last_sync_at
                            ? new Date(
                                settings.sheet_last_sync_at,
                              ).toLocaleString()
                            : "Never"}
                        </p>
                      </div>
                      <div>
                        <p className="font-medium text-gray-500">Status</p>
                        <p className="capitalize text-gray-900">
                          {settings.sheet_last_sync_status || "-"}
                        </p>
                      </div>
                      <div>
                        <p className="font-medium text-gray-500">Message</p>
                        <p className="text-gray-900">
                          {settings.sheet_last_sync_message || "-"}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="flex flex-col gap-3 sm:flex-row">
                    <Button
                      type="button"
                      onClick={handleManualSync}
                      isLoading={syncing}
                      className="w-full sm:w-auto"
                    >
                      <RefreshCw className="mr-2 h-4 w-4" />
                      Run Manual Sync
                    </Button>
                  </div>
                </div>
              )}

              {activeTab === "profile" && (
                <div className="space-y-6">
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">
                    Admin Profile
                  </h2>
                  <div className="mb-6 flex flex-col items-start gap-4 sm:flex-row sm:items-center">
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

              <div className="mt-6 flex border-t border-gray-200 pt-6 sm:justify-end">
                <Button
                  onClick={handleSave}
                  isLoading={saving}
                  className="w-full sm:w-auto"
                >
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
