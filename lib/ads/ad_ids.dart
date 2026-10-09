import 'package:flutter/foundation.dart';

/// AdMob kimlikleri (gizli değildir; APK içinde yer alır).
/// Uygulama: Block Crash Line (AdMob app id 9354185726)
/// App ID: ca-app-pub-5327895171614279~9354185726 (AndroidManifest.xml içinde)
/// Debug derlemelerde Google'ın resmi TEST birimleri kullanılır; release'te gerçek birimler.
/// Test kimlikleri: https://developers.google.com/admob/android/test-ads
class AdIds {
  AdIds._();
  static const bool usingTestIds = !kReleaseMode;

  static const String _androidBannerLive =
      'ca-app-pub-5327895171614279/7547203472'; // Home Banner
  static const String _androidInterstitialLive =
      'ca-app-pub-5327895171614279/7219900417'; // Game Over Interstitial

  static const String _androidBannerTest =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitialTest =
      'ca-app-pub-3940256099942544/1033173712';

  static String get androidBanner =>
      usingTestIds ? _androidBannerTest : _androidBannerLive;
  static String get androidInterstitial =>
      usingTestIds ? _androidInterstitialTest : _androidInterstitialLive;

  // iOS henüz AdMob'da tanımlı değil; test kimlikleri.
  static const String iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
}
