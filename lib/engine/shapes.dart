import 'dart:math';

class Cell {
  final int row, col;
  const Cell(this.row, this.col);
  int get index => row * 8 + col;
}

class Shape {
  final String id;
  final List<Cell> cells;
  const Shape(this.id, this.cells);
  int get width => cells.map((e) => e.col).reduce(max) + 1;
  int get height => cells.map((e) => e.row).reduce(max) + 1;
  int get color => shapes.keys.toList().indexOf(id) % 6 + 1;
}

const shapes = <String, Shape>{
  'single': Shape('single', [Cell(0, 0)]),
  'h2': Shape('h2', [Cell(0, 0), Cell(0, 1)]),
  'v2': Shape('v2', [Cell(0, 0), Cell(1, 0)]),
  'h3': Shape('h3', [Cell(0, 0), Cell(0, 1), Cell(0, 2)]),
  'v3': Shape('v3', [Cell(0, 0), Cell(1, 0), Cell(2, 0)]),
  'square': Shape('square', [Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1)]),
  'L': Shape('L', [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(2, 1)]),
  'T': Shape('T', [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(1, 1)]),
  'Z': Shape('Z', [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 2)]),
  'h4': Shape('h4', [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(0, 3)]),
  'v4': Shape('v4', [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(3, 0)]),
};

List<String?> randomTray(Random random, int score) {
  final pool = shapes.values.toList();
  final result = <String?>[];
  for (var n = 0; n < 3; n++) {
    final weights = pool
        .map<int>(
            (s) => 10 + (s.cells.length >= 4 ? min<int>(score ~/ 500, 25) : 0))
        .toList();
    var pick = random.nextInt(weights.reduce((a, b) => a + b));
    var index = 0;
    while (pick >= weights[index]) {
      pick -= weights[index++];
    }
    result.add(pool.removeAt(index).id);
  }
  return result;
}
