import SwiftUI
import ChessKit

/// Original Turkish explanations for beginner-level chess patterns.
/// Named motifs are factual chess concepts, not copied course text.
struct TacticConcept: Identifiable {
    let id: String
    let title: String
    let internationalName: String
    let definition: String
    let spotIt: String
    let remember: String
    let commonMistake: String
    let lessonID: String?

    static let all: [TacticConcept] = [
        .init(id: "catal", title: "Çatal", internationalName: "Fork",
              definition: "Tek bir taşın aynı anda iki veya daha fazla rakip taşa saldırmasıdır. Özellikle at çatalları güçlüdür.",
              spotIt: "Rakibin şahı ile veziri birbirine yakın mı? Atın ikisini birlikte tehdit edeceği kare var mı?",
              remember: "Bir hamle, iki tehdit.",
              commonMistake: "Saldıran taşın karşı hamlede bedavaya alınabileceğini unutma.",
              lessonID: "taktik-catal"),
        .init(id: "acmaz", title: "Açmaz", internationalName: "Pin",
              definition: "Bir taş yerinden ayrılırsa arkasındaki daha değerli taş, hatta şah, saldırı altında kalır. Şaha karşı açmazda öndeki taş yasal olarak ayrılamaz.",
              spotIt: "Rakibin şahı veya veziriyle aynı yatay, dikey ya da çaprazda başka taş var mı?",
              remember: "Öndeki taş, arkadakini korumak zorunda.",
              commonMistake: "Her açmaz mutlak değildir; şaha karşı olmayan açmazda taş hareket edebilir.",
              lessonID: "taktik-acmaz"),
        .init(id: "sis", title: "Şiş", internationalName: "Skewer",
              definition: "Öndeki yüksek değerli taş saldırıdan kaçınca arkadaki daha düşük değerli taş açığa çıkar. Açmazın tersidir.",
              spotIt: "Şahın arkasında aynı doğrultuda vezir ya da kale var mı?",
              remember: "Öndeki kaçar, arkadaki düşer.",
              commonMistake: "Arkadaki taşın gerçekten savunmasız kalıp kalmadığını kontrol et.",
              lessonID: "taktik-sis"),
        .init(id: "kesif", title: "Keşif saldırısı", internationalName: "Discovered attack",
              definition: "Öndeki kendi taşın çekilince arkadaki uzun menzilli taşın saldırı hattı açılır.",
              spotIt: "Filinin, kalenin veya vezirinin önünde duran kendi taşın var mı?",
              remember: "Yolu aç, gizli tehdidi göster.",
              commonMistake: "Öndeki taşın nereye kaçtığını değil, arkasından hangi hattın açıldığını da düşün.",
              lessonID: "taktik-kesif"),
        .init(id: "ciftesah", title: "Çifte şah", internationalName: "Double check",
              definition: "Tek hamleden sonra iki farklı taş aynı anda rakip şaha saldırır. Bu durumda şahı hareket ettirmek gerekir.",
              spotIt: "Şahı tehdit eden yeni taş ile arkasındaki diğer taş aynı anda şah çekebilir mi?",
              remember: "İki ayrı şah tehdidine yalnızca şah hamlesi cevap olur.",
              commonMistake: "Çifte şahı, çatal ile karıştırma; çatalda bir taş iki hedefi tehdit eder.",
              lessonID: "taktik-cifte-sah"),
        .init(id: "ara-hamle", title: "Ara hamle", internationalName: "Zwischenzug",
              definition: "Beklenen taş alma yerine önce daha güçlü, acil bir tehdit yaparak hamle sırasını kendi lehine değiştirmektir.",
              spotIt: "Taş almadan önce şah çekebiliyor veya daha büyük bir tehdit oluşturabiliyor musun?",
              remember: "Hemen alma, önce daha iyisine bak.",
              commonMistake: "Ara hamle sonrasında asıl hedefinin kaçıp kaçmayacağını hesapla.",
              lessonID: nil),
        .init(id: "saptirma", title: "Saptırma", internationalName: "Deflection",
              definition: "Önemli bir kareyi veya taşı koruyan rakip taşı başka yere gitmek zorunda bırakmaktır.",
              spotIt: "Rakibin hangi taşı bütün savunmayı ayakta tutuyor?",
              remember: "Koruyucuyu görevinden uzaklaştır.",
              commonMistake: "Rakibin tehdit karşısında başka savunması olup olmadığını kontrol et.",
              lessonID: nil),
        .init(id: "fedalar", title: "Taş fedası", internationalName: "Sacrifice",
              definition: "Daha büyük bir amaç için kısa süreliğine taş veya piyon vermektir; arkasında somut bir fikir olmalıdır.",
              spotIt: "Taş vermek mat ağı kuruyor, vezir kazandırıyor veya güçlü bir saldırı başlatıyor mu?",
              remember: "Feda, hesapsız hediye değildir.",
              commonMistake: "Sırf gösterişli diye taşı bırakma; devamı hesapla.",
              lessonID: nil),
        .init(id: "mat-agi", title: "Mat ağı", internationalName: "Mating net",
              definition: "Rakip şahın kaçış karelerini tek tek kapatıp bir sonraki tehditte mat etmeye hazırlanmaktır.",
              spotIt: "Şahın hangi karelere kaçabileceğini say; hangi kareleri hangi taş koruyor?",
              remember: "Şahın etrafındaki kapıları kapat.",
              commonMistake: "Şaha sadece saldırmaya odaklanıp kaçış karelerini unutma.",
              lessonID: nil),
        .init(id: "savunucuyu-kaldirma", title: "Savunucuyu kaldırma", internationalName: "Remove the defender",
              definition: "Önemli rakip taşını koruyan taşı alıp hedefi savunmasız hâle getirmektir.",
              spotIt: "Kazanmaya çalıştığın taş hangi rakip tarafından korunuyor?",
              remember: "Önce koruyucuyu al, sonra hedefi.",
              commonMistake: "Koruyucu alındıktan sonra rakibin araya hamle sıkıştırabileceğini unutma.",
              lessonID: nil)
    ]

