import Testing
@testable import WiFiCat

@Suite("MapleStory Mob selection")
struct MapleMobTests {
    @Test func mobCostumesAreSelectable() {
        #expect(Costume.allCases.contains(.mushroom))
        #expect(Costume.allCases.contains(.snail))
        #expect(Costume.allCases.contains(.pig))
        #expect(Costume.allCases.contains(.stump))
    }

    @Test func eachMobUsesItsOriginalSpriteSource() {
        #expect(MapleMob.allCases.map(\.spriteFilename) == [
            "Mob_Orange_Mushroom.png",
            "Mob_Snail.png",
            "Mob_Pig.png",
            "Mob_Stump.png",
        ])
        #expect(MapleMob.allCases.allSatisfy { $0.spriteURL.scheme == "https" })
        #expect(MapleMob.allCases.allSatisfy { $0.spriteURL.host == "media.maplestorywiki.net" })
    }
}
