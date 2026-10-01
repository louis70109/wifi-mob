// Quality.swift — 純函式 + 資料型別，無 CoreWLAN 依賴

public enum Quality: Equatable, Hashable {
    case excellent
    case good
    case fair
    case unstable

    /// 將 dBm 值分類。rssi == 0 視同未連線，歸入 unstable。
    public static func classify(rssi: Int) -> Quality {
        // rssi == 0 表示未連線（CoreWLAN 常見回傳值），視同最差等級
        guard rssi != 0 else { return .unstable }
        switch rssi {
        case (-50)...: return .excellent
        case (-60)...: return .good
        case (-70)...: return .fair
        default:       return .unstable
        }
    }

    public var displayName: String {
        switch self {
        case .excellent: "疾風領主"
        case .good:      "穩步旅人"
        case .fair:      "蹣跚行者"
        case .unstable:  "迷霧受困者"
        }
    }

    /// 1–4 段進度條段數
    public var level: Int {
        switch self {
        case .excellent: 4
        case .good:      3
        case .fair:      2
        case .unstable:  1
        }
    }

    /// 進度條顯示顏色名（SwiftUI Color(named:) 替代方案：用字串標記，由 View 轉換）
    public var colorLabel: String {
        switch self {
        case .excellent: "green"
        case .good:      "yellow"
        case .fair:      "orange"
        case .unstable:  "red"
        }
    }
}
