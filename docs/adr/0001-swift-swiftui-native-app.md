# ADR 0001: 選擇 Swift + SwiftUI 建立 macOS 原生 app

- Status: Accepted
- Date: 2026-07-22

本專案以 Swift Package Manager 的 executable target 搭配 SwiftUI，直接做成只支援 macOS 的原生小工具。

## Context

WiFiCat 的目標很單純：在家中走動時，即時讀取目前連線 Wi-Fi 的 RSSI dBm，快速找出訊號死角。這個需求第一個卡點不是 UI，而是資料來源。一般 Web app 就算能做漂亮介面，也拿不到實際的 RSSI 數值；`navigator.connection` 最多提供粗略連線資訊，無法支援 `Quality.classify(rssi:)` 這種以 dBm 為核心的分級邏輯。另一條路是 Electron，但對一個只需常駐角落、顯示 `PetWindowView` 與 `MenuBarExtra` 的小程式來說，整包 Chromium 與 Node.js 過重，啟動、記憶體與分發體積都不划算。

## Decision

專案採用 `Package.swift` 定義的 Swift Package Manager executable target，平台固定為 `.macOS(.v13)`，主程式入口是 `WiFiCatApp`。介面層使用 SwiftUI，系統層則直接呼叫 AppKit 與 CoreWLAN。這讓開發流程可用 `swift run`、`swift build -c release`、`swift test` 完成，不依賴 Xcode 專案檔，也不需要額外 runtime 或跨平台包裝層。

## Consequences

- 好處：CommandLineTools 即可建置，降低環境門檻；`swift run` 能直接驗證懸浮視窗行為，迭代快。
- 好處：產物是原生 binary，無額外 runtime 相依，分發包小，release binary 約 500KB 等級，適合個人分享。
- 好處：SwiftUI、AppKit、CoreWLAN 可以直接互通，`WindowAccessor`、`WiFiMonitor` 等元件不需繞橋接層。
- 代價：專案明確綁定 macOS，無法直接移植到 Windows、Linux 或瀏覽器。
- 代價：UI 與系統 API 受 Apple 平台演進影響，設計天然偏向單機工具而非跨平台產品。

## Alternatives Considered

- Electron：可快速做桌面 app，但體積與資源佔用過高，對 WiFiCat 這種單功能常駐工具不划算。
- Web + `navigator.connection`：可部署容易，但拿不到 RSSI dBm，無法滿足核心需求。
- Objective-C：同樣能呼叫 macOS API，但語言與專案可讀性、維護性不如現代 Swift，沒有必要回退。
