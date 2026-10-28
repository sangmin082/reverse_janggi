import Foundation

/// 튜토리얼 미션 배치. 모든 미션은 한(사람)이 둘 차례로 시작한다.
/// 배치의 성질(정답이 유일한지 등)은 엔진 테스트에서 검증한다.
enum TutorialPositions {
    private static func sq(_ f: Int, _ r: Int) -> Square { SquareUtil.make(file: f, rank: r) }
    private static func cho(_ k: PieceKind) -> Piece { Piece(side: .cho, kind: k) }
    private static func han(_ k: PieceKind) -> Piece { Piece(side: .han, kind: k) }

    /// 1. 잡을 수 있으면 잡아야 — 병이 졸을 잡는 수가 유일한 합법수
    static let forcedCapture = Board.custom([
        (4, 8, han(.general)), (0, 9, han(.chariot)), (3, 5, han(.soldier)),
        (5, 1, cho(.general)), (3, 4, cho(.soldier)),
    ])
    static let forcedCaptureAnswer = Move(from: sq(3, 5), to: sq(3, 4))

    /// 2. 차는 2칸까지만 강제 — 5칸 떨어진 졸은 잡지 않아도 된다
    static let chariotRange = Board.custom([
        (4, 8, han(.general)), (0, 8, han(.chariot)), (6, 6, han(.soldier)),
        (3, 1, cho(.general)), (0, 3, cho(.soldier)), (8, 3, cho(.soldier)),
    ])
    static let chariotRangeCapture = Move(from: sq(0, 8), to: sq(0, 3))

    /// 3. 포는 넘어서 — 병을 넘어 마를 잡는 수가 유일한 합법수
    static let cannon = Board.custom([
        (4, 8, han(.general)), (1, 7, han(.cannon)), (1, 5, han(.soldier)),
        (5, 1, cho(.general)), (1, 2, cho(.horse)),
    ])
    static let cannonAnswer = Move(from: sq(1, 7), to: sq(1, 2))

    /// 4. 장군이 먼저 — 병으로 잡을 수 있지만 궁을 피해야 한다
    static let check = Board.custom([
        (4, 8, han(.general)), (0, 5, han(.soldier)),
        (4, 0, cho(.general)), (4, 3, cho(.chariot)), (0, 4, cho(.soldier)),
    ])

    /// 5. 빅장 금지 — 병이 옆으로 비키면 두 궁이 마주 본다
    static let bikjang = Board.custom([
        (4, 8, han(.general)), (4, 5, han(.soldier)),
        (4, 1, cho(.general)), (8, 3, cho(.soldier)),
    ])
    static let bikjangSoldier = sq(4, 5)

    /// 6. 버리는 자가 이긴다 — 마지막 병을 졸 앞에 내밀면 초는 잡을 수밖에 없다
    static let sacrifice = Board.custom([
        (5, 9, han(.general)), (2, 5, han(.soldier)),
        (3, 0, cho(.general)), (2, 3, cho(.soldier)), (8, 3, cho(.soldier)),
    ])
    static let sacrificeAnswer = Move(from: sq(2, 5), to: sq(2, 4))
}
