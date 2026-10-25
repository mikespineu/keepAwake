#!/usr/bin/env bash
# Builds a universal keepAwake.app, zips it and publishes it as a GitHub Release.
#   ./release.sh            release v<MARKETING_VERSION> from project.yml
#   ./release.sh --dry-run  only build build/keepAwake.zip
# The asset is always named keepAwake.zip, so the download link on the website
# (releases/latest/download/keepAwake.zip) never changes.
set -euo pipefail

cd "$(dirname "$0")"

VERSION="$(sed -n 's/^ *MARKETING_VERSION: *//p' project.yml)"
TAG="v$VERSION"
ZIP="build/keepAwake.zip"
SITE="https://mikespineu.github.io/keepAwake/"
CHANGELOG_URL="https://github.com/mikespineu/keepAwake/blob/main/CHANGELOG.md"

# The release notes start with this version's section of CHANGELOG.md ("## <version> — <date>").
CHANGES="$(awk -v v="$VERSION" '/^## /{p = ($2 == v); next} p' CHANGELOG.md | sed '/./,$!d')"
if [[ -z "$CHANGES" ]]; then
    echo "CHANGELOG.md has no \"## $VERSION\" section: add one before releasing." >&2
    exit 1
fi

./build.sh --universal

rm -f "$ZIP"
# ditto keeps the bundle's signature and symlinks intact (plain zip may not).
ditto -c -k --sequesterRsrc --keepParent build/keepAwake.app "$ZIP"
echo "Packed $ZIP ($(du -h "$ZIP" | cut -f1), sha256 $(shasum -a 256 "$ZIP" | cut -d' ' -f1))"

if [[ "${1:-}" == "--dry-run" ]]; then
    printf 'Release notes start with:\n%s\n' "$CHANGES"
    exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Uncommitted changes: commit and push before releasing." >&2
    exit 1
fi
if [[ -z "$(git branch -r --contains HEAD)" ]]; then
    echo "HEAD is not pushed: run git push before releasing." >&2
    exit 1
fi
if gh release view "$TAG" >/dev/null 2>&1; then
    echo "Release $TAG already exists: bump MARKETING_VERSION in project.yml." >&2
    exit 1
fi

gh release create "$TAG" "$ZIP" \
    --target "$(git rev-parse HEAD)" \
    --title "keepAwake $VERSION" \
    --notes "$(cat <<EOF
$CHANGES

Full changelog: $CHANGELOG_URL

---

Universal build for Apple Silicon and Intel Macs, macOS 14 or newer.

**Install**
1. Download \`keepAwake.zip\` below and double-click it.
2. Drag \`keepAwake.app\` into your **Applications** folder.
3. Open it. The first time, macOS blocks it because the app is not notarized by Apple: go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.

Step-by-step guide with screenshots: $SITE
EOF
)"
echo "Published $TAG"
