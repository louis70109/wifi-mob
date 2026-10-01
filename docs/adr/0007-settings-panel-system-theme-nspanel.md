# ADR 0007: 設定面板使用系統配色與獨立 NSPanel

- Status: Accepted
- Date: 2026-07-24

設定面板改用系統語意顏色並以 NSPanel 承載，確保明暗模式相容與文字輸入可用。

## Context

v1.5.0 的設定面板硬寫深色背景 (`Color(white: 0.12)`) 與淺色文字 (`Color(white: 0.70)`)，在 macOS 淺色模式下文字幾乎不可見。另外原先使用 SwiftUI `.sheet` 附著在透明無邊框懸浮視窗上，導致 TextField 無法取得鍵盤焦點（macOS 的 borderless window 不會成為 key window）。

## Decision

### NSPanel 取代 sheet

設定面板改用 `NSPanel`（utility window），具備以下特性：
- `.nonactivatingPanel` + `becomesKeyOnlyIfNeeded = false` 讓它能接收鍵盤輸入
- `.floating` level 確保不被寵物視窗遮蔽
- 由 `SettingsWindowController` singleton 管理生命週期

### 系統語意顏色

移除所有硬寫的 `Color(white: N)` 與 `.background(Color(white: 0.12))`：
- 文字使用 `.primary`（預設）與 `.secondary`
- TextField 使用 `.roundedBorder` 樣式（自動適配明暗）
- 背景不設定，使用 NSPanel 預設外觀

### 搜尋結果預覽圖 + Hover

每筆搜尋結果顯示 32x32 sprite 縮圖（`PokemonPreview`），hover 時：
- 背景亮起（`Color.accentColor.opacity(0.12)`）
- 預覽圖放大 1.2 倍（`.scaleEffect` + animation）

## Consequences

- 好處：明暗模式都能正常閱讀與操作。
- 好處：NSPanel 正確處理鍵盤焦點，搜尋欄可正常輸入。
- 好處：預覽圖讓使用者不需記住編號就能辨識寶可夢。
- 代價：放棄了原本 RPG 風格的深色 UI（設定面板改跟系統走）。
- 代價：NSPanel singleton 的生命週期需手動管理。

## Alternatives Considered

- 保持 `.sheet` + 強制 dark mode：無法解決鍵盤焦點問題。
- 用 `NSWindow` 而非 `NSPanel`：accessory app 的 NSWindow 同樣有焦點問題，NSPanel 天生支援 floating key window。
- 純文字列表不帶預覽：辨識度差，使用者需要記住英文名或編號。
