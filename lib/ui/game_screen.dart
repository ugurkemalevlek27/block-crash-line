import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ads/ads_manager.dart';
import '../controller.dart';
import '../engine/game.dart';
import '../engine/shapes.dart';
import 'style.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  final boardKey = GlobalKey(), rootKey = GlobalKey();
  int? selected, hoverRow, hoverCol;
  Offset? dragPosition;
  bool dragging = false, leaving = false;
  double cell = 32;
  late final AnimationController effect;
  MoveResult? observed;
  Set<int> particles = {};
  @override
  void initState() {
    super.initState();
    effect = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    effect.dispose();
    super.dispose();
  }

  void _drag(int slot, Offset global) {
    final g = ref.read(appProvider).game;
    if (g == null || !g.inputAllowed || ref.read(appProvider).busy) return;
    final box = boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    cell = box.size.width / 8;
    final s = slot >= 0 ? shapes[g.tray[slot]] : null;
    final offset = slot == -1
        ? const Offset(0, -54)
        : Offset(-s!.width * cell / 2, -s.height * cell - 42);
    final local = box.globalToLocal(global + offset);
    setState(() {
      selected = slot;
      dragging = true;
      dragPosition = global + offset;
      hoverRow = (local.dy / cell).floor();
      hoverCol = (local.dx / cell).floor();
    });
  }

  Future<void> _drop() async {
    if (selected != null && hoverRow != null && hoverCol != null) {
      await ref
          .read(appProvider)
          .move(selected!, hoverRow!, hoverCol!, bomb: selected == -1);
    }
    if (mounted)
      setState(() {
        dragging = false;
        dragPosition = null;
        hoverRow = null;
        hoverCol = null;
        selected = null;
      });
  }

  void _cancel() {
    setState(() {
      dragging = false;
      dragPosition = null;
      hoverRow = null;
      hoverCol = null;
    });
  }

  Future<void> _tap(Offset local) async {
    if (selected == null) return;
    final box = boardKey.currentContext!.findRenderObject() as RenderBox;
    cell = box.size.width / 8;
    await ref.read(appProvider).move(
        selected!, (local.dy / cell).floor(), (local.dx / cell).floor(),
        bomb: selected == -1);
    if (mounted) setState(() => selected = null);
  }

  Future<void> _exit() async {
    if (leaving || ref.read(appProvider).busy) return;
    leaving = true;
    await ref.read(appProvider).pause(true);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pause() async {
    final a = ref.read(appProvider), p = a.profile;
    await a.pause(true);
    if (!mounted) return;
    final choice = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
                title: Text(text(p, 'Duraklatıldı', 'Paused')),
                content: Text(a.game?.mode == Mode.timeAttack
                    ? text(p, 'Time Attack geri sayımı devam ediyor.',
                        'Time Attack countdown continues.')
                    : text(p, 'Hazır olduğunda devam et.',
                        'Continue when you are ready.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, 'home'),
                      child: Text(text(p, 'Menü', 'Menu'))),
                  TextButton(
                      onPressed: () => Navigator.pop(c, 'restart'),
                      child: Text(text(p, 'Yeniden başlat', 'Restart'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, 'resume'),
                      child: Text(text(p, 'Devam', 'Continue')))
                ]));
    if (choice == 'home') {
      await _exit();
      return;
    }
    if (choice == 'restart') {
      final g = a.game!;
      await a.start(g.mode, levelId: g.level?.id);
      selected = null;
    } else {
      await a.pause(false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final a = ref.watch(appProvider), g = a.game!, p = a.profile;
    final style = BoardStyle.of(p.theme);
    if (observed != g.last && g.last.accepted) {
      observed = g.last;
      if (!p.reducedMotion && g.last.cleared.isNotEmpty) {
        particles = Set.of(g.last.cleared);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) effect.forward(from: 0);
        });
      }
    }
    final title = g.mode == Mode.adventure
        ? '${text(p, 'Bölüm', 'Level')} ${g.level!.id}'
        : [
            'Classic',
            'Time Attack',
            'High Score Rush',
            'Adventure'
          ][g.mode.index];
    final target = g.mode == Mode.timeAttack
        ? '${(g.remainingMs / 1000).ceil()} ${text(p, 'saniye', 'seconds')}'
        : g.mode == Mode.rush
            ? '${g.score} / 5.000'
            : g.mode == Mode.adventure
                ? '${text(p, 'Hedef', 'Goal')}: ${g.level!.targetScore > 0 ? '${g.score}/${g.level!.targetScore} ${text(p, 'puan', 'points')}' : '${g.lines}/${g.level!.targetLines} ${text(p, 'çizgi', 'lines')}'}'
                : '${text(p, 'Rekor', 'Best')}: ${p.classicBest}';
    final gridValid = selected == -1
        ? hoverRow != null &&
            hoverRow! >= 0 &&
            hoverRow! < 8 &&
            hoverCol! >= 0 &&
            hoverCol! < 8
        : selected != null &&
            selected! >= 0 &&
            g.tray[selected!] != null &&
            hoverRow != null &&
            g.fits(g.tray[selected!]!, hoverRow!, hoverCol!);
    Offset? rootPosition;
    if (dragPosition != null && rootKey.currentContext != null) {
      final root = rootKey.currentContext!.findRenderObject() as RenderBox;
      rootPosition = root.globalToLocal(dragPosition!);
    }
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _exit();
        },
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: IconButton(
                    onPressed: a.busy ? null : _exit,
                    icon: const Icon(Icons.arrow_back)),
                title: Text(title),
                actions: [
                  IconButton(
                      onPressed: a.busy ? null : _pause,
                      tooltip: text(p, 'Duraklat', 'Pause'),
                      icon: const Icon(Icons.pause_rounded))
                ]),
            body: Backdrop(
                profile: p,
                child: SafeArea(
                    child: Stack(key: rootKey, children: [
                  LayoutBuilder(builder: (c, box) {
                    final reserved = 270.0 +
                        (g.mode == Mode.adventure && g.level!.bombs > 0
                            ? 56.0
                            : 0.0);
                    final boardSize = min(
                        box.maxWidth - 28, max(80.0, box.maxHeight - reserved));
                    cell = (boardSize - 4) / 8;
                    return Column(children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 4),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(text(p, 'PUAN', 'SCORE'),
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  letterSpacing: 2,
                                                  color: Colors.white60)),
                                          FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text('${g.score}',
                                                  style: const TextStyle(
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w900)))
                                        ])),
                                Expanded(
                                    flex: 5,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(target,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          Text(
                                              '${g.moves} ${text(p, 'hamle', 'moves')} · ${g.placements} ${text(p, 'yerleştirme', 'placements')}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white60)),
                                          if (g.level != null &&
                                              (g.level!.maxMoves > 0 ||
                                                  g.level!.maxPlacements > 0))
                                            Text(
                                                g.level!.maxMoves > 0
                                                    ? '${text(p, 'Hamle sınırı', 'Move limit')}: ${g.level!.maxMoves}'
                                                    : '${text(p, 'Yerleştirme sınırı', 'Placement limit')}: ${g.level!.maxPlacements}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xffffca76)))
                                        ]))
                              ])),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                              '${text(p, 'Combo', 'Combo')} ×${g.last.combo}  ·  ${text(p, 'Streak', 'Streak')} ×${multiplier(g.streak)}  ·  +${g.last.points}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: style.glow))),
                      Expanded(
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(maxWidth: boardSize),
                                  child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: style.border,
                                                  width: 2),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              color: const Color(0xff0a1429)),
                                          child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: GestureDetector(
                                                  key: boardKey,
                                                  onTapUp: (d) =>
                                                      _tap(d.localPosition),
                                                  child: AnimatedBuilder(
                                                      animation: effect,
                                                      builder: (c, _) => CustomPaint(
                                                          painter: BoardPainter(
                                                              g,
                                                              style,
                                                              selected,
                                                              hoverRow,
                                                              hoverCol,
                                                              gridValid,
                                                              particles,
                                                              effect.value,
                                                              p.theme),
                                                          size: Size(boardSize, boardSize)))))))))),
                      SizedBox(
                          height: 18,
                          child: dragging
                              ? Text(
                                  gridValid
                                      ? text(p, 'Bırak: yerleştir',
                                          'Release to place')
                                      : text(p, 'Buraya yerleştirilemez',
                                          'Cannot place here'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: gridValid
                                          ? const Color(0xff73e4be)
                                          : const Color(0xffff7979)))
                              : const SizedBox()),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                          child: Row(
                              children: List.generate(3, (slot) {
                            final id = g.tray[slot];
                            final shape = id == null ? null : shapes[id]!;
                            return Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Semantics(
                                        button: true,
                                        label:
                                            '${text(p, 'Parça', 'Piece')} ${slot + 1}: ${id ?? text(p, 'kullanıldı', 'used')}',
                                        selected: selected == slot,
                                        child: GestureDetector(
                                            onTap: shape == null || a.busy
                                                ? null
                                                : () => setState(
                                                    () => selected = slot),
                                            onPanStart: shape == null
                                                ? null
                                                : (d) => _drag(
                                                    slot, d.globalPosition),
                                            onPanUpdate: shape == null
                                                ? null
                                                : (d) => _drag(
                                                    slot, d.globalPosition),
                                            onPanEnd: shape == null
                                                ? null
                                                : (_) => _drop(),
                                            onPanCancel: _cancel,
                                            child: AnimatedContainer(
                                                duration: p.reducedMotion ? Duration.zero : const Duration(milliseconds: 120),
                                                height: 86,
                                                decoration: BoxDecoration(color: const Color(0x77182742), borderRadius: BorderRadius.circular(15), border: Border.all(color: selected == slot ? style.glow : style.border, width: selected == slot ? 2 : 1)),
                                                child: shape == null ? const Center(child: Icon(Icons.check, color: Colors.white24)) : Center(child: CustomPaint(size: Size(shape.width * min(18.0, cell * .6), shape.height * min(18.0, cell * .6)), painter: PiecePainter(shape, style, p.theme))))))));
                          }))),
                      if (g.mode == Mode.adventure && g.level!.bombs > 0)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GestureDetector(
                                onPanStart: g.bombs == 0
                                    ? null
                                    : (d) => _drag(-1, d.globalPosition),
                                onPanUpdate: g.bombs == 0
                                    ? null
                                    : (d) => _drag(-1, d.globalPosition),
                                onPanEnd: g.bombs == 0 ? null : (_) => _drop(),
                                onPanCancel: _cancel,
                                child: OutlinedButton.icon(
                                    onPressed: g.bombs == 0 || a.busy
                                        ? null
                                        : () => setState(() => selected = -1),
                                    style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: selected == -1
                                                ? style.glow
                                                : style.border)),
                                    icon:
                                        const Icon(Icons.local_fire_department),
                                    label: Text(
                                        '${text(p, 'Bomba', 'Bomb')} ×${g.bombs}')))),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 14),
                          child: Text(
                              text(p, 'Sürükle veya parça seçip tahtaya dokun.',
                                  'Drag, or select a piece and tap the board.'),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white54))),
                    ]);
                  }),
                  if (dragging && rootPosition != null && selected != null)
                    Positioned(
                        left: rootPosition.dx,
                        top: rootPosition.dy,
                        child: IgnorePointer(
                            child: selected == -1
                                ? Icon(Icons.local_fire_department,
                                    size: 38, color: style.glow)
                                : g.tray[selected!] == null
                                    ? const SizedBox()
                                    : CustomPaint(
                                        size: Size(
                                            shapes[g.tray[selected!]]!.width *
                                                cell,
                                            shapes[g.tray[selected!]]!.height *
                                                cell),
                                        painter: PiecePainter(
                                            shapes[g.tray[selected!]]!,
                                            style,
                                            p.theme)))),
                  if (a.error != null)
                    Align(
                        alignment: Alignment.topCenter,
                        child: MaterialBanner(
                            content: Text(a.error!),
                            actions: [
                              TextButton(
                                  onPressed: a.dismissError,
                                  child: const Text('OK'))
                            ])),
                  if (g.paused && g.outcome == Outcome.playing)
                    ColoredBox(
                        color: const Color(0xb9000000),
                        child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Text(text(p, 'Duraklatıldı', 'Paused'),
                                  style: Theme.of(c).textTheme.headlineMedium),
                              const SizedBox(height: 12),
                              if (g.mode == Mode.timeAttack)
                                Text(text(p, 'Geri sayım devam ediyor.',
                                    'Countdown continues.')),
                              FilledButton(
                                  onPressed: () => a.pause(false),
                                  child: Text(text(p, 'Devam', 'Continue')))
                            ]))),
                  if (g.outcome != Outcome.playing)
                    _Result(
                        game: g,
                        onHome: _exit,
                        onRestart: () async {
                          await a.start(g.mode, levelId: g.level?.id);
                          if (mounted) setState(() => selected = null);
                        },
                        onNext: g.mode == Mode.adventure &&
                                g.outcome == Outcome.won &&
                                g.level!.id < 20
                            ? () async {
                                await a.start(Mode.adventure,
                                    levelId: g.level!.id + 1);
                                if (mounted) setState(() => selected = null);
                              }
                            : null),
                ])))));
  }
}

