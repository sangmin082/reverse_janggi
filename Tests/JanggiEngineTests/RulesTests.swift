import XCTest
@testable import JanggiEngine

private func sq(_ f: Int, _ r: Int) -> Square { SquareUtil.make(file: f, rank: r) }
private func cho(_ k: PieceKind) -> Piece { Piece(side: .cho, kind: k) }
private func han(_ k: PieceKind) -> Piece { Piece(side: .han, kind: k) }

/// 테스트 배치의 기본 궁 위치 (서로 다른 줄이라 빅장이 아님)
private let cornerGenerals: [(Int, Int, Piece)] = [(3, 0, cho(.general)), (5, 9, han(.general))]

private func targets(_ board: Board, from: Square) -> Set<Square> {
    guard let p = board[from] else { return [] }
    var moves: [Move] = []
    Rules.appendPseudoMoves(for: p, at: from, on: board, into: &moves)
    return Set(moves.map(\.to))
}

final class RulesTests: XCTestCase {

    // MARK: 초기 배치

    func testInitialSetup() {
        let board = Board.initial()
        XCTAssertEqual(board.pieces(of: .cho).count, 16)
        XCTAssertEqual(board.pieces(of: .han).count, 16)
        XCTAssertEqual(board.generalSquare(of: .cho), sq(4, 1))
        XCTAssertEqual(board.generalSquare(of: .han), sq(4, 8))
        XCTAssertEqual(board[sq(1, 2)], cho(.cannon))
        XCTAssertEqual(board[sq(7, 7)], han(.cannon))
        XCTAssertEqual(board[sq(1, 9)], han(.horse))
        XCTAssertEqual(board[sq(2, 9)], han(.elephant))
        XCTAssertEqual(board[sq(4, 6)], han(.soldier))

        let game = Game()
        XCTAssertEqual(game.sideToMove, .han)
        XCTAssertNil(game.result)
        XCTAssertFalse(game.isInCheck)
        // 첫 수에는 캡처가 없다
        XCTAssertFalse(game.hasForcedCapture)
        XCTAssertGreaterThan(game.legalMoves().count, 20)
    }

    // MARK: 기물 이동

    func testGeneralMovesAlongPalaceLines() {
        let center = Board.custom([(4, 1, cho(.general)), (3, 9, han(.general))])
        XCTAssertEqual(targets(center, from: sq(4, 1)).count, 8)

        let corner = Board.custom([(3, 0, cho(.general)), (5, 9, han(.general))])
        XCTAssertEqual(targets(corner, from: sq(3, 0)), [sq(4, 0), sq(3, 1), sq(4, 1)])

        // 변 중앙(4,0)에서는 대각선이 없다
        let edge = Board.custom([(4, 0, cho(.general)), (5, 9, han(.general))])
        XCTAssertEqual(targets(edge, from: sq(4, 0)), [sq(3, 0), sq(5, 0), sq(4, 1)])
    }

    func testChariotSlidesAndPalaceDiagonal() {
        let board = Board.custom(cornerGenerals + [
            (3, 7, cho(.chariot)),
            (5, 7, han(.soldier)),  // 대각선 반대편이 아님 — (5,9) 궁이 반대 귀퉁이
        ])
        let t = targets(board, from: sq(3, 7))
        // 궁성 대각선: (4,8) → (5,9) 상대 궁 잡기 가능
        XCTAssertTrue(t.contains(sq(4, 8)))
        XCTAssertTrue(t.contains(sq(5, 9)))
        // 직선: 오른쪽은 (4,7) 다음 (5,7) 적 졸에서 멈춤
        XCTAssertTrue(t.contains(sq(5, 7)))
        XCTAssertFalse(t.contains(sq(6, 7)))
    }

    func testCannonNeedsNonCannonScreen() {
        // 넘을 기물 없음 → 이동 불가
        var board = Board.custom(cornerGenerals + [(0, 4, cho(.cannon))])
        XCTAssertTrue(targets(board, from: sq(0, 4)).isEmpty)

        // 졸을 넘어 이동·잡기
        board = Board.custom(cornerGenerals + [
            (0, 4, cho(.cannon)), (0, 5, cho(.soldier)), (0, 8, han(.horse)),
        ])
        XCTAssertEqual(targets(board, from: sq(0, 4)), [sq(0, 6), sq(0, 7), sq(0, 8)])

        // 포는 포를 넘을 수 없다
        board = Board.custom(cornerGenerals + [
            (0, 4, cho(.cannon)), (0, 5, han(.cannon)), (0, 8, han(.horse)),
        ])
        XCTAssertTrue(targets(board, from: sq(0, 4)).isEmpty)

        // 포는 포를 잡을 수 없다
        board = Board.custom(cornerGenerals + [
            (0, 4, cho(.cannon)), (0, 5, cho(.soldier)), (0, 7, han(.cannon)),
        ])
        XCTAssertEqual(targets(board, from: sq(0, 4)), [sq(0, 6)])
    }