    static func forLesson(_ id: String) -> TacticConcept? {
        all.first { $0.lessonID == id || $0.lessonID == id.replacingOccurrences(of: "puzzle-", with: "taktik-") }
    }
}

struct TacticGlossaryView: View {
    var body: some View {
        List {
            Section {
                Text("Önce kavramı öğren, örneği tahtada gör, sonra kendi hamleni dene. Terimleri ezberlemen gerekmiyor; tehditleri görmen yeterli.")
                    .foregroundStyle(.secondary)
            }
            ForEach(TacticConcept.all) { concept in
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(concept.internationalName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.gold)
                            Text(concept.definition)
                            Group {
                                Label("Tahtada neye bakmalısın?", systemImage: "eye.fill")
                                    .font(.headline)
                                Text(concept.spotIt)
                                Label("Akılda kalsın", systemImage: "brain.head.profile")
                                    .font(.headline)
                                Text(concept.remember)
                                Label("Sık yapılan hata", systemImage: "exclamationmark.triangle.fill")
                                    .font(.headline)
                                Text(concept.commonMistake)
                            }
                            .foregroundStyle(Theme.cream)
                            if let lessonID = concept.lessonID,
                               let lesson = AcademyCourse.all.flatMap({ $0.lessons }).first(where: { $0.id == lessonID }) {
                                NavigationLink {
                                    ChessLessonSession(lesson: lesson)
                                } label: {
                                    Label("Tahtada uygula", systemImage: "checkerboard.rectangle")
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.gold)
                            } else {
                                Text("Bu kavramın interaktif örneği eğitim havuzuna eklenecek.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: 680, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    }
                    .background(Theme.background)
                    .navigationTitle(concept.title)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(concept.title).font(.headline)
                        Text(concept.internationalName + " · " + concept.remember)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Taktik Sözlüğü")
    }
}

/// ChessKit generates standards-based SAN, then we display a Turkish lesson label.
/// English SAN in parentheses is retained so international chess texts remain readable.
enum TurkishMoveNotation {
    static func localized(_ san: String) -> String {
        guard let first = san.first else { return san }
        let letter: [Character: String] = ["N":"A", "B":"F", "R":"K", "Q":"V", "K":"Ş"]
        var output = letter[first].map { $0 + String(san.dropFirst()) } ?? san
        let promotion: [String: String] = ["=N":"=A", "=B":"=F", "=R":"=K", "=Q":"=V"]
        for (english, turkish) in promotion {
            output = output.replacingOccurrences(of: english, with: turkish)
        }
        return output
    }

    static func explained(_ san: String) -> String {
        let localizedMove = localized(san)
        return localizedMove == san ? san : "\(localizedMove) (uluslararası: \(san))"
    }
    static func describe(_ move: Move, in game: Game) -> String {
        let kind = game.position.board[move.from]?.kind.description.lowercased() ?? "p"
        let names = ["p":"Piyon", "n":"At", "b":"Fil", "r":"Kale", "q":"Vezir", "k":"Şah"]
        let from = move.from.coordinate
        let to = move.to.coordinate

        if kind == "k" && abs(move.from.file - move.to.file) == 2 {
            return move.to.file > move.from.file ? "Kısa rok (O-O)" : "Uzun rok (O-O-O)"
        }

        let captures = game.position.board[move.to] != nil ||
                       (kind == "p" && move.from.file != move.to.file)
        let transition = captures ? " × " : " → "
        let title = (names[kind] ?? "Taş") + " " + from + transition + to
        let after = game.deepCopy()
        after.make(move: move)
        if after.isMate { return title + " · ŞAH MAT!" }
        if after.isCheck { return title + " · ŞAH!" }
        if move.promotion != nil { return title + " · Terfi!" }
        return title
    }

}

struct MoveNotationGuideView: View {
    private let examples: [(String, String)] = [
        ("e4", "Beyaz piyon e4 karesine gidiyor. Piyon hamlesinde taş harfi yazılmaz."),
        ("Af3 / Nf3", "At f3 karesine gidiyor. Türkçede A, uluslararası kaynaklarda N kullanılır."),
        ("Fb5 / Bb5", "Fil b5 karesine gidiyor. Türkçede F, İngilizce notasyonda B."),
        ("Vh5 / Qh5", "Vezir h5 karesine gidiyor. Türkçede V, uluslararası notasyonda Q."),
        ("Kxe4 / Rxe4", "Kale e4'teki taşı alıyor. × veya x taş almayı gösterir."),
        ("O-O", "Kısa rok: şah iki kare kale yönüne gider, kale yanına geçer."),
        ("O-O-O", "Uzun rok: şah vezir kanadına doğru rok yapar."),
        ("+", "Hamlenin sonunda şah çekildiğini gösterir."),
        ("#", "Hamlenin şah mat ile bittiğini gösterir."),
        ("a8=V / a8=Q", "Piyon son sırada vezire terfi eder. Diğer taşlara terfi de mümkündür.")
    ]

    var body: some View {
        List {
            Section {
                Text("Satranç tahtasında sütunlar a–h, yatay sıralar 1–8 diye adlandırılır. Beyaz taşlar aşağıda dururken sol alt kare a1'dir.")
                Text("Bazı kaynaklar aynı hamleleri farklı harflerle yazar. Önce Türkçe adını öğren, yanında uluslararası karşılığını gör.")
                    .foregroundStyle(.secondary)
            }
            Section("Hamleler nasıl okunur?") {
                ForEach(0..<examples.count, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(examples[i].0)
                            .font(.title3.monospaced().weight(.bold))
                            .foregroundStyle(Theme.gold)
                        Text(examples[i].1)
                    }
                    .padding(.vertical, 6)
                }
            }
            Section("Taşların Türkçe harfleri") {
                Text("A = At · F = Fil · K = Kale · V = Vezir · Ş = Şah. Piyonun baş harfi kullanılmaz.")
                Text("Uluslararası yazımda sırasıyla N, B, R, Q ve K kullanılır.")
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Hamlelerin Dili")
    }
}
