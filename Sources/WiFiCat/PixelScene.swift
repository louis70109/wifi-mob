// PixelScene.swift — MMORPG 點陣風場景（貓咪主角版）
// 純 SwiftUI Canvas / Path / TimelineView，無外部資源

import SwiftUI

// MARK: - Palette

struct Palette {
    let sky:       Color
    let skyFar:    Color
    let ground:    Color
    let groundAlt: Color
    let accent:    Color
    let dim:       Color

    static func from(_ q: Quality) -> Palette {
        switch q {
        case .excellent:
            return Palette(
                sky:       Color(red: 0.35, green: 0.62, blue: 0.95),
                skyFar:    Color(red: 0.55, green: 0.80, blue: 1.00),
                ground:    Color(red: 0.22, green: 0.62, blue: 0.22),
                groundAlt: Color(red: 0.18, green: 0.52, blue: 0.18),
                accent:    Color(red: 1.00, green: 0.85, blue: 0.20),
                dim:       Color(red: 0.12, green: 0.32, blue: 0.12)
            )
        case .good:
            return Palette(
                sky:       Color(red: 0.75, green: 0.50, blue: 0.25),
                skyFar:    Color(red: 0.90, green: 0.68, blue: 0.35),
                ground:    Color(red: 0.20, green: 0.45, blue: 0.30),
                groundAlt: Color(red: 0.16, green: 0.38, blue: 0.25),
                accent:    Color(red: 0.40, green: 0.90, blue: 0.60),
                dim:       Color(red: 0.10, green: 0.25, blue: 0.18)
            )
        case .fair:
            return Palette(
                sky:       Color(red: 0.28, green: 0.26, blue: 0.38),
                skyFar:    Color(red: 0.38, green: 0.35, blue: 0.48),
                ground:    Color(red: 0.18, green: 0.22, blue: 0.18),
                groundAlt: Color(red: 0.14, green: 0.18, blue: 0.14),
                accent:    Color(red: 0.65, green: 0.58, blue: 0.30),
                dim:       Color(red: 0.08, green: 0.10, blue: 0.08)
            )
        case .unstable:
            return Palette(
                sky:       Color(red: 0.08, green: 0.05, blue: 0.08),
                skyFar:    Color(red: 0.18, green: 0.08, blue: 0.12),
                ground:    Color(red: 0.12, green: 0.06, blue: 0.06),
                groundAlt: Color(red: 0.09, green: 0.04, blue: 0.04),
                accent:    Color(red: 0.60, green: 0.15, blue: 0.15),
                dim:       Color(red: 0.06, green: 0.03, blue: 0.03)
            )
        }
    }
}

// MARK: - 貓咪 Sprite 定義
//
// 16 × 14 格，pixelSize = 2 → 實際 32×28 px
// 色碼：
//   0 = 透明
//   1 = 主毛色（貓身，用 palette.ground 偏亮色）
//   2 = 深毛色 / 條紋陰影（dim 偏亮）
//   3 = 眼睛（accent）
//   4 = 鼻子粉（固定粉色）
//   5 = 肚皮亮色（近白）
//   6 = 耳內粉（固定淡粉）
//   7 = 輪廓黑（dim 深）

// --- excellent：昂首坐姿，耳朵直立，眼睛圓亮，尾巴高舉 ---
private let catExcellent: [[Int]] = [
    [0,0,0,0,7,0,0,0,0,7,0,0,0,0,0,0],  // 0  耳尖
    [0,0,0,7,1,7,0,0,7,1,7,0,0,0,0,0],  // 1  耳外
    [0,0,7,1,6,1,7,7,1,6,1,7,0,0,0,0],  // 2  耳內粉
    [0,0,7,1,1,1,1,1,1,1,1,7,0,0,0,0],  // 3  頭頂
    [0,7,1,1,1,1,1,1,1,1,1,1,7,0,0,0],  // 4  頭寬
    [0,7,1,3,3,1,1,1,1,3,3,1,7,0,0,0],  // 5  圓眼（accent）
    [0,7,1,3,3,1,4,1,1,3,3,1,7,0,0,0],  // 6  眼+鼻
    [0,0,7,1,1,1,1,1,1,1,1,7,0,0,0,0],  // 7  臉下
    [0,7,1,1,5,5,5,5,5,5,1,1,7,0,0,0],  // 8  頸+肚皮起
    [0,7,1,5,5,5,5,5,5,5,5,1,7,7,0,0],  // 9  身體（尾巴分支）
    [0,7,1,1,5,5,5,5,5,1,1,7,1,7,0,0],  // 10 身體+尾根
    [0,0,7,1,1,1,1,1,1,1,7,1,1,7,0,0],  // 11 下身+尾中
    [0,7,1,7,0,0,0,0,0,7,1,7,1,7,0,0],  // 12 前腳+尾
    [0,7,7,0,0,0,0,0,0,0,7,7,7,7,0,0],  // 13 腳底+尾尖
]

