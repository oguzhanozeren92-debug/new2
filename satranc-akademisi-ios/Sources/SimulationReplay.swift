import SwiftUI
import ChessboardKit

/// Visual reconstruction of the exact positions recorded during a scenario.
/// Unlike notation-only history, this makes every decision inspectable on board.
struct SimulationMoveReplay: View {
    let scenario: ChessScenario
    let timeline: [SimulationMoveReview]

    @State private var boardModel: ChessboardModel
    @State private var shownMove = 0

    init(scenario: ChessScenario, timeline: [SimulationMoveReview]) {
        self.scenario = scenario
        self.timeline = timeline
        _boardModel = State(initialValue: ChessboardModel(
            fen: scenario.startFen,
            perspective: .white
        ))
    }

    private var current: SimulationMoveReview? {
        shownMove > 0 && shownMove <= timeline.count ? timeline[shownMove - 1] : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tahtada tekrar izle", systemImage: "play.rectangle.on.rectangle")
                    .font(.headline)
                    .foregroundStyle(Theme.gold)
                Spacer()
                Text("\(shownMove) / \(timeline.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                Chessboard(chessboardModel: boardModel)
                    .allowsHitTesting(false)
                    .frame(width: proxy.size.width, height: proxy.size.width)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(4)
            .background(Theme.gold.opacity(0.35), in: RoundedRectangle(cornerRadius: 7))

            if let current {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(current.id). \(current.player): \(current.moveName)")
                        .font(.subheadline.weight(.semibold))
                    Text(current.verdict.title)
                        .font(.subheadline)
                        .foregroundStyle(Theme.gold)
                    Text(current.verdict.explanation)
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                    if let caution = current.verdict.caution {
                        Text("Dikkat: " + caution)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 11))
            } else {
                Text("Başlangıç pozisyonu. İleriye basınca ilk hamleyi ve koçun yorumunu göreceksin.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    seek(shownMove - 1)
                } label: {
                    Label("Önceki", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .disabled(shownMove == 0)
                .buttonStyle(.bordered)

                Button {
                    seek(shownMove + 1)
                } label: {
                    Label("Sonraki", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .disabled(shownMove >= timeline.count)
                .buttonStyle(.borderedProminent)
                .tint(Theme.gold)
                .foregroundStyle(.black)
            }
        }
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
    }

    private func seek(_ index: Int) {
        guard index >= 0, index <= timeline.count else { return }
        let fen = index == 0 ? scenario.startFen : timeline[index - 1].fenAfter
        let forward = index == shownMove + 1
        if forward {
            boardModel.setFen(fen, lan: timeline[index - 1].verdict.uci)
        } else {
            boardModel.setFen(fen)
        }
        shownMove = index
    }
}
