// WiFiCatApp.swift — @main App：桌面寵物懸浮視窗 + MenuBarExtra

import SwiftUI
import AppKit

// MARK: - App

@main
struct WiFiCatApp: App {
    @StateObject private var monitor  = WiFiMonitor()
    @StateObject private var appState = AppState()

    var body: some Scene {
        // 寵物懸浮視窗
        WindowGroup {
            PetWindowView()
                .environmentObject(monitor)
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 160, height: 160)

        // Menu Bar 下拉面板（不動）
        MenuBarExtra(content: {
            MenuBarPanel()
                .environmentObject(monitor)
                .environmentObject(appState)
                .frame(width: 280)
        }, label: {
            MenuBarCatIcon()
        })
        .menuBarExtraStyle(.window)
    }
}

// MARK: - WindowAccessor
// 取得 NSWindow 並套用透明無邊框浮動設定

struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // 下一個 runloop tick 才能拿到 window
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            self.configure(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - PetWindowView

struct PetWindowView: View {
    @EnvironmentObject private var monitor:  WiFiMonitor
    @EnvironmentObject private var appState: AppState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showAbout = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // 透明底層
            Color.clear

            VStack(spacing: 4) {
                // 寵物 sprite（依造型 + effective quality）
                let eq = appState.effectiveQuality(actual: monitor.quality)
                PetSpriteView(
                    costume:      appState.costume,
                    quality:      eq,
                    reduceMotion: reduceMotion,
                    pixelSize:    appState.spriteScale
                )
                .contextMenu { catContextMenu }

                // 狀態一行字
                statusBadge
            }
            .padding(.bottom, 8)
        }
        // 套用視窗屬性
        .background(
            WindowAccessor { window in
                window.level                       = .floating
                window.isOpaque                    = false
                window.backgroundColor             = .clear
                window.hasShadow                   = false
                window.isMovableByWindowBackground = true
                window.styleMask                   = [.borderless, .fullSizeContentView]
                window.titlebarAppearsTransparent  = true
                window.titleVisibility             = .hidden
                window.standardWindowButton(.closeButton)?.isHidden      = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden        = true
                window.collectionBehavior          = [.canJoinAllSpaces, .stationary]
            }
        )
        .onAppear  { monitor.start() }
        .onDisappear { monitor.stop() }
        .alert("關於 wifi-mob", isPresented: $showAbout) {
            Button("OK") {}
        } message: {
            Text("""
                疾風領主 / 穩步旅人 / 蹣跚行者 / 迷霧受困者
                — 依 Wi-Fi 訊號強度反映貓咪狀態。

                dBm 僅來自目前連線的 Wi-Fi，非附近所有 AP 掃描結果。
                """)
        }
    }

    // MARK: - 狀態小標籤

    private var statusBadge: some View {
        let eq = appState.effectiveQuality(actual: monitor.quality)
        return Group {
            if appState.isTestMode {
                Text("[測試] \(eq.displayName)")
                    .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.2))
            } else if let rssi = monitor.rssi {
                Text("\(eq.displayName)  \(rssi) dBm")
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                Text("未連線")
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .font(.system(size: 10, design: .monospaced))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.black.opacity(0.35), in: Capsule())
        .animation(.easeInOut(duration: 0.4), value: eq)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var catContextMenu: some View {
        Section("造型") {
            ForEach(Costume.allCases) { c in
                Button(appState.costume == c ? "✓ \(c.rawValue)" : "   \(c.rawValue)") {
                    appState.costume = c
                }
            }
        }
        Section("測試") {
            Button(appState.overrideQuality == nil ? "✓ 依實際訊號" : "   依實際訊號") {
                appState.overrideQuality = nil
            }
            ForEach([Quality.excellent, .good, .fair, .unstable], id: \.self) { q in
                Button(appState.overrideQuality == q ? "✓ 強制 \(q.displayName)" : "   強制 \(q.displayName)") {
                    appState.overrideQuality = q
                }
            }
        }
        Divider()
        Button("設定") { SettingsWindowController.shared.show(appState: appState) }
        Button("關於") { showAbout = true }
        Divider()
        Button("結束") { NSApplication.shared.terminate(nil) }
    }
}