// --- good：正常坐姿，半彎眼，尾巴自然平伸 ---
private let catGood: [[Int]] = [
    [0,0,0,0,7,0,0,0,0,7,0,0,0,0,0,0],
    [0,0,0,7,1,7,0,0,7,1,7,0,0,0,0,0],
    [0,0,7,1,6,1,7,7,1,6,1,7,0,0,0,0],
    [0,0,7,1,1,1,1,1,1,1,1,7,0,0,0,0],
    [0,7,1,1,1,1,1,1,1,1,1,1,7,0,0,0],
    [0,7,1,2,2,1,1,1,1,2,2,1,7,0,0,0],  // 半彎眼（深色上眼皮）
    [0,7,1,3,3,1,4,1,1,3,3,1,7,0,0,0],
    [0,0,7,1,1,1,1,1,1,1,1,7,0,0,0,0],
    [0,7,1,1,5,5,5,5,5,5,1,1,7,0,0,0],
    [0,7,1,5,5,5,5,5,5,5,5,1,7,0,0,0],
    [0,7,1,1,5,5,5,5,5,1,1,7,0,0,0,0],  // 尾巴收在身側
    [0,0,7,1,1,1,1,1,1,1,7,0,0,0,0,0],
    [0,7,1,7,0,0,0,0,0,7,7,1,1,7,0,0],  // 尾巴水平延伸
    [0,7,7,0,0,0,0,0,0,0,7,7,7,0,0,0],
]

// --- fair：耷拉耳朵，尾巴垂下，眼睛半閉 ---
private let catFair: [[Int]] = [
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],  // 耳朵向外垂
    [0,7,7,0,0,0,0,0,0,0,0,7,7,0,0,0],
    [0,7,1,7,0,0,0,0,0,0,7,1,7,0,0,0],  // 垂耳
    [0,0,7,1,1,1,1,1,1,1,1,7,0,0,0,0],
    [0,0,7,1,1,1,1,1,1,1,1,1,7,0,0,0],
    [0,0,7,2,2,1,1,1,1,2,2,1,7,0,0,0],  // 半閉眼（上蓋蓋住一半）
    [0,0,7,1,1,1,4,1,1,1,1,1,7,0,0,0],
    [0,0,0,7,1,1,1,1,1,1,1,7,0,0,0,0],
    [0,0,7,1,1,5,5,5,5,5,1,1,7,0,0,0],
    [0,0,7,1,5,5,5,5,5,5,5,1,7,0,0,0],
    [0,0,7,1,1,5,5,5,5,1,1,7,0,0,0,0],
    [0,0,0,7,1,1,1,1,1,1,7,7,0,0,0,0],  // 尾巴向下垂
    [0,0,7,1,7,0,0,0,0,7,1,7,0,0,0,0],
    [0,0,7,7,0,0,0,0,0,0,7,7,7,0,0,0],  // 尾尖垂地
]

// --- unstable：蜷縮趴地，閉眼，只見背部弓形 ---
private let catUnstable: [[Int]] = [
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,7,7,7,7,0,0,0,0,0,0,0],  // 弓背頂
    [0,0,0,7,1,1,1,1,1,1,7,0,0,0,0,0],
    [0,0,7,1,2,1,1,1,1,2,1,7,0,0,0,0],  // 背部條紋
    [0,7,1,1,1,1,1,1,1,1,1,1,7,0,0,0],
    [0,7,1,2,1,1,1,1,1,1,2,1,7,0,0,0],
    [0,7,1,1,1,1,1,1,1,1,1,1,7,0,0,0],
    [0,0,7,1,1,1,5,5,1,1,1,7,0,0,0,0],  // 側面肚皮
    [0,0,7,2,2,1,1,1,1,2,2,7,0,0,0,0],  // 閉眼線
    [0,7,1,1,1,1,4,1,1,1,1,1,7,0,0,0],  // 鼻子
    [0,7,7,1,1,1,1,1,1,1,7,7,7,7,0,0],  // 尾巴收攏環繞
    [0,0,0,7,1,1,1,1,1,7,7,1,1,7,0,0],
    [0,0,0,0,7,7,7,7,7,0,0,7,7,0,0,0],
]

