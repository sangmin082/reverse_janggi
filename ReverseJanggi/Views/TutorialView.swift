import SwiftUI

// MARK: - 레슨 정의 (미션 기반: 직접 정답 수를 찾아야 통과)

struct TutorialLesson: Identifiable {
    let id: Int
    let title: String
    let story: String
    let goal: String
    let hint: String
    let board: Board
    /// 성공 판정: 플레이어가 둔 수를 받아 통과 여부 반환
    let isSuccess: (Move) -> Bool
    /// 성공 후 초의 강제 응수를 자동 재생할지 (승리 체험 미션용)
    var playsReply: Bool = false

    static let all: [TutorialLesson] = [
        TutorialLesson(
            id: 0,
            title: String(localized: "한이 먼저 시작해요"),
            story: String(localized: "리버스 장기의 목표는 정반대예요. 기물을 지키는 게 아니라, 궁만 남기고 전부 잃어야 이깁니다. 그리고 첫 수는 초가 아니라 한의 몫이에요."),
            goal: String(localized: "아무 기물이나 움직여 첫 수를 두세요."),
            hint: String(localized: "기물을 탭하면 갈 수 있는 자리가 표시돼요."),
            board: .initial(),
            isSuccess: { _ in true }
        ),
        TutorialLesson(
            id: 1,
            title: String(localized: "잡을 수 있으면 잡아야 해요"),
            story: String(localized: "잡을 수 있는 기물이 있다면 반드시 그중 하나를 잡아야 해요. 기물을 잃는 게 목표인 게임이라, 이 규칙이 승부의 핵심이 됩니다."),
            goal: String(localized: "지금 둘 수 있는 수는 단 하나뿐이에요. 찾아보세요."),
            hint: String(localized: "차는 움직일 수 없어요. 병으로 잡을 수 있는 것을 찾아보세요."),
            board: TutorialPositions.forcedCapture,
            isSuccess: { $0 == TutorialPositions.forcedCaptureAnswer }
        ),
        TutorialLesson(
            id: 2,
            title: String(localized: "차는 2칸까지만 강제예요"),
            story: String(localized: "예외가 하나 있어요. 가장 강한 기물인 차의 캡처는 2칸 이내일 때만 강제입니다. 멀리 있는 기물은 차로 잡을 수 있어도, 잡지 않아도 돼요."),
            goal: String(localized: "멀리 있는 졸을 차로 잡지 말고, 다른 수를 두세요."),
            hint: String(localized: "졸과 차 사이의 거리를 세어보세요. 병이나 궁을 움직여도 돼요."),
            board: TutorialPositions.chariotRange,
            isSuccess: { $0 != TutorialPositions.chariotRangeCapture }
        ),
        TutorialLesson(
            id: 3,
            title: String(localized: "포는 넘어서 다녀요"),
            story: String(localized: "포는 반드시 기물 하나를 뛰어넘어서 움직이고 잡아요. 다만 포끼리는 넘을 수도, 잡을 수도 없어요. 강제 캡처는 포에게도 똑같이 적용됩니다."),
            goal: String(localized: "포로 초의 마를 잡으세요."),
            hint: String(localized: "포 앞의 병이 디딤돌이에요. 병을 넘어 쭉 내려가 보세요."),
            board: TutorialPositions.cannon,
            isSuccess: { $0 == TutorialPositions.cannonAnswer }
        ),
        TutorialLesson(
            id: 4,
            title: String(localized: "장군이 먼저예요"),
            story: String(localized: "장군 규칙은 일반 장기 그대로예요. 장군을 받으면 반드시 피해야 하고, 강제 캡처보다 장군 피하기가 우선입니다. 스스로 장군을 받는 자리로 갈 수도 없어요."),
            goal: String(localized: "장군에서 벗어나세요."),
            hint: String(localized: "차의 길에서 궁을 비키세요."),
            board: TutorialPositions.check,
            isSuccess: { _ in true }
        ),
        TutorialLesson(
            id: 5,
            title: String(localized: "궁끼리 마주 보면 안 돼요"),
            story: String(localized: "두 궁이 같은 줄에서 사이에 아무것도 없이 마주 보는 것을 빅장이라고 해요. 리버스 장기에서는 빅장을 만드는 수를 둘 수 없어요. 한수쉼(패스)도 없습니다."),
            goal: String(localized: "가운데 병을 움직여 보세요."),
            hint: String(localized: "병이 옆으로 비키면 두 궁이 마주 봐요. 앞으로는 갈 수 있어요."),
            board: TutorialPositions.bikjang,
            isSuccess: { $0.from == TutorialPositions.bikjangSoldier }
        ),
        TutorialLesson(
            id: 6,
            title: String(localized: "버리는 자가 이긴다"),
            story: String(localized: "이제 실전 감각이에요. 상대는 잡을 수 있으면 잡아야만 하죠. 그러니 내 기물을 일부러 상대가 잡을 수 있는 곳에 놓으면, 상대는 어쩔 수 없이 잡아줍니다. 마지막 기물을 버려서 직접 승리해보세요!"),
            goal: String(localized: "병을 초의 졸이 잡을 수밖에 없는 곳에 놓으세요."),
            hint: String(localized: "졸은 앞이나 옆으로 잡아요. 졸 바로 앞에 병을 놓아보세요."),
            board: TutorialPositions.sacrifice,
            isSuccess: { $0 == TutorialPositions.sacrificeAnswer },
            playsReply: true
        ),
    ]
}

