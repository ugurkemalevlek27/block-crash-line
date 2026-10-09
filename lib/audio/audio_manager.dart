import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../economy/profile.dart';

class AudioManager {
  late final music = AudioPlayer(), fx = AudioPlayer();
  bool _initialized = false;
  Profile? profile;
  bool background = false;
  int active = -1;
  void _initialize() {
    if (_initialized) return;
    _initialized = true;
    music.onPlayerComplete.listen((_) {
      if (profile?.musicTrack == -1 && !background) playMusic();
    });
  }

  Future<void> configure(Profile p) async {
    _initialize();
    final changed = profile?.musicTrack != p.musicTrack;
    profile = p;
    await music.setVolume(p.masterVolume * p.musicVolume);
    await fx.setVolume(p.masterVolume);
    if (!background && (active == -1 || changed)) await playMusic();
  }

  Future<void> playMusic() async {
    final p = profile;
    if (p == null || background) return;
    active = p.musicTrack == -1 ? Random().nextInt(3) : p.musicTrack;
    await music.setReleaseMode(
        p.musicTrack == -1 ? ReleaseMode.release : ReleaseMode.loop);
    await music.play(AssetSource('audio/music$active.wav'),
        volume: p.masterVolume * p.musicVolume);
  }

  Future<void> effect(String id) async {
    if (profile?.effects != true || background) return;
    await fx.play(AssetSource('audio/$id.wav'), volume: profile!.masterVolume);
  }

  Future<void> lifecycle(bool hidden) async {
    background = hidden;
    if (!_initialized) return;
    if (hidden) {
      await music.pause();
      await fx.stop();
    } else if (active >= 0) {
      await music.resume();
    } else {
      await playMusic();
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await music.dispose();
    await fx.dispose();
  }
}
