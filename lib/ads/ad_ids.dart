/// AdMob kimlikleri. Varsayılanlar Google'ın resmi TEST kimlikleridir;
/// gerçek AdMob uygulama/reklam birimi kimlikleri alındığında burayı ve
/// android/app/src/main/AndroidManifest.xml içindeki APPLICATION_ID'yi değiştirin.
/// Test kimlikleri: https://developers.google.com/admob/android/test-ads
class AdIds {
  AdIds._();
  static const bool usingTestIds = true;
  static const String androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
}
