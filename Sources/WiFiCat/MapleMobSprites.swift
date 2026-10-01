// MapleMobSprites.swift — MapleStory Wiki pixel sprites with local disk caching.
// Sprites load like the Pokémon costume: pixel-perfect NSImage, downloaded once and cached.

import AppKit
import SwiftUI

// Source: https://media.maplestorywiki.net/yetidb/Mob_Orange_Mushroom.png
//         https://media.maplestorywiki.net/yetidb/Mob_Snail.png
//         https://media.maplestorywiki.net/yetidb/Mob_Pig.png
//         https://media.maplestorywiki.net/yetidb/Mob_Stump.png
enum MapleMob: String, CaseIterable, Equatable, Identifiable {
    case orangeMushroom = "橘菇菇"
    case snail = "蝸牛"
    case pig = "豬"
    case stump = "樹樁"

    var id: String { rawValue }

    var spriteFilename: String {
        switch self {
        case .orangeMushroom: "Mob_Orange_Mushroom.png"
        case .snail: "Mob_Snail.png"
        case .pig: "Mob_Pig.png"
        case .stump: "Mob_Stump.png"
        }
    }

    var spriteURL: URL {
        URL(string: "https://media.maplestorywiki.net/yetidb/\(spriteFilename)")!
    }

    var auraColor: Color {
        switch self {
        case .orangeMushroom: Color(red: 1.0, green: 0.70, blue: 0.20)
        case .snail: Color(red: 0.24, green: 0.78, blue: 0.72)
        case .pig: Color(red: 1.0, green: 0.56, blue: 0.66)
        case .stump: Color(red: 0.62, green: 0.44, blue: 0.23)
        }
    }
}

final class MapleMobSpriteLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false

    private var currentMob: MapleMob?
    private static let cacheDirectory: URL = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WiFiCat/maple-mobs", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    func load(mob: MapleMob) {
        guard mob != currentMob || image == nil else { return }
        currentMob = mob
        image = nil

        let cacheFile = Self.cacheDirectory.appendingPathComponent(mob.spriteFilename)
        if let cachedImage = NSImage(contentsOf: cacheFile) {
            image = cachedImage
            isLoading = false
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: mob.spriteURL) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let self, self.currentMob == mob else { return }
                self.isLoading = false
                guard let data, let downloadedImage = NSImage(data: data) else { return }
                self.image = downloadedImage
                try? data.write(to: cacheFile, options: .atomic)
            }
        }.resume()
    }
}

struct MapleMobSpriteView: View {
    let mob: MapleMob
    let quality: Quality
    let reduceMotion: Bool
    var pixelSize: CGFloat = 4

    @StateObject private var loader = MapleMobSpriteLoader()
    @State private var auraScale: CGFloat = 1.0

    private var displaySize: CGFloat { 16 * pixelSize }

    var body: some View {
        let size = displaySize

        ZStack {
            if quality == .excellent {
                Circle()
                    .fill(RadialGradient(
                        colors: [mob.auraColor.opacity(0.50), mob.auraColor.opacity(0)],
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

            Group {
                if reduceMotion {
                    spriteImage.frame(width: size, height: size)
                } else {
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        spriteImage
                            .frame(width: size, height: size)
                            .offset(y: bobOffset(time: time))
                    }
                }
            }
            .colorMultiply(tintColor)
            .opacity(spriteOpacity)
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.6), value: quality)
        .onAppear { loader.load(mob: mob) }
        .onChange(of: mob) { _ in loader.load(mob: mob) }
    }

    @ViewBuilder
    private var spriteImage: some View {
        if let image = loader.image {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if loader.isLoading {
            ProgressView().scaleEffect(0.5)
        } else {
            Rectangle().fill(mob.auraColor.opacity(0.3))
        }
    }

    private func bobOffset(time: Double) -> CGFloat {
        switch quality {
        case .excellent: CGFloat(sin(time * 2.4)) * pixelSize * -1.2
        case .good: CGFloat(sin(time * 1.8)) * pixelSize * -0.6
        case .fair: CGFloat(sin(time * 1.2)) * pixelSize * -0.3
        case .unstable: CGFloat(sin(time * 1.4)) * 1.5
        }
    }

    private var tintColor: Color {
        switch quality {
        case .excellent, .good: .white
        case .fair: Color(red: 0.82, green: 0.78, blue: 0.72)
        case .unstable: Color(red: 0.58, green: 0.50, blue: 0.60)
        }
    }

    private var spriteOpacity: Double {
        switch quality {
        case .excellent, .good: 1.0
        case .fair: 0.85
        case .unstable: 0.58
        }
    }
}
