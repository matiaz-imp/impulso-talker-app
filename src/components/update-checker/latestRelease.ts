export interface LatestRelease {
  /** Without the leading "v". */
  version: string;
  url: string;
}

/** Reads GitHub's "latest release" reply; null when it has no usable version. */
export const parseLatestRelease = (json: unknown): LatestRelease | null => {
  if (typeof json !== "object" || json === null) return null;
  const { tag_name, html_url, draft, prerelease } = json as Record<
    string,
    unknown
  >;
  if (draft === true || prerelease === true) return null;
  if (typeof tag_name !== "string") return null;
  const version = tag_name.replace(/^v/i, "");
  if (!/^\d+(\.\d+)*$/.test(version)) return null;
  const url =
    typeof html_url === "string" && html_url.startsWith("https://github.com/")
      ? html_url
      : "https://github.com/matiaz-imp/impulso-talker-app/releases";
  return { version, url };
};

/** 1 when a is newer than b, -1 when older, 0 when equal (numeric, dotted). */
export const compareVersions = (a: string, b: string): number => {
  const pa = a.split(".").map(Number);
  const pb = b.split(".").map(Number);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const diff = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (diff !== 0) return diff > 0 ? 1 : -1;
  }
  return 0;
};
