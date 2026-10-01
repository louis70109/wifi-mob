// CharizardSprite.swift — 寶可夢 sprite（PokeAPI Gen V 點陣 + 進化鏈 + 時間驅動）
// 上班時間 10:00-19:00 依時間自動進化，隔天重置

import SwiftUI
import AppKit

// MARK: - PokemonSpriteLoader

final class PokemonSpriteLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false

    private var currentID: Int = 0
    private static let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WiFiCat/pokemon", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func load(id: Int) {
        guard id != currentID || image == nil else { return }
        currentID = id

        // 先查快取
        let cacheFile = Self.cacheDir.appendingPathComponent("\(id).png")
        if let cached = NSImage(contentsOf: cacheFile) {
            self.image = cached
            return
        }

        // 下載 Gen V Black/White sprite（點陣風格，去背，涵蓋全世代 #1~1008+）
        isLoading = true
        let urlStr = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/\(id).png"
        guard let url = URL(string: urlStr) else { isLoading = false; return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let self = self, self.currentID == id else { return }
                self.isLoading = false
                if let data = data, let img = NSImage(data: data) {
                    self.image = img
                    try? data.write(to: cacheFile)
                }
            }
        }.resume()
    }
}

// MARK: - EvolutionChainFetcher

final class EvolutionChainFetcher: ObservableObject {
    /// 進化鏈中的所有 pokemon ID，按順序排列（第一階 → 最終）
    @Published var chain: [Int] = []
    @Published var chainNames: [String] = []
    @Published var isLoading = false

    /// 取某隻寶可夢的進化鏈（走第一條分支）
    func fetch(pokemonID: Int) {
        isLoading = true
        // Step 1: 從 species 取 evolution_chain URL
        let speciesURL = "https://pokeapi.co/api/v2/pokemon-species/\(pokemonID)/"
        guard let url = URL(string: speciesURL) else { isLoading = false; return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let evoChain = json["evolution_chain"] as? [String: Any],
                  let chainURLStr = evoChain["url"] as? String,
                  let chainURL = URL(string: chainURLStr) else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }
            // Step 2: 取 evolution chain
            self?.fetchChain(url: chainURL)
        }.resume()
    }

    private func fetchChain(url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let chainNode = json["chain"] as? [String: Any] else {
                    return
                }
                // 遞迴解析（取第一條路徑，不走分支）
                var ids: [Int] = []
                var names: [String] = []
                self.walkChain(node: chainNode, ids: &ids, names: &names)
                self.chain = ids
                self.chainNames = names
            }
        }.resume()
    }

    private func walkChain(node: [String: Any], ids: inout [Int], names: inout [String]) {
        // 從 species URL 解析 ID
        if let species = node["species"] as? [String: Any],
           let urlStr = species["url"] as? String,
           let name = species["name"] as? String {
            // URL 格式: .../pokemon-species/{id}/
            let parts = urlStr.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/")
            if let idStr = parts.last, let id = Int(idStr) {
                ids.append(id)
                names.append(name)
            }
        }
        // 走第一條分支
        if let evolvesTo = node["evolves_to"] as? [[String: Any]], let next = evolvesTo.first {
            walkChain(node: next, ids: &ids, names: &names)
        }
    }
}

// MARK: - 時間驅動進化邏輯

/// 根據當前時間和進化鏈，回傳應顯示的 pokemon ID
/// 上班時間 10:00-19:00 平分給進化鏈各階段，其餘時間顯示第一階
func evolutionIDForNow(chain: [Int], now: Date = Date()) -> Int {
    guard chain.count > 1 else { return chain.first ?? 0 }

    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: now)
    let minute = calendar.component(.minute, from: now)
    let currentMinutes = hour * 60 + minute

    let startMinutes = 10 * 60  // 10:00
    let endMinutes   = 19 * 60  // 19:00

    // 上班時間外 → 第一階
    guard currentMinutes >= startMinutes && currentMinutes < endMinutes else {
        return chain[0]
    }

    // 上班時間內：平分
    let totalMinutes = endMinutes - startMinutes  // 540 分鐘
    let elapsed = currentMinutes - startMinutes
    let stageCount = chain.count
    let minutesPerStage = totalMinutes / stageCount
    let stageIndex = min(elapsed / minutesPerStage, stageCount - 1)

    return chain[stageIndex]
}

// MARK: - PokemonSearcher (名字 → ID)

final class PokemonSearcher: ObservableObject {
    @Published var results: [(id: Int, name: String)] = []
    @Published var isSearching = false