class _Result extends ConsumerWidget {
  final Game game;
  final VoidCallback onHome, onRestart;
  final VoidCallback? onNext;
  const _Result(
      {required this.game,
      required this.onHome,
      required this.onRestart,
      this.onNext});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final a = ref.watch(appProvider),
        p = a.profile,
        won = game.outcome == Outcome.won;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => AdsManager.instance.onGameEnded(identityHashCode(game)));
    return ColoredBox(
        color: const Color(0xe8071020),
        child: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(won ? Icons.emoji_events : Icons.grid_off,
                      size: 64, color: const Color(0xffffc774)),
                  const SizedBox(height: 14),
                  Text(
                      won
                          ? text(p, 'Harika iş!', 'Great work!')
                          : game.mode == Mode.timeAttack &&
                                  game.remainingMs == 0
                              ? text(p, 'Süre doldu', 'Time is up')
                              : (game.mode == Mode.classic ||
                                      game.mode == Mode.timeAttack)
                                  ? text(p, 'Oyun bitti', 'Game over')
                                  : text(p, 'Hedef tamamlanamadı',
                                      'Goal not reached'),
                      textAlign: TextAlign.center,
                      style: Theme.of(c).textTheme.headlineMedium),
                  if (won)
                    Text(
                        List.generate(3, (i) => i < game.stars ? '★' : '☆')
                            .join(' '),
                        style: const TextStyle(
                            fontSize: 46, color: Color(0xffffc774))),
                  const SizedBox(height: 14),
                  Text('${game.score}',
                      style: const TextStyle(
                          fontSize: 46, fontWeight: FontWeight.w900)),
                  Text(
                      '${game.lines} ${text(p, 'çizgi', 'lines')} · ${game.moves} ${text(p, 'hamle', 'moves')}'),
                  const SizedBox(height: 10),
                  Text(
                      '${text(p, 'Bakiye', 'Balance')}: ${p.coins} ${text(p, 'jeton', 'coins')}'),
                  const SizedBox(height: 24),
                  if (onNext != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FilledButton(
                            onPressed: a.busy ? null : onNext,
                            child:
                                Text(text(p, 'Sonraki bölüm', 'Next level')))),
                  FilledButton.tonal(
                      onPressed: a.busy ? null : onRestart,
                      child: Text(text(p, 'Yeniden oyna', 'Play again'))),
                  const SizedBox(height: 10),
                  TextButton(
                      onPressed: a.busy ? null : onHome,
                      child: Text(text(p, 'Ana menü', 'Main menu')))
                ]))));
  }
}

