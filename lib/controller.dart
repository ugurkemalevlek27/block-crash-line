import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'engine/game.dart';
import 'engine/clock.dart';
import 'levels/level.dart';
import 'economy/profile.dart';
import 'persistence/store.dart';
import 'audio/audio_manager.dart';

final appProvider = ChangeNotifierProvider<AppController>((ref) {
  final c = AppController();
  c.initialize();
  return c;
});

class AppController extends ChangeNotifier {
  final Future<XFile?> Function()? photoPicker;
  AppController({this.photoPicker});
  Profile profile = Profile();
  List<Level> levels = [];
  Game? game;
  Store? store;
  final audio = AudioManager(), clock = MonotonicClock();
  bool ready = false, busy = false, hidden = false;
  String? error;
  Timer? _timer;
  int _origin = 0, _pausedAt = 0, _pausedDuration = 0;
  Future<void> initialize() async {
    try {
      store = Store(await getApplicationSupportDirectory());
      profile = await store!.load();
      levels =
          (jsonDecode(await rootBundle.loadString('assets/levels/levels.json'))
                  as List)
              .map((j) => Level.fromJson(Map<String, dynamic>.from(j)))
              .toList();
      final next = Profile.fromJson(profile.toJson())..daily(DateTime.now());
      await store!.save(next);
      profile = next;
      ready = true;
      await _safeAudio(() => audio.configure(profile));
      final recovered = await ImagePicker().retrieveLostData();
      if (recovered.files?.isNotEmpty == true &&
          profile.owned.contains('custom')) {
        await _installPhoto(recovered.files!.first);
      }
      _timer =
          Timer.periodic(const Duration(milliseconds: 150), (_) => _tick());
    } catch (e) {
      error = 'Başlatma / Startup: $e';
    }
    notifyListeners();
  }

  Future<void> _safeAudio(Future<void> Function() f) async {
    try {
      await f();
    } catch (_) {/* Device audio errors never break saved gameplay. */}
  }

  Future<bool> mutate(void Function(Profile) change) async {
    if (busy || !ready) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final next = Profile.fromJson(profile.toJson());
      change(next);
      await store!.save(next);
      profile = next;
      await _safeAudio(() => audio.configure(profile));
      return true;
    } catch (e) {
      error = 'Kayıt / Save: $e';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> start(Mode mode, {int? levelId, bool resume = false}) async {
    if (busy || !ready) return false;
    if (mode == Mode.adventure) {
      try {
        profile.requireLevel(levelId ?? 0);
      } catch (_) {
        error = 'Bu bölüm kilitli / Level locked';
        notifyListeners();
        return false;
      }
    }
    Game next;
    try {
      next = resume && profile.classic != null
          ? Game.fromJson(profile.classic!)
          : Game(mode,
              level: mode == Mode.adventure ? levels[levelId! - 1] : null);
    } catch (_) {
      next = Game(mode);
    }
    if (mode == Mode.classic && !await mutate((p) => p.classic = next.toJson()))
      return false;
    _origin = await clock.now();
    _pausedDuration = 0;
    _pausedAt = 0;
    game = next;
    notifyListeners();
    return true;
  }

  Future<void> _tick() async {
    final g = game;
    if (g == null ||
        busy ||
        g.outcome != Outcome.playing ||
        ((g.paused || hidden) && g.mode != Mode.timeAttack)) return;
    final now = await clock.now();
    if (!identical(g, game) || busy) return;
    g.tick(now - _origin - _pausedDuration);
    notifyListeners();
  }

  Future<void> move(int slot, int row, int col, {bool bomb = false}) async {
    final current = game;
    if (current == null || busy || hidden) return;
    busy = true;
    error = null;
    notifyListeners();
    MoveResult result = const MoveResult();
    try {
      final next = Game.fromJson(current.toJson(), level: current.level)
        ..paused = current.paused;
      next.tick((await clock.now()) - _origin - _pausedDuration);
      result = bomb ? next.bomb(row, col) : next.place(slot, row, col);
      if (!result.accepted) {
        // Expiry is still visible even when the attempted move was rejected.
        if (next.outcome != Outcome.playing) game = next;
        return;
      }
      final p = Profile.fromJson(profile.toJson());
      p.applyMove(next, result, bomb: bomb, now: DateTime.now());
      await store!.save(p);
      next.paused = current.paused;
      profile = p;
      game = next;
      if (profile.vibration && result.cleared.isNotEmpty) {
        try {
          await HapticFeedback.lightImpact();
        } catch (_) {}
      }
      await _safeAudio(() => audio.effect(bomb
          ? 'bomb'
          : result.lines > 0
              ? 'clear'
              : 'place'));
    } catch (e) {
      error = 'Hamle kaydedilemedi / Move not saved: $e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> pause(bool value) async {
    final g = game;
    if (g == null || g.paused == value || g.outcome != Outcome.playing) return;
    final now = await clock.now();
    if (g.mode != Mode.timeAttack) {
      if (value) {
        _pausedAt = now;
      } else {
        _pausedDuration += now - _pausedAt;
      }
    }
    g.paused = value;
    notifyListeners();
  }

  Future<void> lifecycle(AppLifecycleState state) async {
    final isHidden = state != AppLifecycleState.resumed;
    if (isHidden == hidden) return;
    hidden = isHidden;
    await _safeAudio(() => audio.lifecycle(hidden));
    if (hidden) {
      if (game?.mode != Mode.timeAttack) await pause(true);
    } else {
      await mutate((p) => p.daily(DateTime.now()));
      await _tick();
    }
  }

  Future<bool> selectProduct(String id, bool theme) async {
    var success = false;
    final saved = await mutate((p) {
      if (!p.owned.contains(id) && !p.buy(id)) return;
      if (theme) {
        p.theme = id;
      } else if (id != 'custom') {
        p.background = id;
      }
      success = true;
    });
    return saved && success;
  }

  Future<void> pickPhoto() async {
    if (!profile.owned.contains('custom') || busy) return;
    try {
      final photo = photoPicker != null
          ? await photoPicker!()
          : await ImagePicker().pickImage(
              source: ImageSource.gallery,
              requestFullMetadata: false,
              maxWidth: 1800,
              maxHeight: 2400,
              imageQuality: 90);
      if (photo != null) await _installPhoto(photo);
    } catch (e) {
      error = 'Fotoğraf / Photo: $e';
      notifyListeners();
    }
  }

  Future<void> _installPhoto(XFile photo) async {
    final dir = await getApplicationSupportDirectory();
    final target = File(
        '${dir.path}/background_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await File(photo.path).copy(target.path);
    final old = profile.photo;
    if (await mutate((p) {
      p.photo = target.path;
      p.background = 'custom';
      p.achievement('personal');
    })) {
      if (old.isNotEmpty && old != target.path) {
        try {
          await File(old).delete();
        } catch (_) {}
      }
    } else {
      await target.delete();
    }
  }

  void dismissError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _safeAudio(audio.dispose);
    super.dispose();
  }
}
