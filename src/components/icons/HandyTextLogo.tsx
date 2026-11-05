/* eslint-disable i18next/no-literal-string -- the brand name is a logo, not UI copy */
// Impulso Talker wordmark, in the Impulso Creator style: all lowercase in
// Plus Jakarta Sans, "impulso" bold in Impulso blue, "talker" lighter in slate,
// closed by the amber text cursor from the app icon.
const BRAND_FONT =
  'var(--font-brand, "Plus Jakarta Sans", ui-rounded, system-ui, sans-serif)';

const HandyTextLogo = ({
  size = 22,
  className = "",
}: {
  /** Font size in px; the cursor scales with it. */
  size?: number;
  className?: string;
}) => {
  return (
    <span
      role="img"
      aria-label="impulso talker"
      className={`inline-flex select-none items-center whitespace-nowrap leading-none ${className}`}
      style={{ fontFamily: BRAND_FONT, fontSize: size }}
    >
      <span
        aria-hidden="true"
        className="font-extrabold text-logo-primary"
        style={{ letterSpacing: "-0.03em" }}
      >
        impulso
      </span>
      <span
        aria-hidden="true"
        className="ms-[0.28em] font-medium text-ink-2"
        style={{ letterSpacing: "-0.02em" }}
      >
        talker
      </span>
      <span
        aria-hidden="true"
        className="ms-[0.16em] h-[0.85em] w-[0.1em] rounded-full bg-cursor"
      />
    </span>
  );
};

export default HandyTextLogo;
