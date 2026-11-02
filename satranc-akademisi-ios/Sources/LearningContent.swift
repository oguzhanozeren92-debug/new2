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
            TrainingLesson("sahcek", "Şah çek", "Rakip şahı tehdit altında kaldığında şah çekmiş olursun.", "Kalenle a2'den e2'ye gelerek şah çek.", "4k3/8/8/8/8/8/R7/4K3 w - - 0 1", [("a2e2", "Şah! Rakip şahı tehdit ettin.")]),
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
        ]),
        AcademyCourse(id: "acilislar", title: "4. Açılış Akademisi", summary: "Lichess CC0 açılış verilerinden seçilmiş 11 gerçek açılışı tahtada uygula.", symbol: "book.closed.fill", lessons: [
            TrainingLesson("sicilya", "Sicilya Savunması", "ECO B20. Siyah, 1.e4'e ...c5 ile asimetrik karşılık verir. Temel fikir d4 karesini kontrol etmektir.", "e4 oyna ve siyahın c5 yanıtını izle.", initial, [
                ("e2e4", "Merkezde alan kazandın."),
                ("c7c5", "Siyah c piyonu ile d4 karesine baskı hazırladı.")
            ]),
            TrainingLesson("carokann", "Caro-Kann Savunması", "ECO B10. Siyah önce ...c6 oynayarak ...d5 merkez sürüşünü hazırlar.", "e4 oyna; rakibin c6 yanıtını incele.", initial, [
                ("e2e4", "Merkez kontrolü için ilk adım."),
                ("c7c6", "Siyah d5 sürüşüne hazırlık yapıyor.")
            ]),
            TrainingLesson("iskandinav", "İskandinav Savunması", "ECO B01. Siyah e4 piyonuna hemen ...d5 ile meydan okur.", "e4'ten sonra siyahın d5 hamlesini gör.", initial, [
                ("e2e4", "Merkezi tuttun."),
                ("d7d5", "Siyah e4 piyonuna doğrudan baskı yapıyor.")
            ]),
            TrainingLesson("fransiz", "Fransız Savunması", "ECO C00. Siyah önce ...e6 oynar, ardından ...d5 ile merkezi sorgulamayı planlar.", "e4 oynayıp ...e6 yapısını gözlemle.", initial, [
                ("e2e4", "Beyaz merkeze yerleşti."),
                ("e7e6", "Siyah ...d5 için hazırlık yaptı.")
            ]),
            TrainingLesson("ispanyol", "İspanyol Açılışı (Ruy Lopez)", "ECO C60. Fil b5'e çıkarak c6 atına baskı kurar; önemli olan e5 piyonuna dolaylı etkiyi anlamaktır.", "e4, Af3 ve Fb5 hamlelerini sırayla uygula.", initial, [
                ("e2e4", "Merkez için e4."),
                ("e7e5", "Siyah eşit şekilde merkeze geliyor."),
                ("g1f3", "At, e5 piyonunu tehdit ediyor."),
                ("b8c6", "Siyah e5 piyonunu savundu."),
                ("f1b5", "Fil, c6 atına baskı kuruyor.")
            ]),
            TrainingLesson("viyana", "Viyana Açılışı", "ECO C25. Beyaz 2.Ac3 ile e4 piyonunu destekler ve merkezi güçlendirir.", "e4, ardından b1 atıyla c3 oyna.", initial, [
                ("e2e4", "Merkez piyonu çıktı."),
                ("e7e5", "Siyah aynı fikre karşılık verdi."),
                ("b1c3", "At c3 karesinde e4'ü destekliyor.")
            ]),
            TrainingLesson("dortat", "Dört At Açılışı", "ECO C47. Dört at da doğal gelişim karelerine çıkar; açılışta taş geliştirme fikrini öğretir.", "Beyazın iki atını f3 ve c3'e geliştir.", initial, [
                ("e2e4", "Merkez açıldı."),
                ("e7e5", "Siyah merkezi dengeledi."),
                ("g1f3", "İlk at gelişiyor."),
                ("b8c6", "Siyah atını çıkardı."),
                ("b1c3", "İkinci at da gelişti."),
                ("g8f6", "İki tarafta dört at da oyunda.")
            ]),
            TrainingLesson("vezirgambiti", "Vezir Gambiti", "ECO D06. 1.d4 d5 2.c4 ile beyaz, siyahın d5 piyonunu merkezden uzaklaştırmayı hedefler.", "d4 ve c4 piyon hamlelerini uygula.", initial, [
                ("d2d4", "Merkezde d4 ile alan kazandın."),
                ("d7d5", "Siyah d5 ile karşılık verdi."),
                ("c2c4", "c4 piyonu d5'e baskı kuruyor.")
            ]),
            TrainingLesson("londra", "Londra Sistemi", "ECO A48. d4, Af3 ve Ff4 gelişimiyle düzenli bir yapı kur. Bu, tek zorunlu hamle sırası değildir.", "d4, Af3 ve Ff4 hamlelerini öğren.", initial, [
                ("d2d4", "Merkezi d4 ile kur."),
                ("g8f6", "Siyah atını geliştiriyor."),
                ("g1f3", "Beyaz da atını çıkarıyor."),
                ("g7g6", "Siyah filini g7'ye hazırlıyor."),
                ("c1f4", "Londra sisteminin tipik fil gelişimi.")
            ]),
            TrainingLesson("sahhint", "Şah-Hint Savunması", "ECO E61. Siyah ...Af6 ve ...g6 ile filini fianchetto yapmaya hazırlanır.", "d4 ve c4 oynadıktan sonra Ac3 geliştir.", initial, [
                ("d2d4", "Merkezde d4."),
                ("g8f6", "Siyah atını çıkardı."),
                ("c2c4", "Vezir kanadından alan kazan."),
                ("g7g6", "Siyah g7 filinin yolunu hazırlıyor."),
                ("b1c3", "Atını geliştirerek merkezi destekledin.")
            ]),
            TrainingLesson("ingiliz", "İngiliz Açılışı", "ECO A10. 1.c4, d5 karesi üzerinde etki kurar ve esnek merkez oyununa izin verir.", "c2 piyonunu c4'e sür.", initial, [
                ("c2c4", "İngiliz Açılışı: c piyonu d5 karesini denetliyor.")
            ])
        ]),
        AcademyCourse(id: "oyunsonu", title: "5. Oyun Sonu Temelleri", summary: "Şahı etkinleştir, geçer piyonları ve arka sıra matını tanı.", symbol: "flag.checkered", lessons: [
            TrainingLesson("aktif-sah", "Şahı etkinleştir", "Oyun sonunda şah aktif bir taştır. Güvenli bir merkez karesine ilerlemek çoğu zaman işe yarar.", "e1 şahını d2'ye getir.", "7k/8/8/8/8/8/8/4K3 w - - 0 1", [("e1d2", "Şahın merkeze yaklaşıyor.")]),
            TrainingLesson("gecer-piyon", "Geçer piyonu ilerlet", "Önünde aynı ya da komşu dikeylerde rakip piyon bulunmayan piyon geçer piyondur.", "e4 piyonunu e5'e sür.", "7k/8/8/8/4P3/8/8/4K3 w - - 0 1", [("e4e5", "Geçer piyonu terfiye yaklaştırdın.")]),
            TrainingLesson("sah-destek", "Şahla piyonu destekle", "Şahını geçer piyonun yakınına getirerek ilerlemesini kolaylaştır.", "Şahı e2'den e3'e götür.", "7k/8/8/8/4P3/8/4K3/8 w - - 0 1", [("e2e3", "Şah ve piyon beraber ilerliyor.")]),
            TrainingLesson("arka-sira", "Arka sıra matı", "Rakibin kaçış kareleri kendi piyonlarıyla kapanmışsa aktif kale arka sıradan mat edebilir.", "Kaleyi a1'den a8'e götür.", "6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1", [("a1a8", "Şah mat: siyah şah arka sıraya sıkıştı.")])
        ])
    ]

    static let puzzles: [TrainingLesson] = [
        TrainingLesson("puzzle-mat", "Tek Hamlede Mat", "Rakibin şahının kaçış karelerine bak.", "Vezirle g7'ye giderek mat yap.", "7k/5Q2/5K2/8/8/8/8/8 w - - 0 1", [("f7g7", "Mat hamlesini buldun.")]),
        TrainingLesson("puzzle-alma", "Piyonla Kazan", "Piyonun düz değil çapraz taş aldığını hatırla.", "d5'teki siyah piyonu al.", "k7/8/8/3p4/4P3/8/8/7K w - - 0 1", [("e4d5", "Doğru! Piyonla taş aldın.")]),
        TrainingLesson("puzzle-arka", "Arka Sıra Matı", "Kendi piyonlarının arkasına sıkışmış siyah şahı tek hamlede mat et.", "Kaleyi a8'e götürerek mat et.", "6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1", [("a1a8", "Tebrikler! Arka sıra matı.")]),
        TrainingLesson("puzzle-piyon-terfi", "Terfi Yarışı", "Piyonun son sıraya bir kare uzaklıkta. Kazanan yükseltmeyi bul.", "a7 piyonunu vezire terfi ettir.", "7k/P7/8/8/8/8/8/7K w - - 0 1", [("a7a8q", "Yeni vezir oyuna girdi.")]),
        TrainingLesson("puzzle-rok", "Şahını Güvene Al", "Rakip saldırısına karşı şah güvenliği önemlidir.", "Kısa rok yap.", "4k3/8/8/8/8/8/8/4K2R w K - 0 1", [("e1g1", "Şahını güvenli konuma aldın.")]),
        TrainingLesson("puzzle-sah", "Şah Tehdidi", "Şah çekerek rakibini yanıt vermeye zorlayabilirsin.", "Kalenle a2'den e2'ye gel.", "4k3/8/8/8/8/8/R7/4K3 w - - 0 1", [("a2e2", "Şahı tehdit ettin.")])
    ]
}