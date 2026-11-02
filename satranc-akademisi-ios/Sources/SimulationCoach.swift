import Foundation
import ChessKit

/// Every accepted move is inspected using the real ChessKit position.
/// This is a transparent, rules-based teaching aid, NOT Stockfish, a cloud AI,
/// an Elo strength estimate, or a guarantee of the objectively best move.
struct CoachVerdict {
    let title: String
    let explanation: String
    let caution: String?
    let meetsGoal: Bool
    let san: String
    let uci: String
}

struct SimulationMoveReview: Identifiable {
    let id: Int
    let player: String
    let moveName: String
    let notation: String
    let verdict: CoachVerdict
    let fenAfter: String
}

enum ChessMoveCoach {
    static func evaluate(game: Game, move: Move, scenarioBeat: SimulationBeat? = nil) -> CoachVerdict {
        let uci = move.description.lowercased()
        guard game.legalMoves.contains(move) else {
            return CoachVerdict(
                title: "Bu hamle mümkün değil",
                explanation: "Taşın gidebileceği kareler yeşil işaretlenir. Önce taşını, sonra uygun hedefi seç.",
                caution: nil, meetsGoal: false, san: uci, uci: uci
            )
        }

        let san = SanSerialization().san(for: move, in: game)
        let piece = game.position.board[move.from]
        let target = game.position.board[move.to]
        let pawnCapture = piece?.kind == .pawn && move.from.file != move.to.file
        let capture = target != nil || pawnCapture
        let capturedName = target.map { pieceName($0.kind) } ?? (pawnCapture ? "Piyon" : "")
        let originallyInCheck = game.isCheck

        let after = game.deepCopy()
        after.make(move: move)

        let meetsGoal = scenarioBeat.map { $0.uci.lowercased() == uci } ?? false
        var title = meetsGoal ? "Senaryonun hedefi tamam!" : "Hamleni inceleyelim"
        var details: [String] = []
        var warnings: [String] = []

        if let beat = scenarioBeat {
            if meetsGoal {
                details.append(beat.coachExplanation)
            } else {
                details.append("Bu hamle satranç kurallarına uygun; ancak senaryodaki hedef başka: \(beat.purpose)")
                details.append("Sorun değil: yaptığın hamleyi yine analiz ettim. İstersen senaryoyu baştan deneyebilirsin.")
            }
        }

        let pieceKind = piece?.kind
        if capture {
            details.append(capturedName.isEmpty ? "Rakip taş aldın." : "Rakibin \(capturedName.lowercased()) taşını aldın.")
        } else if pieceKind == .pawn {
            details.append("Piyonla ilerledin. Piyonlar düz gider, çapraz taş alır.")
        } else if pieceKind == .knight || pieceKind == .bishop {
            details.append("\(pieceName(pieceKind).capitalized) geliştirdin. Açılışta hafif taşları kullanmak çoğu zaman iyidir.")
        } else if pieceKind == .king && abs(move.from.file - move.to.file) == 2 {
            details.append("Rok yaptın: şahını daha güvenli bir noktaya götürdün ve kaleni geliştirdin.")
        }

        if after.isMate {
            title = "ŞAH MAT!"
            details.append("Rakibin şahı saldırı altında ve kurtulabileceği yasal hamle kalmadı. Oyun bitti.")
        } else if after.legalMoves.isEmpty {
            title = "Pat — beraberlik"
            details.append("Rakip şah çekilmiyor ama yapabileceği yasal hamle yok. Bu mat değildir, oyun berabere biter.")
        } else if after.isCheck {
            details.append("Şah çektin! Rakibin şimdi bu tehdidi çözmek zorunda.")
        }

        if originallyInCheck && !after.isMate {
            details.append("Önce kendi şahına yapılan tehdidi giderdin. Şah çekildiğinde bunu çözmen zorunludur.")
        }

        if !after.isMate && !after.legalMoves.isEmpty {
            let movedPiece = after.position.board[move.to]
            let capturableImmediately = movedPiece != nil && after.legalMoves.contains {
                $0.to == move.to && after.position.board[$0.to] != nil
            }
            if capturableImmediately {
                warnings.append("Dikkat: Rakip, az önce oynadığın \(pieceName(pieceKind).lowercased()) taşını sonraki hamlede alabilecek yasal bir hamleye sahip. Bu her zaman hata demek değildir; alışverişi hesapla.")
            }

            // One-ply threat detection. We warn about a direct forced mate-in-one
            // opportunity, but we do not claim to have searched the whole game.
            if after.legalMoves.contains(where: { reply in
                let probe = after.deepCopy()
                probe.make(move: reply)
                return probe.isMate
            }) {
                warnings.append("Önemli: Rakibin bir sonraki hamlede mat yapabileceği bir devam yolu var. Şah güvenliğine bak!")
            }
        }

        if scenarioBeat == nil && !after.isMate && !after.isCheck && !capture && warnings.isEmpty {
            details.append("Hamle yasal. Bir sonraki adımda rakibin cevaplarını ve tehdit edilen taşları düşün.")
        }

        if details.isEmpty {
            details.append("Bu hamlede hangi kareleri kontrol ettiğine ve rakibin tehditlerine bak.")
        }

        return CoachVerdict(
            title: title,
            explanation: details.joined(separator: "\n"),
            caution: warnings.isEmpty ? nil : warnings.joined(separator: "\n"),
            meetsGoal: meetsGoal,
            san: san,
            uci: uci
        )
    }

    private static func pieceName(_ kind: PieceKind?) -> String {
        switch kind {
        case .pawn: return "Piyon"
        case .knight: return "At"
        case .bishop: return "Fil"
        case .rook: return "Kale"
        case .queen: return "Vezir"
        case .king: return "Şah"
        case nil: return "Taş"
        }
    }
}

/// Reproducible one-ply bot for scenario detours and freestyle exercises.
/// It selects ONLY ChessKit-legal moves; its playing strength is elementary.
enum ScenarioOpponent {
    static func choose(in game: Game) -> Move? {
        let choices = game.legalMoves
        guard !choices.isEmpty else { return nil }
        let values: [PieceKind: Int] = [
            .pawn: 1, .knight: 3, .bishop: 3, .rook: 5, .queen: 9, .king: 0
        ]

        // A simple rule-based opponent: mate first, otherwise win a piece or
        // develop. Keep it weaker than an engine so beginners can practice.
        return choices.max { a, b in
            score(game: game, move: a, values: values) <
                score(game: game, move: b, values: values)
        }
    }

    private static func score(game: Game, move: Move, values: [PieceKind: Int]) -> Int {
        let taken = game.position.board[move.to]
        var result = taken.map { (values[$0.kind] ?? 0) * 10 } ?? 0
        let actor = game.position.board[move.from]?.kind
        let after = game.deepCopy()
        after.make(move: move)
        if after.isMate { return 100_000 }
        if after.isCheck { result += 5 }
        if after.legalMoves.isEmpty { result -= 40 } // Don't reward stalemate.
        if actor == .knight || actor == .bishop {
            if (2...5).contains(move.to.rank) && (2...5).contains(move.to.file) {
                result += 2
            }
        }
        if after.legalMoves.contains(where: { $0.to == move.to }) {
            result -= (values[actor ?? .pawn] ?? 1) * 3
        }
        return result
    }
}
