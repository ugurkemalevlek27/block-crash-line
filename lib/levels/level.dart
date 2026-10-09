class Level {
  final int id, targetScore, targetLines, maxMoves, maxPlacements, bombs;
  final List<int> board;
  final List<List<String>> trays;
  final List<Map<String, dynamic>> stars, solution;
  Level.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        targetScore = j['targetScore'] as int,
        targetLines = j['targetLines'] as int,
        maxMoves = j['maxMoves'] as int,
        maxPlacements = j['maxPlacements'] as int,
        bombs = j['bombs'] as int,
        board = (j['board'] as List)
            .cast<String>()
            .expand((r) => r.split('').map((c) => c == '.' ? 0 : 1))
            .toList(),
        trays = (j['trays'] as List)
            .map((t) => (t as List).cast<String>())
            .toList(),
        stars = (j['stars'] as List)
            .map((s) => Map<String, dynamic>.from(s))
            .toList(),
        solution = (j['solution'] as List)
            .map((s) => Map<String, dynamic>.from(s))
            .toList() {
    if (id < 1 ||
        id > 20 ||
        board.length != 64 ||
        bombs < 0 ||
        bombs > 3 ||
        trays.isEmpty ||
        trays.any((t) => t.length != 3 || t.toSet().length != 3)) {
      throw FormatException('Invalid level $id');
    }
  }
  bool reached(int score, int lines) =>
      score >= targetScore && lines >= targetLines;
  int awardStars(
      int score, int lines, int moves, int placements, int elapsedMs) {
    var result = 0;
    for (final rule in stars) {
      final metric = rule['metric'];
      final value = switch (metric) {
        'moves' => moves,
        'placements' => placements,
        'elapsedMs' => elapsedMs,
        _ => throw FormatException('Unknown star metric $metric'),
      };
      if (reached(score, lines) &&
          (rule['maximum'] == null || value <= (rule['maximum'] as int))) {
        final count = rule['stars'] as int;
        if (count > result) result = count;
      }
    }
    return result;
  }
}
