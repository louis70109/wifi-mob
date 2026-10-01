// RPGChrome.swift — RPG 風 UI 元件 + 共享狀態

import SwiftUI

// MARK: - 資料模型

struct LocationRecord: Identifiable {
    let id = UUID()
    let room: String
    let rssi: Int
    let quality: Quality
    let timestamp: Date
}

// MARK: - 造型

enum Costume: String, CaseIterable, Identifiable {
    case cat       = "貓"
    case mushroom  = "橘菇菇"
    case snail     = "蝸牛"
    case pig       = "豬"
    case stump     = "樹樁"
    case pokemon   = "寶可夢"
    var id: String { rawValue }
}

// MARK: - 共享 AppState

final class AppState: ObservableObject {
    @Published var records: [LocationRecord] = []
    @Published var costume: Costume = .cat
    @Published var overrideQuality: Quality? = nil
    @Published var pokemonID: Int = 155  // 預設火球鼠
    @Published var pokemonName: String = "cyndaquil"
    @Published var spriteScale: CGFloat = 4  // pixelSize: 2=小, 4=中, 6=大, 8=特大

    var isTestMode: Bool { overrideQuality != nil }

    func effectiveQuality(actual: Quality) -> Quality {
        overrideQuality ?? actual
    }

    func add(room: String, rssi: Int) {
        let q = Quality.classify(rssi: rssi)
        records.append(LocationRecord(
            room: room.isEmpty ? "未命名" : room,
            rssi: rssi,
            quality: q,
            timestamp: Date()
        ))
    }

    func remove(id: UUID) {
        records.removeAll { $0.id == id }
    }

    func clear() {
        records.removeAll()
    }

    var weakestID: UUID? {
        records.min(by: { $0.rssi < $1.rssi })?.id
    }
}

// MARK: - Chunky 邊框修飾器

struct ChunkyBorder: ViewModifier {
    var outerColor: Color = Color(white: 0.08)
    var innerColor: Color = Color(white: 0.35)
    var outerWidth: CGFloat = 3
    var innerWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .strokeBorder(innerColor, lineWidth: innerWidth)
                    .padding(-outerWidth)
            )
            .overlay(
                Rectangle()
                    .strokeBorder(outerColor, lineWidth: outerWidth)
            )
    }
}

extension View {
    func chunkyBorder(
        outerColor: Color = Color(white: 0.08),
        innerColor: Color = Color(white: 0.35)
    ) -> some View {
        self.modifier(ChunkyBorder(outerColor: outerColor, innerColor: innerColor))
    }
}

// MARK: - RPG 像素按鈕樣式

struct PixelButtonStyle: ButtonStyle {
    @State private var isHovered = false
    var destructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(destructive
                ? Color(red: 1.0, green: 0.35, blue: 0.35)
                : Color(white: isHovered ? 1.0 : 0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                configuration.isPressed
                    ? Color(white: 0.25)
                    : (isHovered ? Color(white: 0.18) : Color(white: 0.13))
            )
            .chunkyBorder(
                outerColor: Color(white: 0.06),
                innerColor: destructive
                    ? Color(red: 0.6, green: 0.15, blue: 0.15)
                    : (isHovered ? Color(white: 0.55) : Color(white: 0.30))
            )
            .onHover { isHovered = $0 }
    }
}

// MARK: - RPG 輸入框

struct RPGTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(Color(white: 0.90))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(white: 0.08))
            .chunkyBorder(outerColor: Color(white: 0.06), innerColor: Color(white: 0.30))
            .textFieldStyle(.plain)
    }
}

// MARK: - 浮動數字

struct FloatingText: Identifiable {
    let id = UUID()
    let text: String
    let isPositive: Bool
}

struct FloatingTextOverlay: View {
    let item: FloatingText
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1.0
    let onFinish: () -> Void

    var body: some View {
        Text(item.text)
            .font(.system(.title2, design: .monospaced).bold())
            .foregroundStyle(item.isPositive
                ? Color(red: 0.25, green: 1.00, blue: 0.40)
                : Color(red: 1.00, green: 0.25, blue: 0.25))
            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    offsetY = -44
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                    onFinish()
                }
            }
    }
}

// MARK: - Menu Bar 貓頭圖示（純 SwiftUI shapes）

struct MenuBarCatIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 14.0   // 每格尺寸

            // 14×14 貓頭點陣
            // 0=透明 1=白/亮 2=黑/輪廓
            let grid: [[Int]] = [
                [0,0,2,0,0,0,0,0,0,0,2,0,0,0],
                [0,2,1,2,0,0,0,0,0,2,1,2,0,0],
                [2,1,1,1,2,0,0,0,2,1,1,1,2,0],
                [2,1,1,1,1,2,2,2,1,1,1,1,2,0],
                [0,2,1,1,1,1,1,1,1,1,1,2,0,0],
                [0,2,1,2,2,1,1,1,1,2,2,1,2,0],
                [0,2,1,2,2,1,2,1,1,2,2,1,2,0],
                [0,0,2,1,1,1,1,1,1,1,1,2,0,0],
                [0,2,1,1,1,1,1,1,1,1,1,1,2,0],
                [0,2,1,1,1,1,1,1,1,1,1,1,2,0],
                [0,0,2,1,2,0,0,0,0,2,1,2,0,0],
                [0,0,0,2,0,0,0,0,0,0,2,0,0,0],
                [0,0,0,0,0,0,0,0,0,0,0,0,0,0],
                [0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            ]

            for (row, cols) in grid.enumerated() {
                for (col, idx) in cols.enumerated() {
                    guard idx != 0 else { continue }
                    let color: Color = idx == 1 ? .white : Color(white: 0.15)
                    let rect = CGRect(x: CGFloat(col) * s, y: CGFloat(row) * s, width: s, height: s)
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: 16, height: 16)
    }
}
