# Block Crash Line — Android test kurulumu

Android 5.0 veya üzeri gerekir. APK yaklaşık 25,1 MB’dir.

1. `Block_Crash_Line_Android_Test.apk` dosyasını telefonunuza indirin.
2. Telefonun **Dosyalar → İndirilenler** bölümünden APK’yı açın.
3. Android isterse, dosyayı açtığınız uygulama için **Bu kaynaktan uygulama yüklemeye izin ver** seçeneğini etkinleştirin.
4. **Yükle** düğmesine dokunun; ardından **Block Crash Line** uygulamasını açın.

Oyun kurulduktan sonra internet gerektirmez. Kayıtlar telefonun uygulama dizininde saklanır. Android’de uygulamanın verilerini temizlemek veya kaldırmak yerel ilerlemeyi siler.

Bu APK imzalı bir test sürümüdür. Kaynak projedeki `android/app/block-crash-test.jks` aynı test imzasıyla sonraki APK’ları üretmek içindir; parola `android`, alias `blockcrashtest` değeridir. Bu test anahtarı dağıtım/mağaza anahtarı olarak kullanılmamalıdır. Ürün yayını için size ait nihai imza gerekir.

Kaynak pakette Android platform dosyaları ve `pubspec.lock` bulunur. Flutter ortamında yeniden derleme:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Çıktı: `build/app/outputs/flutter-apk/app-release.apk`.

Sürüm 0.1.1+2: uygulama adı Block Crash Line oldu. Önceki test sürümüyle aynı paket kimliği ve imza kullanılır; kaldırmadan üzerine güncelleyin.
