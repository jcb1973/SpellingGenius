import XCTest
@testable import SpellingGenius

final class ParseLinesTests: XCTestCase {

    // MARK: - Empty / Trivial Input

    func testEmptyInput() {
        let (title, pairs) = WordSetEditorViewModel.parseLines([])
        XCTAssertNil(title)
        XCTAssertTrue(pairs.isEmpty)
    }

    func testBlankLinesOnly() {
        let (title, pairs) = WordSetEditorViewModel.parseLines(["", "   ", "\n"])
        XCTAssertNil(title)
        XCTAssertTrue(pairs.isEmpty)
    }

    // MARK: - Title Only

    func testTitleOnly() {
        let lines = ["Engelska Glosor Vecka 5"]
        let (title, pairs) = WordSetEditorViewModel.parseLines(lines)
        XCTAssertEqual(title, "Engelska Glosor Vecka 5")
        XCTAssertTrue(pairs.isEmpty)
    }

    func testMultiLineTitle() {
        let lines = ["Engelska Glosor", "Vecka 5"]
        let (title, pairs) = WordSetEditorViewModel.parseLines(lines)
        XCTAssertEqual(title, "Engelska Glosor Vecka 5")
        XCTAssertTrue(pairs.isEmpty)
    }

    // MARK: - Pairs with |SPLIT| Marker

    func testSplitMarkerPairs() {
        let lines = [
            "Engelska Glosor Vecka 5",
            "1. water |SPLIT| vatten",
            "2. house |SPLIT| hus",
            "3. cat |SPLIT| katt"
        ]
        let (title, pairs) = WordSetEditorViewModel.parseLines(lines)

        XCTAssertEqual(title, "Engelska Glosor Vecka 5")
        XCTAssertEqual(pairs.count, 3)

        XCTAssertEqual(pairs[0].english, "water")
        XCTAssertEqual(pairs[0].swedish, "vatten")

        XCTAssertEqual(pairs[1].english, "house")
        XCTAssertEqual(pairs[1].swedish, "hus")

        XCTAssertEqual(pairs[2].english, "cat")
        XCTAssertEqual(pairs[2].swedish, "katt")
    }

    func testSplitMarkerWithMultiWordEnglish() {
        let lines = [
            "1. ice cream |SPLIT| glass",
            "2. living room |SPLIT| vardagsrum"
        ]
        let (title, pairs) = WordSetEditorViewModel.parseLines(lines)

        XCTAssertNil(title)
        XCTAssertEqual(pairs.count, 2)

        XCTAssertEqual(pairs[0].english, "ice cream")
        XCTAssertEqual(pairs[0].swedish, "glass")

        XCTAssertEqual(pairs[1].english, "living room")
        XCTAssertEqual(pairs[1].swedish, "vardagsrum")
    }

    // MARK: - Fallback (No |SPLIT| Marker)

    func testFallbackSingleSpacePairs() {
        let lines = [
            "1. water vatten",
            "2. house hus"
        ]
        let (title, pairs) = WordSetEditorViewModel.parseLines(lines)

        XCTAssertNil(title)
        XCTAssertEqual(pairs.count, 2)

        XCTAssertEqual(pairs[0].english, "water")
        XCTAssertEqual(pairs[0].swedish, "vatten")

        XCTAssertEqual(pairs[1].english, "house")
        XCTAssertEqual(pairs[1].swedish, "hus")
    }

    func testFallbackMultiWordEnglish() {
        // Last word becomes Swedish, rest becomes English
        let lines = ["1. ice cream glass"]
        let (_, pairs) = WordSetEditorViewModel.parseLines(lines)

        XCTAssertEqual(pairs.count, 1)
        XCTAssertEqual(pairs[0].english, "ice cream")
        XCTAssertEqual(pairs[0].swedish, "glass")
    }

    // MARK: - Edge Cases

    func testNumberedLineWithSingleWord() {
        // Only one word after the number — not enough to form a pair
        let lines = ["1. water"]
        let (_, pairs) = WordSetEditorViewModel.parseLines(lines)
        XCTAssertTrue(pairs.isEmpty)
    }

    func testNonNumberedLinesAfterPairsAreIgnored() {
        let lines = [
            "Title",
            "1. water |SPLIT| vatten",
            "Some random footer text"
        ]
        let (title, pairs) = WordSetEditorViewModel.parseLines(lines)

        XCTAssertEqual(title, "Title")
        XCTAssertEqual(pairs.count, 1)
        XCTAssertEqual(pairs[0].english, "water")
    }

    func testWhitespaceAroundSplitMarker() {
        let lines = ["1.   water   |SPLIT|   vatten   "]
        let (_, pairs) = WordSetEditorViewModel.parseLines(lines)

        XCTAssertEqual(pairs.count, 1)
        XCTAssertEqual(pairs[0].english, "water")
        XCTAssertEqual(pairs[0].swedish, "vatten")
    }

    func testHighNumberedLines() {
        let lines = [
            "10. beautiful |SPLIT| vacker",
            "25. extraordinary |SPLIT| extraordinär"
        ]
        let (_, pairs) = WordSetEditorViewModel.parseLines(lines)

        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(pairs[0].english, "beautiful")
        XCTAssertEqual(pairs[1].english, "extraordinary")
    }

    func testEmptySplitMarkerPartsAreSkipped() {
        // If one side of the split is empty, the pair should be skipped
        let lines = ["1. |SPLIT| vatten"]
        let (_, pairs) = WordSetEditorViewModel.parseLines(lines)
        XCTAssertTrue(pairs.isEmpty)
    }
}
