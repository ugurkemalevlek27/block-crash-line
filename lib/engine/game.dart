import 'dart:math';
import '../levels/level.dart';
import 'shapes.dart';

enum Mode { classic, timeAttack, rush, adventure }

enum Outcome { playing, won, lost }

class MoveResult {
  final bool accepted;
  final int points, lines, coins, combo, streakMultiplier, bombCells;
  final Set<int> cleared;
  const MoveResult(
      {this.accepted = false,
      this.points = 0,
      this.lines = 0,
      this.coins = 0,
      this.combo = 0,
      this.streakMultiplier = 0,
      this.bombCells = 0,
      this.cleared = const {}});
}

int multiplier(int count) => count <= 0 ? 0 : [1, 2, 4, 8][min(count, 4) - 1];

class Game {
  final Mode mode;
  final Level? level;
  final Random random;
  List<int> board;
  List<String?> tray;
  int score = 0, streak = 0, lines = 0, moves = 0, placements = 0;
  int bombs = 0, trayIndex = 0, elapsedMs = 0, budgetMs = 60000;
  bool paused = false;
  Outcome outcome = Outcome.playing;
  MoveResult last = const MoveResult();

  Game(this.mode, {this.level, Random? random})
      : random = random ?? Random(),
        board = List.filled(64, 0),
        tray = [] {
    if (mode == Mode.adventure) {
      if (level == null) throw ArgumentError('Level required');
      board = List.of(level!.board);
      bombs = level!.bombs;
      tray = List<String?>.of(level!.trays.first);
    } else {
      tray = randomTray(this.random, 0);
    }
  }
  int get remainingMs => max(0, budgetMs - elapsedMs);
  int get stars => outcome != Outcome.won
      ? 0
      : mode == Mode.rush
          ? (placements <= 20
              ? 3
              : placements <= 30
                  ? 2
                  : 1)
          : level?.awardStars(score, lines, moves, placements, elapsedMs) ?? 0;
  bool get inputAllowed =>
      outcome == Outcome.playing &&
      !paused &&
      (mode != Mode.timeAttack || remainingMs > 0);

  bool fits(String id, int row, int col) {
    final shape = shapes[id];
    if (shape == null) return false;
    return shape.cells.every((c) {
      final r = row + c.row, k = col + c.col;
      return r >= 0 && r < 8 && k >= 0 && k < 8 && board[r * 8 + k] == 0;
    });
  }

