#!/usr/bin/env bash
# 發佈新版本：build + 打包 + tag + push；GitHub Actions 發佈雙平台 assets
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

echo ""
echo "pushed tag: $TAG"
echo "GitHub Actions will build and publish the macOS zip and Windows executable."
