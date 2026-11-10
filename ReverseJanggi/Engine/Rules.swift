import Foundation

/// 리버스 장기 규칙 엔진.
///
/// 규칙 요약 (자세한 내용은 RULES.md):
/// - 한이 선공. 배치는 양 진영 모두 마상상마 고정
/// - 기물 이동은 일반 장기와 동일 (궁성 대각선, 포 넘기, 마·상 멱 포함)
/// - 장군 규칙은 일반 장기와 동일: 자기 궁을 장군 상태로 두는 수는 둘 수 없다
/// - 빅장 금지: 두 궁이 같은 줄에서 사이에 아무것도 없이 마주 보게 만드는 수는 둘 수 없다
/// - 한수쉼(패스) 없음
/// - 강제 캡처: 잡을 수 있는 합법수가 있으면 그중 하나를 반드시 둬야 한다.
///   단, 차의 캡처는 2칸 이내일 때만 "강제" 대상이다
///   (2칸 넘는 차 캡처는 강제 캡처가 없을 때 자유롭게 둘 수 있는 일반 수)
/// - 장군 피하기가 강제 캡처보다 우선한다 (합법수 필터가 먼저 적용되므로 자동 충족)
enum Rules {

    /// 차의 캡처가 강제 대상이 되는 최대 거리
    static let chariotForcedCaptureRange = 2

    // MARK: - 공격 판정

    /// `side`가 `target` 칸을 잡을 수 있는가 (장군 판정용)
    static func isAttacked(_ target: Square, by side: Side, on board: Board) -> Bool {
        let tf = SquareUtil.file(target)
        let tr = SquareUtil.rank(target)

        func isEnemy(_ f: Int, _ r: Int, _ kind: PieceKind) -> Bool {
            guard let p = board.piece(file: f, rank: r) else { return false }
            return p.side == side && p.kind == kind
        }
        func isEmpty(_ f: Int, _ r: Int) -> Bool {
            SquareUtil.isValid(file: f, rank: r) && board.piece(file: f, rank: r) == nil
        }

        // 차 · 포: 직선 및 궁성 대각선
        let targetIsCannon = board[target]?.kind == .cannon
        for (df, dr) in SquareUtil.orthogonal + SquareUtil.diagonal {
            let isDiagonal = df != 0 && dr != 0
            var f = tf, r = tr
            var screenFound = false
            while true {
                if isDiagonal {
                    guard SquareUtil.hasPalaceDiagonal(file: f, rank: r, df: df, dr: dr) else { break }
                }
                f += df
                r += dr
                guard SquareUtil.isValid(file: f, rank: r) else { break }
                guard let p = board.piece(file: f, rank: r) else { continue }
                if !screenFound {
                    if p.side == side && p.kind == .chariot { return true }
                    // 포는 포를 넘을 수 없다
                    if p.kind == .cannon { break }
                    screenFound = true
                } else {
                    // 포는 포를 잡을 수 없다
                    if p.side == side && p.kind == .cannon && !targetIsCannon { return true }
                    break
                }
            }
        }

        // 마: 공격하는 마는 T - (2o + p), 멱 자리는 T - o - p
        for (ox, oy) in SquareUtil.orthogonal {
            for s in [-1, 1] {
                let px = ox == 0 ? s : 0, py = oy == 0 ? s : 0
                if isEnemy(tf - 2 * ox - px, tr - 2 * oy - py, .horse),
                   isEmpty(tf - ox - px, tr - oy - py) { return true }
            }
        }

        // 상: 공격하는 상은 T - (3o + 2p), 멱 자리는 T - 2o - 2p 와 T - o - p
        for (ox, oy) in SquareUtil.orthogonal {
            for s in [-1, 1] {
                let px = ox == 0 ? s : 0, py = oy == 0 ? s : 0
                if isEnemy(tf - 3 * ox - 2 * px, tr - 3 * oy - 2 * py, .elephant),
                   isEmpty(tf - 2 * ox - 2 * px, tr - 2 * oy - 2 * py),
                   isEmpty(tf - ox - px, tr - oy - py) { return true }
            }
        }

        // 졸/병: 뒤에서 전진, 옆에서 옆걸음, 궁성 대각선 전진
        let fwd = side.forward
        if isEnemy(tf, tr - fwd, .soldier) || isEnemy(tf - 1, tr, .soldier) || isEnemy(tf + 1, tr, .soldier) {
            return true
        }
        for dx in [-1, 1] {
            let sf = tf - dx, sr = tr - fwd
            if isEnemy(sf, sr, .soldier),
               SquareUtil.hasPalaceDiagonal(file: sf, rank: sr, df: dx, dr: fwd) { return true }
        }

        // 궁 · 사: 자기 궁성 안에서 한 칸
        for (df, dr) in SquareUtil.orthogonal + SquareUtil.diagonal {
            let sf = tf - df, sr = tr - dr
            guard let p = board.piece(file: sf, rank: sr), p.side == side,
                  p.kind == .general || p.kind == .advisor else { continue }
            let sq = SquareUtil.make(file: sf, rank: sr)
            guard SquareUtil.isInPalace(target, of: side), SquareUtil.isInPalace(sq, of: side) else { continue }
            if df == 0 || dr == 0 || SquareUtil.hasPalaceDiagonal(file: sf, rank: sr, df: df, dr: dr) {
                return true
            }
        }
        return false
    }

