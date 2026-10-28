import Foundation

// MARK: - 기본 타입

/// 진영. 초(楚)는 데이터상 아래쪽(rank 0~3)에서 위로, 한(漢)은 위쪽(rank 6~9)에서 아래로 진행한다.
/// 리버스 장기는 한이 선공이다.
enum Side: String, Codable, Hashable, CaseIterable {
    case cho, han

    var opposite: Side { self == .cho ? .han : .cho }

    /// 졸/병의 전진 방향 (rank 증감)
    var forward: Int { self == .cho ? 1 : -1 }
}

enum PieceKind: String, Codable, Hashable, CaseIterable {
    case general, chariot, cannon, horse, elephant, advisor, soldier

    /// 전통 장기 점수 (참고·평가용)
    var value: Int {
        switch self {
        case .general: return 0
        case .chariot: return 13
        case .cannon: return 7
        case .horse: return 5
        case .elephant: return 3
        case .advisor: return 3
        case .soldier: return 2
        }
    }
}

struct Piece: Hashable, Codable {
    let side: Side
    let kind: PieceKind

    /// 말에 새기는 한자. 궁은 진영 이름(楚/漢), 졸은 초=卒 / 한=兵
    var hanja: String {
        switch kind {
        case .general: return side == .cho ? "楚" : "漢"
        case .chariot: return "車"
        case .cannon: return "包"
        case .horse: return "馬"
        case .elephant: return "象"
        case .advisor: return "士"
        case .soldier: return side == .cho ? "卒" : "兵"
        }
    }
}

/// 0..<90. file = sq % 9 (왼쪽=0), rank = sq / 9 (초 진영 끝줄 = 0)
typealias Square = Int

enum SquareUtil {
    static let files = 9
    static let ranks = 10
    static let count = files * ranks

    static func make(file: Int, rank: Int) -> Square { rank * files + file }
    static func file(_ sq: Square) -> Int { sq % files }
    static func rank(_ sq: Square) -> Int { sq / files }
    static func isValid(file: Int, rank: Int) -> Bool {
        file >= 0 && file < files && rank >= 0 && rank < ranks
    }
    static func chebyshev(_ a: Square, _ b: Square) -> Int {
        max(abs(file(a) - file(b)), abs(rank(a) - rank(b)))
    }

    // MARK: 궁성

    /// 궁성 안인가 (초: rank 0~2, 한: rank 7~9, file 3~5)
    static func isInPalace(file: Int, rank: Int) -> Bool {
        (3...5).contains(file) && ((0...2).contains(rank) || (7...9).contains(rank))
    }

    static func isInPalace(_ sq: Square) -> Bool {
        isInPalace(file: file(sq), rank: rank(sq))
    }

    /// 특정 진영의 궁성 안인가
    static func isInPalace(_ sq: Square, of side: Side) -> Bool {
        let r = rank(sq)
        let inRanks = side == .cho ? (0...2).contains(r) : (7...9).contains(r)
        return inRanks && (3...5).contains(file(sq))
    }

    static func isPalaceCenter(file: Int, rank: Int) -> Bool {
        file == 4 && (rank == 1 || rank == 8)
    }

    /// (file, rank)에서 (df, dr) 대각 방향으로 궁성 대각선이 이어져 있는가.
    /// 궁성 대각선은 네 귀퉁이와 중앙을 잇는 선뿐이다.
    static func hasPalaceDiagonal(file: Int, rank: Int, df: Int, dr: Int) -> Bool {
        let nf = file + df, nr = rank + dr
        guard isInPalace(file: file, rank: rank), isInPalace(file: nf, rank: nr) else { return false }
        // 같은 궁성 안이어야 함 (rank 2→3 같은 경계 넘기는 isInPalace에서 이미 걸러짐)
        return isPalaceCenter(file: file, rank: rank) || isPalaceCenter(file: nf, rank: nr)
    }

    static let orthogonal = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    static let diagonal = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
}

