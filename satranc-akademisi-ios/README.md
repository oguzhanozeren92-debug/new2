# Satranç Akademisi — iPhone native kaynakları

**Durum: iOS 17+ için SwiftUI proje taslağıdır; Xcode/Codemagic derlemesi, gerçek iPhone testi ve Apple App Review yapılmadı.**

## Kapsam
- Sadece iPhone (`TARGETED_DEVICE_FAMILY=1`).
- SwiftUI ana ekran, **43 uygulamalı ders (7 ilk hamle, 11 Lichess CC0 açılışı, 5 taktik dersi ve 4 oyun sonu dersi dahil)**, **11 bulmaca**, Kolay/Orta/Zor botlu oyun, profil, yerel ilerleme silme.
- Apple safe-area uyumlu native görünüm; Dynamic Type uyumlu metinler ve çoğunlukla en az 44 pt dokunma alanları.
- Giriş zorunlu değil: rumuz veya misafir; seviye seçerken yazı silinmez.
- Satranç tahtası: ChessboardKit ve ChessKit; MIT kaynaklar. Botlar basit ve gerçek ELO seviyesiyle kalibre edilmemiş.
- Uygulama içinde reklam, gerçek para, IAP, Apple Sign In, konum/galeri/mikrofon izni ve sunucu hesabı yok.

## Xcode
Bu depodaki `project.yml` XcodeGen konfigürasyonudur. macOS / Xcode 26 ile:

1. `brew install xcodegen`
2. `xcodegen generate`
3. `open SatrancAkademisi.xcodeproj`
4. Xcode'da kendi Apple Developer takımını seç; bundle kimliğini App Store Connect ile eşleştir.
5. iPhone aygıtında giriş / ders / mat / bot / veri silmeyi test et.

## Apple App Store öncesi gerekenler
- Xcode ve gerçek iPhone testleri; farklı ekran boyutu, VoiceOver, Dynamic Type, açık/koyu görünüm, erişilebilirlik.
- TestFlight derlemesi için otomatik signing/provisioning ve App Store Connect'te uygulama kaydı.
- Gizlilik Politikası'nın herkese açık kalıcı HTTPS adresi ve uygulama içindeki gizlilik metninin gerçek SDK/ağ davranışıyla eşleşmesi.
- App Store açıklamaları, ekran görüntüleri, app icon, destek adresi, yaş sınıflandırması, inceleme notları.
- Derslerin FEN ve UCI geçerliliğinin otomatik testlerle doğrulanması.
- Paket sürümlerinin Xcode'da gerçek derleme ile doğrulanması; ChessboardKit API değişmiş olabilir.
- Bağımlılıkların telif/lisans dosyalarını dağıtım paketine dahil et.

## Gizlilik
Rumuz, eğitim ilerlemesi ve seçilen seviye yalnızca iPhone üzerindeki `UserDefaults` içinde tutulur. Profil menüsündeki "Yerel ilerlemeyi ve profili sil" işlemi bu kayıtları siler. E-posta, reklam kimliği, GPS konumu, kamera veya mikrofon kullanılmaz.

## Kaynaklar
- `ChessboardKit`: https://github.com/rohanrhu/ChessboardKit (MIT)
- `ChessKit`: https://github.com/aperechnev/ChessKit (MIT)
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/

Not: ChessboardKit'in ChessKit 1.x bağımlılığı olduğu için iki paket 1.x sürümde hizalı tutuldu. Xcode paket çözümlemesini doğrulamadan sürüm 2.x'e sabitlenmemeli.
## İçerik kalite kontrolü (2 Kasım 2026)

- Web ve iOS kaynaklarındaki 43 ders ile 11 bulmacanın FEN/hamle eşleşmeleri ve kimlik tekilliği yapısal olarak kontrol edildi. **Bu gerçek satranç motoruyla oynanış testi değildir.**
- Tam yasal hamle ve mat doğrulaması için geliştirme aracı: `python3 -m pip install python-chess && python3 satranc-akademisi-ios/Tools/validate_lessons.py`. Bu test App Store dağıtımından önce çalıştırılmalıdır.
- Kullanılan MIT, BSD-2 ve CC0 kaynakları: [ACIK_KAYNAK_KAYNAKLAR.md](ACIK_KAYNAK_KAYNAKLAR.md).
- Bot güçleri pedagojik amaçlıdır; Stockfish motoru, rakip eşleştirme sistemi veya resmî ELO karşılığı değildir.

## Sıfırdan satranç eğitimi — öğrenme yolu

