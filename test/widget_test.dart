import 'dart:convert';
import 'dart:io';
import 'package:block_crash/levels/level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:block_crash/controller.dart';
import 'package:block_crash/engine/game.dart';
import 'package:block_crash/ui/game_screen.dart';

void main() {
  testWidgets(
      'Game layout fits small portrait display and offers three piece slots',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController()
      ..ready = true
      ..game = Game(Mode.classic);
    await tester.pumpWidget(ProviderScope(
        overrides: [appProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: GameScreen())));
    await tester.pump();
    expect(find.text('Classic'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Parça [123]:')), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
  for (final mode in [Mode.timeAttack, Mode.rush, Mode.adventure]) {
    testWidgets('Small portrait fits ${mode.name} including bomb tray',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final levels =
          (jsonDecode(File('assets/levels/levels.json').readAsStringSync())
                  as List)
              .map((j) => Level.fromJson(Map<String, dynamic>.from(j)))
              .toList();
      final controller = AppController()
        ..ready = true
        ..game = Game(mode, level: mode == Mode.adventure ? levels[15] : null);
      await tester.pumpWidget(ProviderScope(
          overrides: [appProvider.overrideWith((ref) => controller)],
          child: const MaterialApp(home: GameScreen())));
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('Parça [123]:')), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }
}
