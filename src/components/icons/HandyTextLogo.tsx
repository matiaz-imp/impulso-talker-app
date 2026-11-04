/* eslint-disable i18next/no-literal-string -- the brand name is a logo, not UI copy */
// Impulso Talker wordmark: the mark on the left, the name on two lines.
const HandyTextLogo = ({
  width,
  height,
  className,
}: {
  width?: number;
  height?: number;
  className?: string;
}) => {
  return (
    <svg
      width={width}
      height={height}
      className={className}
      viewBox="0 0 980 328"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      role="img"
      aria-label="Impulso Talker"
    >
      <rect
        x="10"
        y="118"
        width="38"
        height="82"
        rx="19"
        className="fill-text"
      />
      <rect
        x="68"
        y="76"
        width="38"
        height="166"
        rx="19"
        className="fill-text"
      />
      <rect
        x="126"
        y="100"
        width="38"
        height="118"
        rx="19"
        className="fill-text"
      />
      <rect
        x="196"
        y="70"
        width="16"
        height="178"
        rx="8"
        style={{ fill: "var(--color-cursor)" }}
      />
      <text
        x="270"
        y="152"
        fontSize="148"
        fontWeight="700"
        letterSpacing="-3"
        className="fill-text"
        style={{ fontFamily: "inherit" }}
      >
        Impulso
      </text>
      <text
        x="270"
        y="296"
        fontSize="148"
        fontWeight="700"
        letterSpacing="-3"
        className="fill-text"
        style={{ fontFamily: "inherit" }}
      >
        Talker
      </text>
    </svg>
  );
};

export default HandyTextLogo;
