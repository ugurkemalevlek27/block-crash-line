# 0.1.2+3 — Google Play hazırlık değişiklikleri (10 Ekim 2026)

Değişiklikler (oyun motoru, bölümler, kayıt/ekonomi/ses kaynaklarına dokunulmadı):
- targetSdk/compileSdk 35 → **36** (Play şartı, 31 Ağustos 2026+), minSdk 21 korundu.
- AGP 8.7.0 → 8.9.1, Kotlin 1.8.22 → 2.1.20, Gradle 8.10.2 → 8.11.1, Java 11 → 17 hedefi.
- Flutter doğrulama tabanı 3.29.3 → 3.35.x (CI); bağımlılıklar: image_picker 1.2.0, audioplayers 6.5.1 (16 KB sayfa uyumu); pubspec.lock CI'da yeniden üretilir.
- `android/app/block-crash-test.jks` (herkesçe bilinen test anahtarı) **kaldırıldı**. Release artık yalnızca `android/key.properties` ile verilen özel upload key'le imzalanır; dosya yoksa paket imzasız kalır.
- `jniLibs.useLegacyPackaging=false` (16 KB sayfa hizalaması). CI, AAB içindeki .so dosyalarının p_align değerini doğrular.
- versionCode 2 → 3, versionName 0.1.1 → 0.1.2.
- CI (`.github/workflows/flutter.yml`): format/analyze/test → `flutter build appbundle --release` + APK; imza gizli anahtarlardan (GitHub Secrets) okunur; çıktı artifact olarak yüklenir.

Henüz yapılmayanlar: bu ortamda Flutter/Android SDK indirilemediği için derleme ve testler **çalıştırılmadı**; CI ilk çalışmada doğrulanacak. Fiziksel cihaz testi, ekran görüntüleri ve Play Console işlemleri bekliyor.
