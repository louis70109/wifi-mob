# ADR 0006: PokeAPI 動態 Sprite + 上班時間進化機制

- Status: Accepted
- Date: 2026-07-23

寶可夢造型從 PokeAPI 動態下載 Gen V 點陣 sprite，並在上班時間 (10:00-19:00) 依進化鏈自動切換型態。

## Context

v1.4.0 引入寶可夢造型，原先嘗試手繪 16x16 `[[Int]]` grid，但辨識度不足。改用 PokeAPI 提供的 Gen V Black/White sprite（96x96 pixel art，透明背景），以 `.interpolation(.none)` 保持像素銳利。這打破了 ADR 0004 的「純程式碼 sprite」原則，但寶可夢的設計複雜度遠超手繪可行範圍，且 PokeAPI 涵蓋 1025 隻，手繪不現實。

使用者進一步希望寶可夢能「在上班時間隨時間進化」，每天早上重置回第一階，營造養成感。

## Decision

### Sprite 來源

- URL: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/{id}.png`
- 覆蓋 #1~1008+，全世代，去背，pixel art 風格
- 本地快取至 `~/Library/Caches/WiFiCat/pokemon/{id}.png`

### 進化鏈查詢

兩步 API 呼叫：
1. `GET /pokemon-species/{id}/` 取得 `evolution_chain.url`
2. `GET /evolution-chain/{chainId}/` 遞迴解析 `chain.evolves_to`

分支進化（如伊布）取第一條路徑。

### 時間驅動進化

```
上班時間: 10:00 - 19:00 (540 分鐘)
進化鏈:  [stage0, stage1, stage2]  (最多 3 階)
時段:     540 / stageCount = 每階段分鐘數

10:00 前  → stage0 (重置)
10:00-12:59 → stage0
13:00-15:59 → stage1
16:00-18:59 → stage2
19:00 後  → stage0 (重置)
```

每 60 秒檢查一次，自動切換 sprite。隔天自然重置（因為新的一天從 stage0 開始）。

### 搜尋機制

- 輸入數字 (1-1025) 直接查
- 輸入英文名透過 `GET /pokemon/{name}` 解析 ID
- 選中後立即載入 sprite 並查詢進化鏈

## Consequences

- 好處：1025 隻寶可夢可選，無需手繪任何 sprite。
- 好處：上班時間進化機制增加日常趣味與養成感。
- 好處：快取機制避免重複網路請求。
- 代價：需要網路連線（首次載入）；離線時若快取不存在會顯示 placeholder。
- 代價：PokeAPI 無 SLA；若 GitHub raw 或 PokeAPI 不可用，sprite 載入失敗。
- 代價：圖像版權屬 The Pokemon Company，僅適用於個人/非商業場景。
- 代價：偏離 ADR 0004 的純程式碼原則，寶可夢造型依賴外部 PNG。

## Alternatives Considered

- 手繪 `[[Int]]` grid：辨識度不足，1025 隻不可行。
- 內嵌 PNG 資源到 bundle：體積膨脹，且授權不允許重新分發。
- 預設 sprite 路徑 (`/pokemon/{id}.png`)：更大更清晰但非 pixel art 風格，與整體點陣美學不一致。
