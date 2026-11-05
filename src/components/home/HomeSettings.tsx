import React, { useCallback, useEffect, useMemo, useState } from "react";
import { Check, Copy, Search } from "lucide-react";
import { useTranslation } from "react-i18next";
import {
  commands,
  events,
  type HistoryEntry,
  type HistoryUpdatePayload,
} from "@/bindings";
import { useOsType } from "@/hooks/useOsType";
import { useSettings } from "@/hooks/useSettings";
import { useModelStore } from "@/stores/modelStore";
import { formatKeyCombination } from "@/lib/utils/keyboard";
import { copyToClipboard } from "../settings/history/clipboard";

// How many entries feed the numbers and the list. Enough for a busy week.
const LOAD = 200;
const SHOWN = 6;

const DAY = 86_400;

const countWords = (text: string) => {
  const trimmed = text.trim();
  return trimmed ? trimmed.split(/\s+/).length : 0;
};

// What was actually pasted: the cleaned-up text when there is one.
const finalText = (entry: HistoryEntry) =>
  (entry.post_processed_text ?? entry.transcription_text).trim();

const startOfToday = () => {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return Math.floor(d.getTime() / 1000);
};

const Stat: React.FC<{ value: number; label: string; hint: string }> = ({
  value,
  label,
  hint,
}) => (
  <div className="flex flex-1 flex-col gap-1 rounded-xl border border-line px-4 py-3">
    <span className="text-xs font-medium text-ink-3">{label}</span>
    <span className="text-2xl font-semibold tabular-nums text-text">
      {value.toLocaleString()}
    </span>
    <span className="text-xs text-ink-3">{hint}</span>
  </div>
);

interface HomeSettingsProps {
  onShowHistory: () => void;
}

