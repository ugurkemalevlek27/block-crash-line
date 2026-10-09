# Block Crash Line — Flutter MVP / Android test sürümü

Bu paket Flutter/Dart kaynak projesi, Android/iOS platform dosyaları ve Android test APK’sını üretmek için gereken yapılandırmayı içerir. Flutter 3.29.3 / Dart 3.7.2 ile **30 otomatik test geçti**, analyzer hata bulmadı. Android release APK başarıyla üretildi (25,1 MB), imzası doğrulandı; Android 5.0/API 21 ve üzerini destekler. Android sürümü yerel test anahtarıyla imzalanır; üretim/mağaza anahtarı değildir. Gerçek telefonda ses, fotoğraf seçici ve yaşam döngüsü kontrolü ayrıca yapılmalıdır. iOS derlemesi bu Linux ortamında yapılmadı.

Android yükleme: `ANDROID_INSTALL_TR.md`. APK arşivden ayrı teslim edilir.

## Hemen oynama

`Block_Crash_Line_Playable_Preview.html` dosyasını bilgisayar veya telefon tarayıcısında açın. Dosya; dört mod, 20 bölüm, temalar, ödüller, ses ve kayıt içeren **ayrı bir tarayıcı provasıdır**. İnternet veya CDN kullanmaz; bütün sesler, görseller ve bölüm verileri dosyanın içindedir. Flutter APK’sının yerine geçmez.

- Parçayı seçin, ardından tahtada sol üst yerleştirme hücresine dokunun; veya sürükleyin.
- Sürüklenen parçanın sol üst köşesi parmağın üzerinde tutulur. Önizleme bırakılacak yeri gösterir.
- Bomba seçildikten sonra tahtaya dokunmak 3×3 alanın merkezini belirler.
- İlk macera bölümü açıktır. Başarılı bölüm bir sonrakini açar.
- Müziğin başlaması için ilk düğmeye dokunmak gerekir (tarayıcı otomatik oynatma kuralı).
- Yerel dosya açıldığında depolama engellenirse, bu klasörde `python3 -m http.server 8080` çalıştırıp `http://localhost:8080/Block_Crash_Line_Playable_Preview.html` adresini açın.
- Tarayıcı provası `performance.now()` kullanır; işletim sistemi derin uyku davranışı tarayıcıya göre değişebilir. Native Time Attack, aşağıda açıklanan sürekli cihaz saatini kullanır.

## Flutter kurulumu ve çalıştırma

Önerilen ilk doğrulama tabanı: Flutter 3.29.3 / Dart 3.7.2, Java 17. Üst sürüm kullanılacaksa ayrıca bağımlılık ve platform uyumluluğu kontrol edin. Python 3 platform kurulum aracını çalıştırmak içindir, oyun Python kullanmaz.

```bash
cd block_crash
flutter doctor
flutter pub get
# Platform dosyalarını yeniden oluşturmak gerekirse: python3 tool/bootstrap.py

dart format lib test
flutter analyze
flutter test
flutter run
```

`bootstrap.py`, resmi `flutter create` komutuyla geçici bir proje açıp `android/` ve `ios/` platform kabuklarını kaynakların yanına kopyalar. **Mevcut oyun kaynaklarını değiştirmez.** Ardından Kotlin/Swift sürekli saat köprülerini ve iOS fotoğraf açıklamasını kurar, `flutter pub get` çalıştırır. Android ve iOS platform dosyaları bu teslimde oluşturulmuştur; bootstrap ilk çalıştırma için gerekli değildir. `platform_templates/` bizim native eklerimizi içerir.

Ana bağımlılık sürümleri pubspec içinde sabitlenmiştir. Doğrulamada kullanılan `pubspec.lock` teslim edilmiştir.

### Android APK

Android Studio / Android SDK kurulu, lisanslar kabul edilmiş olmalıdır:

