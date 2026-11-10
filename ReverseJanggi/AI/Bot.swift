import Foundation

enum BotLevel: String, CaseIterable, Identifiable {
    case easy, normal, hard

    var id: String { rawValue }

    /// 기본 탐색 깊이 (반수)
    var depth: Int {
        switch self {
        case .easy: return 1
        case .normal: return 2
        case .hard: return 3
        }
    }

    /// 한 수에 쓸 최대 시간(초). 넘으면 마지막으로 끝난 깊이의 결과를 쓴다.
    var timeBudget: TimeInterval {
        switch self {
        case .easy: return 0.5
        case .normal: return 1.2
        case .hard: return 2.5
        }
    }

    /// 상위 후보 중 무작위로 고를 확률 (실수 유도)
    var blunderPercent: Int {
        switch self {
        case .easy: return 40
        case .normal: return 12
        case .hard: return 0
        }
    }
}

/// 리버스 장기 AI — 네가맥스 + 알파베타 + 강제 캡처 연장 탐색.
/// 평가: 내 기물이 적을수록 좋다 (기물을 버리는 것이 승리 조건이므로).
enum Bot {

    private static let winScore = 100_000

    static func bestMove(in game: Game, level: BotLevel) -> Move? {
        let moves = ordered(game.legalMoves(), on: game.board)
        guard !moves.isEmpty else { return nil }
        if moves.count == 1 { return moves[0] }

        var search = Search(deadline: Date().addingTimeInterval(level.timeBudget))
        var scored: [(Move, Int)] = moves.map { ($0, 0) }

        // 반복 심화: 시간이 넘치면 마지막으로 완료된 깊이의 점수를 사용
        for depth in 1...level.depth {
            var current: [(Move, Int)] = []
            for (move, _) in scored {
                let next = game.board.applying(move)
                let score = -search.negamax(
                    board: next, side: game.sideToMove.opposite, depth: depth - 1,
                    alpha: -winScore * 2, beta: winScore * 2, ply: 1
                )
                if search.timedOut { break }
                current.append((move, score))
            }
            if search.timedOut && current.count < scored.count { break }
            current.shuffle()
            current.sort { $0.1 > $1.1 }
            scored = current
            // 이미 이기는 수를 찾았으면 더 볼 필요 없음
            if let top = scored.first, top.1 > winScore / 2 { break }
        }

        if level.blunderPercent > 0, scored.count > 1, Int.random(in: 0..<100) < level.blunderPercent {
            // 지는 수(상대 강제 승리)는 피해서 고른다
            let pool = scored.prefix(3).filter { $0.1 > -winScore / 2 }
            if let pick = pool.randomElement() { return pick.0 }
        }
        return scored.first?.0
    }

    /// 캡처를 먼저 보도록 정렬 (알파베타 가지치기 효율)
    private static func ordered(_ moves: [Move], on board: Board) -> [Move] {
        moves.sorted { (board[$0.to] != nil ? 1 : 0) > (board[$1.to] != nil ? 1 : 0) }
    }

    private struct Search {
        let deadline: Date
        var nodes = 0
        var timedOut = false

        /// 깊이가 다 된 뒤에도 강제 캡처가 이어지면 이만큼 더 본다
        let maxExtension = 4

        mutating func negamax(board: Board, side: Side, depth: Int, alpha: Int, beta: Int, ply: Int) -> Int {
            nodes += 1
            if nodes & 1023 == 0, Date() > deadline { timedOut = true }
            if timedOut { return 0 }

            let moves = Rules.legalMoves(for: side, on: board)
            if let result = Game.terminalResult(board: board, sideToMove: side, legalMoves: moves) {
                switch result {
                case .win(let winner, _):
                    return winner == side ? Bot.winScore - ply : -Bot.winScore + ply
                case .draw:
                    return 0
                }
            }

            if depth <= 0 {
                // 강제 캡처 상황은 결과가 크게 요동치므로 연장 탐색
                let forcedOnly = moves.allSatisfy { board[$0.to] != nil }
                guard forcedOnly, -depth < maxExtension else {
                    return Bot.evaluate(board: board, for: side)
                }
            }

            var alpha = alpha
            var best = -Bot.winScore * 2
            for move in Bot.ordered(moves, on: board) {
                let score = -negamax(
                    board: board.applying(move), side: side.opposite, depth: depth - 1,
                    alpha: -beta, beta: -alpha, ply: ply + 1
                )
                if timedOut { return 0 }
                best = max(best, score)
                alpha = max(alpha, score)
                if alpha >= beta { break }
            }
            return best
        }
    }

    /// 관점 진영 기준 점수: 상대 기물이 많고 내 기물이 적을수록 높다.
    static func evaluate(board: Board, for side: Side) -> Int {
        let myCount = board.nonGeneralCount(of: side)
        let theirCount = board.nonGeneralCount(of: side.opposite)
        var score = (theirCount - myCount) * 100

        // 같은 수라면 무거운 기물(차·포)을 먼저 정리하는 편이 낫다
        score += (board.material(of: side.opposite) - board.material(of: side)) * 2
        return score
    }
}
