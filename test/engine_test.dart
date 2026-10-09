import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_crash/engine/game.dart';
import 'package:block_crash/engine/shapes.dart';
import 'package:block_crash/levels/level.dart';

List<Level> loadLevels() =>
    (jsonDecode(File('assets/levels/levels.json').readAsStringSync()) as List)
        .map((x) => Level.fromJson(Map<String, dynamic>.from(x)))
        .toList();
Game empty({Mode mode = Mode.classic}) => Game(mode, random: Random(1));
void rowGap(Game g, int row, int gap) {
  for (var c = 0; c < 8; c++) {
    g.board[row * 8 + c] = c == gap ? 0 : 1;
  }
}

void main() {
  test('Out-of-bounds and overlap never consume piece or move', () {
    final g = empty()..tray = ['square', 'single', 'h2'];
    final before = g.toJson().toString();
    expect(g.place(0, 7, 7).accepted, false);
    expect(g.toJson().toString(), before);
    expect(g.place(0, -1, 0).accepted, false);
    g.board[0] = 1;
    expect(g.place(0, 0, 0).accepted, false);
    expect(g.tray[0], 'square');
    expect(g.moves, 0);
  });
  test('Crossing row and column clear simultaneously, unique cells once', () {
    final g = empty()..tray = ['single', 'square', 'T'];
    for (var n = 0; n < 8; n++) {
      if (n != 3) {
        g.board[3 * 8 + n] = 1;
        g.board[n * 8 + 3] = 1;
      }
    }
    final r = g.place(0, 3, 3);
    expect(r.lines, 2);
    expect(r.cleared.length, 15);
    expect(g.board.where((x) => x > 0), isEmpty);
    expect(r.points, 405);
    expect(r.combo, 2);
    expect(r.streakMultiplier, 1);
    expect(r.coins, 40);
  });
  test('Exact streak, combo and coin formulas including cap and reset', () {
    final g = empty()..tray = ['single', 'h2', 'v2'];
    final expected = [105, 205, 405, 805, 805];
    for (var n = 0; n < 5; n++) {
      g.tray[0] = 'single';
      rowGap(g, n, 7);
      final r = g.place(0, n, 7);
      expect(r.points, expected[n]);
      expect(r.streakMultiplier, multiplier(n + 1));
      expect(r.coins, n == 0 ? 10 : 10 + 10 * multiplier(n + 1));
    }
    g.tray[0] = 'single';
    g.place(0, 7, 0);
    expect(g.streak, 0);
  });
  test('Four-line combo uses x8', () {
    final g = empty()..tray = ['v4', 'T', 'Z'];
    for (var r = 0; r < 4; r++) rowGap(g, r, 7);
    final result = g.place(0, 0, 7);
    expect(result.lines, 4);
    expect(result.combo, 8);
    expect(result.points, 3220);
    expect(result.coins, 120);
  });
  test('Only exhausted tray refills; every random tray has distinct geometry',
      () {
    final g = empty()..tray = ['single', 'h2', 'v2'];
    g.place(0, 0, 0);
    expect(g.tray, [null, 'h2', 'v2']);
    g.place(1, 1, 0);
    expect(g.tray, [null, null, 'v2']);
    g.place(2, 2, 0);
    expect(g.tray.whereType<String>().length, 3);
    for (var n = 0; n < 1000; n++) {
      final t = randomTray(Random(n), n * 100);
      expect(t.toSet().length, 3);
    }
  });
  test('Game over checks ALL remaining pieces after clearing', () {
    final g = empty()..tray = ['square', 'single', 'T'];
    for (var r = 0; r < 8; r++)
      for (var c = 0; c < 8; c++) g.board[r * 8 + c] = (r + c) % 2;
    for (final i in [0, 1, 8, 9]) g.board[i] = 0;
    expect(g.place(0, 0, 0).accepted, true);
    expect(g.canPlace('T'), false);
    expect(g.canPlace('single'), true);
    expect(g.outcome, Outcome.playing);
    g.place(1, 2, 2);
    expect(g.outcome, Outcome.lost);
    final cross = empty()..tray = ['single', 'square', 'h2'];
    cross.board = List.filled(64, 1);
    for (var n = 0; n < 8; n++) cross.board[n * 8 + n] = 0;
    cross.place(0, 0, 0); // Clearing creates room for remaining pieces.
    expect(cross.outcome, Outcome.playing);
  });
  test('Trapped remaining pieces produce a loss without full lines', () {
    final g = empty()..tray = ['single', 'square', 'T'];
    for (var r = 0; r < 8; r++)
      for (var c = 0; c < 8; c++) g.board[r * 8 + c] = (r + c) % 2;
    expect(g.place(0, 0, 0).accepted, true);
    expect(g.outcome, Outcome.lost);
  });
  test('Time bonuses: two lines +2s, three lines +5s, expiry rejects moves',
      () {
    final g = empty(mode: Mode.timeAttack)..tray = ['v2', 'v3', 'single'];
    rowGap(g, 0, 7);
    rowGap(g, 1, 7);
    g.tick(59000);
    g.place(0, 0, 7);
    expect(g.budgetMs, 62000);
    expect(g.remainingMs, 3000);
    for (var n = 2; n < 5; n++) rowGap(g, n, 7);
    g.place(1, 2, 7);
    expect(g.budgetMs, 67000);
    g.tick(67000);
    final before = g.score;
    expect(g.place(2, 7, 0).accepted, false);
    expect(g.score, before);
    expect(g.outcome, Outcome.lost);
  });
  test('Time advances while paused; other modes reject input while paused', () {
    final g = empty(mode: Mode.timeAttack)..paused = true;
    g.tick(60000);
    expect(g.outcome, Outcome.lost);
    final classic = empty()..paused = true;
    expect(classic.place(0, 0, 0).accepted, false);
  });
  test('Rush wins at goal and awards placement-based stars', () {
    for (final item in [(19, 3), (20, 2), (30, 1)]) {
      final g = empty(mode: Mode.rush)
        ..tray = ['single', 'h2', 'v2']
        ..score = 4995
        ..placements = item.$1;
      g.place(0, 0, 0);
      expect(g.outcome, Outcome.won);
      expect(g.stars, item.$2);
    }
  });
  test(
      'Every authored level solution succeeds in the real Dart engine with 3 stars',
      () {
    for (final l in loadLevels()) {
      final g = Game(Mode.adventure, level: l);
      for (final action in l.solution) {
        expect(g.outcome, Outcome.playing,
            reason: 'Level ${l.id} extra action');
        final result = action['bomb'] == true
            ? g.bomb(action['row'], action['col'])
            : g.place(action['slot'], action['row'], action['col']);
        expect(result.accepted, true, reason: 'Level ${l.id}: $action');
      }
      expect(g.outcome, Outcome.won, reason: 'Level ${l.id}');
      expect(g.stars, 3);
    }
  });
  test('Adventure reset exactly reproduces board, tray, bombs and sequence',
      () {
    for (final l in loadLevels()) {
      final a = Game(Mode.adventure, level: l),
          b = Game(Mode.adventure, level: l);
      expect(a.toJson(), b.toJson());
      for (final x in l.solution) {
        if (x['bomb'] == true) {
          a.bomb(x['row'], x['col']);
          b.bomb(x['row'], x['col']);
        } else {
          a.place(x['slot'], x['row'], x['col']);
          b.place(x['slot'], x['row'], x['col']);
        }
        expect(a.toJson(), b.toJson());
      }
      final reset = Game(Mode.adventure, level: l);
      expect(reset.board, l.board);
      expect(reset.bombs, l.bombs);
      expect(reset.tray, l.trays.first);
    }
  });
  test('Corner bomb clips 3x3, no line coins, does not increment placements',
      () {
    final l = loadLevels()[15], g = Game(Mode.adventure, level: l)..streak = 4;
    g.board = List.filled(64, 1);
    final r = g.bomb(0, 0);
    expect(r.cleared, {0, 1, 8, 9});
    expect(r.points, 20);
    expect(r.lines, 0);
    expect(r.coins, 0);
    expect(g.moves, 1);
    expect(g.placements, 0);
    expect(g.streak, 0);
    expect(g.bombs, l.bombs - 1);
    expect(g.board[2], 1);
    expect(g.board[16], 1);
  });
  test('Bomb reserves prevent early loss when none of three shapes fits', () {
    final g = Game(Mode.adventure, level: loadLevels()[15]);
    expect(g.tray.whereType<String>().any(g.canPlace), false);
    expect(g.outcome, Outcome.playing);
    expect(g.bomb(0, 0).accepted, true);
    expect(g.canPlace('square'), true);
  });
  test('Finite sequence exhausted without target is a failure', () {
    final l = Level.fromJson({
      'id': 1,
      'board': List.filled(8, '........'),
      'trays': [
        ['single', 'h2', 'v2']
      ],
      'targetScore': 9999,
      'targetLines': 0,
      'maxMoves': 0,
      'maxPlacements': 0,
      'bombs': 0,
      'stars': [
        {'stars': 1, 'metric': 'moves', 'maximum': 99}
      ],
      'solution': []
    });
    final g = Game(Mode.adventure, level: l);
    g.place(0, 0, 0);
    g.place(1, 1, 0);
    g.place(2, 2, 0);
    expect(g.outcome, Outcome.lost);
  });
  test('Star rules distinguish time and placement metrics', () {
    final l = Level.fromJson({
      'id': 1,
      'board': List.filled(8, '........'),
      'trays': [
        ['single', 'h2', 'v2']
      ],
      'targetScore': 5,
      'targetLines': 0,
      'maxMoves': 0,
      'maxPlacements': 0,
      'bombs': 0,
      'solution': [],
      'stars': [
        {'stars': 1, 'metric': 'elapsedMs', 'maximum': 60000},
        {'stars': 2, 'metric': 'elapsedMs', 'maximum': 30000},
        {'stars': 3, 'metric': 'elapsedMs', 'maximum': 10000}
      ]
    });
    expect(l.awardStars(5, 0, 1, 1, 45000), 1);
    expect(l.awardStars(5, 0, 999, 999, 5000), 3);
  });
  test('Classic saves round-trip board, remaining pieces, score and streak',
      () {
    final g = empty()..tray = ['single', 'h2', 'T'];
    g.place(0, 0, 0);
    g.score = 987;
    g.streak = 3;
    final restored = Game.fromJson(
        jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>);
    expect(restored.toJson(), g.toJson());
    expect(() => Game.fromJson({'mode': 'classic', 'board': [], 'tray': []}),
        throwsA(isA<FormatException>()));
  });
}
