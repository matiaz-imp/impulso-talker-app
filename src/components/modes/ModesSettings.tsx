import React, { useEffect, useRef, useState } from "react";
import { Crosshair, Plus, Trash2, X } from "lucide-react";
import { useTranslation } from "react-i18next";
import {
  commands,
  type EndMark,
  type FirstLetter,
  type Mode,
} from "@/bindings";
import { useSettings } from "@/hooks/useSettings";
import { SettingsGroup } from "../ui/SettingsGroup";
import { ToggleSwitch } from "../ui/ToggleSwitch";
import { Button } from "../ui/Button";

const DETECT_SECONDS = 8;

// Names people recognise for the apps the default modes ship with; any other
// app shows the identifier it was added with.
const FRIENDLY: Record<string, string> = {
  "com.apple.mail": "Mail",
  "com.microsoft.outlook": "Outlook",
  "outlook.exe": "Outlook",
  "olk.exe": "Outlook",
  "com.readdle.smartemail-mac": "Spark",
  "net.whatsapp.whatsapp": "WhatsApp",
  "whatsapp.exe": "WhatsApp",
  "com.tinyspeck.slackmacgap": "Slack",
  "slack.exe": "Slack",
  "com.apple.mobilesms": "Mensajes",
  "ru.keepcoder.telegram": "Telegram",
  "telegram.exe": "Telegram",
  "com.hnc.discord": "Discord",
  "discord.exe": "Discord",
  "com.apple.terminal": "Terminal",
  "com.googlecode.iterm2": "iTerm",
  "com.microsoft.vscode": "VS Code",
  "code.exe": "VS Code",
  "com.todesktop.230313mzl4w4u92": "Cursor",
  "cursor.exe": "Cursor",
  "windowsterminal.exe": "Terminal de Windows",
  "powershell.exe": "PowerShell",
  "com.apple.notes": "Notas",
  "md.obsidian": "Obsidian",
  "obsidian.exe": "Obsidian",
  "notion.id": "Notion",
  "notion.exe": "Notion",
};
const friendly = (id: string) => FRIENDLY[id.toLowerCase()] ?? id;

const fieldClass =
  "h-9 rounded-lg border border-line bg-background px-2 text-sm text-text outline-none focus-visible:border-logo-primary";

const newId = () => `modo-${Date.now().toString(36)}`;

const Field: React.FC<{ label: string; children: React.ReactNode }> = ({
  label,
  children,
}) => (
  <label className="flex min-w-[8.5rem] flex-1 flex-col gap-1">
    <span className="text-xs font-medium text-ink-3">{label}</span>
    {children}
  </label>
);

interface ModeCardProps {
  mode: Mode;
  onChange: (next: Mode) => void;
  onDelete: () => void;
}

