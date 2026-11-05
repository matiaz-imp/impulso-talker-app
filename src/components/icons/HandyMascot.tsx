/** Impulso Talker's mark: the app icon (light tile, Impulso-blue sound bars, amber text cursor). */
const HandyMascot = ({ className = "" }: { className?: string }) => {
  return (
    <svg
      viewBox="0 0 151 165"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
    >
      <g transform="translate(5.5 12.5)">
        <rect
          x="1.5"
          y="1.5"
          width="137"
          height="137"
          rx="31"
          fill="#FFFFFF"
          stroke="#E1E4EA"
          strokeWidth="3"
        />
        <rect x="20" y="53" width="16" height="34" rx="8" fill="#155EEF" />
        <rect x="50" y="35" width="16" height="70" rx="8" fill="#155EEF" />
        <rect x="80" y="46" width="16" height="48" rx="8" fill="#155EEF" />
        <rect x="114" y="32" width="7" height="76" rx="3.5" fill="#F2A900" />
      </g>
    </svg>
  );
};

export default HandyMascot;
