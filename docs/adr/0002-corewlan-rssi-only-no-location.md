# ADR 0002: 只讀 RSSI，不申請 Location 權限

- Status: Accepted
- Date: 2026-07-22

本專案刻意只讀 `CWInterface.rssiValue()`，避開 SSID/BSSID 與 Location 權限整串摩擦。

## Context

wifi-mob 要反映的是訊號強弱，不是做完整 Wi-Fi 掃描器。macOS 12 之後，若想從 CoreWLAN 讀取 SSID，通常需要 Location 授權，且 App 還必須從 LaunchServices session 啟動；BSSID 在實務上更接近長期鎖死，不能把它當可靠資料來源。這些條件會把一個原本只想顯示即時品質的小工具，變成要解釋權限、沙盒與啟動方式的複雜桌面程式。相對地，`WiFiMonitor` 內的 `CWWiFiClient.shared().interface()?.rssiValue()` 可以直接取得目前連線的 RSSI，正好足夠驅動 `Quality.classify(rssi:)` 與 `AppState` 的顯示流程。

## Decision

專案只呼叫 `CWInterface.rssiValue()`，不讀 SSID、不讀 BSSID，也不在 `Info.plist` 宣告 `NSLocationUsageDescription`。`scripts/package.sh` 產生的 app bundle 不加入額外 entitlement，整體流程維持非沙盒、低摩擦的本地工具模式。UI 層只展示 `monitor.rssi` 與由此推得的品質，不假裝提供網路名稱或 AP 識別資訊。

## Consequences

- 好處：第一次啟動幾乎沒有授權學習成本，不會跳出 Location 權限視窗，安裝體驗單純。
- 好處：不需處理沙盒、LaunchServices session 或權限被拒後的錯誤分支，`WiFiMonitor` 可以保持很小。
- 好處：降低 Mac App Store 或系統審查時對敏感網路資訊的疑慮，雖然目前專案未上架。
- 代價：使用者無法在 `MenuBarPanel` 或 `PetWindowView` 看到目前連到哪個 SSID。
- 代價：若未來要做多 AP 比對、頻段識別或網路名稱標示，必須重新引入權限設計與啟動條件。

## Alternatives Considered

- 完整 CoreWLAN + Location 權限：功能較完整，但授權流程複雜，且對小工具來說摩擦過高，也可能增加審查風險。
- shell out `wdutil info`：表面上可拿更多資訊，但常需要 `sudo`，自動化分發差，且 BSSID 仍不是可靠解法。
