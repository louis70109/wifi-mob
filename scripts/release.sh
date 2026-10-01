#!/usr/bin/env bash
# 發佈新版本：build + 打包 + tag + push + GitHub Release
set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "usage: bash scripts/release.sh <version>   e.g. 1.1.0" >&2
  exit 1
fi
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "version must match MAJOR.MINOR.PATCH" >&2
  exit 1
fi
TAG="v$VERSION"

cd "$(dirname "$0")/.."

if [[ -n "$(git status --porcelain)" ]]; then
  echo "working tree not clean，先 commit 或 stash：" >&2
  git status --short >&2
  exit 1
fi

# 更新 package.sh 中的版本號
sed -i.bak "s/^VERSION=.*/VERSION=\"$VERSION\"/" scripts/package.sh
rm -f scripts/package.sh.bak

swift test
swift build -c release
bash scripts/package.sh

if [[ -n "$(git status --porcelain scripts/package.sh)" ]]; then
  git add scripts/package.sh
  git commit -m "release: $TAG"
fi

git tag -a "$TAG" -m "$TAG"
git push origin HEAD
git push origin "$TAG"

# 產生 release notes：從上一個 tag 到 HEAD 的 commit 訊息
PREV_TAG=$(git describe --tags --abbrev=0 "$TAG^" 2>/dev/null || echo "")
NOTES_FILE=$(mktemp)
{
  echo "## 更新內容"
  echo ""
  if [[ -n "$PREV_TAG" ]]; then
    git log "$PREV_TAG..$TAG" --pretty=format:"- %s" --no-merges | grep -v "^- release: v" || true
    echo ""
    echo ""
    echo "**Full changelog:** $PREV_TAG...$TAG"
  else
    git log "$TAG" --pretty=format:"- %s" --no-merges | grep -v "^- release: v" || true
  fi
  echo ""
  echo ""
  echo "## 安裝"
  echo ""
  echo "解壓 zip → 雙擊 \`安裝.command\` 自動安裝，或手動："
  echo ""
  echo "1. 拖 \`WiFiCat.app\` 進 \`/Applications/\`"
  echo "2. Terminal 執行："
  echo '   ```sh'
  echo "   xattr -dr com.apple.quarantine \"/Applications/WiFiCat.app\""
  echo '   ```'
} > "$NOTES_FILE"

gh release create "$TAG" \
  --title "WiFiCat $VERSION" \
  --notes-file "$NOTES_FILE" \
  "dist/WiFiCat-$VERSION.zip"

rm -f "$NOTES_FILE"

echo ""
echo "released: $TAG"
gh release view "$TAG" --web >/dev/null 2>&1 || true
