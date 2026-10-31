import Foundation

struct TrainingStep: Identifiable, Hashable {
    let uci: String
    let explanation: String
    var id: String { uci }
}

struct TrainingLesson: Identifiable {
    let id: String
    let title: String
    let description: String
    let goal: String
    let fen: String
    let steps: [TrainingStep]

    init(_ id: String, _ title: String, _ description: String, _ goal: String, _ fen: String, _ steps: [(String, String)]) {
        self.id = id
        self.title = title
        self.description = description
        self.goal = goal
        self.fen = fen
        self.steps = steps.map { TrainingStep(uci: $0.0, explanation: $0.1) }
    }
}

struct AcademyCourse: Identifiable {
    let id: String
    let title: String
    let summary: String
    let symbol: String
    let lessons: [TrainingLesson]

    static let initial = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    static let all: [AcademyCourse] = [
        AcademyCourse(id: "baslangic", title: "1. Başlangıç", summary: "Tahtayı tanı, her taşın hareketini bizzat uygula.", symbol: "square.grid.3x3.fill", lessons: [
            TrainingLesson("merkez", "Merkeze ilk adım", "e4 ve d4 önemli merkez kareleridir. Bir piyonla merkezde yer kazanmayı öğren.", "e2 piyonunu e4 karesine ilerlet.", initial, [("e2e4", "Doğru! e4 ile merkeze etki ettin.")]),
            TrainingLesson("piyon", "Piyon nasıl hareket eder?", "Piyon düz ilerler; ilk hamlesinde yolu açıksa iki kare gidebilir. Rakip taşları çapraz alır.", "e2'deki piyonu e4'e götür.", "7k/8/8/8/8/8/4P3/7K w - - 0 1", [("e2e4", "İlk hamlede iki kare ilerledin.")]),
            TrainingLesson("kale", "Kalenin gücü", "Kale yatay veya dikey hareket eder. Başka taşların üzerinden geçemez.", "a1'deki kaleyi a4 karesine götür.", "7k/8/8/8/8/8/8/R6K w - - 0 1", [("a1a4", "Kalenin dikey hareketini yaptın.")]),
            TrainingLesson("fil", "Fil çapraz gider", "Fil hep aynı renk karelerin üzerinde çapraz hareket eder.", "Fili c1'den g5'e götür.", "7k/8/8/8/8/8/8/2B4K w - - 0 1", [("c1g5", "Doğru: fil çapraz ilerledi.")]),
            TrainingLesson("at", "Atın L hareketi", "At iki kare bir yönde ve bir kare dik yönde ilerler. Diğer taşların üzerinden atlayabilir.", "Atı g1'den f3'e götür.", "7k/8/8/8/8/8/8/6NK w - - 0 1", [("g1f3", "Atın L hamlesini başardın.")]),
            TrainingLesson("vezir", "Vezir nasıl oynar?", "Vezir hem kale gibi düz, hem fil gibi çapraz ilerler.", "d1'deki veziri h5'e götür.", "7k/8/8/8/8/8/8/3Q3K w - - 0 1", [("d1h5", "Vezirin çapraz hareketini gördün.")]),
            TrainingLesson("sah", "Şahı korumak", "Şah bir kare hareket eder; rakibin tehdit ettiği kareye gidemez.", "Şahı e1'den f2'ye götür.", "4k3/8/8/8/8/8/8/4K3 w - - 0 1", [("e1f2", "Şahın güvenli bir kareye geçti.")]),
            TrainingLesson("caprazalma", "Piyonla taş alma", "Piyonlar çapraz karedeki rakip taşı alır.", "e4 piyonu ile d5'teki siyah piyonu al.", "k7/8/8/3p4/4P3/8/8/7K w - - 0 1", [("e4d5", "Piyonla çapraz almayı öğrendin.")])
        ]),
        AcademyCourse(id: "kurallar", title: "2. Özel Kurallar", summary: "Şah, mat, rok, geçerken alma ve terfi.", symbol: "crown.fill", lessons: [
            TrainingLesson("sahcek", "Şah çek", "Rakip şahı tehdit altında kaldığında şah çekmiş olursun.", "Kalenle e2'den e7'ye çıkıp şah çek.", "4k3/8/8/8/8/8/4R3/4K3 w - - 0 1", [("e2e7", "Şah! Rakip şahı tehdit ettin.")]),
            TrainingLesson("mat", "Tek hamlede mat", "Şahın tehditten kurtulacak yasal hamlesi kalmıyorsa oyun mat ile biter.", "Veziri f7'den g7'ye götür.", "7k/5Q2/5K2/8/8/8/8/8 w - - 0 1", [("f7g7", "Şah mat! Rakibin şahı kaçamıyor.")]),
            TrainingLesson("rok", "Kısa rok", "Şah ve kale daha önce oynamadıysa, araları boşsa ve şah tehdit altından geçmiyorsa rok yapılır.", "Şahı e1'den g1'e taşı.", "4k3/8/8/8/8/8/8/4K2R w K - 0 1", [("e1g1", "Kısa rok ile şahını güvene aldın.")]),
            TrainingLesson("enpassant", "Geçerken alma", "Rakip piyon iki kare ilerleyerek senin piyonunun yanına gelirse hemen sonraki hamlede geçerken alma yapabilirsin.", "e5 piyonu ile d6'ya geçerken alma yap.", "4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1", [("e5d6", "Geçerken alma başarılı.")]),
            TrainingLesson("terfi", "Piyon terfisi", "Son sıraya ulaşan piyon vezire, kaleye, file veya ata dönüşebilir.", "a7 piyonunu a8'de vezire terfi ettir.", "7k/P7/8/8/8/8/8/7K w - - 0 1", [("a7a8q", "Piyon vezire dönüştü.")])
        ]),
        AcademyCourse(id: "plan", title: "3. İlk Stratejiler", summary: "Merkez kontrolü, taş geliştirme ve plan kurma.", symbol: "brain.head.profile", lessons: [
            TrainingLesson("d4", "Merkezi sahiplen", "d4 ve e4 karelerinde piyon bulunması merkezde alan kazandırır.", "d2 piyonunu d4'e ilerlet.", initial, [("d2d4", "Merkezi tuttun.")]),
            TrainingLesson("gelistirme", "Atını geliştir", "Atlar oyunun başında daha etkin karelere çıkmalıdır.", "g1 atını f3'e getir.", initial, [("g1f3", "Atın merkeze bakıyor.")]),
            TrainingLesson("italyan", "İtalyan Açılışı", "Önce merkez piyonu, sonra at ve fil geliştirilir. Amaç sadece hamle ezberlemek değildir.", "Siyahın yanıtlarını izle; e4, Af3 ve Fc4 oyna.", initial, [
                ("e2e4", "Merkezde alan kazandın."),
                ("e7e5", "Siyah da merkeze karşılık veriyor."),
                ("g1f3", "Atın e5'e baskı yapıyor."),
                ("b8c6", "Siyah e5 piyonunu savundu."),
                ("f1c4", "İtalyan Açılışı kuruldu.")
            ])
        ])
    ]

    static let puzzles: [TrainingLesson] = [
        TrainingLesson("puzzle-mat", "Tek Hamlede Mat", "Rakibin şahının kaçış karelerine bak.", "Vezirle g7'ye giderek mat yap.", "7k/5Q2/5K2/8/8/8/8/8 w - - 0 1", [("f7g7", "Mat hamlesini buldun.")]),
        TrainingLesson("puzzle-alma", "Piyonla Kazan", "Piyonun düz değil çapraz taş aldığını hatırla.", "d5'teki siyah piyonu al.", "k7/8/8/3p4/4P3/8/8/7K w - - 0 1", [("e4d5", "Doğru! Piyonla taş aldın.")]),
        TrainingLesson("puzzle-sah", "Şah Tehdidi", "Şah çekerek rakibini yanıt vermeye zorlayabilirsin.", "Kalenle e7'ye çık.", "4k3/8/8/8/8/8/4R3/4K3 w - - 0 1", [("e2e7", "Şahı tehdit ettin.")])
    ]
}