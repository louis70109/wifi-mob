# WiFiCat

一隻懸浮在桌面上的點陣寵物，會依當前 Wi-Fi 訊號強度改變外觀，幫你走動找家中 Wi-Fi 死角。

- 可切換造型：貓、橘菇菇、蝸牛、豬、樹樁、寶可夢
- 貓的訊號極佳：橘虎斑，昂首坐姿，金光光暈
- 貓的訊號普通：淡褐虎斑，滿意半彎眼
- 貓的訊號尚可：灰貓，垂耳半閉眼
- 貓的訊號不穩：幽靈黑貓，半透明趴地

## 安裝（一般使用者）

1. 從 [GitHub Releases](https://github.com/louis70109/wifi-mob/releases) 下載最新的 `WiFiCat-x.y.z.zip`
2. 解壓縮，把 `WiFiCat.app` 拖進 `/Applications/`
3. 首次開啟：
   - AirDrop 過來：右鍵 → 打開 → 打開
   - 網路下載：先在 Terminal 執行 `xattr -dr com.apple.quarantine "/Applications/WiFiCat.app"`
4. 系統會問一次「允許存取 Wi-Fi 資訊」，按允許

## Windows

1. 在 [Actions → Windows build](https://github.com/louis70109/wifi-mob/actions/workflows/windows-build.yml) 開啟最新成功的執行紀錄。
2. 下載 `WiFiCat-win-x64` artifact，解壓縮後執行 `WiFiCat.exe`（自包含，不需另外安裝 .NET）。
3. 楓之谷 Mob 原圖首次載入需網路，之後快取在 `%LOCALAPPDATA%\WiFiCat\mobs`。

## 使用

- 打開後，桌面出現可拖曳的懸浮角色
- 從選單列設定或角色右鍵選單切換貓、橘菇菇、蝸牛、豬、樹樁或寶可夢
- 所選角色的外觀與動態會反映 Wi-Fi 品質
- 楓之谷 Mob 首次載入需網路，之後從本機快取顯示
- 右上選單列可記錄目前房間位置；排序記錄找出 RSSI 最弱處
- 右鍵角色或選單列 → 結束

系統需求：macOS 13+；Windows 10/11 x64

## 開發

```sh
swift test          # 執行自動化測試
swift run           # 開發時直接執行
swift build -c release
bash scripts/package.sh   # 打包為 .app + zip
```

### 發佈新版本

```sh
bash scripts/release.sh <version>
```

新功能請升 minor 版；腳本會 build、打包、tag、push，並建立 GitHub Release。

## 限制

- 只讀「目前連線」的 Wi-Fi RSSI，不掃描附近所有 AP（macOS 對第三方 app 的架構限制）
- macOS 版本採 Ad-hoc 簽章、未經 Apple 公證；首次開啟可能需要使用者允許。
- Wi-Fi RSSI 反映的是「貓（Mac）到路由器」的訊號，不代表整個網路品質
