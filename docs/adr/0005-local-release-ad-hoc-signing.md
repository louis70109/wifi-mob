# ADR 0005: Cross-platform CI builds and macOS Ad-hoc signing

- Status: Accepted
- Date: 2026-10-01

wifi-mob provides a SwiftUI macOS app and a WPF Windows app. Public GitHub Actions workflows build the macOS release package and a self-contained Windows x64 executable.

## Context

The macOS app uses CoreWLAN and requires a macOS build host. The Windows app reads the current WLAN signal and must be built on a Windows runner. Both platforms share the same signal-quality states and selectable MapleStory mob sprites, while retaining native UI and platform-specific Wi-Fi providers.

The macOS package is ad-hoc signed and is not notarized. This keeps the app straightforward to build and distribute, but macOS may require the user to approve the first launch.

## Decision

- Run the Windows build workflow on pushes and pull requests to `main`; publish a self-contained `wifi-mob.exe` artifact.
- Run the release workflow on semantic-version tags; build the macOS zip and Windows executable, then attach both assets to the GitHub Release.
- Fetch MapleStory mob sprites from their public source URLs and cache them locally; do not commit downloaded image files or credentials.
- Keep the GitHub Actions token scoped to the release job and do not store secrets in the repository.

## Consequences

- Windows users can download a self-contained x64 executable from either the GitHub Actions artifact or the GitHub Release.
- macOS releases remain ad-hoc signed and are not notarized; the first launch may require approval.
- Mob sprites require network access on first selection and are available from the local cache afterward.

## Alternatives Considered

- A Windows installer/MSIX package: defer until installation requirements justify a separate packaging pipeline.
- Apple Developer ID signing and notarization: more formal distribution, but requires a paid developer account.