struct Move: Hashable, Codable {
    let from: Square
    let to: Square
}

// MARK: - 보드

struct Board: Hashable {
    /// 90칸. nil = 빈 칸
    private(set) var cells: [Piece?]

    init(cells: [Piece?]) {
        precondition(cells.count == SquareUtil.count)
        self.cells = cells
    }

    static func empty() -> Board {
        Board(cells: [Piece?](repeating: nil, count: SquareUtil.count))
    }

    /// 리버스 장기 초기 배치 — 양 진영 모두 차·마·상·사·_·사·상·마·차 (마상상마)
    static func initial() -> Board {
        var board = Board.empty()
        let back: [PieceKind?] = [.chariot, .horse, .elephant, .advisor, nil, .advisor, .elephant, .horse, .chariot]
        for side in Side.allCases {
            let home = side == .cho ? 0 : 9
            let f = side.forward
            for (file, kind) in back.enumerated() {
                if let kind { board[SquareUtil.make(file: file, rank: home)] = Piece(side: side, kind: kind) }
            }
            board[SquareUtil.make(file: 4, rank: home + f)] = Piece(side: side, kind: .general)
            board[SquareUtil.make(file: 1, rank: home + 2 * f)] = Piece(side: side, kind: .cannon)
            board[SquareUtil.make(file: 7, rank: home + 2 * f)] = Piece(side: side, kind: .cannon)
            for file in stride(from: 0, through: 8, by: 2) {
                board[SquareUtil.make(file: file, rank: home + 3 * f)] = Piece(side: side, kind: .soldier)
            }
        }
        return board
    }

    /// 튜토리얼 등 임의 배치를 위한 생성자. (file, rank, 기물) 목록
    static func custom(_ placements: [(Int, Int, Piece)]) -> Board {
        var board = Board.empty()
        for (file, rank, piece) in placements {
            board[SquareUtil.make(file: file, rank: rank)] = piece
        }
        return board
    }

    subscript(_ sq: Square) -> Piece? {
        get { cells[sq] }
        set { cells[sq] = newValue }
    }

    func piece(file: Int, rank: Int) -> Piece? {
        guard SquareUtil.isValid(file: file, rank: rank) else { return nil }
        return cells[SquareUtil.make(file: file, rank: rank)]
    }

    func pieces(of side: Side) -> [(Square, Piece)] {
        var result: [(Square, Piece)] = []
        for sq in 0..<SquareUtil.count {
            if let p = cells[sq], p.side == side { result.append((sq, p)) }
        }
        return result
    }

    func generalSquare(of side: Side) -> Square? {
        for sq in 0..<SquareUtil.count {
            if let p = cells[sq], p.side == side, p.kind == .general { return sq }
        }
        return nil
    }

    func material(of side: Side) -> Int {
        pieces(of: side).reduce(0) { $0 + $1.1.kind.value }
    }

    /// 궁을 제외한 기물 수
    func nonGeneralCount(of side: Side) -> Int {
        var n = 0
        for p in cells {
            if let p, p.side == side, p.kind != .general { n += 1 }
        }
        return n
    }

    mutating func apply(_ move: Move) {
        cells[move.to] = cells[move.from]
        cells[move.from] = nil
    }

    func applying(_ move: Move) -> Board {
        var b = self
        b.apply(move)
        return b
    }

    /// 동형 반복 판정용 위치 키
    func positionKey(sideToMove: Side) -> String {
        var chars: [Character] = [sideToMove == .cho ? "c" : "h"]
        chars.reserveCapacity(SquareUtil.count + 1)
        for p in cells {
            guard let p else { chars.append("."); continue }
            let c: Character
            switch p.kind {
            case .general: c = "g"
            case .chariot: c = "r"
            case .cannon: c = "c"
            case .horse: c = "h"
            case .elephant: c = "e"
            case .advisor: c = "a"
            case .soldier: c = "s"
            }
            chars.append(p.side == .cho ? Character(c.uppercased()) : c)
        }
        return String(chars)
    }
}
