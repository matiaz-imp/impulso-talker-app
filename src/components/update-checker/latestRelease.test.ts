import { compareVersions, parseLatestRelease } from "./latestRelease";

const assert = (ok: boolean, message: string) => {
  if (!ok) throw new Error(`latestRelease: ${message}`);
};

assert(compareVersions("0.1.1", "0.1.0") === 1, "0.1.1 > 0.1.0");
assert(compareVersions("0.10.0", "0.9.5") === 1, "numeric, not text, order");
assert(compareVersions("0.1.0", "0.1.0") === 0, "equal");
assert(compareVersions("0.1", "0.1.0") === 0, "missing part counts as 0");
assert(compareVersions("0.1.0", "1.0.0") === -1, "older");

const ok = parseLatestRelease({
  tag_name: "v0.2.0",
  html_url:
    "https://github.com/matiaz-imp/impulso-talker-app/releases/tag/v0.2.0",
});
assert(ok?.version === "0.2.0", "strips the v");
assert(
  parseLatestRelease({ tag_name: "v0.2.0", draft: true }) === null,
  "draft",
);
assert(
  parseLatestRelease({ tag_name: "v0.2.0", prerelease: true }) === null,
  "prerelease",
);
assert(parseLatestRelease({ tag_name: "latest" }) === null, "not a version");
assert(parseLatestRelease(null) === null, "null");
assert(
  parseLatestRelease({
    tag_name: "v1.0.0",
    html_url: "https://evil.example/x",
  })?.url.startsWith("https://github.com/") === true,
  "never opens a link outside github.com",
);
console.log("latestRelease: all assertions passed");