    func testCannonPalaceDiagonalJump() {
        let board = Board.custom([
            (3, 2, cho(.cannon)), (4, 1, cho(.advisor)), (4, 0, cho(.general)), (3, 9, han(.general)),
        ])
        XCTAssertTrue(targets(board, from: sq(3, 2)).contains(sq(5, 0)))
    }

    func testHorseBlocked() {
        var board = Board.custom(cornerGenerals + [(4, 4, cho(.horse))])
        XCTAssertEqual(targets(board, from: sq(4, 4)).count, 8)

        // 위쪽 멱이 막히면 위로 가는 두 수가 사라진다
        board = Board.custom(cornerGenerals + [(4, 4, cho(.horse)), (4, 5, han(.soldier))])
        let t = targets(board, from: sq(4, 4))
        XCTAssertEqual(t.count, 6)
        XCTAssertFalse(t.contains(sq(3, 6)))
        XCTAssertFalse(t.contains(sq(5, 6)))
    }

    func testElephantBlocked() {
        var board = Board.custom(cornerGenerals + [(4, 4, cho(.elephant))])
        XCTAssertEqual(targets(board, from: sq(4, 4)).count, 8)

        // 두 번째 멱 (5,6)이 막히면 (6,7)으로는 못 간다
        board = Board.custom(cornerGenerals + [(4, 4, cho(.elephant)), (5, 6, han(.soldier))])
        let t = targets(board, from: sq(4, 4))
        XCTAssertFalse(t.contains(sq(6, 7)))
        XCTAssertTrue(t.contains(sq(2, 7)))
    }

    func testSoldierMoves() {
        let board = Board.custom(cornerGenerals + [(4, 5, cho(.soldier)), (4, 7, han(.soldier))])
        XCTAssertEqual(targets(board, from: sq(4, 5)), [sq(4, 6), sq(3, 5), sq(5, 5)])
        XCTAssertEqual(targets(board, from: sq(4, 7)), [sq(4, 6), sq(3, 7), sq(5, 7)])

        // 상대 궁성 안에서는 궁성 대각선으로 전진 가능
        let palace = Board.custom([(3, 0, cho(.general)), (5, 9, han(.general)), (3, 7, cho(.soldier))])
        XCTAssertTrue(targets(palace, from: sq(3, 7)).contains(sq(4, 8)))
    }

    // MARK: 장군 · 빅장

    func testCheckFromCannonThroughScreen() {
        let board = Board.custom([
            (4, 1, cho(.general)), (4, 4, han(.soldier)), (4, 6, han(.cannon)), (3, 9, han(.general)),
        ])
        XCTAssertTrue(Rules.isInCheck(.cho, on: board))
    }

    func testBikjangForbidden() {
        // 초 궁 (4,1), 한 궁 (4,8), 사이를 막던 초 졸이 옆으로 비키면 빅장 → 금지
        let board = Board.custom([
            (4, 1, cho(.general)), (4, 5, cho(.soldier)), (4, 8, han(.general)), (0, 9, han(.chariot)),
        ])
        let moves = Rules.legalMoves(for: .cho, on: board)
        XCTAssertFalse(moves.contains(Move(from: sq(4, 5), to: sq(3, 5))))
        XCTAssertTrue(moves.contains(Move(from: sq(4, 5), to: sq(4, 6))))
    }

    // MARK: 강제 캡처

    func testForcedCapture() {
        let board = Board.custom(cornerGenerals + [
            (2, 4, cho(.soldier)), (2, 5, han(.soldier)), (8, 0, cho(.chariot)),
        ])
        let moves = Rules.legalMoves(for: .cho, on: board)
        XCTAssertEqual(moves, [Move(from: sq(2, 4), to: sq(2, 5))])
    }

    func testLongChariotCaptureIsNotForced() {
        // 차가 4칸 떨어진 적을 잡을 수 있지만 강제는 아님 → 다른 수도 둘 수 있다
        let board = Board.custom(cornerGenerals + [(0, 2, cho(.chariot)), (0, 6, han(.soldier))])
        let moves = Rules.legalMoves(for: .cho, on: board)
        XCTAssertTrue(moves.contains(Move(from: sq(0, 2), to: sq(0, 6))))
        XCTAssertTrue(moves.contains(Move(from: sq(0, 2), to: sq(1, 2))))

        // 2칸 이내면 강제
        let near = Board.custom(cornerGenerals + [(0, 4, cho(.chariot)), (0, 6, han(.soldier))])
        XCTAssertEqual(Rules.legalMoves(for: .cho, on: near), [Move(from: sq(0, 4), to: sq(0, 6))])
    }