// MARK: - 尾巴 sway 動畫用的尾巴頂端 Y 偏移
// excellent 模式下，尾巴上方額外偏移讓視覺有 sway 感
// 實作：在 excellent 模式下，尾巴那幾行（row 9-13）向上偏移 0 或 1

private func catSpriteFor(_ quality: Quality) -> [[Int]] {
    switch quality {
    case .excellent: return catExcellent
    case .good:      return catGood
    case .fair:      return catFair
    case .unstable:  return catUnstable
    }
}

// MARK: - CatPalette — 獨立於地形的真貓配色

struct CatPalette {
    let body:     Color    // idx 1 主毛色
    let stripe:   Color    // idx 2 深色條紋/陰影
    let eye:      Color    // idx 3 眼睛
    let nose:     Color    // idx 4 鼻子
    let belly:    Color    // idx 5 肚皮亮色
    let earPink:  Color    // idx 6 耳內粉
    let outline:  Color    // idx 7 輪廓
    let aura:     Color?   // 身邊光暈；nil = 不畫
    let opacity:  Double   // 整體透明度（幽靈貓 < 1.0）

    // 橘虎斑 — excellent
    static let excellent = CatPalette(
        body:    Color(red: 0.91, green: 0.58, blue: 0.31),  // #E89550
        stripe:  Color(red: 0.55, green: 0.29, blue: 0.12),  // #8B4A1E
        eye:     Color(red: 0.50, green: 0.81, blue: 0.37),  // #7FCE5F
        nose:    Color(red: 0.95, green: 0.65, blue: 0.67),  // #F2A6AB
        belly:   Color(red: 0.96, green: 0.91, blue: 0.82),  // #F5E8D0
        earPink: Color(red: 0.96, green: 0.75, blue: 0.79),  // #F5C0CA
        outline: Color(red: 0.24, green: 0.12, blue: 0.04),  // #3E1F0A
        aura:    Color(red: 1.00, green: 0.78, blue: 0.42),  // #FFC66B
        opacity: 1.0
    )

    // 淡褐虎斑 — good
    static let good = CatPalette(
        body:    Color(red: 0.78, green: 0.65, blue: 0.47),  // #C8A579
        stripe:  Color(red: 0.48, green: 0.34, blue: 0.22),  // #7A5738
        eye:     Color(red: 0.91, green: 0.66, blue: 0.27),  // #E8A845
        nose:    Color(red: 0.95, green: 0.65, blue: 0.67),
        belly:   Color(red: 0.94, green: 0.89, blue: 0.81),  // #F0E4CE
        earPink: Color(red: 0.96, green: 0.75, blue: 0.79),
        outline: Color(red: 0.23, green: 0.14, blue: 0.08),  // #3B2415
        aura:    Color(red: 0.91, green: 0.70, blue: 0.44),  // #E8B270
        opacity: 1.0
    )

    // 冷灰貓 — fair
    static let fair = CatPalette(
        body:    Color(red: 0.56, green: 0.59, blue: 0.63),  // #8E96A0
        stripe:  Color(red: 0.30, green: 0.31, blue: 0.35),  // #4B5058
        eye:     Color(red: 0.62, green: 0.71, blue: 0.76),  // #9EB4C2
        nose:    Color(red: 0.95, green: 0.65, blue: 0.67),
        belly:   Color(red: 0.85, green: 0.86, blue: 0.89),  // #D8DCE2
        earPink: Color(red: 0.96, green: 0.75, blue: 0.79),
        outline: Color(red: 0.14, green: 0.16, blue: 0.19),  // #242830
        aura:    nil,
        opacity: 1.0
    )

    // 幽靈貓 — unstable
    static let unstable = CatPalette(
        body:    Color(red: 0.16, green: 0.13, blue: 0.16),  // #2A2028
        stripe:  Color(red: 0.08, green: 0.06, blue: 0.08),  // #150F14
        eye:     Color(red: 0.48, green: 0.13, blue: 0.13),  // #7A2020
        nose:    Color(red: 0.54, green: 0.35, blue: 0.38),  // #8A5A62
        belly:   Color(red: 0.24, green: 0.19, blue: 0.22),  // #3E3038
        earPink: Color(red: 0.48, green: 0.31, blue: 0.35),  // #7A4E58
        outline: Color(red: 0.04, green: 0.02, blue: 0.03),  // #0A0608
        aura:    nil,
        opacity: 0.62
    )

