import React from "react";
import { useTranslation } from "react-i18next";
import {
  Cog,
  FlaskConical,
  History,
  House,
  Info,
  Sparkles,
  Cpu,
} from "lucide-react";
import { ModesSettings } from "./modes/ModesSettings";
import HandyTextLogo from "./icons/HandyTextLogo";
import HandyHand from "./icons/HandyHand";
import HandyMascot from "./icons/HandyMascot";
import { useSettings } from "../hooks/useSettings";
import {
  GeneralSettings,
  AdvancedSettings,
  HistorySettings,
  AboutSettings,
  PostProcessingSettings,
  ModelsSettings,
} from "./settings";

export type SidebarSection = keyof typeof SECTIONS_CONFIG;

interface IconProps {
  width?: number | string;
  height?: number | string;
  size?: number | string;
  className?: string;
  [key: string]: any;
}

interface SectionConfig {
  labelKey: string;
  icon: React.ComponentType<IconProps>;
  /** `null` when App renders the section itself (Debug, with its handlers). */
  component: React.ComponentType | null;
  enabled: (settings: any) => boolean;
}

export const SECTIONS_CONFIG = {
  home: {
    labelKey: "sidebar.home",
    icon: House,
    /** App renders Home itself: it needs to jump to the history. */
    component: null,
    enabled: () => true,
  },
  modes: {
    labelKey: "sidebar.modes",
    icon: Sparkles,
    component: ModesSettings,
    enabled: () => true,
  },
  general: {
    labelKey: "sidebar.general",
    icon: HandyHand,
    component: GeneralSettings,
    enabled: () => true,
  },
  history: {
    labelKey: "sidebar.history",
    icon: History,
    component: HistorySettings,
    enabled: () => true,
  },
  models: {
    labelKey: "sidebar.models",
    icon: Cpu,
    component: ModelsSettings,
    enabled: () => true,
  },
  advanced: {
    labelKey: "sidebar.advanced",
    icon: Cog,
    component: AdvancedSettings,
    enabled: () => true,
  },
  postprocessing: {
    labelKey: "sidebar.postProcessing",
    icon: Sparkles,
    component: PostProcessingSettings,
    enabled: (settings) => settings?.post_process_enabled ?? false,
  },
  debug: {
    labelKey: "sidebar.debug",
    icon: FlaskConical,
    component: null,
    enabled: (settings) => settings?.debug_mode ?? false,
  },
  about: {
    labelKey: "sidebar.about",
    icon: Info,
    component: AboutSettings,
    enabled: () => true,
  },
} as const satisfies Record<string, SectionConfig>;

interface SidebarProps {
  activeSection: SidebarSection;
  onSectionChange: (section: SidebarSection) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeSection,
  onSectionChange,
}) => {
  const { t } = useTranslation();
  const { settings } = useSettings();

  const availableSections = Object.entries(SECTIONS_CONFIG)
    .filter(([_, config]) => config.enabled(settings))
    .map(([id, config]) => ({ id: id as SidebarSection, ...config }));

  return (
    <header className="flex flex-wrap items-center gap-x-5 gap-y-1 border-b border-line px-4 py-2">
      <div className="flex items-center gap-2">
        <HandyMascot className="h-8 w-auto shrink-0" />
        <HandyTextLogo size={19} />
      </div>
      <nav
        aria-label={t("sidebar.navLabel", "Secciones")}
        className="flex flex-wrap items-center gap-0.5 ms-auto"
      >
        {availableSections.map((section) => {
          const isActive = activeSection === section.id;
          return (
            <button
              key={section.id}
              type="button"
              aria-current={isActive ? "page" : undefined}
              onClick={() => onSectionChange(section.id)}
              className={`min-h-[36px] cursor-pointer rounded-lg px-3 text-sm transition-colors focus-visible:outline-2 focus-visible:outline-logo-primary ${
                isActive
                  ? "bg-wash font-semibold text-text"
                  : "font-medium text-ink-2 hover:bg-wash hover:text-text"
              }`}
            >
              {t(section.labelKey)}
            </button>
          );
        })}
      </nav>
    </header>
  );
};
