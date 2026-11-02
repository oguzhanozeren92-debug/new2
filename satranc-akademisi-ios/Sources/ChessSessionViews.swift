import SwiftUI
import UIKit
import ChessboardKit
import ChessKit

struct ChessLessonSession: View {
    let lesson: TrainingLesson
    @State private var boardModel: ChessboardModel
    @State private var stepIndex = 0
    @State private var feedback = ""
    @State private var finished = false
    @AppStorage("academy.completed") private var completed = ""

    init(lesson: TrainingLesson) {
        self.lesson = lesson
        _boardModel = State(initialValue: ChessboardModel(fen: lesson.fen, perspective: .white))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 13) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("HAMLE HOCASI", systemImage: "graduationcap.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.gold)
                    Text(lesson.title)
                        .font(.system(.title2, design: .serif, weight: .bold))
                    Text(lesson.description).font(.body).foregroundStyle(.secondary)
                    Text(finished ? "Ders tamamlandı." : lesson.goal)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))

                ProgressView(value: Double(stepIndex),
                             total: Double(max(lesson.steps.count, 1))).tint(Theme.gold)

                GeometryReader { proxy in
                    Chessboard(chessboardModel: boardModel)
                        .onMove { move, isLegal, from, to, lan, promotionPiece in
                            onMove(move: move, lan: lan, isLegal: isLegal)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.width)
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(5)
                .background(Theme.gold.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))

                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(finished ? Color.green.opacity(0.20) : Theme.surface,
                                    in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityAddTraits(.updatesFrequently)
                }

                if finished {
                    Label("Başardın!", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.gold).font(.headline)
                }
                HStack(spacing: 8) {
                    Button("↶ Yeniden") { restart() }
                        .buttonStyle(.bordered).frame(minHeight: 44)
                    Button("💡 İpucu") { showHint() }
                        .buttonStyle(.borderedProminent).tint(Theme.gold)
                        .foregroundStyle(.black).frame(minHeight: 44)
                        .disabled(finished)
                }
                Text("Ders yalnızca doğru hamle tahtada yapıldığında tamamlanır.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func onMove(move: Move, lan: String, isLegal: Bool) {
        guard !finished, stepIndex < lesson.steps.count else { return }
        guard isLegal else { feedback = "Bu satranç kurallarına uygun bir hamle değil."; return }
        let wanted = lesson.steps[stepIndex].uci
        let entered = lan.lowercased().filter { $0.isLetter || $0.isNumber }
        guard entered == wanted || (wanted.count == 4 && entered.hasPrefix(wanted)) else {
            feedback = "Bu hamle yasal ama hedef farklı: " + lesson.goal
            return
        }
        boardModel.game.make(move: move)
        withAnimation(.easeInOut(duration: 0.2)) {
            boardModel.setFen(FenSerialization.default.serialize(position: boardModel.game.position), lan: lan)
        }
        feedback = lesson.steps[stepIndex].explanation
        stepIndex += 1
        if stepIndex == lesson.steps.count { finish() }
        else { playDemonstration() }
    }

    private func playDemonstration() {
        while stepIndex < lesson.steps.count,
              boardModel.game.position.fen.split(separator: " ").dropFirst().first == "b" {
            let reply = lesson.steps[stepIndex]
            boardModel.game.make(move: reply.uci)
            withAnimation(.easeInOut(duration: 0.25)) {
                boardModel.setFen(FenSerialization.default.serialize(position: boardModel.game.position),
                                  lan: reply.uci)
            }
            feedback = "Siyah oynadı: " + reply.explanation
            stepIndex += 1
            if stepIndex == lesson.steps.count { finish() }
        }
    }

    private func finish() {
        finished = true
        var ids = Set(completed.split(separator: ",").map(String.init))
        ids.insert(lesson.id)
        completed = ids.sorted().joined(separator: ",")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func showHint() {
        guard stepIndex < lesson.steps.count else { return }
        let step = lesson.steps[stepIndex]
        let a = String(step.uci.prefix(2)), b = String(step.uci.dropFirst(2).prefix(2))
        feedback = "Önce " + a + ", sonra " + b + " karesine dokun."
        boardModel.clearHint()
        for square in [a, b] {
            guard let file = square.first?.asciiValue,
                  let rank = Int(String(square.last!)) else { continue }
            boardModel.hint(row: 8 - rank, column: Int(file) - 97)
        }
    }

    private func restart() {
        boardModel.setFen(lesson.fen)
        boardModel.clearHint()
        stepIndex = 0
        feedback = ""
        finished = false
    }
}

enum BotDifficulty: String, CaseIterable, Identifiable {
    case easy = "Kolay", medium = "Orta", hard = "Zor"
    var id: String { rawValue }
    var description: String {
        switch self {
        case .easy: return "Rastgele yasal hamle yapan başlangıç botu."
        case .medium: return "Taş kazanımına bakarak hamle seçer."
        case .hard: return "Rakibin bir yanıtını da hesaplar."
        }
    }
}

