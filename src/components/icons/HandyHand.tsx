// Impulso Talker: símbolo (tres barras de sonido + cursor). Mantiene el nombre del
// componente de Handy para no tocar a sus usuarios (Sidebar, FileDropOverlay).
const HandyHand = ({
  width,
  height,
}: {
  width?: number | string;
  height?: number | string;
  // The sidebar passes a className for its icons; the mark ignores it.
  className?: string;
}) => (
  <svg
    width={width || 126}
    height={height || 135}
    viewBox="0 0 126 135"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
  >
    <rect x="10" y="50" width="16" height="34" rx="8" className="fill-text" />
    <rect x="38" y="32" width="16" height="70" rx="8" className="fill-text" />
    <rect x="66" y="43" width="16" height="48" rx="8" className="fill-text" />
    <rect
      x="98"
      y="29"
      width="8"
      height="76"
      rx="4"
      style={{ fill: "var(--color-cursor)" }}
    />
  </svg>
);

export default HandyHand;
