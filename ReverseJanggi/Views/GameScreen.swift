import SwiftUI

enum GameMode: Hashable {
    case vsBot(BotLevel)
    case twoPlayer
    /// 온라인 대전 — 연관값은 내가 둘 진영 (서버가 배정)
    case online(Side)

    var title: String {
        switch self {
        case .vsBot(let level): return String(localized: "컴퓨터 대전 · \(level.localizedName)")
        case .twoPlayer: return String(localized: "함께 하기")
        case .online: return String(localized: "온라인 대전")
        }
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published var game = Game()
    @Published var selected: Square?
    @Published var isBotThinking = false
    @Published var opponentLeft = false
    /// 무르기용 이전 상태
    @Published private(set) var history: [Game] = []

    let mode: GameMode
    /// 사람이 조종하는 진영 — vsBot은 한(선공), 온라인은 서버 배정
    let humanSide: Side
    private let client: RoomClient?
    /// 무르기·재시작 후 늦게 도착한 AI 응수를 버리기 위한 토큰
    private var botToken = UUID()

    init(mode: GameMode, client: RoomClient? = nil) {
        self.mode = mode
        self.client = client
        if case .online(let side) = mode {
            self.humanSide = side
        } else {
            self.humanSide = .han
        }
        client?.onRemoteMove = { [weak self] move in
            self?.applyRemote(move)
        }
        client?.onOpponentLeft = { [weak self] in
            self?.opponentLeft = true
        }
    }

    var botLevel: BotLevel? {
        if case .vsBot(let level) = mode { return level }
        return nil
    }

    var isOnline: Bool {
        if case .online = mode { return true }
        return false
    }

    /// 화면 아래쪽 진영 — 함께 하기는 선공(한)이 아래
    var bottomSide: Side { humanSide }

    var isHumanTurn: Bool {
        guard !game.isFinished, !opponentLeft else { return false }
        switch mode {
        case .twoPlayer: return true
        case .vsBot, .online: return game.sideToMove == humanSide
        }
    }

    var canUndo: Bool {
        guard !isOnline, !isBotThinking else { return false }
        if botLevel != nil {
            return history.contains { $0.sideToMove == humanSide }
        }
        return !history.isEmpty
    }

    var targets: Set<Square> {
        guard let sel = selected else { return [] }
        return Set(game.legalMoves(from: sel).map(\.to))
    }

    var forcedTargets: Set<Square> {
        guard let sel = selected else { return [] }
        return Set(
            game.legalMoves(from: sel)
                .filter { Rules.isForcedCapture($0, on: game.board) }
                .map(\.to)
        )
    }

    /// "기물을 잃을수록 승리에 가까워지는" 리버스 진행도 (0.0 = 시작, 1.0 = 궁만 남음)
    func reverseProgress(for side: Side) -> Double {
        Double(15 - game.board.nonGeneralCount(of: side)) / 15.0
    }

    func handleTap(_ sq: Square) {
        guard isHumanTurn else { return }

        if let sel = selected,
           let move = game.legalMoves(from: sel).first(where: { $0.to == sq }) {
            selected = nil
            perform(move)
            return
        }

        if let piece = game.board[sq], piece.side == game.sideToMove,
           !game.legalMoves(from: sq).isEmpty {
            selected = (selected == sq) ? nil : sq
            Haptics.tap()
        } else {
            selected = nil
        }
    }

    private func perform(_ move: Move, fromRemote: Bool = false) {
        let before = game
        let isCapture = game.board[move.to] != nil
        guard game.play(move) else { return }
        history.append(before)
        isCapture ? Haptics.capture() : Haptics.move()

        if isOnline && !fromRemote {
            client?.send(move: move)
        }

        if game.isFinished {
            announceResult()
        } else {
            scheduleBotIfNeeded()
        }
    }

    /// 온라인 상대의 무브 적용
    func applyRemote(_ move: Move) {
        guard isOnline, game.sideToMove != humanSide else { return }
        perform(move, fromRemote: true)
    }

    func scheduleBotIfNeeded() {
        guard let level = botLevel, !game.isFinished, game.sideToMove != humanSide else { return }
        isBotThinking = true
        let snapshot = game
        let token = UUID()
        botToken = token
        Task.detached(priority: .userInitiated) {
            let started = Date()
            let move = Bot.bestMove(in: snapshot, level: level)
            // 최소한의 "생각하는" 연출
            let elapsed = Date().timeIntervalSince(started)
            if elapsed < 0.45 {
                try? await Task.sleep(nanoseconds: UInt64((0.45 - elapsed) * 1_000_000_000))
            }
            await MainActor.run { [weak self] in
                guard let self, self.botToken == token, !self.game.isFinished else { return }
                self.isBotThinking = false
                if let move { self.perform(move) }
            }
        }
    }

    /// 한 수 무르기. 컴퓨터 대전은 내 차례가 될 때까지 되돌린다.
    func undo() {
        guard canUndo else { return }
        botToken = UUID()
        selected = nil
        while let previous = history.popLast() {
            game = previous
            if botLevel == nil || previous.sideToMove == humanSide { break }
        }
        Haptics.tap()
    }

    private func announceResult() {
        guard case .win(let winner, _)? = game.result else { return }
        if case .twoPlayer = mode {
            Haptics.success()
        } else {
            winner == humanSide ? Haptics.success() : Haptics.failure()
        }
    }

    func restart() {
        botToken = UUID()
        game = Game()
        history = []
        selected = nil
        isBotThinking = false
    }
}

struct GameScreen: View {
    @StateObject private var model: GameViewModel
    @Environment(\.dismiss) private var dismiss

