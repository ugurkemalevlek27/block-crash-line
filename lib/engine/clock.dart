import 'package:flutter/services.dart';

/// Native clocks include time in device suspend and do not use calendar time.
class MonotonicClock {
  static const _channel = MethodChannel('block_crash/clock');
  final Stopwatch _fallback = Stopwatch()..start();
  Future<int> now() async {
    try {
      return (await _channel.invokeMethod<int>('now'))!;
    } on MissingPluginException {
      return _fallback.elapsedMilliseconds;
    }
  }
}
