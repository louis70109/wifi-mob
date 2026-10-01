# ADR 0003: 使用懸浮無邊框透明視窗作為桌面寵物

- Status: Accepted
- Date: 2026-07-22

主介面不是一般視窗，而是以 `WindowAccessor` 調整出的透明、可拖曳、跨 Space 懸浮桌面寵物。

## Context

WiFiCat 的核心互動不是表單或多頁面，而是讓使用者在螢幕角落持續看到一個小圖示，隨 `WiFiMonitor` 的即時 RSSI 改變姿態與顏色。若採一般 SwiftUI 視窗加標題列，使用者會把它當成普通 app：需要切換、縮放、整理視窗，反而干擾「常駐陪伴」這個目的。另一方面，若只做 `MenuBarExtra`，雖然能節省畫面，但就失去把寵物拖到特定角落、在不同空間都看得到的能力。專案因此需要一個視覺上近似桌面物件、行為上又仍是正常 app window 的折衷方案。

## Decision

`WiFiCatApp` 仍以 SwiftUI `WindowGroup` 建立主視窗，但在 `PetWindowView` 透過 `WindowAccessor: NSViewRepresentable` 取得 `NSWindow` 後，統一設定 `.level = .floating`、`.isOpaque = false`、`.backgroundColor = .clear`、`.hasShadow = false`、`.isMovableByWindowBackground = true`、`.styleMask = [.borderless, .fullSizeContentView]`、`.collectionBehavior = [.canJoinAllSpaces, .stationary]`。主窗只負責 `PetSpriteView` 與狀態 badge；記錄與管理功能另放進 `MenuBarExtra` 的 `MenuBarPanel`。

## Consequences

- 好處：視窗像桌面寵物而不是工具面板，存在感低，但即時狀態可視性高。
- 好處：可拖曳到任意角落，且跨 Space 顯示，適合邊走動邊觀察訊號變化。
- 好處：把 `AppState.records` 的記錄流程移到選單列面板後，主視窗保持單一職責，不會因表單與列表變得雜亂。
- 代價：無標題列與系統按鈕，關閉方式只能靠右鍵選單的「結束」或選單列結束， discoverability 較差。
- 代價：部分標準視窗行為需手動設定與維護，不能只靠 SwiftUI 預設值。

## Alternatives Considered

- 一般 SwiftUI Window 搭配標題列：實作最省，但視覺上太像普通 app，違背桌面寵物目標。
- 只保留 `MenuBarExtra`、沒有主視窗：可再更小，但失去可拖曳、可常駐角落的主要體驗。