    init(mode: GameMode) {
        _model = StateObject(wrappedValue: GameViewModel(mode: mode))
    }

    /// 외부에서 구성한 모델로 표시 (온라인 대전)
    init(model: GameViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 12) {
                playerPanel(for: model.bottomSide.opposite)

                BoardView(
                    board: model.game.board,
                    lastMove: model.game.lastMove,
                    selected: model.selected,
                    targets: model.targets,
                    forcedTargets: model.forcedTargets,
                    bottomSide: model.bottomSide,
                    onTap: model.handleTap
                )
                .padding(.horizontal, 14)

                playerPanel(for: model.bottomSide)
                statusBanner
                Spacer(minLength: 0)
            }
            .padding(.top, 8)

            if model.game.isFinished {
                Theme.ink.opacity(0.25).ignoresSafeArea()
                resultOverlay
            } else if model.opponentLeft {
                Theme.ink.opacity(0.25).ignoresSafeArea()
                opponentLeftOverlay
            }
        }
        .navigationTitle(model.mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.paper, for: .navigationBar)
        .toolbar {
            if !model.isOnline {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.undo()
                    } label: {
                        Label("무르기", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(!model.canUndo)
                }
            }
        }
    }

    // MARK: - 구성 요소

    private func playerPanel(for side: Side) -> some View {
        let isTurn = !model.game.isFinished && model.game.sideToMove == side
        let name: String = {
            switch model.mode {
            case .vsBot: return side == model.humanSide
                ? String(localized: "나 · \(side.localizedName)")
                : String(localized: "컴퓨터 · \(side.localizedName)")
            case .twoPlayer: return side.localizedName
            case .online: return side == model.humanSide
                ? String(localized: "나 · \(side.localizedName)")
                : String(localized: "상대 · \(side.localizedName)")
            }
        }()
        let board = model.game.board

        return HStack(spacing: 10) {
            PieceView(piece: Piece(side: side, kind: .general), cell: 26)

            Text(name)
                .font(.system(.subheadline, design: .serif, weight: .bold))
                .foregroundStyle(Theme.ink)

            if isTurn {
                if model.isBotThinking {
                    Text("생각 중…")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Circle().fill(Theme.color(for: side)).frame(width: 7, height: 7)
                }
            }
            Spacer()

            // 리버스 진행도: 기물을 잃을수록 승리에 가까워진다
            VStack(alignment: .trailing, spacing: 3) {
                Text("남은 기물 \(board.nonGeneralCount(of: side)) · \(board.material(of: side))점")
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSoft)
                ProgressView(value: model.reverseProgress(for: side))
                    .tint(Theme.color(for: side))
                    .frame(width: 84)
            }
        }
        .padding(.horizontal, 22)
    }

    private var statusBanner: some View {
        Group {
            if !model.game.isFinished {
                if model.game.isInCheck {
                    bannerLabel("장군 — 반드시 피해야 합니다")
                } else if model.game.hasForcedCapture {
                    bannerLabel("강제 캡처 — 잡을 수 있으면 잡아야 합니다")
                } else if model.game.quietHalfMoves >= 60 {
                    bannerLabel("캡처 없이 \(model.game.quietHalfMoves / 2)수 — 50수가 되면 점수 판정")
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.game.moveCount)
    }

    private func bannerLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(.footnote, weight: .semibold))
            .foregroundStyle(Theme.accent)
            .padding(.top, 2)
    }

    private var resultOverlay: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(resultTitle)
                .font(.system(size: 34, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)
            Text(resultDetail)
                .font(.system(.subheadline))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if !model.isOnline {
                    Button("한 판 더") { model.restart() }
                        .buttonStyle(InkButtonStyle(filled: true))
                }
                Button("홈으로") { dismiss() }
                    .buttonStyle(InkButtonStyle(filled: model.isOnline))
            }
            .padding(.top, 8)

            if model.canUndo {
                Button {
                    model.undo()
                } label: {
                    Text("마지막 수 무르기")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .underline()
                }
            }
        }
        .padding(26)
        .frame(maxWidth: 330, alignment: .leading)
        .panelStyle()
        .padding(24)
        .transition(.scale.combined(with: .opacity))
    }

    private var opponentLeftOverlay: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("상대가 나갔습니다")
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)
            Text("연결이 끊어져 대국을 계속할 수 없습니다.")
                .font(.system(.subheadline))
                .foregroundStyle(Theme.inkSoft)
            Button("홈으로") { dismiss() }
                .buttonStyle(InkButtonStyle(filled: true))
                .padding(.top, 8)
        }
        .padding(26)
        .frame(maxWidth: 330, alignment: .leading)
        .panelStyle()
        .padding(24)
        .transition(.scale.combined(with: .opacity))
    }

    private var resultTitle: String {
        switch model.game.result {
        case .win(let winner, _):
            if model.botLevel != nil || model.isOnline {
                return winner == model.humanSide
                    ? String(localized: "승리") : String(localized: "패배")
            }
            return String(localized: "\(winner.localizedName)의 승리")
        case .draw: return String(localized: "무승부")
        case nil: return ""
        }
    }

    private var resultDetail: String {
        switch model.game.result {
        case .win(_, let reason):
            switch reason {
            case .onlyGeneralLeft:
                return String(localized: "궁만 남기고 모든 기물을 버려서 승리했습니다.")
            case .checkmated:
                return String(localized: "외통수를 당하면 이기는 게임 — 그렇게 끝났습니다.")
            case .loneIsland:
                return String(localized: "외딴 섬 — 궁 말고는 움직일 기물이 없어서 승리했습니다.")
            case .lowerScore:
                return String(localized: "캡처 없이 50수가 지나 점수 판정 — 남은 점수가 더 낮은 쪽이 이겼습니다.")
            }
        case .draw(let reason):
            switch reason {
            case .stalemate:
                return String(localized: "둘 수 있는 수가 없어 무승부입니다.")
            case .threefoldRepetition:
                return String(localized: "같은 국면이 세 번 반복되어 무승부입니다.")
            case .fiftyMoveRule:
                return String(localized: "캡처 없이 50수가 지났고 점수가 같아 무승부입니다.")
            }
        case nil: return ""
        }
    }
}
