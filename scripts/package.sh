#!/usr/bin/env bash
# 打包 wifi-mob 為 .app bundle + ad-hoc 簽章 + zip
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP_NAME="wifi-mob"
EXECUTABLE_NAME="WiFiCat"
BUNDLE_ID="com.louis70109.wifi-mob"
VERSION="1.8.3"
BUILD="1"

DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
BIN="$ROOT/.build/release/$EXECUTABLE_NAME"

if [[ ! -x "$BIN" ]]; then
  echo "找不到 release binary，先跑 swift build -c release" >&2
  exit 1
fi

rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/$EXECUTABLE_NAME"
# Strip DWARF debug data, which embeds the local source path.
strip -S "$APP/Contents/MacOS/$EXECUTABLE_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key><string>$EXECUTABLE_NAME</string>
  <key>CFBundleVersion</key><string>$BUILD</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" >/dev/null 2>&1
codesign --verify --deep --strict "$APP" && echo "codesign OK"

ZIP="$DIST/$APP_NAME-$VERSION.zip"
STAGE="$DIST/stage"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"

cat > "$STAGE/安裝.command" <<'INSTALL'
#!/bin/bash
# 雙擊此檔即可安裝：複製 .app 到 /Applications、去除 quarantine 標記、啟動
set -e
cd "$(dirname "$0")"

APP="wifi-mob.app"
DEST="/Applications"

if [[ ! -d "$APP" ]]; then
  echo "找不到 $APP，請確認此 .command 檔和 .app 在同一資料夾" >&2
  read -n 1 -s -r -p "按任意鍵關閉..."
  exit 1
fi

echo "複製 $APP 到 $DEST/ ..."
rm -rf "$DEST/$APP" 2>/dev/null || true
cp -R "$APP" "$DEST/"

echo "移除 quarantine 標記 ..."
xattr -dr com.apple.quarantine "$DEST/$APP" || true

echo "啟動 wifi-mob ..."
open "$DEST/$APP"

echo ""
echo "完成！桌面應該出現懸浮的點陣貓。"
echo "此視窗 3 秒後自動關閉。"
sleep 3
INSTALL
chmod +x "$STAGE/安裝.command"

cat > "$STAGE/README.txt" <<'README'
wifi-mob — Wi-Fi 訊號點陣寵物（macOS）

最快安裝方式
1. 雙擊「安裝.command」
   - 若 macOS 擋下來說「不明開發者」：右鍵它 → 打開 → 打開
   - 之後這個檔會自動：複製到 /Applications、去除隔離標記、啟動 App
2. 系統會問一次「允許存取 Wi-Fi 資訊」，按允許

如果不想用 .command 的手動安裝
1. 拖 wifi-mob.app 進 /Applications/
2. Terminal 執行：
   xattr -dr com.apple.quarantine "/Applications/wifi-mob.app"
3. 從 Launchpad 或 Applications 打開

用法
- 螢幕出現可拖曳的懸浮角色
- 造型選單可切換貓、橘菇菇、蝸牛、豬、樹樁或寶可夢
- MapleStory Mob 圖片首次載入需網路，下載後快取於本機
- 所選角色會依 Wi-Fi 品質改變外觀與動態
- 選單列可記錄房間 RSSI，排序找訊號弱處
- 右鍵角色或選單列 → 結束

系統需求：macOS 13 Ventura 以上
限制：macOS 版本採 Ad-hoc 簽章，未經 Apple 公證。
README

( cd "$STAGE" && /usr/bin/ditto -c -k --sequesterRsrc . "$ZIP" )
rm -rf "$STAGE"

echo "---"
ls -lh "$APP/Contents/MacOS/$EXECUTABLE_NAME" "$ZIP"
echo "output: $ZIP"
