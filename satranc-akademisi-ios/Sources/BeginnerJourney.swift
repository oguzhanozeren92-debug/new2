import SwiftUI

/// A truly zero-knowledge starting point. No chess notation or timed quiz is
/// required to enter. Learners explore pieces and tap the actual starting board
/// before trying a legal move in ChessboardKit.
struct BeginnerJourneyView: View {
    @AppStorage("academy.beginnerJourneyDone") private var journeyDone = false
    @AppStorage("academy.completed") private var completedLessons = ""

    @State private var page = 0
    @State private var explored: Set<String> = []
    @State private var focusedPiece = "P"
    @State private var tappedPawn = false
    @State private var choseWhite = false
    @State private var colorFeedback = ""
    @State private var boardFeedback = ""

    private let pieces: [(code: String, symbol: String, name: String, guide: String)] = [
        ("P", "♙", "Piyon", "Her tarafta 8 tane vardır. Genellikle ileri gider. İlk hamlesinde iki kare de ilerleyebilir. Çaprazındaki rakip taşı alır."),
        ("R", "♖", "Kale", "Sağa, sola, ileri ve geri düz gider. Aradaki taşların üzerinden atlayamaz."),
        ("N", "♘", "At", "İki kare bir yöne ve bir kare yanına, L harfi gibi gider. Diğer taşların üzerinden atlayabilir."),
        ("B", "♗", "Fil", "Çapraz gider. Açık ve koyu karede başlayan iki filin vardır."),
        ("Q", "♕", "Vezir", "En hareketli taşındır: hem düz hem çapraz gidebilir. Başlangıçta vezir kendi rengindeki kareye yerleşir."),
        ("K", "♔", "Şah", "En önemli taştır. Bir kare gidebilir; saldırı altındaki kareye gidemez. Amaç rakibin şahını mat etmektir.")
    ]

    private let initialRows = [
        Array("rnbqkbnr"), Array("pppppppp"), Array("........"),
        Array("........"), Array("........"), Array("........"),
        Array("PPPPPPPP"), Array("RNBQKBNR")
    ]

    private let symbols: [Character: String] = [
        "K":"♔", "Q":"♕", "R":"♖", "B":"♗", "N":"♘", "P":"♙",
        "k":"♚", "q":"♛", "r":"♜", "b":"♝", "n":"♞", "p":"♟︎"
    ]

    private var readyToContinue: Bool {
        switch page {
        case 1: return explored.count == pieces.count
        case 2: return tappedPawn
        case 3: return choseWhite
        default: return true
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Label("SIFIRDAN BAŞLA", systemImage: "graduationcap.fill")
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                        .foregroundStyle(Theme.gold)
                    Spacer()
                    Text("\(min(page + 1, 5))/5")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Theme.gold)
                }
                ProgressView(value: Double(page + 1), total: 5)
                    .tint(Theme.gold)

