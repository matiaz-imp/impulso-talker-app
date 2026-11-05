import React, { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { getVersion } from "@tauri-apps/api/app";
import { listen } from "@tauri-apps/api/event";
import { openUrl } from "@tauri-apps/plugin-opener";
import { useSettings } from "../../hooks/useSettings";
import { compareVersions, parseLatestRelease } from "./latestRelease";

// The only request this makes: GitHub's public "latest release" of the project.
// It carries no user data (just the IP address any web request has) and it
// never downloads or installs anything: it opens the release page instead.
const LATEST_RELEASE_URL =
  "https://api.github.com/repos/matiaz-imp/impulso-talker-app/releases/latest";
const RELEASES_PAGE = "https://github.com/matiaz-imp/impulso-talker-app/releases";
const LAST_CHECK_KEY = "update-check-at";
const CHECK_EVERY_MS = 24 * 60 * 60 * 1000;

interface UpdateCheckerProps {
  className?: string;
}

const UpdateChecker: React.FC<UpdateCheckerProps> = ({ className = "" }) => {
  const { t } = useTranslation();
  const [isChecking, setIsChecking] = useState(false);
  const [newVersion, setNewVersion] = useState<string | null>(null);
  const [releaseUrl, setReleaseUrl] = useState(RELEASES_PAGE);
  const [showUpToDate, setShowUpToDate] = useState(false);
  const [failed, setFailed] = useState(false);

  const { settings, isLoading, updateChecksLocked } = useSettings();
  const settingsLoaded =
    !isLoading && settings !== null && updateChecksLocked !== null;
  // HANDY_DISABLE_UPDATER (system configuration) overrides the stored choice.
  const enabled =
    (settings?.update_checks_enabled ?? true) && updateChecksLocked === false;

  const timeout = useRef<ReturnType<typeof setTimeout>>();

  const check = useCallback(async (manual: boolean) => {
    setIsChecking(true);
    setFailed(false);
    try {
      const response = await fetch(LATEST_RELEASE_URL, {
        headers: { Accept: "application/vnd.github+json" },
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const latest = parseLatestRelease(await response.json());
      const current = await getVersion();
      try {
        localStorage.setItem(LAST_CHECK_KEY, String(Date.now()));
      } catch {
        // Private mode or blocked storage: the daily check just runs again.
      }
      if (latest && compareVersions(latest.version, current) > 0) {
        setNewVersion(latest.version);
        setReleaseUrl(latest.url);
      } else {
        setNewVersion(null);
        if (manual) {
          setShowUpToDate(true);
          clearTimeout(timeout.current);
          timeout.current = setTimeout(() => setShowUpToDate(false), 3000);
        }
      }
    } catch (error) {
      console.warn("Could not check for a new version:", error);
      if (manual) setFailed(true);
    } finally {
      setIsChecking(false);
    }
  }, []);

  useEffect(() => {
    if (!settingsLoaded || !enabled) {
      setNewVersion(null);
      return;
    }

    let last = 0;
    try {
      last = Number(localStorage.getItem(LAST_CHECK_KEY) ?? 0);
    } catch {
      // Treated as never checked.
    }
    if (Date.now() - last > CHECK_EVERY_MS) void check(false);

    const unlisten = listen("check-for-updates", () => void check(true));
    return () => {
      clearTimeout(timeout.current);
      unlisten.then((fn) => fn());
    };
  }, [settingsLoaded, enabled, check]);

  let label: string;
  let action: (() => void) | undefined;
  if (!enabled) {
    label = t("footer.updateCheckingDisabled");
  } else if (isChecking) {
    label = t("footer.checkingUpdates");
  } else if (newVersion) {
    label = t("footer.newVersion", { version: newVersion });
    action = () => void openUrl(releaseUrl);
  } else if (showUpToDate) {
    label = t("footer.upToDate");
  } else if (failed) {
    label = t("footer.checkFailed");
    action = () => void check(true);
  } else {
    label = t("footer.checkForUpdates");
    action = () => void check(true);
  }

  return (
    <div className={`flex items-center gap-3 ${className}`}>
      {action ? (
        <button
          type="button"
          onClick={action}
          className={`cursor-pointer transition-colors tabular-nums ${
            newVersion
              ? "font-medium text-logo-primary hover:text-logo-primary"
              : "text-ink-2 hover:text-text"
          }`}
        >
          {label}
        </button>
      ) : (
        <span className="text-ink-2 tabular-nums">{label}</span>
      )}
    </div>
  );
};

export default UpdateChecker;
