import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_crash/engine/game.dart';
import 'package:block_crash/levels/level.dart';
import 'package:block_crash/economy/profile.dart';
import 'package:block_crash/persistence/store.dart';
import 'package:block_crash/controller.dart';

Level firstLevel() => Level.fromJson(Map<String, dynamic>.from(
    (jsonDecode(File('assets/levels/levels.json').readAsStringSync()) as List)
        .first));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Balance prevents purchases; owned item cannot be charged twice', () {
    final p = Profile()..coins = 499;
    expect(p.buy('neon'), false);
    expect(p.coins, 499);
    expect(p.owned.contains('neon'), false);
    p.coins = 500;
    expect(p.buy('neon'), true);
    expect(p.coins, 0);
    expect(p.buy('neon'), false);
    expect(p.coins, 0);
    expect(p.buy('invalid'), false);
  });
  test('Daily login and mission each once across restart and backward date',
      () {
    var p = Profile();
    final today = DateTime(2026, 10, 8);
    p.daily(today);
    p.daily(today);
    expect(p.coins, 50);
    final g = Game(Mode.classic);
    for (var n = 0; n < 20; n++)
      p.applyMove(g, const MoveResult(accepted: true, lines: 1, coins: 10),
          bomb: false, now: today);
    expect(p.coins, 350);
    p = Profile.fromJson(p.toJson());
    p.daily(today);
    p.applyMove(g, const MoveResult(accepted: true, lines: 1, coins: 10),
        bomb: false, now: today);
    expect(p.coins, 360);
    p.daily(DateTime(2026, 10, 7));
    expect(p.coins, 360);
    p.daily(DateTime(2026, 10, 9));
    expect(p.coins, 410);
    expect(p.dailyLines, 0);
  });
  test(
      'Completion, first three stars and achievements never repeat; line coins do',
      () {
    var p = Profile();
    final now = DateTime(2026, 10, 8);
    Game win() {
      final g = Game(Mode.adventure, level: firstLevel());
      g.place(0, 0, 6);
      return g;
    }

    final first = win();
    p.applyMove(first, first.last, bomb: false, now: now);
    expect(p.coins,
        260); // Login 50 + line 10 + complete 100 + stars 50 + first step 50.
    p = Profile.fromJson(p.toJson());
    final replay = win();
    p.applyMove(replay, replay.last, bomb: false, now: now);
    expect(p.coins, 270);
    expect(p.unlocked, 2);
    expect(p.levelStars[1], 3);
    replay.moves = 20;
    p.applyMove(replay, const MoveResult(), bomb: false, now: now);
    expect(p.levelStars[1], 3);
    expect(p.levelScores[1], first.score);
  });
  test('Locked level checked at domain and game launch layers', () async {
    final p = Profile();
    expect(() => p.requireLevel(2), throwsStateError);
    p.requireLevel(1);
    final a = AppController()..ready = true;
    expect(await a.start(Mode.adventure, levelId: 2), false);
    expect(a.game, isNull);
    a.dispose();
  });
  test('Photo cancellation keeps ownership, path, background and balance',
      () async {
    final a = AppController(photoPicker: () async => null)..ready = true;
    a.profile.owned.add('custom');
    a.profile.background = 'mountain';
    a.profile.photo = '/old.jpg';
    a.profile.coins = 100;
    final before = a.profile.toJson();
    await a.pickPhoto();
    expect(a.profile.toJson(), before);
    expect(a.error, isNull);
    a.dispose();
  });
  test('All six achievements reward exactly once after serialization', () {
    var p = Profile();
    for (final id in achievementRewards.keys) p.achievement(id);
    final expected = achievementRewards.values.reduce((a, b) => a + b);
    expect(p.coins, expected);
    p = Profile.fromJson(p.toJson());
    for (final id in achievementRewards.keys) expect(p.achievement(id), false);
    expect(p.coins, expected);
  });
  test('Profile stores all settings, cosmetics, progress and Classic snapshot',
      () async {
    final dir = await Directory.systemTemp.createTemp('block_crash_test_');
    try {
      final store = Store(dir),
          p = Profile()
            ..coins = 2222
            ..theme = 'forest'
            ..background = 'bamboo'
            ..language = 'en'
            ..masterVolume = .25
            ..musicVolume = .8
            ..effects = false
            ..vibration = false
            ..reducedMotion = true
            ..musicTrack = -1
            ..levelStars = {1: 3, 2: 2}
            ..levelScores = {1: 400, 2: 800};
      p.owned.addAll({'forest', 'bamboo'});
      p.classic = Game(Mode.classic).toJson();
      await store.save(p);
      final loaded = await Store(dir).load();
      expect(loaded.toJson(), p.toJson());
      loaded.award('once', 100);
      await store.save(loaded);
      final reopened = await Store(dir).load();
      expect(reopened.award('once', 100), false);
      expect(reopened.coins, 2322);
      expect(await File('${dir.path}/profile.tmp').exists(), false);
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('Save failure rolls back both gameplay and earned currency', () async {
    final dir = await Directory.systemTemp.createTemp('block_crash_failure_');
    final a = AppController()
      ..ready = true
      ..game = Game(Mode.classic);
    try {
      final obstacle = File('${dir.path}/not_directory');
      await obstacle.writeAsString('occupied');
      a.store = Store(Directory(obstacle.path));
      a.game!.tray = ['single', 'h2', 'v2'];
      final board = List.of(a.game!.board), before = a.profile.coins;
      await a.move(0, 0, 0);
      expect(a.game!.board, board);
      expect(a.game!.moves, 0);
      expect(a.profile.coins, before);
      expect(a.error, isNotNull);
    } finally {
      a.dispose();
      await dir.delete(recursive: true);
    }
  });
  test(
      'Corrupt main profile recovers backup; bad Classic does not lose progress',
      () async {
    final dir = await Directory.systemTemp.createTemp('block_crash_corrupt_');
    try {
      final store = Store(dir);
      await store.save(Profile()..coins = 77);
      await store.save(Profile()..coins = 99);
      await store.file.writeAsString('{broken');
      expect((await store.load()).coins, 77);
      final j = Profile().toJson()
        ..['coins'] = 123
        ..['classic'] = {'board': []};
      final p = Profile.fromJson(j);
      expect(p.classic, isNull);
      expect(p.coins, 123);
      await store.backup.delete();
      expect((await store.load()).coins, 0);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