                Group {
                    switch page {
                    case 0: welcome
                    case 1: learnPieces
                    case 2: understandBoard
                    case 3: whiteFirst
                    default: firstMove
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    if page > 0 {
                        Button("Geri") { withAnimation { page -= 1 } }
                            .buttonStyle(.bordered)
                            .frame(minHeight: 44)
                    }
                    if page < 4 {
                        Button(page == 0 ? "Başlayalım" : "Devam et") {
                            if page == 3 { journeyDone = true }
                            withAnimation { page += 1 }
                        }
                        .disabled(!readyToContinue)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.gold)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 46)
                    } else if !journeyDone {
                        Button("Bu bölümü tamamladım") { journeyDone = true }
                            .buttonStyle(.borderedProminent).tint(Theme.gold)
                    }
                }

                Text("Acele yok. İstediğin zaman geri dönebilirsin; hata yapınca puan kaybetmezsin.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Sıfırdan Satranç")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Satranç bilmiyor olabilirsin. Sorun değil!")
                .font(.system(.title, design: .serif, weight: .bold))
            Text("İki kişi 64 kareli bir tahtada oynar. Bir taraf beyaz, diğeri siyahtır. Oyuna her zaman beyaz başlar.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                Label("Her oyuncunun 16 taşı vardır.", systemImage: "checkerboard.rectangle")
                Label("Oyunun hedefi: rakip şahı mat etmek.", systemImage: "crown.fill")
                Label("Mat, şahın saldırıdan kurtulacak hamlesi kalmaması demektir.", systemImage: "lightbulb.fill")
                Label("Şahı gerçekten tahtadan almayız.", systemImage: "checkmark.circle.fill")
            }
            .font(.subheadline)
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            Text("Önce taşları tanıyacağız. Ardından tahtada ilk hamleni kendin yapacaksın.")
                .foregroundStyle(Theme.gold)
        }
    }

    private var learnPieces: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bu altı taşı tanı")
                .font(.system(.title2, design: .serif, weight: .bold))
            Text("Bir taşa dokun, nasıl hareket ettiğini gör. Altısını da inceleyince devam edebilirsin.")
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(pieces, id: \.code) { p in
                    Button {
                        focusedPiece = p.code
                        explored.insert(p.code)
                    } label: {
                        VStack(spacing: 5) {
                            Text(p.symbol).font(.system(size: 43))
                            Text(p.name).font(.subheadline.weight(.bold))
                            if explored.contains(p.code) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 104)
                        .foregroundStyle(Theme.cream)
                        .background(
                            focusedPiece == p.code ? Theme.gold.opacity(0.28) : Theme.surface,
                            in: RoundedRectangle(cornerRadius: 13)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(p.name + (explored.contains(p.code) ? ", incelendi" : ", incele"))
                }
            }
            if let selected = pieces.first(where: { $0.code == focusedPiece }) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selected.name + " nasıl hareket eder?")
                        .font(.headline).foregroundStyle(Theme.gold)
                    Text(selected.guide)
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 13))
            }
            Text("İncelenen: \(explored.count) / 6")
                .font(.subheadline.weight(.medium))
        }
    }

    private var understandBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tahta ve taşların yerleri")
                .font(.system(.title2, design: .serif, weight: .bold))
            Text("Satranç tahtası 8'e 8, toplam 64 karedir. Beyaz taşlar altta, siyahlar üsttedir. Sağ alt köşe her zaman açık renk karedir.")
                .foregroundStyle(.secondary)
            Text("Şimdi alt taraftaki **beyaz piyonlardan birine dokun**.")
                .foregroundStyle(Theme.gold)
            starterBoard
            if !boardFeedback.isEmpty {
                Text(boardFeedback)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
            Text("Tahtanın altındaki a–h harfleri sütunları, 1–8 rakamları sıraları belirtir. Bunları şimdilik ezberlemen gerekmiyor.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var starterBoard: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 8), spacing: 0) {
            ForEach(0..<64, id: \.self) { i in
                let rank = i / 8
                let file = i % 8
                let piece = initialRows[rank][file]
                Button {
                    if rank == 6 && piece == "P" {
                        tappedPawn = true
                        boardFeedback = "Harika! Bu bir beyaz piyon. Henüz hamle yapmak zorunda değilsin."
                    } else {
                        boardFeedback = "Bu başka bir kare. Beyaz piyonlar alt taraftan ikinci sırada, sekiz tanedir. Yeniden dene."
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .fill((rank + file).isMultiple(of: 2) ?
                                  Color(red: 0.94, green: 0.85, blue: 0.72) :
                                  Color(red: 0.65, green: 0.48, blue: 0.34))
                        if let icon = symbols[piece] {
                            Text(icon)
                                .font(.system(size: 29))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .foregroundStyle(piece.isUppercase ? .white : .black)
                                .shadow(color: piece.isUppercase ? .black : .white, radius: 2)
                        }
                        if tappedPawn && rank == 6 && piece == "P" {
                            Circle().stroke(.green, lineWidth: 2).padding(2)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(String("abcdefgh".map { $0 }[file]))\(8 - rank) \(pieceName(piece))")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.gold, lineWidth: 3))
        .aspectRatio(1, contentMode: .fit)
    }

    private func pieceName(_ p: Character) -> String {
        switch p.lowercased() {
        case "p": return "piyon"
        case "r": return "kale"
        case "n": return "at"
        case "b": return "fil"
        case "q": return "vezir"
        case "k": return "şah"
        default: return "boş kare"
        }
    }

    private var whiteFirst: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("İlk hamleyi kim yapar?")
                .font(.system(.title2, design: .serif, weight: .bold))
            Text("Satrançta iki taraf sırayla oynar. Bir oyuncu tek turda normalde bir hamle yapar.")
                .foregroundStyle(.secondary)
            Text("Sence ilk kim başlar?")
                .font(.headline)
            HStack(spacing: 12) {
                Button("♔ Beyaz") {
                    choseWhite = true
                    colorFeedback = "Tebrikler! Oyuna her zaman beyaz başlar."
                }
                Button("♚ Siyah") {
                    choseWhite = false
                    colorFeedback = "Yaklaştın! İlk hamleyi beyaz yapar. Beyazı seçip tekrar dene."
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.gold)
            .foregroundStyle(.black)
            if !colorFeedback.isEmpty {
                Text(colorFeedback)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var firstMove: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("İlk bölüm tamam!", systemImage: "checkmark.seal.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.gold)
            Text("Artık beyazın başladığını, taşların nerede durduğunu ve altı taşın adını biliyorsun.")
            Text("Şimdi ilk hamleni gerçek satranç tahtasında yapabilirsin. Senden sadece bir piyonu **bir kare ileri** götürmeni isteyeceğiz.")
                .foregroundStyle(.secondary)
            if let lesson = AcademyCourse.all.flatMap({ $0.lessons }).first(where: { $0.id == "ilk-piyon" }) {
                NavigationLink {
                    ChessLessonSession(lesson: lesson)
                } label: {
                    Label(completedLessons.split(separator: ",").contains("ilk-piyon") ?
                          "İlk hamleni yeniden dene" : "♙ İlk hamleni yap",
                          systemImage: "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 49)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.gold)
                .foregroundStyle(.black)
            }
            Text("Bir hamleyi anlayana kadar tekrar deneyebilirsin; hiçbir süre sınırı yok.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}
