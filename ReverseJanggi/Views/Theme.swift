import SwiftUI

/// 앱 전역 팔레트 — 페이퍼 & 잉크. 한(漢)은 주홍, 초(楚)는 청록 먹색.
/// 다크모드 분기 없이 하나의 톤으로 고정한 보드게임 룩.
enum Theme {
    static let paper = Color(red: 0.957, green: 0.945, blue: 0.902)     // 배경
    static let ink = Color(red: 0.106, green: 0.118, blue: 0.149)       // 본문
    static let inkSoft = Color(red: 0.106, green: 0.118, blue: 0.149).opacity(0.55)
    static let accent = Color(red: 0.776, green: 0.263, blue: 0.169)    // 주홍
    static let hairline = Color(red: 0.106, green: 0.118, blue: 0.149).opacity(0.18)

    static let board = Color(red: 0.925, green: 0.871, blue: 0.741)    // 장기판 나무결 톤
    static let boardLine = Color(red: 0.106, green: 0.118, blue: 0.149).opacity(0.78)
    static let boardSelected = accent.opacity(0.35)
    static let boardLastMove = Color(red: 0.84, green: 0.62, blue: 0.20).opacity(0.45)

    static let han = accent
    static let cho = Color(red: 0.090, green: 0.353, blue: 0.369)      // 청록
    static let pieceFace = Color(red: 0.985, green: 0.972, blue: 0.937)

    static func color(for side: Side) -> Color {
        side == .han ? han : cho
    }
}

/// 플랫 패널: 헤어라인 테두리, 그림자 없음
struct PanelBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Theme.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Theme.ink, lineWidth: 1.5)
                    )
            )
    }
}

extension View {
    func panelStyle() -> some View { modifier(PanelBackground()) }
}

/// 본문 버튼: 잉크 테두리의 플랫 버튼
struct InkButtonStyle: ButtonStyle {
    var filled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(filled ? Theme.paper : Theme.ink)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(filled ? Theme.ink : .clear)
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Theme.ink, lineWidth: 1.5))
            )
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