// MARK: - MenuBarPanel（不動）

struct MenuBarPanel: View {
    @EnvironmentObject private var monitor:  WiFiMonitor
    @EnvironmentObject private var appState: AppState

    @State private var roomName: String = ""
    @State private var showAbout: Bool  = false
    @State private var sortByRSSI: Bool = false

    private var sortedRecords: [LocationRecord] {
        sortByRSSI
            ? appState.records.sorted { $0.rssi < $1.rssi }
            : appState.records.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusSection
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            costumeSection
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            recordInputSection
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            recordListSection

            Divider()

            footerSection
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .background(Color(white: 0.10))
        .alert("關於 wifi-mob", isPresented: $showAbout) {
            Button("OK") {}
        } message: {
            Text("dBm 僅來自目前連線的 Wi-Fi，非附近所有 AP 掃描結果。")
        }
    }

    private var statusSection: some View {
        let eq = appState.effectiveQuality(actual: monitor.quality)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("目前狀態：\(eq.displayName)")
                    .font(.system(.body, design: .monospaced).bold())
                    .foregroundStyle(levelColor(eq))
                if appState.isTestMode {
                    Text("[測試中]")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.2))
                }
            }
            if appState.isTestMode {
                Text("強制：\(eq.displayName)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.2).opacity(0.8))
            } else if let rssi = monitor.rssi {
                Text("\(rssi) dBm")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color(white: 0.75))
            } else {
                Text("未連線")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color(white: 0.40))
            }
        }
    }

    private var costumeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("造型")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color(white: 0.70))
                Spacer()
                Picker("", selection: $appState.costume) {
                    ForEach(Costume.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 130)
            }
            HStack {
                Text("大小")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(white: 0.55))
                Slider(value: $appState.spriteScale, in: 2...8, step: 1)
                    .frame(width: 100)
                Text("\(Int(appState.spriteScale))x")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(white: 0.55))
                    .frame(width: 24)
            }
            if appState.costume == .pokemon {
                PokemonSearchField()
                    .environmentObject(appState)
            }
        }
    }

    private var recordInputSection: some View {
        HStack(spacing: 8) {
            RPGTextField(placeholder: "房間名稱", text: $roomName)
            Button("記錄") {
                appState.add(room: roomName, rssi: monitor.rssi ?? 0)
                roomName = ""
            }
            .buttonStyle(PixelButtonStyle())
        }
    }

    private var recordListSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(">> 冒險日誌")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color(white: 0.45))
                Spacer()
                Button(sortByRSSI ? "RSSI" : "時間") { sortByRSSI.toggle() }
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color(white: 0.55))
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(sortedRecords) { rec in
                        recordRow(rec)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
            }
            .frame(maxHeight: 200)
        }
    }

    private func recordRow(_ rec: LocationRecord) -> some View {
        let isWeakest = rec.id == appState.weakestID && appState.records.count > 1
        let ts        = formatted(rec.timestamp)
        let prefix    = isWeakest ? "▼ " : "  "
        let line      = "\(prefix)[\(rec.room)] Lv.\(rec.quality.level) \(rec.quality.displayName) \(rec.rssi)dBm"

        return HStack(alignment: .center, spacing: 4) {
            Text(line)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(isWeakest
                    ? Color(red: 1.0, green: 0.35, blue: 0.35)
                    : Color(white: 0.75))
            Spacer()
            Text(ts)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color(white: 0.35))
            Button("x") { appState.remove(id: rec.id) }
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color(white: 0.45))
                .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private var footerSection: some View {
        HStack(spacing: 8) {
            Button("清空") { appState.clear() }
                .buttonStyle(PixelButtonStyle(destructive: true))
                .font(.system(.caption, design: .monospaced))
            Button("關於") { showAbout = true }
                .buttonStyle(PixelButtonStyle())
                .font(.system(.caption, design: .monospaced))
            Spacer()
            Button("結束") { NSApplication.shared.terminate(nil) }
                .buttonStyle(PixelButtonStyle(destructive: true))
                .font(.system(.caption, design: .monospaced))
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func levelColor(_ q: Quality) -> Color {
        switch q {
        case .excellent: Color(red: 0.30, green: 0.95, blue: 0.45)
        case .good:      Color(red: 0.70, green: 0.95, blue: 0.30)
        case .fair:      Color(red: 0.95, green: 0.70, blue: 0.15)
        case .unstable:  Color(red: 0.95, green: 0.30, blue: 0.30)
        }
    }
}

// MARK: - PokemonSearchField

struct PokemonSearchField: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var searcher = PokemonSearcher()
    @State private var query: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                TextField("名字或編號 (1-1025)", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                    .onSubmit { searcher.search(query: query) }
                Button("搜尋") { searcher.search(query: query) }
                    .font(.system(.caption, design: .monospaced))
            }

            if searcher.isSearching {
                Text("搜尋中...")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            ForEach(searcher.results, id: \.id) { result in
                PokemonResultRow(
                    pokemonID: result.id,
                    name: result.name,
                    isSelected: appState.pokemonID == result.id
                ) {
                    appState.pokemonID = result.id
                    appState.pokemonName = result.name
                }
            }

            if !appState.pokemonName.isEmpty {
                HStack(spacing: 8) {
                    PokemonPreview(pokemonID: appState.pokemonID)
                        .frame(width: 32, height: 32)
                    Text("目前: #\(appState.pokemonID) \(appState.pokemonName)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - PokemonResultRow（hover 特效）

struct PokemonResultRow: View {
    let pokemonID: Int
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                PokemonPreview(pokemonID: pokemonID)
                    .frame(width: 32, height: 32)
                    .scaleEffect(isHovered ? 1.2 : 1.0)
                    .animation(.easeOut(duration: 0.15), value: isHovered)
                Text("#\(pokemonID) \(name)")
                    .font(.system(.caption, design: .monospaced))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - PokemonPreview（小型預覽圖）

struct PokemonPreview: View {
    let pokemonID: Int
    @StateObject private var loader = PokemonSpriteLoader()

    var body: some View {
        Group {
            if let img = loader.image {
                Image(nsImage: img)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .scaleEffect(0.4)
            }
        }
        .onAppear { loader.load(id: pokemonID) }
        .onChange(of: pokemonID) { newID in loader.load(id: newID) }
    }
}

// MARK: - SettingsPanel（從右鍵選單開啟的設定視窗）

struct SettingsPanel: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("設定")
                .font(.system(.title2, design: .monospaced))

            // 造型選擇
            HStack {
                Text("造型")
                    .font(.system(.body, design: .monospaced))
                Spacer()
                Picker("", selection: $appState.costume) {
                    ForEach(Costume.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 130)
            }

            // 大小
            HStack {
                Text("大小")
                    .font(.system(.body, design: .monospaced))
                Slider(value: $appState.spriteScale, in: 2...8, step: 1)
                    .frame(width: 120)
                Text("\(Int(appState.spriteScale))x")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
            }

            // 寶可夢搜尋（僅在寶可夢造型時顯示）
            if appState.costume == .pokemon {
                Divider()
                Text("選擇寶可夢")
                    .font(.system(.body, design: .monospaced))
                PokemonSearchField()
                    .environmentObject(appState)
            }

            Spacer()

            HStack {
                Spacer()
                Button("關閉") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 300, height: appState.costume == .pokemon ? 320 : 200)
    }
}

// MARK: - SettingsWindowController（獨立 NSPanel，支援文字輸入）

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var panel: NSPanel?

    func show(appState: AppState) {
        if let existing = panel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let content = SettingsPanel()
            .environmentObject(appState)

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 360)

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 360),
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        p.title = "wifi-mob 設定"
        p.contentView = hostingView
        p.center()
        p.isReleasedWhenClosed = false
        p.level = .floating
        p.isFloatingPanel = true
        p.becomesKeyOnlyIfNeeded = false  // 允許成為 key window
        p.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.panel = p
    }
}
