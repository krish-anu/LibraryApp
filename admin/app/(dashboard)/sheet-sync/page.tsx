"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { RefreshCw, Save } from "lucide-react";

interface SheetSyncSettings {
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

const defaults: SheetSyncSettings = {
  sheet_sync_enabled: false,
  sheet_sync_interval_days: 30,
  sheet_spreadsheet_id: "",
  sheet_books_tab: "Books",
  sheet_blogs_tab: "Blogs",
  sheet_videos_tab: "Videos",
};

export default function SheetSyncPage() {
  const [settings, setSettings] = useState<SheetSyncSettings>(defaults);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      const res = await fetch("/api/settings");
      const json = await res.json();
      if (json.data) setSettings((current) => ({ ...current, ...json.data }));
    } catch (error) {
      console.error("Error fetching sync settings:", error);
    } finally {
      setLoading(false);
    }
  };

  const saveSettings = async () => {
    const res = await fetch("/api/settings", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(settings),
    });
    if (!res.ok) {
      const error = await res
        .json()
        .catch(() => ({ error: "Failed to save sync settings" }));
      throw new Error(error.error || "Failed to save sync settings");
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await saveSettings();
      alert("Sheet sync settings saved successfully!");
      await fetchSettings();
    } catch (error) {
      alert(error instanceof Error ? error.message : "Failed to save settings");
    } finally {
      setSaving(false);
    }
  };

  const handleManualSync = async () => {
    setSyncing(true);
    try {
      await saveSettings();
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
      alert(error instanceof Error ? error.message : "Failed to run sheet sync");
    } finally {
      setSyncing(false);
    }
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#1E3A5F]" />
      </div>
    );
  }

  return (
    <div>
      <Header
        title="Sheet Sync"
        subtitle="Sync books, blogs, and YouTube videos from Google Sheets"
      />

      <div className="px-4 py-6 sm:px-6 lg:px-8">
        <div className="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
          <div className="space-y-6">
            <div className="rounded-lg border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800">
              The spreadsheet must be published or shared so the API can read
              CSV exports. Paste only the spreadsheet ID, not the full URL.
            </div>

            <label className="flex items-center gap-3">
              <input
                type="checkbox"
                checked={settings.sheet_sync_enabled}
                onChange={(event) =>
                  setSettings({
                    ...settings,
                    sheet_sync_enabled: event.target.checked,
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
              onChange={(event) =>
                setSettings({
                  ...settings,
                  sheet_spreadsheet_id: event.target.value,
                })
              }
              placeholder="1AbC..."
            />

            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <Input
                label="Books Tab Name"
                value={settings.sheet_books_tab || ""}
                onChange={(event) =>
                  setSettings({ ...settings, sheet_books_tab: event.target.value })
                }
                placeholder="Books"
              />
              <Input
                label="Blogs Tab Name"
                value={settings.sheet_blogs_tab || ""}
                onChange={(event) =>
                  setSettings({ ...settings, sheet_blogs_tab: event.target.value })
                }
                placeholder="Blogs"
              />
              <Input
                label="Videos Tab Name"
                value={settings.sheet_videos_tab || ""}
                onChange={(event) =>
                  setSettings({ ...settings, sheet_videos_tab: event.target.value })
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
              onChange={(event) =>
                setSettings({
                  ...settings,
                  sheet_sync_interval_days: parseInt(event.target.value) || 30,
                })
              }
              className="max-w-xs"
            />

            <div className="rounded-lg border border-gray-200 bg-gray-50 p-4">
              <h3 className="mb-3 font-semibold text-gray-900">Last Sync</h3>
              <div className="grid grid-cols-1 gap-3 text-sm md:grid-cols-3">
                <div>
                  <p className="font-medium text-gray-500">Time</p>
                  <p className="text-gray-900">
                    {settings.sheet_last_sync_at
                      ? new Date(settings.sheet_last_sync_at).toLocaleString()
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

            <div className="flex flex-col gap-3 border-t border-gray-200 pt-6 sm:flex-row sm:justify-end">
              <Button
                type="button"
                variant="secondary"
                isLoading={saving}
                onClick={handleSave}
                className="w-full sm:w-auto"
              >
                <Save className="mr-2 h-4 w-4" />
                Save Settings
              </Button>
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
        </div>
      </div>
    </div>
  );
}
