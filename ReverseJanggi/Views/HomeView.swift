import SwiftUI

struct HomeView: View {
    @State private var botLevel: BotLevel = .easy
    @State private var showRules = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    wordmark
                        .padding(.top, 48)

                    Spacer()

                    menu

                    Spacer()

                    Button {
                        showRules = true
                    } label: {
                        Text("규칙 한 장 보기")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                            .underline()
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 28)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showRules) { RulesSheet() }
        }
        .tint(Theme.ink)
    }

    // MARK: - 워드마크

    private var wordmark: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 뒤집힌 궁 — 지는 것이 곧 이기는 것
            PieceView(piece: Piece(side: .han, kind: .general), cell: 64)
                .rotationEffect(.degrees(180))

            Text("리버스 장기")
                .font(.system(size: 42, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)

            Text("지는 법을 아는 사람이 이깁니다")
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: - 메뉴

    private var menu: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuRow(title: "배우기", detail: "일곱 개의 미션으로 규칙 익히기") {
                TutorialView()
            }
            menuRow(title: "컴퓨터 대전", detail: "혼자서 한 판") {
                GameScreen(mode: .vsBot(botLevel))
            }

            // 난이도: 텍스트 토글
            HStack(spacing: 20) {
                ForEach(BotLevel.allCases) { level in
                    Button {
                        botLevel = level
                    } label: {
                        Text(level.localizedName)
                            .font(.system(.subheadline, weight: botLevel == level ? .bold : .regular))
                            .foregroundStyle(botLevel == level ? Theme.accent : Theme.inkSoft)
                            .overlay(alignment: .bottom) {
                                if botLevel == level {
                                    Rectangle()
                                        .fill(Theme.accent)
                                        .frame(height: 2)
                                        .offset(y: 4)
                                }
                            }
                    }
                }
                Spacer()
            }
            .padding(.leading, 2)
            .padding(.top, 2)
            .padding(.bottom, 18)

            menuRow(title: "함께 하기", detail: "한 기기로 번갈아 두기") {
                GameScreen(mode: .twoPlayer)
            }
            menuRow(title: "온라인 대전", detail: "방코드로 친구와 대결") {
                OnlineScreen()
            }
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }

    private func menuRow<Destination: View>(
        title: LocalizedStringKey, detail: LocalizedStringKey,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            NavigationLink {
                destination()
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 27, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.vertical, 18)
                .contentShape(Rectangle())
            }
        }
    }
}

// MARK: - 규칙 시트

struct RulesSheet: View {
    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("규칙 한 장")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 12) {
                        ruleLine("한(漢)이 먼저 둡니다. 배치는 양쪽 모두 마상상마입니다.")
                        ruleLine("궁만 남기고 모든 기물을 잃으면 승리합니다.")
                        ruleLine("잡을 수 있는 수가 있으면 반드시 잡아야 합니다. 단, 차의 캡처는 2칸 이내일 때만 강제입니다.")
                        ruleLine("장군 규칙은 그대로 — 장군 피하기가 강제 캡처보다 우선합니다.")
                        ruleLine("외통수를 당한 쪽이 이깁니다.")
                        ruleLine("장군이 아닌데 궁밖에 움직일 수 없다면, 그것도 승리입니다. (외딴 섬)")
                        ruleLine("두 궁이 사이에 아무것도 없이 마주 보게 만드는 수(빅장)는 둘 수 없습니다. 한수쉼도 없습니다.")
                        ruleLine("캡처 없이 50수가 지나면 점수 판정 — 남은 기물 점수가 낮은 쪽이 이깁니다. 같으면 무승부.")
                        ruleLine("둘 수가 없을 때와 같은 국면이 세 번 반복될 때는 무승부입니다.")
                    }

                    Text("기물 이동")
                        .font(.system(.headline, design: .serif, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 10) {
                        pieceLine(.general, "궁성 안에서 선을 따라 한 칸. 궁성 밖으로 나갈 수 없습니다.")
                        pieceLine(.advisor, "궁과 같습니다.")
                        pieceLine(.chariot, "가로·세로로 원하는 만큼. 궁성 안에서는 대각선도.")
                        pieceLine(.cannon, "반드시 기물 하나를 넘어서 움직이고 잡습니다. 포는 넘을 수도, 잡을 수도 없습니다.")
                        pieceLine(.horse, "한 칸 직진 후 한 칸 대각선. 첫 칸이 막히면 못 갑니다.")
                        pieceLine(.elephant, "한 칸 직진 후 두 칸 대각선. 지나는 칸이 막히면 못 갑니다.")
                        pieceLine(.soldier, "앞이나 옆으로 한 칸. 상대 궁성 안에서는 대각선 앞으로도.")
                        Text("점수: 차 13 · 포 7 · 마 5 · 상 3 · 사 3 · 졸 2")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 28)
            }
        }
        .presentationDetents([.large])
    }

    private func ruleLine(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("—")
                .foregroundStyle(Theme.accent)
                .font(.system(.body, weight: .bold))
            Text(text)
                .font(.system(.callout))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pieceLine(_ kind: PieceKind, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .center, spacing: 12) {
            PieceView(piece: Piece(side: .han, kind: kind), cell: 34)
                .frame(width: 34, height: 34)
            Text(text)
                .font(.system(.callout))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