void paintBlock(Canvas canvas, Rect rect, Color color, String theme) {
  final r = RRect.fromRectAndRadius(
      rect.deflate(2), Radius.circular(theme == 'gem' ? 3 : 6));
  final paint = Paint()
    ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, .18)!,
          color,
          Color.lerp(color, Colors.black, .2)!
        ]).createShader(rect);
  if (theme == 'neon')
    canvas.drawRRect(
        r,
        Paint()
          ..color = color.withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  canvas.drawRRect(r, paint);
  canvas.drawLine(
      Offset(rect.left + 7, rect.top + 5),
      Offset(rect.right - 7, rect.top + 5),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 2);
  if (theme == 'gem')
    canvas.drawPath(
        Path()
          ..moveTo(rect.left + 3, rect.center.dy)
          ..lineTo(rect.center.dx, rect.top + 3)
          ..lineTo(rect.right - 3, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom - 3)
          ..close(),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white30);
}

class PiecePainter extends CustomPainter {
  final Shape shape;
  final BoardStyle style;
  final String theme;
  PiecePainter(this.shape, this.style, this.theme);
  @override
  void paint(Canvas c, Size size) {
    final step = size.width / shape.width;
    for (final cell in shape.cells)
      paintBlock(c, Rect.fromLTWH(cell.col * step, cell.row * step, step, step),
          style.colors[shape.color], theme);
  }

