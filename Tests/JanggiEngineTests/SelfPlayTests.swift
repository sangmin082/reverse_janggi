import XCTest
@testable import JanggiEngine

/// 규칙 밸런스 확인용 AI 자가대국. 오래 걸리므로 평소에는 건너뛴다.
///   SELFPLAY_GAMES=40 swift test -c release -Xswiftc -enable-testing --filter SelfPlay
final class SelfPlayTests: XCTestCase {

    func testSelfPlayStatistics() throws {
        guard let raw = ProcessInfo.processInfo.environment["SELFPLAY_GAMES"], let games = Int(raw) else {
            throw XCTSkip("SELFPLAY_GAMES 환경변수가 없으면 건너뜀")
        }
        var wins: [Side: Int] = [.cho: 0, .han: 0]
        var reasons: [String: Int] = [:]
        var totalPlies = 0

        for _ in 0..<games {
            var game = Game()
            while !game.isFinished, let move = Bot.bestMove(in: game, level: .normal) {
                game.play(move)
            }
            totalPlies += game.moveCount
            switch game.result {
            case .win(let side, let reason):
                wins[side, default: 0] += 1
                reasons["\(reason)", default: 0] += 1
            case .draw(let reason):
                reasons["draw:\(reason)", default: 0] += 1
            case nil:
                break
            }
        }
        print("""
            SELFPLAY games=\(games) chariotRange=\(Rules.chariotForcedCaptureRange)
              han(선공) 승=\(wins[.han]!) cho 승=\(wins[.cho]!)
              평균 수=\(totalPlies / max(games, 1))
              사유=\(reasons.sorted { $0.key < $1.key })
            """)
    }
}
