# Satranç Akademisi – iPhone / App Store kontrol listesi (31 Ekim 2026)

## Hazırlanan
- [x] iOS 17+ native SwiftUI proje kaynağı
- [x] TARGETED_DEVICE_FAMILY = 1; iPhone odaklı
- [x] SwiftUI safe-area ve dinamik metin kullanımı
- [x] MIT lisanslı ChessboardKit ve ChessKit satranç bağımlılıkları
- [x] Açıklamalı ders, hamleyi oyuncuya yaptırma, yanlış hamlede dersi tamamlamama
- [x] Basit üç seviyeli bot taslağı; ELO kalibrasyonu yok
- [x] Rumuz kalıcı; seviye değiştirmek rumuzu silmez; misafir giriş
- [x] Yerel eğitim ilerlemesini ve profili silme akışı
- [x] 1024x1024 AppIcon üreten script ve asset tanımı
- [x] Codemagic unsigned iPhone simulator derlemesi için YAML
- [x] Gizlilik ve destek metni kaynakları
- [x] Swift dosyaları yerelde Swift sözdizimi kontrolünden geçti; Xcode derlemesi değildir

## App Store'a göndermeden önce zorunlu
- [ ] Codemagic/Xcode iOS simulator derlemesi başarılı olmalı
- [ ] Gerçek iPhone eğitim, bot, mat, rok, geçerken alma, terfi ve profil silme testi
- [ ] Tüm derslerin FEN/UCI pozisyon ve hamleleri otomatik doğrulanmalı
- [ ] VoiceOver, Dynamic Type, küçük iPhone, safe-area ve Dynamic Island testleri
- [ ] Bundle ID App Store Connect'te kaydedilmeli; Apple signing ve provisioning bağlanmalı
- [ ] TestFlight cihaz testi ve gerçek App Store ekran görüntüleri
- [ ] Kalıcı, herkese açık HTTPS gizlilik politikası ve destek URL'leri uygulamaya ve App Store Connect'e eklenmeli
- [ ] App Privacy beyanı gerçekten kullanılan SDK ve verilere göre doldurulmalı
- [ ] Açıklama ve görüntüler uygulamada gerçekten bulunan işlevleri yansıtmalı
- [ ] Bot seviyeleri test edilmeli; Stockfish veya resmî ELO iddia edilmemeli
- [ ] App Review 2.1, 2.3.10, 4.2 ve 5.1.1 maddeleri tekrar denetlenmeli

## Codemagic
GitHub deposu: oguzhanozeren92-debug/new2
YAML dosyası: satranc-akademisi-ios/codemagic.yaml
Codemagic uygulama ayarlarında YAML yolu belirtilmelidir. Komutlar repo içindeki satranc-akademisi-ios klasöründe çalışır.
Bu workflow bir simulator build testidir, App Store dağıtımı değildir.

## Resmî kaynaklar
https://developer.apple.com/app-store/review/guidelines/
https://developer.apple.com/design/human-interface-guidelines/designing-for-ios/
https://developer.apple.com/design/tips/