const ModeCard: React.FC<ModeCardProps> = ({ mode, onChange, onDelete }) => {
  const { t } = useTranslation();
  const [name, setName] = useState(mode.name);
  const [manual, setManual] = useState("");
  const [left, setLeft] = useState<number | null>(null);
  const [detectFailed, setDetectFailed] = useState(false);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);
  const apps = mode.apps ?? [];

  useEffect(() => setName(mode.name), [mode.name]);
  useEffect(
    () => () => {
      if (timer.current) clearInterval(timer.current);
    },
    [],
  );

  const addApp = (id: string) => {
    const clean = id.trim();
    if (!clean) return;
    if (apps.some((a) => a.toLowerCase() === clean.toLowerCase())) return;
    onChange({ ...mode, apps: [...apps, clean] });
  };

  const detect = async () => {
    setDetectFailed(false);
    setLeft(DETECT_SECONDS);
    timer.current = setInterval(
      () => setLeft((s) => (s === null ? s : Math.max(s - 1, 0))),
      1000,
    );
    try {
      const result = await commands.detectApp(DETECT_SECONDS);
      if (result.status === "ok" && result.data) {
        addApp(result.data.id);
      } else {
        setDetectFailed(true);
      }
    } finally {
      if (timer.current) clearInterval(timer.current);
      setLeft(null);
    }
  };

  return (
    <div className="flex flex-col gap-4 px-4 py-4">
      <div className="flex items-center gap-2">
        <input
          value={name}
          maxLength={40}
          aria-label={t("modes.name", "Nombre del modo")}
          onChange={(e) => setName(e.target.value)}
          onBlur={() => {
            const clean = name.trim();
            if (clean && clean !== mode.name)
              onChange({ ...mode, name: clean });
            else setName(mode.name);
          }}
          className={`${fieldClass} flex-1 text-base font-semibold`}
        />
        <button
          type="button"
          onClick={onDelete}
          title={t("modes.delete", "Eliminar modo")}
          aria-label={t("modes.delete", "Eliminar modo")}
          className="flex h-9 w-9 cursor-pointer items-center justify-center rounded-lg text-ink-3 transition-colors hover:bg-error-wash hover:text-error"
        >
          <Trash2 className="h-4 w-4" />
        </button>
      </div>

      <div className="flex flex-col gap-2">
        <span className="text-xs font-medium text-ink-3">
          {t("modes.apps", "Apps")}
        </span>
        <div className="flex flex-wrap gap-1.5">
          {apps.length === 0 && (
            <span className="text-sm text-ink-3">
              {t("modes.noApps", "Aún no hay apps")}
            </span>
          )}
          {apps.map((app) => (
            <span
              key={app}
              className="inline-flex items-center gap-1 rounded-full border border-line bg-wash py-1 ps-3 pe-1 text-sm text-text"
            >
              {friendly(app)}
              <button
                type="button"
                onClick={() =>
                  onChange({ ...mode, apps: apps.filter((a) => a !== app) })
                }
                aria-label={t("modes.removeApp", "Quitar {{app}}", {
                  app: friendly(app),
                })}
                className="flex h-6 w-6 cursor-pointer items-center justify-center rounded-full text-ink-3 hover:bg-line hover:text-text"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </span>
          ))}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant="secondary"
            size="sm"
            onClick={detect}
            disabled={left !== null}
            className="flex min-h-9 items-center gap-2"
          >
            <Crosshair className="h-4 w-4" />
            {left !== null
              ? t("modes.detecting", "Cambia a la app… {{seconds}} s", {
                  seconds: left,
                })
              : t("modes.detect", "Detectar app")}
          </Button>
          <input
            value={manual}
            onChange={(e) => setManual(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                addApp(manual);
                setManual("");
              }
            }}
            placeholder={t("modes.manual", "o escribe su nombre")}
            aria-label={t("modes.manual", "o escribe su nombre")}
            className={`${fieldClass} min-w-[10rem] flex-1`}
          />
        </div>
        {detectFailed && (
          <p className="text-xs text-warning" role="status">
            {t(
              "modes.detectFailed",
              "No detecté otra app. Vuelve a intentarlo.",
            )}
          </p>
        )}
      </div>

      <div className="flex flex-wrap gap-3">
        <Field label={t("modes.firstLetter", "Primera letra")}>
          <select
            value={mode.first_letter ?? "as_is"}
            onChange={(e) =>
              onChange({ ...mode, first_letter: e.target.value as FirstLetter })
            }
            className={fieldClass}
          >
            <option value="as_is">{t("modes.asIs", "Como sale")}</option>
            <option value="upper">{t("modes.upper", "Mayúscula")}</option>
            <option value="lower">{t("modes.lower", "Minúscula")}</option>
          </select>
        </Field>
        <Field label={t("modes.endMark", "Punto final")}>
          <select
            value={mode.end_mark ?? "as_is"}
            onChange={(e) =>
              onChange({ ...mode, end_mark: e.target.value as EndMark })
            }
            className={fieldClass}
          >
            <option value="as_is">{t("modes.asIs", "Como sale")}</option>
            <option value="remove">{t("modes.remove", "Quitar")}</option>
            <option value="add">{t("modes.add", "Agregar")}</option>
          </select>
        </Field>
        <Field label={t("modes.singleLine", "Líneas")}>
          <select
            value={mode.single_line ? "one" : "many"}
            onChange={(e) =>
              onChange({ ...mode, single_line: e.target.value === "one" })
            }
            className={fieldClass}
          >
            <option value="many">{t("modes.manyLines", "Como salen")}</option>
            <option value="one">{t("modes.oneLine", "Una sola línea")}</option>
          </select>
        </Field>
      </div>
    </div>
  );
};

export const ModesSettings: React.FC = () => {
  const { t } = useTranslation();
  const { getSetting, updateSetting, isUpdating } = useSettings();
  const enabled = getSetting("modes_enabled") ?? true;
  const modes = getSetting("modes") ?? [];

  const save = (next: Mode[]) => updateSetting("modes", next);

  return (
    <div className="mx-auto flex w-full max-w-3xl flex-col gap-6">
      <SettingsGroup title={t("modes.title", "Modos por app")}>
        <ToggleSwitch
          checked={enabled}
          onChange={(v) => updateSetting("modes_enabled", v)}
          isUpdating={isUpdating("modes_enabled")}
          label={t("modes.enabled", "Ajustar el texto según la app")}
          description={t(
            "modes.enabledHint",
            "Antes de pegar, retoca mayúsculas, punto final y saltos de línea según dónde estés escribiendo. Sin IA y sin costo.",
          )}
          descriptionMode="inline"
          grouped={true}
        />
      </SettingsGroup>

      <div className={enabled ? "" : "pointer-events-none opacity-50"}>
        <SettingsGroup>
          {modes.map((mode) => (
            <ModeCard
              key={mode.id}
              mode={mode}
              onChange={(next) =>
                save(modes.map((m) => (m.id === mode.id ? next : m)))
              }
              onDelete={() => save(modes.filter((m) => m.id !== mode.id))}
            />
          ))}
          <div className="px-4 py-3">
            <Button
              variant="secondary"
              size="md"
              className="flex min-h-9 items-center gap-2"
              onClick={() =>
                save([
                  ...modes,
                  {
                    id: newId(),
                    name: t("modes.newName", "Modo nuevo"),
                    apps: [],
                    first_letter: "as_is",
                    end_mark: "as_is",
                    single_line: false,
                  },
                ])
              }
            >
              <Plus className="h-4 w-4" />
              {t("modes.new", "Nuevo modo")}
            </Button>
          </div>
        </SettingsGroup>
      </div>
    </div>
  );
};

export default ModesSettings;