// MARK: - 튜토리얼 화면

@MainActor
final class TutorialViewModel: ObservableObject {
    @Published var lessonIndex = 0
    @Published var game: Game
    @Published var selected: Square?
    @Published var phase: Phase = .concept
    @Published var showHint = false

    enum Phase {
        case concept      // 리버스 장기란? (최초 1회)
        case intro        // 레슨 소개
        case playing      // 미션 수행 중
        case wrong        // 오답 → 다시
        case success      // 통과
        case finished     // 전체 완료
    }

    var lesson: TutorialLesson { TutorialLesson.all[lessonIndex] }

    init() {
        game = Game(board: TutorialLesson.all[0].board, sideToMove: .han)
    }

    var targets: Set<Square> {
        guard let sel = selected, phase == .playing else { return [] }
        return Set(game.legalMoves(from: sel).map(\.to))
    }

    var forcedTargets: Set<Square> {
        guard let sel = selected, phase == .playing else { return [] }
        return Set(
            game.legalMoves(from: sel)
                .filter { Rules.isForcedCapture($0, on: game.board) }
                .map(\.to)
        )
    }

    func startLesson() {
        phase = .playing
        showHint = false
        selected = nil
        game = Game(board: lesson.board, sideToMove: .han)
    }

    func handleTap(_ sq: Square) {
        guard phase == .playing || phase == .wrong else { return }
        if phase == .wrong { phase = .playing }

        if let sel = selected,
           let move = game.legalMoves(from: sel).first(where: { $0.to == sq }) {
            selected = nil
            submit(move)
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

    private func submit(_ move: Move) {
        guard lesson.isSuccess(move) else {
            Haptics.failure()
            phase = .wrong
            game = Game(board: lesson.board, sideToMove: .han)
            return
        }
        game.play(move)
        Haptics.move()

        if lesson.playsReply {
            // 초의 강제 응수를 자동 재생해 승리를 체험시킨다
            let snapshot = game
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 600_000_000)
                var g = snapshot
                if let reply = g.legalMoves().first {
                    g.play(reply)
                    self.game = g
                    Haptics.capture()
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                Haptics.success()
                self.phase = .success
            }
        } else {
            Haptics.success()
            phase = .success
        }
    }

    func next() {
        if lessonIndex + 1 < TutorialLesson.all.count {
            lessonIndex += 1
            phase = .intro
            selected = nil
            game = Game(board: lesson.board, sideToMove: .han)
        } else {
            phase = .finished
        }
    }
}

struct TutorialView: View {
    @StateObject private var model = TutorialViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 12) {
                progressBar

                BoardView(
                    board: model.game.board,
                    lastMove: model.game.lastMove,
                    selected: model.selected,
                    targets: model.targets,
                    forcedTargets: model.forcedTargets,
                    bottomSide: .han,
                    onTap: model.handleTap
                )
                .padding(.horizontal, 14)
                .opacity(dimmedPhases ? 0.3 : 1)

                missionPanel
                Spacer(minLength: 0)
            }
            .padding(.top, 8)

