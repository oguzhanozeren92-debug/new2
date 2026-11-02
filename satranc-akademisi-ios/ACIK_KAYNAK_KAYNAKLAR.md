# Satranç Akademisi — Açık kaynak envanteri (2 Kasım 2026)

Bu dosya seçilen bileşenlerin kaynaklarını ve lisans denetimini belgeler. Kodları yalnızca lisans koşullarına uygun şekilde kullanın.

## Üründe kullanılan bileşenler

| Bileşen | Kaynak | Lisans | Kullanım |
| --- | --- | --- | --- |
| ChessboardKit | https://github.com/rohanrhu/ChessboardKit | MIT | iOS / SwiftUI satranç tahtası ve taş görselleri (Swift Package) |
| ChessKit | https://github.com/aperechnev/ChessKit | MIT | iOS yasal hamleler, pozisyon, FEN ve oyun akışı (Swift Package) |
| chess.js | https://github.com/jhlywa/chess.js | BSD-2-Clause | Web eğitimleri, pozisyonlar, yasal hamle kontrolü, mat/beraberlik ve bot için oyun durumu (ES module) |
| lichess-org/chess-openings | https://github.com/lichess-org/chess-openings | CC0-1.0 (public domain dedication) | Açılışların ECO kodları, isimleri ve temel hamle sıraları |
| Lichess Open Database - puzzles | https://database.lichess.org/#puzzles | CC0-1.0 | Taktik temaları ve dereceleri için kaynak; otomatik seçme scripti eklendi, veri tabanı **henüz ürüne alınmadı** |

## Lichess üzerinden eklenen açılışlar

Aşağıdaki 11 açılışın ECO kodu, temel hamle sırası ve adı Lichess açılış veri dosyalarıyla eşleştirildi; Türkçe anlatım ve hedefler Satranç Akademisi için özgün yazıldı.

- B20: Sicilian Defense — `1.e4 c5`
- B10: Caro-Kann Defense — `1.e4 c6`
- B01: Scandinavian Defense — `1.e4 d5`
- C00: French Defense — `1.e4 e6`
- C60: Ruy Lopez — `1.e4 e5 2.Nf3 Nc6 3.Bb5`
- C25: Vienna Game — `1.e4 e5 2.Nc3`
- C47: Four Knights Game — `1.e4 e5 2.Nf3 Nc6 3.Nc3 Nf6`
- D06: Queen's Gambit — `1.d4 d5 2.c4`
- A48: London System — `1.d4 Nf6 2.Nf3 g6 3.Bf4`
- E61: King's Indian Defense — `1.d4 Nf6 2.c4 g6 3.Nc3`
- A10: English Opening — `1.c4`

Kaynak TSV: https://github.com/lichess-org/chess-openings/tree/master (`a.tsv`, `b.tsv`, `c.tsv`, `d.tsv`, `e.tsv`).
Kullanım biçimi: Oyuncu beyaz hamlelerini tahtada yapar; kısa örneklerde siyah hamleleri eğitim gösterimi olarak oynatılır. Yasal hamlelerin tamamını otomatik doğrulamak ve gerçek cihaz testi yayımdan önce zorunludur.

## Lisans ve dağıtım notları

- ChessboardKit MIT: https://github.com/rohanrhu/ChessboardKit/blob/main/LICENSE
- ChessKit MIT: https://github.com/aperechnev/ChessKit/blob/master/LICENSE
- chess.js BSD-2-Clause: https://github.com/jhlywa/chess.js/blob/master/LICENSE
- Lichess açılış verisi CC0: https://github.com/lichess-org/chess-openings/blob/master/README.md

MIT ve BSD lisanslarının gerektirdiği telif, lisans ve sorumluluk reddi bildirimleri nihai App Store / web dağıtımının dokümantasyon ve lisans ekranına eklenmelidir. Kaynaklara yalnızca bağlantı vermek dağıtıma ait tüm yükümlülükleri otomatik olarak karşılamaz. Paketler bu projede doğrudan kopyalanmadı; iOS tarafı Swift Package Manager ile bağımlılık kullanıyor.

## Bilinçli olarak kopyalanmayanlar

- Chessground (lichess-org/chessground) — GPLv3.
- Lichess sunucu uygulaması (lichess-org/lila) — AGPLv3.
- Stockfish/Stockfish.js — GPL kapsamındaki motorlar için kaynak kod, dağıtım ve lisans uyumluluğu ayrıca değerlendirilmeli. Bu sürüm Stockfish veya resmî ELO gücü iddia etmez.

## Projedeki son durum

- iPhone SwiftUI: 36 ders (ilk 16 + 11 açılış + 4 oyun sonu + 5 taktik), 11 bulmaca, 10 açıklamalı taktik kavramı ve 3 basit bot seviyesi.
- Web yedek prototipi: 36 ders ve 11 bulmaca eşleştirildi. Web hâlâ canlı kullanım için doğrulanmadı.
- iOS gerçek derleme, oynanış otomasyon testleri, TestFlight ve web canlı erişim testi **henüz doğrulanmadı**.
- Vercel'in ücretsiz günlük dağıtım kotası dolduğu için web sürümünü canlıya yeniden dağıtma işlemi ayrıca yapılmalı.