    func search(query: String) {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { results = []; return }

        // 如果是數字，直接當 ID
        if let id = Int(q), id >= 1, id <= 1025 {
            results = [(id: id, name: "#\(id)")]
            return
        }

        // 查 PokeAPI
        isSearching = true
        let urlStr = "https://pokeapi.co/api/v2/pokemon/\(q)"
        guard let url = URL(string: urlStr) else { isSearching = false; return }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSearching = false
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let id = json["id"] as? Int,
                      let name = json["name"] as? String,
                      id <= 1025 else {
                    self.results = []
                    return
                }
                self.results = [(id: id, name: name)]
            }
        }.resume()
    }
}

// MARK: - CharizardSpriteView

struct CharizardSpriteView: View {
    let quality:      Quality
    let reduceMotion: Bool
    var pixelSize:    CGFloat = 4

    @EnvironmentObject private var appState: AppState
    @StateObject private var loader = PokemonSpriteLoader()
    @StateObject private var evoFetcher = EvolutionChainFetcher()
    @State private var auraScale: CGFloat = 1.0
    @State private var displayedID: Int = 0

    private var displaySize: CGFloat { 16 * pixelSize }

    var body: some View {
        let size = displaySize

        ZStack {
            // Aura (excellent only)
            if quality == .excellent {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.orange.opacity(0.50), Color.orange.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    ))
                    .frame(width: size * 1.4, height: size * 1.4)
                    .blur(radius: 6)
                    .scaleEffect(auraScale)
                    .allowsHitTesting(false)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            auraScale = 1.08
                        }
                    }
                    .onChange(of: quality) { _ in auraScale = 1.0 }
            }

            // Sprite
            Group {
                if reduceMotion {
                    spriteImage.frame(width: size, height: size)
                } else {
                    TimelineView(.animation) { tl in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        spriteImage
                            .frame(width: size, height: size)
                            .offset(y: bobOffset(t: t))
                    }
                }
            }
            .colorMultiply(tintColor)
            .opacity(spriteOpacity)
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.6), value: quality)
        .onAppear { startEvolution() }
        .onChange(of: appState.pokemonID) { _ in startEvolution() }
        .onChange(of: quality) { _ in startEvolution() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            updateEvolutionStage()
        }
    }

    // MARK: - Evolution logic

    private func startEvolution() {
        // 只在網路品質 good 以上才查進化鏈
        guard quality == .excellent || quality == .good else {
            loader.load(id: appState.pokemonID)
            return
        }
        evoFetcher.fetch(pokemonID: appState.pokemonID)
        // 等 fetch 完成後更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            updateEvolutionStage()
        }
    }

    private func updateEvolutionStage() {
        // 網路差時不進化，顯示預設
        guard quality == .excellent || quality == .good else {
            loader.load(id: appState.pokemonID)
            return
        }
        let chain = evoFetcher.chain
        guard !chain.isEmpty else {
            // 還沒拿到進化鏈，直接顯示選的
            loader.load(id: appState.pokemonID)
            return
        }
        let targetID = evolutionIDForNow(chain: chain)
        if targetID != displayedID {
            displayedID = targetID
            loader.load(id: targetID)
        }
    }

    @ViewBuilder
    private var spriteImage: some View {
        if let img = loader.image {
            Image(nsImage: img)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if loader.isLoading {
            ProgressView()
                .scaleEffect(0.5)
        } else {
            Rectangle().fill(Color.orange.opacity(0.3))
        }
    }

    private func bobOffset(t: Double) -> CGFloat {
        switch quality {
        case .excellent: return CGFloat(sin(t * 2.4)) * pixelSize * -1.2
        case .good:      return CGFloat(sin(t * 1.8)) * pixelSize * -0.6
        case .fair:      return CGFloat(sin(t * 1.2)) * pixelSize * -0.3
        case .unstable:  return CGFloat(sin(t * 1.4)) * 1.5
        }
    }

    private var tintColor: Color {
        switch quality {
        case .excellent: return .white
        case .good:      return .white
        case .fair:      return Color(red: 0.75, green: 0.70, blue: 0.65)
        case .unstable:  return Color(red: 0.45, green: 0.35, blue: 0.50)
        }
    }

    private var spriteOpacity: Double {
        switch quality {
        case .excellent: return 1.0
        case .good:      return 1.0
        case .fair:      return 0.85
        case .unstable:  return 0.55
        }
    }
}