    static func from(_ q: Quality) -> CatPalette {
        switch q {
        case .excellent: return .excellent
        case .good:      return .good
        case .fair:      return .fair
        case .unstable:  return .unstable
        }
    }
}

// MARK: - 貓咪色碼對照（使用 CatPalette，不依賴地形 palette）

private func catColors(quality: Quality) -> [Int: Color] {
    let cp = CatPalette.from(quality)
    return [
        1: cp.body,
        2: cp.stripe,
        3: cp.eye,
        4: cp.nose,
        5: cp.belly,
        6: cp.earPink,
        7: cp.outline,
    ]
}

// MARK: - 路由器 Sprite（不動）

private let routerSprite: [[Int]] = [
    [0,0,0,1,2,2,1,0,0,0],
    [0,0,1,1,2,2,1,1,0,0],
    [0,0,0,1,2,2,1,0,0,0],
    [0,0,0,0,1,1,0,0,0,0],
    [0,0,0,0,1,1,0,0,0,0],
    [0,1,1,1,1,1,1,1,1,0],
    [1,1,2,2,2,2,2,2,1,1],
    [1,2,2,3,3,3,3,2,2,1],
    [1,1,2,4,2,2,4,2,1,1],
    [0,1,1,2,2,2,2,1,1,0],
    [0,0,1,1,1,1,1,1,0,0],
    [0,0,0,1,3,3,1,0,0,0],
    [0,0,0,1,3,3,1,0,0,0],
    [0,0,1,1,3,3,1,1,0,0],
]

private func routerColors(palette: Palette) -> [Int: Color] {
    [
        1: Color(white: 0.55),
        2: Color(white: 0.70),
        3: Color(white: 0.35),
        4: palette.accent,
    ]
}

// MARK: - 貓咪繪製（共用，供 PixelScene 與 CatSpriteView 呼叫）

/// 在 ctx 的指定原點畫一隻貓，pixelSize 決定每格大小
func drawCat(
    ctx: inout GraphicsContext,
    quality: Quality,
    origin: CGPoint,
    pixelSize: CGFloat,
    reduceMotion: Bool,
    t: Double
) {
    let grid   = catSpriteFor(quality)
    let colors = catColors(quality: quality)
    let catW   = CGFloat(grid[0].count) * pixelSize
    let catH   = CGFloat(grid.count)    * pixelSize

    let idleBob: CGFloat = (!reduceMotion && Int(t / 0.65) % 2 == 0) ? 0 : -pixelSize * 0.5
    let tailSway: CGFloat = (!reduceMotion && quality == .excellent)
        ? CGFloat(sin(t * 2.8)) * pixelSize
        : 0
    let blinkActive: Bool = !reduceMotion && t.truncatingRemainder(dividingBy: 3.5) < 0.15

    let baseX = origin.x
    let baseY = origin.y + idleBob

    for (row, cols) in grid.enumerated() {
        let rowOffX: CGFloat = (row >= 9 && quality == .excellent) ? tailSway : 0
        for (col, idx) in cols.enumerated() {
            var drawIdx = idx
            if blinkActive && (quality == .excellent || quality == .good) && row == 5 && idx == 3 {
                drawIdx = 2
            }
            guard drawIdx != 0, let color = colors[drawIdx] else { continue }
            ctx.fill(Path(CGRect(
                x: baseX + CGFloat(col) * pixelSize + rowOffX,
                y: baseY + CGFloat(row) * pixelSize,
                width: pixelSize, height: pixelSize
            )), with: .color(color))
        }
    }

    // 腳下陰影
    ctx.fill(Path(ellipseIn: CGRect(
        x: baseX + pixelSize * 2, y: origin.y + catH - pixelSize * 0.5,
        width: catW - pixelSize * 4, height: pixelSize * 1.2
    )), with: .color(.black.opacity(0.22)))
}

// MARK: - CatSpriteView（獨立貓 View，透明背景，供 PetWindow 使用）

struct CatSpriteView: View {
    let quality:      Quality
    let reduceMotion: Bool
    var pixelSize:    CGFloat = 4

    @State private var auraScale: CGFloat = 1.0

    private var catPalette: CatPalette { CatPalette.from(quality) }