  bool canPlace(String id) {
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (fits(id, r, c)) return true;
      }
    }
    return false;
  }

  void tick(int totalElapsedMs) {
    elapsedMs = max(elapsedMs, totalElapsedMs);
    if (mode == Mode.timeAttack &&
        remainingMs == 0 &&
        outcome == Outcome.playing) {
      outcome = Outcome.lost;
    }
  }

  MoveResult place(int slot, int row, int col) {
    if (!inputAllowed ||
        slot < 0 ||
        slot >= 3 ||
        tray[slot] == null ||
        !fits(tray[slot]!, row, col)) return const MoveResult();
    final shape = shapes[tray[slot]]!;
    for (final c in shape.cells) {
      board[(row + c.row) * 8 + col + c.col] = shape.color;
    }
    tray[slot] = null;
    moves++;
    placements++;
    final rows = <int>[], cols = <int>[];
    for (var n = 0; n < 8; n++) {
      if (List.generate(8, (c) => board[n * 8 + c]).every((x) => x != 0))
        rows.add(n);
      if (List.generate(8, (r) => board[r * 8 + n]).every((x) => x != 0))
        cols.add(n);
    }
    final removed = <int>{};
    for (final r in rows) {
      for (var c = 0; c < 8; c++) {
        removed.add(r * 8 + c);
      }
    }
    for (final c in cols) {
      for (var r = 0; r < 8; r++) {
        removed.add(r * 8 + c);
      }
    }
    for (final i in removed) {
      board[i] = 0;
    }
    final count = rows.length + cols.length;
    streak = count == 0 ? 0 : streak + 1;
    final combo = multiplier(count), sm = multiplier(streak);
    final points = shape.cells.length * 5 + count * 100 * combo * sm;
    final coins =
        count * 10 + (count > 1 ? 10 * combo : 0) + (streak > 1 ? 10 * sm : 0);
    score += points;
    lines += count;
    if (mode == Mode.timeAttack)
      budgetMs += count >= 3
          ? 5000
          : count == 2
              ? 2000
              : 0;
    last = MoveResult(
        accepted: true,
        points: points,
        lines: count,
        coins: coins,
        combo: combo,
        streakMultiplier: sm,
        cleared: removed);
    _resolve();
    return last;
  }

  MoveResult bomb(int row, int col) {
    if (!inputAllowed ||
        mode != Mode.adventure ||
        bombs == 0 ||
        row < 0 ||
        row > 7 ||
        col < 0 ||
        col > 7) return const MoveResult();
    final removed = <int>{};
    for (var r = max(0, row - 1); r <= min(7, row + 1); r++) {
      for (var c = max(0, col - 1); c <= min(7, col + 1); c++) {
        final i = r * 8 + c;
        if (board[i] != 0) removed.add(i);
        board[i] = 0;
      }
    }
    bombs--;
    moves++;
    streak = 0;
    score += removed.length * 5;
    last = MoveResult(
        accepted: true,
        points: removed.length * 5,
        bombCells: removed.length,
        cleared: removed);
    _resolve();
    return last;
  }

  void _resolve() {
    if (mode == Mode.rush && score >= 5000) {
      outcome = Outcome.won;
      return;
    }
    if (mode == Mode.adventure) {
      final l = level!;
      if (l.reached(score, lines)) {
        outcome = Outcome.won;
        return;
      }
      if ((l.maxMoves > 0 && moves >= l.maxMoves) ||
          (l.maxPlacements > 0 && placements >= l.maxPlacements)) {
        outcome = Outcome.lost;
        return;
      }
    }
    if (tray.every((s) => s == null)) {
      if (mode == Mode.adventure) {
        trayIndex++;
        if (trayIndex >= level!.trays.length) {
          outcome = Outcome.lost;
          return;
        }
        tray = List<String?>.of(level!.trays[trayIndex]);
      } else {
        tray = randomTray(random, score);
      }
    }
    if (bombs == 0 && !tray.whereType<String>().any(canPlace))
      outcome = Outcome.lost;
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'level': level?.id,
        'board': board,
        'tray': tray,
        'score': score,
        'streak': streak,
        'lines': lines,
        'moves': moves,
        'placements': placements,
        'bombs': bombs,
        'trayIndex': trayIndex,
        'elapsedMs': elapsedMs,
        'budgetMs': budgetMs,
        'outcome': outcome.name
      };
  factory Game.fromJson(Map<String, dynamic> j, {Level? level}) {
    final g = Game(Mode.values.byName(j['mode'] as String), level: level);
    final board = (j['board'] as List).cast<int>();
    final tray = (j['tray'] as List).cast<String?>();
    if (board.length != 64 ||
        board.any((v) => v < 0 || v > 6) ||
        tray.length != 3 ||
        tray.whereType<String>().any((s) => !shapes.containsKey(s)) ||
        tray.whereType<String>().toSet().length !=
            tray.whereType<String>().length ||
        tray.every((s) => s == null))
      throw const FormatException('Invalid game');
    g.board = List.of(board);
    g.tray = List.of(tray);
    g.score = j['score'] as int;
    g.streak = j['streak'] as int;
    g.lines = j['lines'] as int;
    g.moves = j['moves'] as int;
    g.placements = j['placements'] as int;
    g.bombs = j['bombs'] as int;
    g.trayIndex = j['trayIndex'] as int;
    g.elapsedMs = j['elapsedMs'] as int;
    g.budgetMs = j['budgetMs'] as int;
    g.outcome = Outcome.values.byName(j['outcome'] as String);
    if ([
      g.score,
      g.streak,
      g.lines,
      g.moves,
      g.placements,
      g.bombs,
      g.elapsedMs
    ].any((v) => v < 0)) {
      throw const FormatException('Negative state');
    }
    if (g.outcome == Outcome.playing) g._resolve();
    return g;
  }
}