```bash
flutter doctor --android-licenses
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Release imzası `android/key.properties` dosyasındaki özel upload key ile yapılır (örnek: `android/key.properties.example`); test anahtarı kaldırılmıştır. Bkz. `RELEASE_0.1.2_PLAY_HAZIRLIK.md`. Mağaza dağıtımı için kendi gizli keystore imzanızı yapılandırın, ardından `flutter build apk --release` veya `flutter build appbundle --release` çalıştırın. Paket kimliği başlangıçta `com.uke.block_crash`; mağazada kullanmadan önce sizin nihai kimliğinizle sabitleyin. Debug APK ile test; mağazaya yükleme ayrı işlemlerdir.

### iOS

macOS, uyumlu Xcode ve CocoaPods gereklidir. Mac üzerinde:

```bash
flutter pub get
flutter build ios --debug --no-codesign
open ios/Runner.xcworkspace
```

Xcode’da Runner için kendi Apple ekibinizi, bundle identifier ve signing ayarlarınızı seçin. Gerçek cihazı seçip Run çalıştırın. App Store dağıtımı için Archive / signing işlemleri gerekir. `NSPhotoLibraryUsageDescription` bootstrap ile eklenir; kamera ve mikrofon istenmez. `mach_continuous_time` köprüsü cihaz uyku süresini saymak için kullanılır. Güncel App Store privacy manifest / gerekli API beyanları dağıtım aşamasında resmi Apple kurallarına göre kontrol edilmelidir.

## Mimari

| Bileşen | Dosyalar | İşlev |
| --- | --- | --- |
| Saf Dart motor | `lib/engine/game.dart`, `shapes.dart` | 8×8 tahta, yerleştirme, çizgiler, puan, modlar, bombalar |
| Bölümler | `lib/levels/level.dart`, `assets/levels/levels.json` | Açık başlangıç tahtaları, sabit üçlüler, hedefler, sınırlar, yıldız koşulları ve çözümler |
| Ekonomi | `lib/economy/profile.dart` | Bakiye, satın alma, ödül defteri, günlük görev, başarılar, kilit kontrolü |
| Kayıt | `lib/persistence/store.dart` | Tek JSON snapshot, flush + atomik rename, geçerli önceki yedek, bozuk Classic kurtarma |
| Durum | `lib/controller.dart` | Riverpod ChangeNotifier, kayıt tamamlandıktan sonra hamleyi gösterme, hata halinde geri alma |
| Ses | `lib/audio/audio_manager.dart` | Yerel WAV, seviyeler, shuffle, arka planda durdurma |
| UI | `lib/ui/` | Menü, modlar, harita, mağaza, ayarlar, sonuç, sürükleme ve dokunma |
| Süre | `lib/engine/clock.dart`, `platform_templates/` | Android elapsedRealtime / iOS mach_continuous_time |
| Tanıtım | `marketing/block-crash-line/index.html`, `SEO.md` | Verilen SEO başlığı, açıklama, H1/H2 ve sosyal etiketler |

Motor UI’dan bağımsızdır; `clock.dart` yalnızca platform saat adaptörüdür. Motor, toplam geçen milisaniyeyi dışarıdan alır. Hesap, sunucu, reklam SDK’sı veya ödeme kodu yoktur. Platform achievement arayüzü vardır; Google Play Games veya Game Center bağlı olarak gösterilmez.

### Atomik ödül ve kayıt davranışı

Her kabul edilen hamlede motor ve profil kopyaları hazırlanır. Jetonlar, bir defalık ödül anahtarları, yıldızlar ve devam eden Classic tek dosyada kaydedilir. Dosya kaydı başarılı olmadan bu hamle UI’da geçerli sayılmaz. Kayıt başarısızsa tahta ve bakiye önceki durumda kalır. Günlük tarih için ileri giden yerel takvim günü kullanılır; geriye alınan tarih aynı günün ödülünü yeniden açmaz. Özel fotoğraf uygulama support dizinine kopyalanır; iptalde arka plan değiştirilmez.

### Bölüm verisi ve çözümler

20 bölümün her birinde `board`, `trays`, `targetScore`, `targetLines`, `maxMoves`, `maxPlacements`, `bombs`, `stars` ve `solution` vardır. Koordinatlar sıfırdan başlar. `slot` 0–2’dir; `bomb: true` bombayı belirtir. Aynı üçlüde üç farklı geometri bulunur. Çözüm sırası tekrarlanabilir; hiçbir Adventure parçası runtime rastgele üretilmez.

- 1–5 temel yatay/dikey/kesişen çizgiler.
- 6–10 hamle sınırında puan.
- 11–15 yerleştirme sınırında çizgi hedefi.
- 16–20 yoğun, çapraz boşluklu başlangıç; bombayla alan açma.
- 16–19’daki köşe bomba görevleri bilinçli olarak kolay başlangıç dersleridir; 20 ek yerleştirme ister. Ürün yayını öncesi kullanıcı testleriyle zorluk dengesi iyileştirilmelidir.
- Yıldız koşulları bölüm verisindedir. `metric`: `moves`, `placements` veya `elapsedMs`; `maximum: null` koşulsuz 1 yıldız tabanını destekler.

## Testler ve doğrulama durumu

```bash
flutter analyze --no-pub
flutter test
```

**30 Flutter testi geçti.** Motor testleri sınır/çakışma, kesişen çizgilerin eşzamanlı temizlenmesi, combo/streak/puan/jeton, üçlü tüketimi, tüm kalan parçaların kontrolü, süre bonusu ve süre bitimi, Rush yıldızları, köşe bombası ve sıfırlama kurallarını kapsar. 20 bölümün çözümü gerçek Dart motorunda hedefe ve 3 yıldız koşuluna ulaştı.

Ekonomi ve kayıt testleri tek seferlik ödülleri, yetersiz bakiye, kilitli bölüm başlatma, günlük ödüller, disk kayıt/geri yükleme, bozuk kayıt kurtarma, kayıt hatasında geri alma ve fotoğraf seçimi iptalini kapsar. Widget testleri Classic, Time Attack, Rush ve bomba içeren Adventure ekranlarının küçük dikey ekranda taşmamasını kontrol eder.

Python/JavaScript bağımsız prova kontrolleri de teslim içindedir. Tarayıcı provası native APK’nın yerine geçmez. GitHub Actions Android release test APK’sı ve imzasız iOS derlemesi için hazırlanmıştır; CI workflow bu oturumda çalıştırılmadı.

## Tamamlanan ve kalan işler

- Flutter motoru, dört mod, 20 sabit bölüm ve çözümler, Riverpod ekranları, ekonomi, atomik yerel kayıt, özgün yerel sesler, temalar, arka planlar, fotoğraf kopyalama ve ayarlar uygulandı.
- Android platformu, test imzası ve özgün uygulama ikonu yapılandırıldı. Derleme/imza bilgileri `verification/ANDROID_BUILD_REPORT.json` içinde bulunur.
- Gerçek Android telefonda yükleme ve etkileşim, ses, fotoğraf seçici, uyku/arka plan süre davranışı doğrulanmadı. Bu ortamda donanım hızlandırmasız Android emülatörü açılışını tamamlayamadı.
- iOS derlemesi ve cihaz testi için macOS/Xcode gerekir. Mağaza imzaları, final bundle id, yayın gizlilik beyanları ve SEO sayfasının domain yayını yapılmadı.
- Survival/çöp blokları ve Google Play Games/Game Center bağlantıları ikinci sürüme bırakıldı. Reklam, ödeme, hesap ve sunucu MVP kapsamı dışındadır.

Kaynaklarda pasif reklam/satın alma düğmesi yoktur. Kilitli/yetersiz bakiyeli ürünler devre dışıdır. Platform desteği veya kayıt hatası oluşursa UI hata bildirir.

## Varlıklar

Üç özgün 32 saniyelik sakin sentez parça, üç efekt ve üç özgün çizim teslim içindedir. Bunlar gerçek enstrüman kayıtları değil, guzheng/flüt esintili sentez eskizleridir. Kaynak ve kullanım listesi: `ASSET_LICENSES.md`. Yeniden üretme aracı `python3 tool/make_assets.py` için Pillow gerekir (`pip install Pillow`); uygulamayı çalıştırmak için bu araç veya Pillow gerekmez.

## Ad güncellemesi — 0.1.1+2

Görünen marka adı **Block Crash Line** olarak güncellendi. Android uygulama kimliği `com.uke.block_crash`, saat kanalı ve test imzası önceki sürümle aynıdır. Önceki APK’nın üzerine kurulabilir; kaldırmaya gerek yoktur.
