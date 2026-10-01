// WiFiMonitor.swift — CoreWLAN 每秒讀取 RSSI

import Foundation
import CoreWLAN
import Combine

// 可注入的 provider 介面，方便未來測試替換
protocol RSSIProvider {
    func currentRSSI() -> Int?
}

struct CoreWLANProvider: RSSIProvider {
    func currentRSSI() -> Int? {
        guard let iface = CWWiFiClient.shared().interface() else { return nil }
        let v = iface.rssiValue()
        return v == 0 ? nil : v
    }
}

final class WiFiMonitor: ObservableObject {
    @Published private(set) var rssi: Int? = nil   // nil = 未連線
    @Published private(set) var quality: Quality = .unstable

    private let provider: RSSIProvider
    private var task: Task<Void, Never>?

    init(provider: RSSIProvider = CoreWLANProvider()) {
        self.provider = provider
    }

    func start() {
        task = Task { [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func refresh() {
        let v = provider.currentRSSI()
        DispatchQueue.main.async {
            self.rssi = v
            self.quality = v.map { Quality.classify(rssi: $0) } ?? .unstable
        }
    }
}
