import XCTest
@testable import JanggiEngine

/// 튜토리얼 미션이 설명대로 동작하는지 검증
final class TutorialPositionTests: XCTestCase {

    private func game(_ board: Board) -> Game {
        let game = Game(board: board, sideToMove: .han)
        XCTAssertNil(game.result, "미션 시작 시점에 이미 끝난 판이면 안 된다")
        return game
    }

    func testForcedCaptureHasSingleAnswer() {
        XCTAssertEqual(game(TutorialPositions.forcedCapture).legalMoves(), [TutorialPositions.forcedCaptureAnswer])
    }

    func testChariotFarCaptureIsOptional() {
        let g = game(TutorialPositions.chariotRange)
        let moves = g.legalMoves()
        XCTAssertTrue(moves.contains(TutorialPositions.chariotRangeCapture))
        XCTAssertFalse(Rules.isForcedCapture(TutorialPositions.chariotRangeCapture, on: g.board))
        XCTAssertGreaterThan(moves.count, 5)
    }

    func testCannonHasSingleAnswer() {
        XCTAssertEqual(game(TutorialPositions.cannon).legalMoves(), [TutorialPositions.cannonAnswer])
    }

    func testCheckForcesGeneralMove() {
        let g = game(TutorialPositions.check)
        XCTAssertTrue(g.isInCheck)
        XCTAssertFalse(g.legalMoves().isEmpty)
        XCTAssertTrue(g.legalMoves().allSatisfy { g.board[$0.from]?.kind == .general })
    }

    func testBikjangSoldierCanOnlyAdvance() {
        let g = game(TutorialPositions.bikjang)
        let soldierMoves = g.legalMoves(from: TutorialPositions.bikjangSoldier)
        XCTAssertEqual(soldierMoves, [Move(from: TutorialPositions.bikjangSoldier, to: SquareUtil.make(file: 4, rank: 4))])
    }

    func testSacrificeWins() {
        var g = game(TutorialPositions.sacrifice)
        XCTAssertTrue(g.play(TutorialPositions.sacrificeAnswer))
        let replies = g.legalMoves()
        XCTAssertEqual(replies.count, 1)
        g.play(replies[0])
        XCTAssertEqual(g.result, .win(.han, .onlyGeneralLeft))
    }
}
