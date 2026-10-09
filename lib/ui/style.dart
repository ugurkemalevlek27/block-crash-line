import 'dart:io';
import 'package:flutter/material.dart';
import '../economy/profile.dart';

class BoardStyle {
  final Color cell, border, glow;
  final List<Color> colors;
  const BoardStyle(this.cell, this.border, this.glow, this.colors);
  static BoardStyle of(String id) => switch (id) {
        'neon' => const BoardStyle(
              Color(0xff11112b), Color(0xff7135bd), Color(0xffff4bce), [
            Colors.transparent,
            Color(0xff10e0ee),
            Color(0xffff47c1),
            Color(0xffae5aff),
            Color(0xffdcfa57),
            Color(0xffff9849),
            Color(0xff598dff)
          ]),
        'forest' => const BoardStyle(
              Color(0xff102c26), Color(0xff356c50), Color(0xff8add7f), [
            Colors.transparent,
            Color(0xff66bd76),
            Color(0xffdfbe62),
            Color(0xff53bfbd),
            Color(0xffa78bd4),
            Color(0xffec9461),
            Color(0xff81aadd)
          ]),
        'gem' => const BoardStyle(
              Color(0xff211b35), Color(0xff6f579b), Color(0xffb2e8ff), [
            Colors.transparent,
            Color(0xff8cd7ff),
            Color(0xffcf87ee),
            Color(0xffeec873),
            Color(0xff6cdbbd),
            Color(0xfff085a3),
            Color(0xff8c9eef)
          ]),
        _ => const BoardStyle(
              Color(0xff172541), Color(0xff2c3d5f), Color(0xff5bcef5), [
            Colors.transparent,
            Color(0xff5bb4ff),
            Color(0xffffbd59),
            Color(0xffaa89ff),
            Color(0xff59d3b8),
            Color(0xfff581a1),
            Color(0xffec8964)
          ]),
      };
}

String text(Profile p, String tr, String en) => p.language == 'en' ? en : tr;

class Backdrop extends StatelessWidget {
  final Profile profile;
  final Widget child;
  const Backdrop({super.key, required this.profile, required this.child});
  @override
  Widget build(BuildContext context) {
    Widget? image;
    if (profile.background == 'custom' && profile.photo.isNotEmpty) {
      image = Image.file(File(profile.photo),
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox());
    } else if (['bamboo', 'mountain', 'waterfall']
        .contains(profile.background)) {
      image = Image.asset('assets/backgrounds/${profile.background}.png',
          fit: BoxFit.cover);
    }
    return Stack(fit: StackFit.expand, children: [
      const DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff101e37), Color(0xff080e20)]))),
      if (image != null) image,
      if (image != null) const ColoredBox(color: Color(0xb9000718)),
      child
    ]);
  }
}

class BlockLogo extends StatelessWidget {
  const BlockLogo({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 94,
      height: 94,
      child: Wrap(
          spacing: 5,
          runSpacing: 5,
          children: List.generate(
              9,
              (n) => Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: n == 0 || n == 8
                          ? Colors.transparent
                          : [
                              const Color(0xff5bb4ff),
                              const Color(0xffffbd59),
                              const Color(0xffaa89ff)
                            ][n % 3],
                      borderRadius: BorderRadius.circular(7))))));
}