    var body: some View {
        let grid = catSpriteFor(quality)
        let w    = CGFloat(grid[0].count) * pixelSize
        let h    = CGFloat(grid.count)    * pixelSize

        ZStack {
            // 底層：光暈（aura）
            if let aura = catPalette.aura {
                Circle()
                    .fill(RadialGradient(
                        colors: [aura.opacity(0.55), aura.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: w * 0.65
                    ))
                    .frame(width: w * 1.4, height: h * 1.4)
                    .blur(radius: 6)
                    .scaleEffect(auraScale)
                    .allowsHitTesting(false)
                    .onAppear {
                        guard !reduceMotion && quality == .excellent else { return }
                        withAnimation(
                            .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
                        ) { auraScale = 1.08 }
                    }
                    .onChange(of: quality) { _ in
                        auraScale = 1.0  // 切換時重置，避免殘留動畫狀態
                    }
            }

            // 中層：貓 Canvas（幽靈透明度）
            Group {
                if reduceMotion {
                    Canvas { ctx, _ in
                        var c = ctx
                        drawCat(ctx: &c, quality: quality,
                                origin: .zero, pixelSize: pixelSize,
                                reduceMotion: true, t: 0)
                    }
                } else {
                    TimelineView(.animation) { tl in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        // 幽靈飄動：Y offset 透過 GeometryReader 無法在 Canvas 內做，
                        // 改在外層 .offset 用 @State 驅動，此處只做繪製
                        Canvas { ctx, _ in
                            var c = ctx
                            drawCat(ctx: &c, quality: quality,
                                    origin: .zero, pixelSize: pixelSize,
                                    reduceMotion: false, t: t)
                        }
                        // 幽靈飄動：在 TimelineView 內以 offset modifier 套用
                        .offset(y: (quality == .unstable)
                            ? CGFloat(sin(t * 1.4) * 1.5)
                            : 0)
                    }
                }
            }
            .frame(width: w, height: h)
            .opacity(catPalette.opacity)
        }
        .frame(width: w, height: h)
        .animation(.easeInOut(duration: 0.6), value: quality)
    }
}

// MARK: - 通用 Sprite 繪製

private func drawSprite(
    ctx: inout GraphicsContext,
    grid: [[Int]],
    colorMap: [Int: Color],
    origin: CGPoint,
    pixelSize: CGFloat
) {
    for (row, cols) in grid.enumerated() {
        for (col, idx) in cols.enumerated() {
            guard idx != 0, let color = colorMap[idx] else { continue }
            let rect = CGRect(
                x: origin.x + CGFloat(col) * pixelSize,
                y: origin.y + CGFloat(row) * pixelSize,
                width:  pixelSize,
                height: pixelSize
            )
            ctx.fill(Path(rect), with: .color(color))
        }
    }
}

// MARK: - 地面 Tile

private func drawGround(
    ctx: inout GraphicsContext,
    size: CGSize,
    groundY: CGFloat,
    tileSize: CGFloat,
    palette: Palette
) {
    let rows = Int(ceil((size.height - groundY) / tileSize)) + 1
    let cols = Int(ceil(size.width / tileSize)) + 1
    for r in 0..<rows {
        for c in 0..<cols {
            let color = (r + c) % 2 == 0 ? palette.ground : palette.groundAlt
            ctx.fill(Path(CGRect(
                x: CGFloat(c) * tileSize, y: groundY + CGFloat(r) * tileSize,
                width: tileSize, height: tileSize
            )), with: .color(color))
        }
    }
}

// MARK: - 訊號環

private func drawSignalRings(
    ctx: inout GraphicsContext,
    origin: CGPoint,
    palette: Palette,
    quality: Quality,
    reduceMotion: Bool,
    t: Double
) {
    guard !reduceMotion else {
        let rp = Path(ellipseIn: CGRect(x: origin.x - 8, y: origin.y - 8, width: 16, height: 16))
        ctx.stroke(rp, with: .color(palette.accent.opacity(0.4)), lineWidth: 1)
        return
    }
    let period: Double = {
        switch quality {
        case .excellent: return 1.0
        case .good:      return 1.6
        case .fair:      return 2.8
        case .unstable:  return 5.0
        }
    }()
    for i in 0..<3 {
        let offset  = Double(i) * period / 3.0
        let phase   = (t + offset).truncatingRemainder(dividingBy: period) / period
        let radius  = CGFloat(4 + phase * 22)
        let opacity = (1.0 - phase) * 0.75
        guard opacity > 0.02 else { continue }
        let rp = Path(ellipseIn: CGRect(
            x: origin.x - radius,       y: origin.y - radius * 0.55,
            width: radius * 2,          height: radius * 1.1
        ))
        ctx.stroke(rp, with: .color(palette.accent.opacity(opacity)), lineWidth: 1.2)
    }
}

// MARK: - PixelScene View

struct PixelScene: View {
    let quality:      Quality
    let reduceMotion: Bool

