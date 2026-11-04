/** Impulso Talker's mark: the app icon (blue tile, sound bars, yellow text cursor). */
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
        <rect width="140" height="140" rx="32" fill="#155EEF" />
        <rect x="20" y="53" width="16" height="34" rx="8" fill="#FFFFFF" />
        <rect x="50" y="35" width="16" height="70" rx="8" fill="#FFFFFF" />
        <rect x="80" y="46" width="16" height="48" rx="8" fill="#FFFFFF" />
        <rect x="114" y="32" width="7" height="76" rx="3.5" fill="#FFC53D" />
      </g>
    </svg>
  );
};

export default HandyMascot;