    /// 두 궁이 같은 세로줄에서 사이에 아무것도 없이 마주 보는가 (빅장)
    static func generalsFacing(on board: Board) -> Bool {
        guard let a = board.generalSquare(of: .cho), let b = board.generalSquare(of: .han),
              SquareUtil.file(a) == SquareUtil.file(b) else { return false }
        let file = SquareUtil.file(a)
        let lo = min(SquareUtil.rank(a), SquareUtil.rank(b))
        let hi = max(SquareUtil.rank(a), SquareUtil.rank(b))
        for r in (lo + 1)..<hi where board.piece(file: file, rank: r) != nil {
            return false
        }
        return true
    }

    /// 장군 상태인가
    static func isInCheck(_ side: Side, on board: Board) -> Bool {
        guard let general = board.generalSquare(of: side) else { return false }
        return isAttacked(general, by: side.opposite, on: board)
    }

    /// 이 진영의 궁이 위험한가 — 장군이거나 빅장. 이런 상태로 끝나는 수는 둘 수 없다.
    static func isGeneralExposed(_ side: Side, on board: Board) -> Bool {
        isInCheck(side, on: board) || generalsFacing(on: board)
    }

    // MARK: - 수 생성

    /// 장군·빅장 규칙만 반영한 합법수 (강제 캡처 미적용)
    static func movesIgnoringForcedCapture(for side: Side, on board: Board) -> [Move] {
        var moves: [Move] = []
        moves.reserveCapacity(64)
        for (sq, piece) in board.pieces(of: side) {
            appendPseudoMoves(for: piece, at: sq, on: board, into: &moves)
        }
        return moves.filter { !isGeneralExposed(side, on: board.applying($0)) }
    }

    /// 강제 캡처까지 반영한 최종 합법수
    static func legalMoves(for side: Side, on board: Board) -> [Move] {
        let legal = movesIgnoringForcedCapture(for: side, on: board)
        let forced = legal.filter { isForcedCapture($0, on: board) }
        return forced.isEmpty ? legal : forced
    }

    /// 이 수가 "강제 캡처" 대상인가
    static func isForcedCapture(_ move: Move, on board: Board) -> Bool {
        guard board[move.to] != nil else { return false }
        if board[move.from]?.kind == .chariot {
            return SquareUtil.chebyshev(move.from, move.to) <= chariotForcedCaptureRange
        }
        return true
    }

    /// 현재 진영의 합법수 중 강제 캡처가 존재하는가 (UI 안내용)
    static func hasForcedCapture(for side: Side, on board: Board) -> Bool {
        movesIgnoringForcedCapture(for: side, on: board).contains { isForcedCapture($0, on: board) }
    }

