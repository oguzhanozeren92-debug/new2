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

    private func evaluate(fen: String) -> Int {
        let value: [Character: Int] = ["p":100,"n":320,"b":330,"r":500,"q":900,"k":0]
        return String(fen.split(separator:" ").first ?? "").reduce(0) { score, p in
            let weight = value[Character(String(p).lowercased())] ?? 0
            return score + (p.isLowercase ? weight : -weight)
        }
    }

    private func score(position: Position, move: Move, lookAhead: Bool) -> Int {
        let child = Game(position: position)
        child.make(move: move)
        let now = evaluate(fen: FenSerialization.default.serialize(position: child.position))
        if !lookAhead { return now }
        let replies = Array(child.legalMoves)
        if replies.isEmpty { return now }
        return replies.map { reply in
            let branch = Game(position: child.position)
            branch.make(move: reply)
            return evaluate(fen: FenSerialization.default.serialize(position: branch.position))
        }.min() ?? now
    }

    private func botTurn() {
        thinking = true
        feedback = "Bot düşünüyor..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
        if Array(boardModel.game.legalMoves).isEmpty {
            gameOver = true
            feedback = "Oyun sona erdi. Yeni maç başlatabilirsin."
        }
    }

    private func reset() {
        boardModel.setFen(AcademyCourse.initial)
        gameOver = false
        thinking = false
        feedback = "Sıra sende: beyaz taşlar senin."
    }
}
