import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// Reklam katmanı. Başlatılmadığı sürece (testler, desteklenmeyen platform)
/// tüm çağrılar sessizce no-op'tur; oyun motoru ve kayıt sistemi reklama bağımlı değildir.
class AdsManager {
  AdsManager._();
  static final AdsManager instance = AdsManager._();

  bool _enabled = false;
  bool _canRequestAds = false;
  InterstitialAd? _interstitial;
  int _gamesSinceAd = 0;
  DateTime? _lastInterstitial;
  int? _lastGameKey;

  /// Oyun sonu reklamı en erken her 3. oyun sonunda ve 90 sn arayla gösterilir.
  static const int gamesBetweenAds = 3;
  static const Duration minInterval = Duration(seconds: 90);

  bool get enabled => _enabled && _canRequestAds;

  String get _bannerId => Platform.isIOS ? AdIds.iosBanner : AdIds.androidBanner;
  String get _interstitialId =>
      Platform.isIOS ? AdIds.iosInterstitial : AdIds.androidInterstitial;

  /// Uygulama açılışında çağrılır. UMP (AB/İngiltere rıza formu) akışını yürütür,
  /// ardından SDK'yı başlatır. Hata durumunda oyun reklamsız devam eder.
  Future<void> initialize() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final params = ConsentRequestParameters();
      final done = ValueNotifier<bool>(false);
      ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
        ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          done.value = true;
        });
      }, (error) {
        done.value = true;
      });
      // Rıza akışı en fazla 8 sn bekletir; sonrasında başlatmaya devam edilir.
      final sw = Stopwatch()..start();
      while (!done.value && sw.elapsed < const Duration(seconds: 8)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (!_canRequestAds) return;
      await MobileAds.instance.initialize();
      _enabled = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('Ads disabled: $e');
      _enabled = false;
    }
  }

  void _loadInterstitial() {
    if (!enabled) return;
    InterstitialAd.load(
        adUnitId: _interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
          _interstitial = ad;
        }, onAdFailedToLoad: (err) {
          _interstitial = null;
        }));
  }

  /// Oyun bittiğinde çağrılır; [gameKey] aynı oyun için tekrar gösterimi engeller.
  void onGameEnded(int gameKey) {
    if (!enabled || _lastGameKey == gameKey) return;
    _lastGameKey = gameKey;
    _gamesSinceAd++;
    final now = DateTime.now();
    final intervalOk = _lastInterstitial == null ||
        now.difference(_lastInterstitial!) >= minInterval;
    if (_gamesSinceAd < gamesBetweenAds || !intervalOk) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    _gamesSinceAd = 0;
    _lastInterstitial = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (a, err) {
          a.dispose();
          _loadInterstitial();
        });
    ad.show();
  }

  String? get bannerAdUnitId => enabled ? _bannerId : null;
}

/// Ana ekran altında sabit banner. Reklam yüklenemezse hiç yer kaplamaz.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final unit = AdsManager.instance.bannerAdUnitId;
    if (unit == null) return;
    _ad = BannerAd(
        size: AdSize.banner,
        adUnitId: unit,
        request: const AdRequest(),
        listener: BannerAdListener(onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        }, onAdFailedToLoad: (a, err) {
          a.dispose();
          if (mounted) setState(() => _loaded = false);
        }));
    _ad!.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
        top: false,
        child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad)));
  }
}