    // 貓咪 X 比率（靠近 / 遠離訊號塔）
    private var catXRatio: Double {
        switch quality {
        case .excellent: 0.65
        case .good:      0.48
        case .fair:      0.30
        case .unstable:  0.15
        }
    }

    var body: some View {
        let palette = Palette.from(quality)
        Group {
            if reduceMotion {
                Canvas { ctx, size in
                    var c = ctx
                    drawScene(&c, size: size, palette: palette, t: 0)
                }
            } else {
                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in
                        var c = ctx
                        drawScene(&c, size: size, palette: palette, t: t)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.7), value: quality)
    }

    // MARK: - Scene Drawing

    private func drawScene(_ ctx: inout GraphicsContext, size: CGSize, palette: Palette, t: Double) {
        let groundY:  CGFloat = size.height * 0.65
        let tileSize: CGFloat = 16

        // 天空
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.sky))
        ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: groundY * 0.7)),
                 with: .color(palette.skyFar.opacity(0.4)))

        // 地面
        drawGround(ctx: &ctx, size: size, groundY: groundY, tileSize: tileSize, palette: palette)

        // 地面邊線
        var border = Path()
        border.move(to: CGPoint(x: 0, y: groundY))
        border.addLine(to: CGPoint(x: size.width, y: groundY))
        ctx.stroke(border, with: .color(palette.accent.opacity(0.6)), lineWidth: 1.5)

        // 路由器位置
        let routerX   = size.width * 0.85
        let routerH   = CGFloat(routerSprite.count) * 2   // pixelSize=2
        let routerY   = groundY - routerH
        let ringOrigin = CGPoint(x: routerX + 10, y: routerY - 6)

        // 訊號環
        drawSignalRings(ctx: &ctx, origin: ringOrigin, palette: palette,
                        quality: quality, reduceMotion: reduceMotion, t: t)

        // 路由器 sprite
        var ctxR = ctx
        drawSprite(ctx: &ctxR, grid: routerSprite,
                   colorMap: routerColors(palette: palette),
                   origin: CGPoint(x: routerX, y: routerY), pixelSize: 2)

        // --- 貓咪（共用 drawCat）---
        let grid      = catSpriteFor(quality)
        let catW      = CGFloat(grid[0].count) * 2
        let catH      = CGFloat(grid.count) * 2
        let catBaseX  = size.width * catXRatio - catW / 2
        let catBaseY  = groundY - catH

        drawCat(ctx: &ctx, quality: quality,
                origin: CGPoint(x: catBaseX, y: catBaseY),
                pixelSize: 2, reduceMotion: reduceMotion, t: t)
    }
}

// MARK: - TimelineSchedule 輔助（保留以防其他地方引用）

private struct PausedSchedule: TimelineSchedule {
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> [Date] { [startDate] }
}

extension TimelineSchedule where Self == PausedSchedule {
    static var pausedClock: PausedSchedule { PausedSchedule() }
}

// MARK: - PetSpriteView（統一入口，依造型分派）

struct PetSpriteView: View {
    let costume:      Costume
    let quality:      Quality
    let reduceMotion: Bool
    var pixelSize:    CGFloat = 4

    var body: some View {
        switch costume {
        case .cat:
            CatSpriteView(quality: quality, reduceMotion: reduceMotion, pixelSize: pixelSize)
        case .mushroom:
            MapleMobSpriteView(mob: .orangeMushroom, quality: quality, reduceMotion: reduceMotion, pixelSize: pixelSize)
        case .snail:
            MapleMobSpriteView(mob: .snail, quality: quality, reduceMotion: reduceMotion, pixelSize: pixelSize)
        case .pig:
            MapleMobSpriteView(mob: .pig, quality: quality, reduceMotion: reduceMotion, pixelSize: pixelSize)
        case .stump:
            MapleMobSpriteView(mob: .stump, quality: quality, reduceMotion: reduceMotion, pixelSize: pixelSize)
        case .pokemon:
            CharizardSpriteView(quality: quality, reduceMotion: reduceMotion, pixelSize: pixelSize)
        }
    }
}
