import Testing
@testable import WiFiCat

@Suite("Quality classification")
struct QualityTests {

    // MARK: - 四個等級各一

    @Test func excellent() {
        #expect(Quality.classify(rssi: -45) == .excellent)
    }

    @Test func good() {
        #expect(Quality.classify(rssi: -55) == .good)
    }

    @Test func fair() {
        #expect(Quality.classify(rssi: -65) == .fair)
    }

    @Test func unstable() {
        #expect(Quality.classify(rssi: -80) == .unstable)
    }

    // MARK: - 邊界

    @Test func boundary_minus50_is_excellent() {
        #expect(Quality.classify(rssi: -50) == .excellent)
    }

    @Test func boundary_minus51_is_good() {
        #expect(Quality.classify(rssi: -51) == .good)
    }

    @Test func boundary_minus60_is_good() {
        #expect(Quality.classify(rssi: -60) == .good)
    }

    @Test func boundary_minus61_is_fair() {
        #expect(Quality.classify(rssi: -61) == .fair)
    }

    @Test func boundary_minus70_is_fair() {
        #expect(Quality.classify(rssi: -70) == .fair)
    }

    @Test func boundary_minus71_is_unstable() {
        #expect(Quality.classify(rssi: -71) == .unstable)
    }

    // MARK: - RSSI 0（未連線常見值）

    @Test func zero_rssi_is_unstable() {
        #expect(Quality.classify(rssi: 0) == .unstable)
    }

    // MARK: - 顯示名稱與等級

    @Test func display_names() {
        #expect(Quality.excellent.displayName == "疾風領主")
        #expect(Quality.good.displayName      == "穩步旅人")
        #expect(Quality.fair.displayName      == "蹣跚行者")
        #expect(Quality.unstable.displayName  == "迷霧受困者")
    }

    @Test func levels() {
        #expect(Quality.excellent.level == 4)
        #expect(Quality.good.level      == 3)
        #expect(Quality.fair.level      == 2)
        #expect(Quality.unstable.level  == 1)
    }
}
