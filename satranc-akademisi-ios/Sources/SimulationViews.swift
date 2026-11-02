import SwiftUI
import UIKit
import ChessboardKit
import ChessKit

struct SimulationHubView: View {
    @AppStorage("academy.scenarios.completed") private var completed = ""

    var body: some View {
        ZStack {
            PremiumBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    PremiumPanel(accent: true) {
                        HStack(spacing: 15) {
                            ChessPieceBadge(piece: .knight, size: 76, highlighted: true)
                            VStack(alignment: .leading, spacing: 7) {
                                Text("HAMLE HOCASI SUNAR")
                                    .font(.system(size: 10, weight: .heavy))
                                    .tracking(1.7)
                                    .foregroundStyle(Theme.gold)
                                Text("Senaryolu Satranç")
                                    .font(.system(.title2, design: .serif, weight: .bold))
                                    .foregroundStyle(Theme.cream)
                                Text("Bir hikâyenin içindesin: düşün, oynat, analiz et.")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.pale)
                            }
                        }
                    }

                    PremiumSectionHeading(title: "Hikâyeni Seç",
                                          eyebrow: "BAŞLANGIÇTAN İLK MATA",
                                          count: "6 senaryo")
                    ForEach(Array(ChessScenario.all.filter { !$0.isFreePlay }.enumerated()),
                            id: \.element.id) { index, scenario in
                        NavigationLink {
                            SimulationSessionView(scenario: scenario)
                        } label: {
                            scenarioCard(scenario, number: index + 1)
                        }
                        .buttonStyle(.plain)
                    }

                    PremiumSectionHeading(title: "Koçlu Serbest Maç",
                                          eyebrow: "ÖĞRENDİKLERİNİ DENE")
                        .padding(.top, 8)
                    ForEach(ChessScenario.all.filter(\.isFreePlay)) { scenario in
                        NavigationLink {
                            SimulationSessionView(scenario: scenario)
                        } label: {
                            scenarioCard(scenario, number: 7)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Koç hamlelerin yasal olup olmadığını, şah/mat durumlarını ve kısa vadeli tehditleri açıklar. Derin motor analizi değildir.")
                        .font(.footnote)
                        .foregroundStyle(Theme.pale)
                        .padding(.horizontal, 4)
                }
                .padding(16)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Simülasyon")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func piece(for id: String) -> PremiumChessPiece {
        switch id {
        case "ilk-mini-mac": return .pawn
        case "piyon-kurtarma": return .rook
        case "sah-tehlikede": return .king
        case "at-catal": return .knight
        case "korunan-at": return .bishop
        case "ilk-mat": return .queen
        default: return .king
        }
    }

    private func scenarioCard(_ scenario: ChessScenario, number: Int) -> some View {
        PremiumPanel(accent: scenario.isFreePlay) {
            HStack(alignment: .center, spacing: 13) {
                ChessPieceBadge(piece: piece(for: scenario.id),
                                size: 62, highlighted: scenario.isFreePlay)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(String(format: "%02d · ", number) + scenario.difficulty.uppercased())
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(0.7)
                            .foregroundStyle(Theme.gold)
                        if completed.split(separator: ",").contains(Substring(scenario.id)) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Theme.warmGreen)
                                .accessibilityLabel("Tamamlandı")
                        }
                    }
                    Text(scenario.title)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Theme.cream)
                    Text(scenario.mission)
                        .font(.caption)
                        .foregroundStyle(Theme.pale)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.gold)
            }
        }
    }
}

struct SimulationSessionView: View {
    let scenario: ChessScenario

    @State private var boardModel: ChessboardModel
    @State private var stepIndex = 0
    @State private var wandered = false
    @State private var timeline: [SimulationMoveReview] = []
    @State private var comment = "İlk hamle için bir taş seç. Gidebileceği kareleri göreceksin."
    @State private var caution: String? = nil
    @State private var showReport = false
    @AppStorage("academy.scenarios.completed") private var completed = ""

    init(scenario: ChessScenario) {
        self.scenario = scenario
        _boardModel = State(initialValue: ChessboardModel(
            fen: scenario.startFen,
            perspective: .white
        ))
    }

