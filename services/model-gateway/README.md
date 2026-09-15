# TarlaPusula Model Gateway

Bu servis Python tabanlı tarım motorlarını React uygulamasından ayırır. Harici motorlar doğrudan UI veya Pusula AI tarafından çağrılmaz.

Akış:

`React / Supabase -> trusted backend -> Model Gateway -> engine adapter -> Decision Layer -> Pusula`

## Aktif motorlar

- `pyfao56`: shadow modda iki ayrı doğrulama yolu vardır:
  - referans ET0 + TarlaPusula'nın doğrulanmış günlük Kc değeriyle ETc karşılaştırması,
  - doğrulanmış basal Kcb, gerçek/kanıtlı başlangıç De-Dr durumu ve FAO REW alt/üst sınırlarını ayrı senaryolar halinde çalıştıran bounded dual-Kc su dengesi. REW aralığı keyfi bir orta değere düşürülmez.
- `PCSE/WOFOST`: pilot/readiness; gerçek tarla hava + ürün + toprak + site + agromanagement girdileri tamamlanmadan çalıştırılmaz.
- `AquaCrop-OSPy`: pilot/readiness; gerçek sezon/su/toprak girdileri tamamlanmadan çalıştırılmaz.

Bu motorların hiçbiri tek başına production sulama/tarım karar otoritesi değildir. Son kullanıcı kararı TarlaPusula karar katmanından geçer.

Aşağıdaki motorlar registry'de kayıtlıdır ancak kapalıdır: AutoGeoBound, OpenAgri Pest&Disease, AgML, FarmVibes.AI.

## Bağımlılıklar

Canonical Python bağımlılıkları ve motor sürümleri `requirements.txt` içinde pinlenir:

```bash
pip install -r requirements.txt
```

`requirements-pilot.txt` geriye uyumluluk için aynı canonical dosyayı referans eder; ayrı motor sürümü pinlemez.

## Tek uygulama entrypoint'i

Tüm deploy yolları aynı FastAPI uygulamasını çalıştırır:

`services/model-gateway/app.py -> app`

`dual_app.py` yalnız eski deploy komutları için geriye uyumlu bir re-export katmanıdır. Dual-Kc route'u da dahil olmak üzere bütün endpointler `app.py` içinde kayıtlıdır.

## Yerel çalıştırma

```bash
cd services/model-gateway
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8080
```

Development dışında `MODEL_GATEWAY_SHARED_KEY` tanımlanmalıdır. Bu anahtar frontend'e konmaz. `VITE_*` secret kullanılmaz.

## Ana endpointler

- `GET /health`
- `GET /v1/registry`
- `POST /v1/irrigation/pyfao56/shadow`
- `POST /v1/irrigation/pyfao56/dual-kc-shadow`
- `POST /v1/phenology/pcse/readiness`
- `POST /v1/phenology/pcse/pilot`
- `POST /v1/scenario/aquacrop/readiness`
- `POST /v1/scenario/aquacrop/pilot`

## Vercel yedek deploy yolu

Vercel projesinin Root Directory değeri `services/model-gateway` olmalıdır. `app.py` FastAPI entrypoint'idir; `vercel.json` fonksiyon süresini 60 saniyeye ayarlar.

Vercel ortam değişkenlerinde en az:

- `MODEL_GATEWAY_ENV=production`
- `MODEL_GATEWAY_SHARED_KEY=<server-only-secret>`

olmalıdır. Bu değerler mobil uygulamaya veya `VITE_*` değişkenlerine yazılmaz. Aynı secret Supabase model Edge Function tarafındaki `MODEL_GATEWAY_SHARED_KEY` ile eşleşmelidir; gateway URL de yalnız Supabase server secret'ı olarak tutulur.

## Güvenlik / veri ilkeleri

- Gateway public frontend endpoint'i değildir; yalnız trusted backend çağırır.
- Motor sonucu production otoritesi değildir; rollout registry belirler.
- Eksik tarla girdisi sahte/default tarla verisiyle doldurulmaz.
- pyfao56 shadow sonuçları mevcut production sulama kararını otomatik değiştirmez.
- Bounded dual-Kc shadow, FAO REW aralığını ayrı alt/üst senaryolar olarak taşır; sahte tek REW değeri üretmez.
- Tam su dengesi; doğrulanmış basal Kcb, yüzey buharlaşma durumu ve mevcut kök-bölgesi su durumu olmadan çalıştırılmaz.
- PCSE ve AquaCrop gerçek tarla girdileri tamamlanana kadar kullanıcı tavsiyesi üretmez.
- Upstream sürümleri bilinçli pin ile tutulur ve yükseltmeler benchmark ister.
