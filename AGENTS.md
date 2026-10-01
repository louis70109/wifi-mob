# WiFiCat Contributor Guide

WiFiCat is a floating desktop companion that reflects current Wi-Fi signal quality and helps users compare signal strength between rooms.

## Platforms

- macOS: SwiftUI, CoreWLAN, and Swift Package Manager (`Sources/WiFiCat`).
- Windows: .NET 8 WPF (`windows/WiFiCat.Windows`). The current WLAN signal is read with fixed `netsh wlan show interfaces` arguments.
- MapleStory mob sprites are fetched over HTTPS from the public MapleStory Wiki and cached in the user's local cache directory; image files are not committed.

## Build and test

macOS:

```sh
swift test
swift build -c release
bash scripts/package.sh
```

Windows:

```powershell
dotnet publish windows/WiFiCat.Windows/WiFiCat.Windows.csproj `
  --configuration Release --runtime win-x64 --self-contained true `
  -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true
```

GitHub Actions builds a self-contained Windows executable on pushes and pull requests to `main`, and publishes it as the `WiFiCat-win-x64` artifact. The macOS release workflow runs on semantic-version tags (`vMAJOR.MINOR.PATCH`).

## Release versions

- Follow semantic versioning.
- New user-visible features → minor version.
- Bug fixes and visual corrections → patch version.
- `bash scripts/release.sh <version>` requires a clean worktree, runs tests and packaging, creates a tag, and publishes a GitHub release.

## Project structure

```text
Sources/WiFiCat/
├── Quality.swift          RSSI quality classification
├── WiFiMonitor.swift      CoreWLAN monitoring
├── PixelScene.swift       Cat sprite and shared pixel drawing
├── MapleMobSprites.swift  MapleStory sprite loading and local cache
├── CharizardSprite.swift  Pokémon sprite loading and evolution
├── RPGChrome.swift        Costume, app state, and menu-bar UI
└── WiFiCatApp.swift       macOS app, floating window, and settings

windows/WiFiCat.Windows/   Windows WPF desktop app
Tests/WiFiCatTests/        RSSI and mob-source tests
```

## Development rules

- Keep credentials, private URLs, and local machine paths out of tracked files.
- Do not add package dependencies without a clear need.
- Preserve `Quality` thresholds and display names unless tests and documentation change with them.
- Animations must respect `accessibilityReduceMotion` on macOS.
- Do not commit `.build/`, `.swiftpm/`, `dist/`, Windows `bin/` or `obj/`, or `artifacts/`.