    private var expected: SimulationBeat? {
        guard !scenario.isFreePlay && !wandered && stepIndex < scenario.beats.count else { return nil }
        return scenario.beats[stepIndex]
    }

    private var scenarioComplete: Bool {
        !scenario.isFreePlay && !wandered && stepIndex == scenario.beats.count
    }

    private var gameEnded: Bool {
        boardModel.game.isMate || boardModel.game.legalMoves.isEmpty
    }

    private var awaitingOpponent: Bool {
        !scenarioComplete && !gameEnded && boardModel.game.position.state.turn == .black
    }

    private var playerCanMove: Bool {
        !awaitingOpponent && !scenarioComplete && !gameEnded
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 13) {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Label("YAŞAYARAK ÖĞREN", systemImage: "theatermasks.fill")
                            .font(.caption.weight(.heavy)).foregroundStyle(Theme.gold)
                        Spacer()
                        Text(scenario.difficulty)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(Theme.gold.opacity(0.18), in: Capsule())
                    }
                    Text(scenario.title)
                        .font(.system(.title2, design: .serif, weight: .bold))
                    Text(scenario.story)
                        .font(.subheadline)
                    Text(scenario.mission)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.gold)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 17))

                if !scenario.isFreePlay {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(wandered ? "Serbest keşif" : "Senaryo ilerlemesi")
                                .font(.caption.weight(.bold))
                            Spacer()
                            Text("\(stepIndex) / \(scenario.beats.count)")
                                .font(.caption.monospacedDigit())
                        }
                        ProgressView(
                            value: Double(stepIndex),
                            total: Double(max(1, scenario.beats.count))
                        )
                        .tint(Theme.gold)
                    }
                }

                if scenarioComplete {
                    notice(
                        "Senaryo tamamlandı!",
                        scenario.takeaway,
                        success: true
                    )
                } else if gameEnded {
                    notice(
                        boardModel.game.isMate ? "Şah mat!" : "Pat — oyun berabere",
                        "Maç bitti. Şimdi bütün hamlelerini raporda tek tek inceleyebilirsin.",
                        success: true
                    )
                } else if awaitingOpponent {
                    notice(
                        "Sıra rakipte",
                        "Hamleni analiz ettik. İstersen şimdi rakibin cevabını gör ve neden böyle oynadığını öğren.",
                        success: false
                    )
                } else {
                    notice(
                        wandered ? "Kendi yolunu deniyorsun" : "Sıra sende",
                        expected?.purpose ?? "İstediğin yasal hamleyi yap. Hamle Hocası sana hemen geri bildirim verecek.",
                        success: false
                    )
                }

                GeometryReader { proxy in
                    Chessboard(chessboardModel: boardModel)
                        .onMove { move, isLegal, from, to, lan, promotionPiece in
                            playerMove(move, isLegal: isLegal)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.width)
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(5)
                .background(Theme.gold.opacity(0.55), in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(Theme.gold)
                        Text("Hamle Hocası")
                            .font(.headline)
                        Spacer()
                        Text("Kural tabanlı")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text(comment)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    if let caution {
                        Label(caution, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))

                if awaitingOpponent {
                    Button {
                        opponentMove()
                    } label: {
                        Label("Rakibin hamlesini gör ve analiz et", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.gold)
                    .foregroundStyle(.black)
                }

                HStack(spacing: 8) {
                    Button {
                        showHint()
                    } label: {
                        Label("İpucu", systemImage: "lightbulb.fill")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .disabled(!playerCanMove || expected == nil)
                    .buttonStyle(.bordered)

                    Button {
                        undoMove()
                    } label: {
                        Label("Geri al", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .disabled(timeline.isEmpty)
                    .buttonStyle(.bordered)

                    Button {
                        restart()
                    } label: {
                        Label("Baştan", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)

                Button {
                    showReport = true
                } label: {
                    Label(scenarioComplete || gameEnded ? "Tam Hamle Analizini Aç" : "Yaptığım Hamleleri İncele",
                          systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity, minHeight: 47)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.gold)
                .foregroundStyle(.black)
                .disabled(timeline.isEmpty)

                if !scenario.isFreePlay {
                    DisclosureGroup("Senaryonun amacı ve öğrenilecek fikir") {
                        Text(scenario.takeaway)
                            .font(.subheadline)
                            .padding(.top, 8)
                    }
                    .padding(13)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                }
                Text("Süre sınırı yok. Koçun değerlendirmesi temel tehditleri inceler; motor derinliği ve kesin en iyi hamle garantisi yoktur.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(13)
            .frame(maxWidth: 690)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Simülasyon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rapor") { showReport = true }
                    .disabled(timeline.isEmpty)
            }
        }
        .sheet(isPresented: $showReport) {
            NavigationStack {
                SimulationReportView(
                    scenario: scenario,
                    timeline: timeline,
                    completed: scenarioComplete,
                    wasExploration: wandered
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Kapat") { showReport = false }
                    }
                }
            }
        }
        .onAppear {
            if timeline.isEmpty && !scenario.isFreePlay { showHint() }
        }
    }

    private func notice(_ title: String, _ message: String, success: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: success ? "checkmark.seal.fill" : "arrow.up.right.circle.fill")
                .font(.headline)
                .foregroundStyle(success ? .green : Theme.gold)
            Text(message).font(.subheadline)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 13))
    }

    private func playerMove(_ move: Move, isLegal: Bool) {
        guard playerCanMove else { return }
        guard isLegal, boardModel.game.legalMoves.contains(move) else {
            let fen = FenSerialization.default.serialize(position: boardModel.game.position)
            let verdict = ChessMoveCoach.evaluate(game: boardModel.game, move: move)
            timeline.append(SimulationMoveReview(
                id: timeline.count + 1,
                player: "Sen (deneme)",
                moveName: move.description,
                notation: "Yasal değil",
                verdict: verdict,
                fenBefore: fen,
                fenAfter: fen,
                guidedIndexBefore: stepIndex,
                deviatedBefore: wandered
            ))
            comment = "Bu hamle satranç kurallarına uygun değil. Taşın seçilince yasal karelerini göreceksin; yeniden dene."
            caution = nil
            return
        }
        commit(move, player: "Sen")
    }

    private func opponentMove() {
        guard awaitingOpponent else { return }
        let move: Move?
        if let beat = expected,
           let guided = boardModel.game.legalMoves.first(where: { $0.description.lowercased() == beat.uci }) {
            move = guided
        } else {
            move = ScenarioOpponent.choose(in: boardModel.game)
        }
        guard let move else { return }
        commit(move, player: "Rakip")
    }

    private func commit(_ move: Move, player: String) {
        let before = boardModel.game
        guard before.legalMoves.contains(move) else { return }

        let currentBeat = expected
        let expectedIndexBefore = stepIndex
        let wasWandering = wandered
        let fenBefore = FenSerialization.default.serialize(position: before.position)
        let verdict = ChessMoveCoach.evaluate(game: before, move: move, scenarioBeat: currentBeat)
        let spokenMove = TurkishMoveNotation.describe(move, in: before)

        // Keep the visible board's original position intact until setFen,
        // so ChessboardKit can animate from the true source square.
        let progressed = before.deepCopy()
        progressed.make(move: move)
        let fenAfter = FenSerialization.default.serialize(position: progressed.position)
        boardModel.setFen(fenAfter, lan: move.description)
        boardModel.clearHint()

        if currentBeat != nil {
            if verdict.meetsGoal {
                stepIndex += 1
            } else {
                wandered = true
            }
        }

        timeline.append(SimulationMoveReview(
            id: timeline.count + 1,
            player: player,
            moveName: spokenMove,
            notation: verdict.san,
            verdict: verdict,
            fenBefore: fenBefore,
            fenAfter: fenAfter,
            guidedIndexBefore: expectedIndexBefore,
            deviatedBefore: wasWandering
        ))

        comment = "\(player) — \(spokenMove)\n\(verdict.title)\n\(verdict.explanation)"
        caution = verdict.caution

        if scenarioComplete {
            var ids = Set(completed.split(separator: ",").map(String.init))
            ids.insert(scenario.id)
            completed = ids.sorted().joined(separator: ",")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func showHint() {
        guard let beat = expected,
              playerCanMove,
              beat.uci.count >= 4 else { return }
        let from = String(beat.uci.prefix(2))
        let to = String(beat.uci.dropFirst(2).prefix(2))
        boardModel.clearHint()
        boardModel.hint([from, to])
        comment = "İpucu: \(beat.purpose)\nÖnce işaretlenen taşı, sonra hedef kareyi seç. Yanlış hamle yaparsan da öğrenmeye devam edeceğiz."
        caution = nil
    }

    private func undoMove() {
        guard let last = timeline.popLast() else { return }
        boardModel.setFen(last.fenBefore)
        boardModel.clearHint()
        stepIndex = last.guidedIndexBefore
        wandered = last.deviatedBefore
        comment = timeline.last.map { "\($0.player) — \($0.moveName)\n\($0.verdict.explanation)" } ??
            "Son hamleyi geri aldın. Yeniden deneyebilirsin."
        caution = timeline.last?.verdict.caution
    }

    private func restart() {
        boardModel.setFen(scenario.startFen)
        boardModel.clearHint()
        stepIndex = 0
        wandered = false
        timeline = []
        comment = "Senaryo yeniden başladı. İlk hamleye hazır mısın?"
        caution = nil
        if !scenario.isFreePlay { showHint() }
    }
}

struct SimulationReportView: View {
    let scenario: ChessScenario
    let timeline: [SimulationMoveReview]
    let completed: Bool
    let wasExploration: Bool

    private var userMoves: [SimulationMoveReview] {
        timeline.filter { $0.player.hasPrefix("Sen") }
    }

    private var goalMoves: Int {
        userMoves.filter { $0.verdict.meetsGoal }.count
    }

    private var warnings: Int {
        userMoves.filter { $0.verdict.caution != nil }.count
    }

    var body: some View {
        List {
            Section("Hamle Hocası · Maç Sonu Raporu") {
                Text(scenario.title)
                    .font(.title2.bold())
                Text(completed ? "Senaryoyu tamamladın! Şimdi her hamlenin nedenini hatırla." :
                     wasExploration ? "Senaryodan ayrılıp yeni hamleler denedin. Keşif hamlelerini de analiz ettik." :
                     "Bu rapor henüz devam eden maçtaki hamleleri kapsıyor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    metric(String(userMoves.count), "Hamle/deneme")
                    metric(String(goalMoves), "Hedef hamle")
                    metric(String(warnings), "Dikkat notu")
                }
                Text("Bu rapor bir ELO veya motor puanı değildir. Tehdit, yasal hamle ve senaryo hedefi üzerinden hazırlanır.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Hamleleri tahtada geri sar") {
                SimulationMoveReplay(scenario: scenario, timeline: timeline)
                    .padding(.vertical, 8)
            }

            Section("Her hamlenin ayrı analizi") {
                ForEach(timeline) { record in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(record.id). \(record.player)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.gold)
                            Spacer()
                            Text(record.notation)
                                .font(.headline.monospaced())
                        }
                        Text(record.moveName).font(.headline)
                        Text(record.verdict.title).font(.subheadline.weight(.semibold))
                        Text(record.verdict.explanation).font(.subheadline)
                        if let warning = record.verdict.caution {
                            Label(warning, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            Section("Bir sonraki maç için") {
                Text(scenario.takeaway)
                Text("Her hamleden önce şu üç soruyu sor: Şahım güvende mi? Rakibim neyi tehdit ediyor? Ben hangi kareleri kontrol ediyorum?")
                    .font(.subheadline)
                Text("Daha derin motor analizi ve alternatif hamleleri sayısal olarak değerlendirme sonraki geliştirme aşamasıdır.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Hamle Analizi")
    }

    private func metric(_ count: String, _ label: String) -> some View {
        VStack(spacing: 5) {
            Text(count)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(Theme.gold)
            Text(label)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 11))
    }
}