            if model.phase == .concept { conceptCard }
            if model.phase == .intro { introCard }
            if model.phase == .finished { finishedCard }
        }
        .navigationTitle("배우기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.paper, for: .navigationBar)
    }

    private var dimmedPhases: Bool {
        model.phase == .concept || model.phase == .intro || model.phase == .finished
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(TutorialLesson.all) { lesson in
                Rectangle()
                    .fill(lesson.id <= model.lessonIndex && model.phase != .concept
                          ? Theme.accent : Theme.hairline)
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 22)
    }

    @ViewBuilder
    private var missionPanel: some View {
        if model.phase == .playing || model.phase == .wrong || model.phase == .success {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.lesson.title)
                        .font(.system(.headline, design: .serif, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if model.phase != .success {
                        Button {
                            model.showHint.toggle()
                        } label: {
                            Text("힌트")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(Theme.inkSoft)
                                .underline()
                        }
                    }
                }

                switch model.phase {
                case .wrong:
                    Text("그 수가 아닙니다. 다시 해보세요.")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                case .success:
                    Text("정답입니다.")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                default:
                    Text(model.lesson.goal)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                }

                if model.showHint && model.phase != .success {
                    Text(model.lesson.hint)
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                }

                if model.phase == .success {
                    Button(model.lessonIndex + 1 < TutorialLesson.all.count
                        ? String(localized: "다음 레슨") : String(localized: "완료")) {
                        model.next()
                    }
                    .buttonStyle(InkButtonStyle(filled: true))
                }
            }
            .padding(18)
            .panelStyle()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 카드

    private var conceptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("리버스 장기란?")
                .font(.system(size: 28, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)

            Text("모든 것이 거꾸로인 장기입니다. 기물은 지키는 게 아니라 버리는 것이고, 외통수는 당하는 쪽이 이깁니다.")
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                conceptLine("궁만 남기면 승리")
                conceptLine("외통수를 당해도 승리")
                conceptLine("장군이 아닌데 궁밖에 못 움직여도 승리 — 외딴 섬")
            }

            Text("일곱 개의 미션으로 차근차근 배워봅시다.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)

            Button("시작") { model.phase = .intro }
                .buttonStyle(InkButtonStyle(filled: true))
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: 340, alignment: .leading)
        .panelStyle()
        .padding(24)
    }

    private func conceptLine(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("—").foregroundStyle(Theme.accent).fontWeight(.bold)
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("레슨 \(model.lessonIndex + 1) / \(TutorialLesson.all.count)")
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text(model.lesson.title)
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text(model.lesson.story)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button("미션 시작") { model.startLesson() }
                .buttonStyle(InkButtonStyle(filled: true))
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: 340, alignment: .leading)
        .panelStyle()
        .padding(24)
    }

    private var finishedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("수료")
                .font(.system(size: 28, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)
            Text("리버스 장기의 모든 규칙을 배웠습니다. 이제 실전에서 마음껏 져보세요 — 그게 이기는 길입니다.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button("홈으로") { dismiss() }
                .buttonStyle(InkButtonStyle(filled: true))
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: 340, alignment: .leading)
        .panelStyle()
        .padding(24)
    }
}