  @override
  bool shouldRepaint(covariant PiecePainter old) =>
      old.shape != shape || old.theme != theme;
}

class BoardPainter extends CustomPainter {
  final Game game;
  final BoardStyle style;
  final int? slot, row, col;
  final bool valid;
  final Set<int> particles;
  final double progress;
  final String theme;
  BoardPainter(this.game, this.style, this.slot, this.row, this.col, this.valid,
      this.particles, this.progress, this.theme);
  @override
  void paint(Canvas c, Size size) {
    final step = size.width / 8;
    for (var i = 0; i < 64; i++) {
      final rect = Rect.fromLTWH(i % 8 * step, i ~/ 8 * step, step, step);
      c.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(5)),
          Paint()..color = style.cell);
      if (game.board[i] > 0)
        paintBlock(c, rect, style.colors[game.board[i]], theme);
    }
    if (slot != null && row != null && col != null) {
      final cells = slot == -1
          ? [
              for (var r = -1; r <= 1; r++)
                for (var k = -1; k <= 1; k++) Cell(r, k)
            ]
          : game.tray[slot!] == null
              ? <Cell>[]
              : shapes[game.tray[slot!]]!.cells;
      for (final cell in cells) {
        final rect = Rect.fromLTWH(
                (col! + cell.col) * step, (row! + cell.row) * step, step, step)
            .deflate(2);
        c.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(5)),
            Paint()
              ..color = (valid ? style.glow : Colors.redAccent)
                  .withValues(alpha: .42));
        c.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(5)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = valid ? Colors.white : Colors.redAccent);
        if (!valid) {
          c.drawLine(
              rect.topLeft + const Offset(4, 4),
              rect.bottomRight - const Offset(4, 4),
              Paint()
                ..color = Colors.white
                ..strokeWidth = 2);
          c.drawLine(
              rect.topRight + const Offset(-4, 4),
              rect.bottomLeft + const Offset(4, -4),
              Paint()
                ..color = Colors.white
                ..strokeWidth = 2);
        }
      }
    }
    if (progress > 0 && progress < 1) {
      for (final i in particles) {
        final center = Offset((i % 8 + .5) * step, (i ~/ 8 + .5) * step);
        for (var j = 0; j < 4; j++) {
          final angle = j * pi / 2 + i * .6;
          final at =
              center + Offset(cos(angle), sin(angle)) * progress * step * 1.3;
          final paint = Paint()
            ..color = style.glow.withValues(alpha: 1 - progress);
          if (theme == 'gem')
            c.drawRect(
                Rect.fromCenter(
                    center: at,
                    width: 5 * (1 - progress),
                    height: 5 * (1 - progress)),
                paint);
          else
            c.drawCircle(at, 4 * (1 - progress), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
