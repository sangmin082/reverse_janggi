import Foundation

/// 게임 종료 사유
enum GameResult: Equatable {
    case win(Side, WinReason)
    case draw(DrawReason)

    enum WinReason: Equatable {
        /// 궁을 제외한 모든 기물을 잃음
        case onlyGeneralLeft
        /// 외통수를 "당한" 쪽이 승리
        case checkmated
        /// 장군이 아닌데 움직일 수 있는 기물이 궁뿐 (다른 기물은 남아 있음)
        case loneIsland
        /// 캡처 없이 50수가 지나 점수 판정 — 남은 기물 점수가 낮은 쪽이 승리
        case lowerScore
    }

    enum DrawReason: Equatable {
        /// 장군이 아닌데 둘 수 있는 수가 없음
        case stalemate
        case threefoldRepetition
        /// 캡처 없이 50수가 지났고 점수도 같음
        case fiftyMoveRule
    }
}

/// 한 판의 진행 상태 (값 타입)
struct Game {
    private(set) var board: Board
    private(set) var sideToMove: Side
    private(set) var result: GameResult?
    private(set) var lastMove: Move?
    private(set) var moveCount: Int = 0

    /// 50수 규칙: 캡처 없이 지나간 반수(half-move) 수
    private(set) var quietHalfMoves: Int = 0
    private var positionCounts: [String: Int] = [:]

    /// 한이 선공
    init(board: Board = .initial(), sideToMove: Side = .han) {
        self.board = board
        self.sideToMove = sideToMove
        self.positionCounts[board.positionKey(sideToMove: sideToMove)] = 1
        self.result = Self.evaluateResult(
            board: board, sideToMove: sideToMove,
            quietHalfMoves: 0, positionCounts: positionCounts
        )
    }

    var isFinished: Bool { result != nil }

    func legalMoves() -> [Move] {
        isFinished ? [] : Rules.legalMoves(for: sideToMove, on: board)
    }

    func legalMoves(from sq: Square) -> [Move] {
        legalMoves().filter { $0.from == sq }
    }

    var isInCheck: Bool { Rules.isInCheck(sideToMove, on: board) }
    var hasForcedCapture: Bool { Rules.hasForcedCapture(for: sideToMove, on: board) }

    @discardableResult
    mutating func play(_ move: Move) -> Bool {
        guard !isFinished, legalMoves().contains(move) else { return false }

        let isCapture = board[move.to] != nil
        board.apply(move)
        lastMove = move
        moveCount += 1
        quietHalfMoves = isCapture ? 0 : quietHalfMoves + 1
        sideToMove = sideToMove.opposite

        let key = board.positionKey(sideToMove: sideToMove)
        positionCounts[key, default: 0] += 1

        result = Self.evaluateResult(
            board: board, sideToMove: sideToMove,
            quietHalfMoves: quietHalfMoves, positionCounts: positionCounts
        )
        return true
    }

    /// 종료 판정. `sideToMove`는 지금 둘 차례인 쪽.
    static func evaluateResult(
        board: Board, sideToMove: Side,
        quietHalfMoves: Int, positionCounts: [String: Int]
    ) -> GameResult? {
        if let terminal = terminalResult(board: board, sideToMove: sideToMove) {
            return terminal
        }
        // 4. 같은 국면 3회 반복 → 무승부
        if positionCounts[board.positionKey(sideToMove: sideToMove)] ?? 0 >= 3 {
            return .draw(.threefoldRepetition)
        }
        // 5. 캡처 없이 50수(양쪽 합 100수): 장기식 점수 판정을 뒤집어, 점수가 낮은 쪽이 승리
        if quietHalfMoves >= 100 {
            let cho = board.material(of: .cho), han = board.material(of: .han)
            if cho == han { return .draw(.fiftyMoveRule) }
            return .win(cho < han ? .cho : .han, .lowerScore)
        }
        return nil
    }

    /// 수순 기록 없이 판정 가능한 종료 (AI 탐색에서도 사용)
    static func terminalResult(board: Board, sideToMove: Side, legalMoves: [Move]? = nil) -> GameResult? {
        // 1. 궁만 남음 → 그 플레이어 승리 (둘 다는 동시에 될 수 없음: 이전 판정에서 이미 끝났을 것)
        for side in Side.allCases where board.nonGeneralCount(of: side) == 0 {
            return .win(side, .onlyGeneralLeft)
        }

        let moves = legalMoves ?? Rules.legalMoves(for: sideToMove, on: board)
        let inCheck = Rules.isInCheck(sideToMove, on: board)

        // 2. 둘 수 있는 수가 없음: 외통이면 "당한 쪽" 승리, 아니면 무승부
        if moves.isEmpty {
            return inCheck ? .win(sideToMove, .checkmated) : .draw(.stalemate)
        }

        // 3. 외딴 섬: 장군이 아니고, 움직일 수 있는 기물이 궁뿐이면 그 플레이어 승리.
        //    "움직일 수 있는"은 강제 캡처 적용 전 기준이다 — 궁만 잡을 수 있는 상황은 외딴 섬이 아니다.
        if !inCheck && moves.allSatisfy({ board[$0.from]?.kind == .general }) {
            let movable = Rules.movesIgnoringForcedCapture(for: sideToMove, on: board)
            if movable.allSatisfy({ board[$0.from]?.kind == .general }) {
                return .win(sideToMove, .loneIsland)
            }
        }
        return nil
    }
}