- Dersler ekranının en başında **Hamlelerin Dili** (e4, Af3/Nf3, taş alma, rok, şah, mat ve terfi) ve **Taktik Sözlüğü** bulunur.
- On adet taktik adı, Türkçe açıklama, hamleyi fark etme ipucu, akılda kalacak cümle ve sık yapılan hata örneğiyle sunulur.
- Çatal, açmaz, şiş, keşif saldırısı ve çifte şah: 5 uygulamalı ders ve 5 ek bulmaca. Dersler yalnızca doğru hamle tahtada oynanınca tamamlanır.
- Hamle yapıldıktan sonra Türkçe açıklama görüntülenir: **At e4 → f6 · ŞAH!** gibi. İngilizce/Türkçe hamle harfi dönüşüm rehberi sunulur.
- Bütün 54 eğitim kaydı, iOS ve web içerikleri arasında karşılaştırılarak 0x88 satranç kurallarıyla hamle yasallığı açısından ayrıca kontrol edildi (2 Kasım 2026). Bu, Codemagic/Xcode gerçek derleme ve cihaz testi değildir.
- Lichess'in CC0 bulmaca verisinden zorluk ve motif filtreli aday çıkarma aracı: `Tools/import_lichess_tactics.py`. Kullanım ve kaynak: `https://database.lichess.org/#puzzles`.
- Büyük puzzle aktarımı **otomatik yayın yapmaz**; durum `draft_requires_review_not_live` olarak tutulur. Eğitici açıklamaların kalitesini doğrulamadan bulmaca yayınlanmamalı.

## Yeni başlayanlar için 0. seviye (2 Kasım 2026)

Ana ekrandaki **“Sıfırdan Başla — Hiç bilmiyorum”** bölümü satranç notasyonu bilmeden açılır. Dört hazırlık aşaması ve ilk hamleye geçiş:

1. Satranç nedir? Hedef şah mat etmek; şahı fiziksel olarak taş almaya çalışmak değildir.
2. Altı taşı gerçek simgelerinden tanıma; her birinin hareketi ve ismi açıklanır. Altısını da dokunarak keşfetme.
3. Kurallara uygun başlangıç dizilişindeki 64 karelik tahtada beyaz piyonu bulma. Tahta yönü ve kare sistemi görsel anlatılır.
4. Beyaz mı siyah mı başlar? Hatasız ilerleme zorunlu değil, yanlış seçime açıklama verilir.
5. **İlk gerçek hamle**: e2–e3, tek karelik piyon hareketi. Yeni başlayanlar için kaynak ve hedef kareleri kendiliğinden işaretlenir.

Bundan sonra **“0. İlk Hamle Alıştırmaları”** içinde ikinci piyon, kale, fil, at, vezir ve şah için birer çok kolay hamle vardır. Taktik, özel kurallar ve hamle notasyonu rehberi sonraki aşamada görünür; ayrı kayıt ve rumuz gerekmez. Bütün alıştırmalar tekrar oynanabilir, süre sınırı ve hata cezası yoktur.

**Dikkat:** SwiftUI başlangıç öğreticisi yeni eklendi; gerçek Xcode derlemesi, cihazda erişilebilirlik ve bütün animasyon akışı henüz doğrulanmadı.

## Senaryolu Satranç Simülatörü ve Hamle Hocası (2 Kasım 2026)

Ana sayfa ve Dersler ekranına **Senaryolu Simülasyon** girişi eklendi. iOS kaynakları:
- `Sources/SimulationContent.swift` — altı rehberli senaryo: ilk mini maç, piyonla taş alma, şahı kurtarma, at çatalı, mutlak açmaz ve mat. Bunlara ek olarak bir **koçlu serbest maç** bulunur.
- `Sources/SimulationViews.swift` — 8x8 oynanabilir satranç tahtası, oyuncunun gerçek hamlesi, rakibin senaryo hamlesi, istenirse ipucu, yanlış yola sapınca serbest devam, geri alma, yeniden başlatma ve sonuç ekranı.
- `Sources/SimulationCoach.swift` — ChessKit üzerinden **her yasal hamleyi** inceler: mevcut hedef, taş alma, şah, mat, pat, oynanan taşın bir sonraki hamlede alınabilme riski ve rakibin tek hamlede mat tehdidi. Rakibin hamleleri de ayrı ayrı raporlanır.
- `Sources/SimulationReplay.swift` — senaryo raporundaki **tahtalı geri/ileri oynatma**, her hamleyle eşzamanlı Türkçe açıklama ve uyarı.
- Her hamle için sahici **FEN öncesi/sonrası** ve rehber ilerleme kaydı tutulur; geri alma tam FEN durumunu geri yükler.
- Senaryo doğru tamamlanınca yerel `academy.scenarios.completed` anahtarına kaydedilir. **Bütün hamle listesi oturumda tutulur; henüz bulut senkronu veya kalıcı geçmiş özelliği yoktur.**

Senaryo dizilerinin tamamı 0x88 satranç kurallarıyla doğrulandı: örneklerde **yasal olmayan hamle yok**, mat senaryosu gerçekten mat ile biter. Ancak iPhone'da Xcode/Codemagic derlemesi, gerçek cihaz testi ve oynanış/erişilebilirlik doğrulaması **henüz yapılmadı**.

**Önemli şeffaflık notu:** Hamle Hocası bu ilk sürümde **kural ve bir hamle derinliğindeki taktik kontrolü** kullanır. Bu sistem Stockfish, güçlü motorla derin varyasyon taraması, bulut yapay zekâsı veya kesin “en iyi hamle” analizi değildir. İleri düzey alternatif hamle sıralaması ve puanlama için lisans şartları gözetilerek ayrı bir motor entegrasyonu yapılmalıdır.
