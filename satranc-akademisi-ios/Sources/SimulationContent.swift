import Foundation

/// Scenario scripts are original educational situations. Opponent replies are
/// deliberately simple; ChessKit, not this data, determines legal chess moves.
struct SimulationBeat: Identifiable {
    let uci: String
    let purpose: String
    let coachExplanation: String
    var id: String { uci }
}

struct ChessScenario: Identifiable {
    let id: String
    let title: String
    let difficulty: String
    let story: String
    let mission: String
    let startFen: String
    let beats: [SimulationBeat]
    let takeaway: String

    var isFreePlay: Bool { beats.isEmpty }

    static let all: [ChessScenario] = [
        .init(
            id: "ilk-mini-mac", title: "İlk Mini Maçın", difficulty: "Sıfırdan",
            story: "İlk defa gerçek bir maçın başındasın. Acele yok! Beyaz taşlar sende. Sana yardımcı olacağım, siyah ise sırayla basit karşı hamleler yapacak.",
            mission: "Önce merkezde bir piyon sür, sonra at ve filini geliştir, en sonunda şahını rok ile koru.",
            startFen: AcademyCourse.initial,
            beats: [
                .init(uci:"e2e4", purpose:"e2'deki piyonu iki kare ileri e4'e sür.", coachExplanation:"Merkeze doğru alan kazandın. İlk piyonunu geliştirdin."),
                .init(uci:"e7e5", purpose:"Siyah da merkezi tutmak istiyor.", coachExplanation:"Rakip de e5 oynadı. İki tarafın merkez mücadelesi başladı."),
                .init(uci:"g1f3", purpose:"g1'deki atı f3'e getir.", coachExplanation:"At geliştirdin ve siyahın e5 piyonunu tehdit etmeye başladın."),
                .init(uci:"b8c6", purpose:"Siyah atıyla e5 piyonunu koruyor.", coachExplanation:"Rakibin c6 atı, e5 piyonuna destek verdi."),
                .init(uci:"f1c4", purpose:"f1'deki fili c4'e götür.", coachExplanation:"Filin oyuna çıktı. Siyahın zayıf f7 karesine bakıyor."),
                .init(uci:"g8f6", purpose:"Siyah ikinci atını geliştiriyor.", coachExplanation:"Rakip de taş geliştirdi. Acele vezir çıkarmak zorunda değilsin."),
                .init(uci:"e1g1", purpose:"Şahını kısa rok ile koru: şahı e1'den g1'e taşı.", coachExplanation:"Rok yaptın! Şahın güvenli bir köşeye geçti, h1 kalesi de oyuna yaklaşmış oldu.")
            ],
            takeaway:"Bir açılışta önce merkezi tut, at ve filini çıkar, şah güvenliğini sağla. Ezber değil, mantık!"
        ),
        .init(
            id:"piyon-kurtarma", title:"Piyonla İlk Taşını Al", difficulty:"Çok kolay",
            story:"Rakip bir piyonunu senin piyonunun çaprazına bıraktı. Burada taş almak için savaşa girmene gerek yok; piyonun kuralını kullan.",
            mission:"e4'teki piyonu d5'e götürerek siyah piyonu al.",
            startFen:"7k/8/8/3p4/4P3/8/8/7K w - - 0 1",
            beats:[.init(uci:"e4d5", purpose:"e4 piyonuyla d5'teki siyah piyonu al.", coachExplanation:"Piyon ileri hareket eder ama çaprazdaki rakip taşı alır. İlk taşını kazandın!")],
            takeaway:"Piyon düz gider, çapraz taş alır. Her hamlede neyin tehdit edildiğine bak."
        ),
        .init(
            id:"sah-tehlikede", title:"Şahın Tehlikede!", difficulty:"Çok kolay",
            story:"Rakibin kalesi şahına doğru bakıyor. Önce saldırıya devam edemezsin; şahını tehlikeden çıkarmalısın.",
            mission:"Beyaz şahı e1'den f1'e götür ve saldırıdan kurtar.",
            startFen:"4k3/8/8/8/8/8/4r3/4K3 w - - 0 1",
            beats:[.init(uci:"e1f1", purpose:"Şahını f1 karesine güvenle götür.", coachExplanation:"Şahı güvenli kareye taşıdın. Şah çekildiğinde ilk iş tehdidi çözmektir.")],
            takeaway:"Şahına saldırı varsa önce onu savun. Saldırı altında hamle yapamazsın."
        ),
        .init(
            id:"at-catal", title:"İki Hedefe Tek At", difficulty:"Kolay",
            story:"Siyahın şahı ve veziri birbirine yakın duruyor. Atın tek hamlede ikisini birden tehdit edebilir mi?",
            mission:"e4'teki atı f6'ya getir ve çatal yap.",
            startFen:"6k1/3q4/8/8/4N3/8/8/7K w - - 0 1",
            beats:[.init(uci:"e4f6", purpose:"Atı e4'ten f6'ya götür.", coachExplanation:"Atın hem g8'deki şaha hem d7'deki vezire saldırıyor! Bu taktiğin adı çatal.")],
            takeaway:"Tek hamlede iki tehdit kurmak çoğu zaman taş kazandırır."
        ),
        .init(
            id:"korunan-at", title:"Filinle Atı Sabitle", difficulty:"Kolay",
            story:"Siyah at c6'da, şahı e8'de. Atın önünden çekilmesi şaha doğrudan saldırı doğuracak bir fil hamlesi bul.",
            mission:"c4 filini b5'e götürerek açmaz yap.",
            startFen:"4k3/8/2n5/8/2B5/8/8/7K w - - 0 1",
            beats:[.init(uci:"c4b5", purpose:"Beyaz fili c4'ten b5'e getir.", coachExplanation:"Fil b5'ten e8 şahına bakıyor; önündeki c6 atı ayrılamaz. Bu bir mutlak açmaz.")],
            takeaway:"Bir taşın arkasında şah varsa, öndeki taş bazen hareket edemez."
        ),
        .init(
            id:"ilk-mat", title:"İlk Şah Matın", difficulty:"Kolay",
            story:"Siyah şah köşeye sıkışmış. Vezir ve şahın beraber çalışıyor. Tek doğru hamlede oyun bitecek.",
            mission:"f7'deki veziri g7'ye götür ve matı bul.",
            startFen:"7k/5Q2/5K2/8/8/8/8/8 w - - 0 1",
            beats:[.init(uci:"f7g7", purpose:"Veziri f7'den g7'ye taşı.", coachExplanation:"Şah mat! Siyah şahın kaçacak veya tehdidi durduracak yasal hamlesi kalmadı.")],
            takeaway:"Şahı mat etmek taş almak değil, tüm kaçış ve savunma seçeneklerini kapatmaktır."
        ),
        .init(
            id:"serbest-koclu", title:"Koçlu Serbest Maç", difficulty:"Serbest",
            story:"Burada zorunlu hamle yok. Sen beyazlarla oynarken ben her hamlenin ne yaptığına bakacağım; siyah da temel bir bilgisayar rakibi olarak oynayacak.",
            mission:"İstediğin yasal hamleyi yap. Her hamlenin yorumunu oku; bitirince raporu incele.",
            startFen: AcademyCourse.initial, beats: [],
            takeaway:"Her maçta öğrendiğin en az bir iyi hamleyi ve geliştirmen gereken bir davranışı hatırla."
        )
    ]
}
