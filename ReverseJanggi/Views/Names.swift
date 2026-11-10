import Foundation

// 엔진 타입의 표시 이름. 엔진은 Linux에서도 테스트하므로 현지화 코드는 앱 쪽에 둔다.

extension Side {
    var localizedName: String {
        self == .cho ? String(localized: "초") : String(localized: "한")
    }
}

extension PieceKind {
    var localizedName: String {
        switch self {
        case .general: return String(localized: "궁")
        case .chariot: return String(localized: "차")
        case .cannon: return String(localized: "포")
        case .horse: return String(localized: "마")
        case .elephant: return String(localized: "상")
        case .advisor: return String(localized: "사")
        case .soldier: return String(localized: "졸")
        }
    }
}

extension BotLevel {
    var localizedName: String {
        switch self {
        case .easy: return String(localized: "쉬움")
        case .normal: return String(localized: "보통")
        case .hard: return String(localized: "어려움")
        }
    }
}

extension GameResult.WinReason {
    var localizedName: String {
        switch self {
        case .onlyGeneralLeft: return String(localized: "궁만 남음")
        case .checkmated: return String(localized: "외통")
        case .loneIsland: return String(localized: "외딴 섬")
        case .lowerScore: return String(localized: "점수 판정")
        }
    }
}

extension GameResult.DrawReason {
    var localizedName: String {
        switch self {
        case .stalemate: return String(localized: "수 없음")
        case .threefoldRepetition: return String(localized: "3회 동형")
        case .fiftyMoveRule: return String(localized: "50수 규칙")
        }
    }
}