    func testEscapingCheckBeatsForcedCapture() {
        // 초는 장군 상태. 졸로 잡는 수가 있어도 장군을 피하는 수만 가능
        let board = Board.custom([
            (4, 1, cho(.general)), (4, 7, han(.chariot)), (5, 9, han(.general)),
            (0, 4, cho(.soldier)), (0, 5, han(.soldier)),
        ])
        let moves = Rules.legalMoves(for: .cho, on: board)
        XCTAssertFalse(moves.isEmpty)
        XCTAssertTrue(moves.allSatisfy { $0.from == sq(4, 1) })
    }

    // MARK: 승패

    func testOnlyGeneralLeftWins() {
        let board = Board.custom([(3, 0, cho(.general)), (5, 9, han(.general)), (0, 5, han(.soldier))])
        XCTAssertEqual(Game(board: board, sideToMove: .han).result, .win(.cho, .onlyGeneralLeft))
    }

    func testCheckmatedSideWins() {
        // 초 궁 (3,0) 귀퉁이, 한 차 두 대로 외통
        let board = Board.custom([
            (3, 0, cho(.general)), (8, 8, cho(.soldier)),
            (8, 0, han(.chariot)), (8, 1, han(.chariot)), (5, 9, han(.general)),
        ])
        let game = Game(board: board, sideToMove: .cho)
        XCTAssertEqual(game.result, .win(.cho, .checkmated))
    }

    func testLoneIslandWins() {
        // 초의 졸은 끝줄 구석에서 자기 사에 막혀 못 움직이고, 사는 궁성 밖이라 못 움직인다.
        // 초는 궁만 움직일 수 있다 → 외딴 섬 승리
        let board = Board.custom([
            (4, 1, cho(.general)), (0, 9, cho(.soldier)), (1, 9, cho(.advisor)),
            (3, 9, han(.general)), (8, 6, han(.soldier)),
        ])
        let game = Game(board: board, sideToMove: .cho)
        XCTAssertEqual(game.result, .win(.cho, .loneIsland))
    }

    // MARK: 공격 판정 교차 검증

    /// 빠른 역방향 공격 판정이 "상대 의사수 중 그 칸으로 가는 수가 있는가"와 일치하는지
    /// 무작위 대국 위치 수천 개에서 확인한다.
    func testAttackDetectionMatchesMoveGeneration() {
        var rng = SystemRandomNumberGenerator()
        var checked = 0
        for _ in 0..<60 {
            var game = Game()
            for _ in 0..<120 {
                guard let move = game.legalMoves().randomElement(using: &rng) else { break }
                game.play(move)
                let board = game.board
                for side in Side.allCases {
                    var attacked = Set<Square>()
                    for (from, piece) in board.pieces(of: side) {
                        var moves: [Move] = []
                        Rules.appendPseudoMoves(for: piece, at: from, on: board, into: &moves)
                        attacked.formUnion(moves.map(\.to))
                    }
                    for target in 0..<SquareUtil.count {
                        // 의사수는 자기 기물 칸으로는 가지 않으므로, 상대 기물이나 빈 칸만 비교
                        guard board[target]?.side != side else { continue }
                        XCTAssertEqual(
                            Rules.isAttacked(target, by: side, on: board), attacked.contains(target),
                            "square \(target) side \(side)\n\(board.positionKey(sideToMove: game.sideToMove))"
                        )
                        checked += 1
                    }
                }
            }
        }
        XCTAssertGreaterThan(checked, 10_000)
    }

    // MARK: 무작위 대국

    func testRandomGamesTerminate() {
        for _ in 0..<40 {
            var game = Game()
            var plies = 0
            while !game.isFinished && plies < 2000 {
                let moves = game.legalMoves()
                XCTAssertFalse(moves.isEmpty)
                game.play(moves.randomElement()!)
                plies += 1
                // 어떤 경우에도 차례인 쪽이 빅장 상태가 될 수 없다
                XCTAssertFalse(Rules.generalsFacing(on: game.board))
            }
            XCTAssertTrue(game.isFinished)
        }
    }

    func testBotReturnsLegalMove() {
        var game = Game()
        for level in BotLevel.allCases {
            let move = Bot.bestMove(in: game, level: level)
            XCTAssertNotNil(move)
            XCTAssertTrue(game.legalMoves().contains(move!))
        }
        game.play(Bot.bestMove(in: game, level: .normal)!)
        XCTAssertEqual(game.sideToMove, .cho)
    }

    func testBotTakesImmediateWin() {
        // 한의 마지막 기물(졸)을 초 졸 앞으로 밀면 초는 반드시 잡아야 한다 → 한 승리
        let board = Board.custom([
            (3, 0, cho(.general)), (2, 3, cho(.soldier)), (8, 3, cho(.soldier)),
            (2, 5, han(.soldier)), (5, 9, han(.general)),
        ])
        let game = Game(board: board, sideToMove: .han)
        XCTAssertEqual(Bot.bestMove(in: game, level: .hard), Move(from: sq(2, 5), to: sq(2, 4)))
    }
}