struct ChessBotSession: View {
    let difficulty: BotDifficulty
    @State private var boardModel = ChessboardModel(fen: AcademyCourse.initial, perspective: .white)
    @State private var feedback = "Beyaz taşlar senin. İlk hamleni yap."
    @State private var thinking = false
    @State private var gameOver = false
    @State private var turnToken = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "cpu").foregroundStyle(Theme.gold)
                    Text("Bilgisayar")
                    Spacer()
                    Text(difficulty.rawValue).foregroundStyle(Theme.gold)
                }
                .padding(12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                GeometryReader { proxy in
                    Chessboard(chessboardModel: boardModel)
                        .onMove { move, isLegal, from, to, lan, promotionPiece in
                            guard !thinking, !gameOver, isLegal else { return }
                            boardModel.game.make(move: move)
                            withAnimation {
                                boardModel.setFen(FenSerialization.default.serialize(position: boardModel.game.position), lan: lan)
                            }
                            endCheck()
                            if !gameOver { botTurn() }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.width)
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(5)
                .background(Theme.gold.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                Text(feedback)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(13)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                Button("Yeni Maç") { reset() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.gold)
                    .foregroundStyle(.black)
                    .frame(minHeight: 44)
                Text("Bot zorlukları eğitim amaçlıdır; resmî ELO puanları değildir.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(12).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(difficulty.rawValue + " Bot")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Black's advantage is positive. Positional scoring makes the beginner bot
    // prefer development and central control, not only random material exchanges.
    private func evaluate(fen: String) -> Int {
        let values: [Character: Int] = ["p":100, "n":320, "b":330, "r":500, "q":900, "k":0]
        let ranks = String(fen.split(separator: " ").first ?? "").split(separator: "/")
        var result = 0
        for (rankIndex, rank) in ranks.enumerated() {
            var file = 0
            for character in rank {
                if let skip = character.wholeNumberValue {
                    file += skip
                    continue
                }
                let kind = Character(String(character).lowercased())
                let isBlack = character.isLowercase
                let progress = isBlack ? rankIndex - 1 : 6 - rankIndex
                let center = (3...4).contains(file) && (3...4).contains(rankIndex) ? 15 : 0
                let pawnAdvance = kind == "p" ? max(0, progress) * 6 : 0
                let development = (kind == "n" || kind == "b") && (2...5).contains(rankIndex) ? 12 : 0
                let score = (values[kind] ?? 0) + center + pawnAdvance + development
                result += isBlack ? score : -score
                file += 1
            }
        }
        return result
    }

    private func score(position: Position, move: Move, lookAhead: Bool) -> Int {
        let child = Game(position: position)
        child.make(move: move)
        if child.isMate { return 100_000 }
        let replies = Array(child.legalMoves)
        if replies.isEmpty { return 0 } // Stalemate is not a victory.
        let now = evaluate(fen: FenSerialization.default.serialize(position: child.position))
        if !lookAhead { return now }
        // The hard bot avoids moves refuted by White's strongest immediate reply.
        return replies.map { reply in
            let branch = Game(position: child.position)
            branch.make(move: reply)
            if branch.isMate { return -100_000 }
            if branch.legalMoves.isEmpty { return 0 }
            return evaluate(fen: FenSerialization.default.serialize(position: branch.position))
        }.min() ?? now
    }

    private func botTurn() {
        thinking = true
        feedback = "Bot düşünüyor..."
        let requestedTurn = turnToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard requestedTurn == turnToken, thinking, !gameOver else { return }
            let candidates = Array(boardModel.game.legalMoves)
            guard !candidates.isEmpty else { thinking = false; endCheck(); return }
            let source = boardModel.game.position
            let chosen: Move
            switch difficulty {
            case .easy:
                chosen = candidates.randomElement()!
            case .medium:
                chosen = candidates.max(by: { score(position: source, move: $0, lookAhead: false) < score(position: source, move: $1, lookAhead: false) })!
            case .hard:
                chosen = candidates.max(by: { score(position: source, move: $0, lookAhead: true) < score(position: source, move: $1, lookAhead: true) })!
            }
            boardModel.game.make(move: chosen)
            withAnimation {
                boardModel.setFen(FenSerialization.default.serialize(position: boardModel.game.position))
            }
            thinking = false
            feedback = "Bot oynadı. Sıra sende."
            endCheck()
        }
    }

    private func endCheck() {
        if boardModel.game.isMate {
            gameOver = true
            let whiteTurn = FenSerialization.default.serialize(position: boardModel.game.position)
                .split(separator: " ").dropFirst().first == "w"
            feedback = whiteTurn ? "Şah mat! Bilgisayar kazandı." : "Şah mat! Sen kazandın."
        } else if boardModel.game.legalMoves.isEmpty {
            gameOver = true
            feedback = "Pat: oyun berabere."
        } else if boardModel.game.isCheck {
            feedback = "Şah! Tehdit altındaki şahı koru."
        }
    }

    private func reset() {
        turnToken += 1
        boardModel.setFen(AcademyCourse.initial)
        gameOver = false
        thinking = false
        feedback = "Sıra sende: beyaz taşlar senin."
    }
}
