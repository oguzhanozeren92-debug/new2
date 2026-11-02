# Satranç Akademisi — iPhone native kaynakları

**Durum: iOS 17+ için SwiftUI proje taslağıdır; Xcode/Codemagic derlemesi, gerçek iPhone testi ve Apple App Review yapılmadı.**

## Kapsam
- Sadece iPhone (`TARGETED_DEVICE_FAMILY=1`).
- SwiftUI ana ekran, **31 uygulamalı ders (11 Lichess CC0 açılışı ve 4 oyun sonu dersi dahil)**, **6 bulmaca**, Kolay/Orta/Zor botlu oyun, profil, yerel ilerleme silme.
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

- Web ve iOS kaynaklarındaki 31 ders ile 6 bulmacanın FEN/hamle eşleşmeleri ve kimlik tekilliği yapısal olarak kontrol edildi. **Bu gerçek satranç motoruyla oynanış testi değildir.**
- Tam yasal hamle ve mat doğrulaması için geliştirme aracı: `python3 -m pip install python-chess && python3 satranc-akademisi-ios/Tools/validate_lessons.py`. Bu test App Store dağıtımından önce çalıştırılmalıdır.
- Kullanılan MIT, BSD-2 ve CC0 kaynakları: [ACIK_KAYNAK_KAYNAKLAR.md](ACIK_KAYNAK_KAYNAKLAR.md).
- Bot güçleri pedagojik amaçlıdır; Stockfish motoru, rakip eşleştirme sistemi veya resmî ELO karşılığı değildir.