    /// 한 기물의 의사 합법수 (장군 여부 미확인)
    static func appendPseudoMoves(for piece: Piece, at sq: Square, on board: Board, into moves: inout [Move]) {
        let f = SquareUtil.file(sq)
        let r = SquareUtil.rank(sq)

        func canLand(_ nf: Int, _ nr: Int) -> Bool {
            guard SquareUtil.isValid(file: nf, rank: nr) else { return false }
            return board.piece(file: nf, rank: nr)?.side != piece.side
        }
        func add(_ nf: Int, _ nr: Int) {
            moves.append(Move(from: sq, to: SquareUtil.make(file: nf, rank: nr)))
        }
        func isEmpty(_ nf: Int, _ nr: Int) -> Bool {
            SquareUtil.isValid(file: nf, rank: nr) && board.piece(file: nf, rank: nr) == nil
        }

        switch piece.kind {
        case .general, .advisor:
            // 자기 궁성 안에서 선을 따라 한 칸
            for (df, dr) in SquareUtil.orthogonal + SquareUtil.diagonal {
                let nf = f + df, nr = r + dr
                guard SquareUtil.isValid(file: nf, rank: nr),
                      SquareUtil.isInPalace(SquareUtil.make(file: nf, rank: nr), of: piece.side) else { continue }
                if df != 0 && dr != 0 && !SquareUtil.hasPalaceDiagonal(file: f, rank: r, df: df, dr: dr) { continue }
                if canLand(nf, nr) { add(nf, nr) }
            }

        case .chariot, .cannon:
            for (df, dr) in SquareUtil.orthogonal + SquareUtil.diagonal {
                let isDiagonal = df != 0 && dr != 0
                var nf = f, nr = r
                var screenFound = false
                while true {
                    if isDiagonal {
                        guard SquareUtil.hasPalaceDiagonal(file: nf, rank: nr, df: df, dr: dr) else { break }
                    }
                    nf += df
                    nr += dr
                    guard SquareUtil.isValid(file: nf, rank: nr) else { break }
                    let occupant = board.piece(file: nf, rank: nr)

                    if piece.kind == .chariot {
                        if let occupant {
                            if occupant.side != piece.side { add(nf, nr) }
                            break
                        }
                        add(nf, nr)
                    } else if !screenFound {
                        // 포: 넘을 기물(포가 아닌)을 찾을 때까지 이동 불가
                        guard let occupant else { continue }
                        if occupant.kind == .cannon { break }
                        screenFound = true
                    } else {
                        if let occupant {
                            if occupant.side != piece.side && occupant.kind != .cannon { add(nf, nr) }
                            break
                        }
                        add(nf, nr)
                    }
                }
            }

        case .horse:
            // 직선 한 칸(멱) → 대각 한 칸
            for (ox, oy) in SquareUtil.orthogonal where isEmpty(f + ox, r + oy) {
                for s in [-1, 1] {
                    let px = ox == 0 ? s : 0, py = oy == 0 ? s : 0
                    let nf = f + 2 * ox + px, nr = r + 2 * oy + py
                    if canLand(nf, nr) { add(nf, nr) }
                }
            }

        case .elephant:
            // 직선 한 칸(멱) → 대각 두 칸 (중간 멱 포함)
            for (ox, oy) in SquareUtil.orthogonal where isEmpty(f + ox, r + oy) {
                for s in [-1, 1] {
                    let px = ox == 0 ? s : 0, py = oy == 0 ? s : 0
                    guard isEmpty(f + 2 * ox + px, r + 2 * oy + py) else { continue }
                    let nf = f + 3 * ox + 2 * px, nr = r + 3 * oy + 2 * py
                    if canLand(nf, nr) { add(nf, nr) }
                }
            }

        case .soldier:
            let fwd = piece.side.forward
            for (df, dr) in [(0, fwd), (-1, 0), (1, 0)] where canLand(f + df, r + dr) {
                add(f + df, r + dr)
            }
            // 상대 궁성 안에서는 대각선(전진 방향)으로도
            for df in [-1, 1] where SquareUtil.hasPalaceDiagonal(file: f, rank: r, df: df, dr: fwd) {
                if canLand(f + df, r + fwd) { add(f + df, r + fwd) }
            }
        }
    }
}