export const HomeSettings: React.FC<HomeSettingsProps> = ({
  onShowHistory,
}) => {
  const { t, i18n } = useTranslation();
  const osType = useOsType();
  const { getSetting } = useSettings();
  const currentModel = useModelStore((state) => state.currentModel);
  const models = useModelStore((state) => state.models);
  const [entries, setEntries] = useState<HistoryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState("");
  const [copiedId, setCopiedId] = useState<number | null>(null);

  const load = useCallback(async () => {
    try {
      const result = await commands.getHistoryEntries(null, LOAD);
      if (result.status === "ok") setEntries(result.data.entries);
    } catch (error) {
      console.error("Failed to load history for Home:", error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  // Keep the numbers live while the window is open.
  useEffect(() => {
    const unlisten = events.historyUpdatePayload.listen((event) => {
      const payload: HistoryUpdatePayload = event.payload;
      if (payload.action === "deleted") {
        setEntries((prev) => prev.filter((e) => e.id !== payload.id));
      } else if (payload.action === "added") {
        setEntries((prev) => [
          payload.entry,
          ...prev.filter((e) => e.id !== payload.entry.id),
        ]);
      } else if (payload.action === "updated") {
        setEntries((prev) =>
          prev.map((e) => (e.id === payload.entry.id ? payload.entry : e)),
        );
      }
    });
    return () => {
      unlisten.then((fn) => fn());
    };
  }, []);

  // Dictations only: a transcribed file is not something you said.
  const spoken = useMemo(
    () =>
      entries.filter((e) => e.source_name === null && finalText(e).length > 0),
    [entries],
  );

  const stats = useMemo(() => {
    const today = startOfToday();
    const weekAgo = Math.floor(Date.now() / 1000) - 7 * DAY;
    const todays = spoken.filter((e) => e.timestamp >= today);
    const week = spoken.filter((e) => e.timestamp >= weekAgo);
    const words = (list: HistoryEntry[]) =>
      list.reduce((sum, e) => sum + countWords(finalText(e)), 0);
    return {
      todayWords: words(todays),
      todayCount: todays.length,
      weekWords: words(week),
      weekCount: week.length,
    };
  }, [spoken]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    const list = q
      ? spoken.filter((e) => finalText(e).toLowerCase().includes(q))
      : spoken;
    return list.slice(0, SHOWN);
  }, [spoken, query]);

  const shortcut = getSetting("bindings")?.transcribe?.current_binding ?? "";
  const keys = shortcut
    ? formatKeyCombination(shortcut, osType)
        .split("+")
        .map((k) => k.trim())
        .filter(Boolean)
    : [];
  const modelName =
    models.find((m) => m.id === currentModel)?.name ??
    t("home.noModel", "Sin modelo elegido");

  const relative = useMemo(
    () => new Intl.RelativeTimeFormat(i18n.language, { numeric: "auto" }),
    [i18n.language],
  );
  const when = (timestamp: number) => {
    const diff = Math.floor(Date.now() / 1000) - timestamp;
    if (diff < 60) return relative.format(0, "minute");
    if (diff < 3600) return relative.format(-Math.floor(diff / 60), "minute");
    if (diff < DAY) return relative.format(-Math.floor(diff / 3600), "hour");
    return relative.format(-Math.floor(diff / DAY), "day");
  };

  const copy = async (entry: HistoryEntry) => {
    if (await copyToClipboard(finalText(entry))) {
      setCopiedId(entry.id);
      setTimeout(
        () => setCopiedId((id) => (id === entry.id ? null : id)),
        1800,
      );
    }
  };

  return (
    <div className="mx-auto flex w-full max-w-3xl flex-col gap-6">
      <section
        aria-label={t("home.ready", "Listo para dictar")}
        className="flex items-center gap-4 rounded-2xl border border-logo-primary/20 bg-logo-primary/[0.06] px-5 py-5"
      >
        <span
          aria-hidden
          className="h-10 w-1.5 shrink-0 rounded-full bg-cursor"
        />
        <div className="min-w-0 flex-1">
          <h1 className="text-xl font-semibold leading-tight text-text">
            {t("home.ready", "Listo para dictar")}
          </h1>
          <p className="mt-1 text-sm text-ink-2">
            {t("home.readyHint", "Presiona el atajo en cualquier app y habla.")}
          </p>
        </div>
        {keys.length > 0 && (
          <div className="flex shrink-0 flex-wrap items-center justify-end gap-1.5">
            {keys.map((key, i) => (
              <kbd
                key={`${key}-${i}`}
                className="inline-flex min-h-8 min-w-8 items-center justify-center rounded-md border border-line-strong bg-background px-2 font-sans text-sm font-semibold text-text"
              >
                {key}
              </kbd>
            ))}
          </div>
        )}
      </section>
      <p className="-mt-3 px-1 text-xs text-ink-3">
        {t("home.modelLine", "Modelo: {{name}}", { name: modelName })}
      </p>

      <div className="flex flex-col gap-3 sm:flex-row">
        <Stat
          value={stats.todayWords}
          label={t("home.today", "Hoy")}
          hint={t("home.dictations", "{{count}} dictados", {
            count: stats.todayCount,
          })}
        />
        <Stat
          value={stats.weekWords}
          label={t("home.week", "Últimos 7 días")}
          hint={t("home.dictations", "{{count}} dictados", {
            count: stats.weekCount,
          })}
        />
      </div>

      <section className="flex flex-col gap-3">
        <div className="flex items-center justify-between gap-3">
          <h2 className="text-sm font-semibold text-text">
            {t("home.recent", "Dictados recientes")}
          </h2>
          <button
            type="button"
            onClick={onShowHistory}
            className="min-h-[36px] cursor-pointer rounded-lg px-2 text-sm font-medium text-ink-2 hover:bg-wash hover:text-text"
          >
            {t("home.seeAll", "Ver todo el historial")}
          </button>
        </div>

        <label className="relative block">
          <span className="sr-only">
            {t("home.search", "Buscar en tus dictados")}
          </span>
          <Search
            aria-hidden
            className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-3"
          />
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={t("home.search", "Buscar en tus dictados")}
            className="h-10 w-full rounded-xl border border-line bg-background ps-9 pe-3 text-sm text-text outline-none placeholder:text-ink-3 focus-visible:border-logo-primary"
          />
        </label>

        {loading ? null : visible.length === 0 ? (
          <p className="rounded-xl border border-dashed border-line px-4 py-8 text-center text-sm text-ink-2">
            {query
              ? t("home.noResults", "No hay dictados con esa palabra.")
              : t(
                  "home.empty",
                  "Aún no dictas nada. Presiona el atajo y habla: aparecerá aquí.",
                )}
          </p>
        ) : (
          <ul className="divide-y divide-line overflow-hidden rounded-xl border border-line">
            {visible.map((entry) => (
              <li key={entry.id} className="flex items-start gap-3 px-4 py-3">
                <div className="min-w-0 flex-1">
                  <p className="line-clamp-2 select-text cursor-text text-sm text-text">
                    {finalText(entry)}
                  </p>
                  <p className="mt-1 text-xs text-ink-3">
                    {when(entry.timestamp)}
                    {" · "}
                    {t("home.words", "{{count}} palabras", {
                      count: countWords(finalText(entry)),
                    })}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => copy(entry)}
                  title={t("home.copy", "Copiar")}
                  aria-label={t("home.copy", "Copiar")}
                  className="flex h-9 w-9 shrink-0 cursor-pointer items-center justify-center rounded-lg text-ink-3 transition-colors hover:bg-wash hover:text-text"
                >
                  {copiedId === entry.id ? (
                    <Check className="h-4 w-4" />
                  ) : (
                    <Copy className="h-4 w-4" />
                  )}
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
};

export default HomeSettings;
