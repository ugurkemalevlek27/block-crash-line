import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ads/ads_manager.dart';
import '../controller.dart';
import '../economy/profile.dart';
import '../engine/game.dart';
import 'style.dart';
import 'game_screen.dart';

void open(BuildContext c, Widget page) =>
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => page));
Future<void> launch(BuildContext c, AppController app, Mode mode,
    {int? level, bool resume = false}) async {
  final ok = await app.start(mode, levelId: level, resume: resume);
  if (c.mounted && ok) open(c, const GameScreen());
}

class PageShell extends ConsumerWidget {
  final String tr, en;
  final Widget child;
  const PageShell(
      {super.key, required this.tr, required this.en, required this.child});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return Scaffold(
        appBar: AppBar(title: Text(text(app.profile, tr, en))),
        body: Backdrop(
            profile: app.profile,
            child: SafeArea(
                child: Column(children: [
              if (app.error != null)
                MaterialBanner(content: Text(app.error!), actions: [
                  TextButton(
                      onPressed: app.dismissError, child: const Text('OK'))
                ]),
              Expanded(child: child)
            ]))));
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final app = ref.watch(appProvider), p = app.profile;
    return PageShell(
        tr: '',
        en: '',
        child: Column(children: [
          Expanded(
              child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            children: [
              const Center(child: BlockLogo()),
              const SizedBox(height: 16),
              const Text('BLOCK\nCRASH LINE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 36,
                      height: .98,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(
                  text(p, 'Bir hamle. Yeni bir ihtimal.',
                      'One move. A new possibility.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xffa4b5d0))),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: _Stat(
                        Icons.emoji_events_outlined,
                        '${p.classicBest}',
                        text(p, 'CLASSIC REKOR', 'CLASSIC BEST'))),
                const SizedBox(width: 10),
                Expanded(
                    child: _Stat(
                        Icons.toll, '${p.coins}', text(p, 'JETON', 'COINS')))
              ]),
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed:
                      app.busy ? null : () => open(c, const ModeScreen()),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(text(p, 'OYNA', 'PLAY'))),
              if (p.classic != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                        onPressed: app.busy
                            ? null
                            : () => launch(c, app, Mode.classic, resume: true),
                        icon: const Icon(Icons.history),
                        label: Text(text(p, 'Classic oyununa devam et',
                            'Continue Classic')))),
              const SizedBox(height: 14),
              _Menu(Icons.explore_outlined, text(p, 'Macera', 'Adventure'),
                  () => open(c, const AdventureScreen())),
              _Menu(Icons.palette_outlined, text(p, 'Mağaza', 'Shop'),
                  () => open(c, const ShopScreen())),
              _Menu(
                  Icons.military_tech_outlined,
                  text(p, 'Başarılar', 'Achievements'),
                  () => open(c, const AchievementsScreen())),
              _Menu(Icons.tune, text(p, 'Ayarlar', 'Settings'),
                  () => open(c, const SettingsScreen())),
              const SizedBox(height: 16),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text(p, 'GÜNLÜK GÖREV', 'DAILY QUEST'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(text(p, '20 çizgi temizle · 100 jeton',
                                'Clear 20 lines · 100 coins')),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                                value: min(p.dailyLines, 20) / 20),
                            const SizedBox(height: 8),
                            Text(
                                '${min(p.dailyLines, 20)}/20 · ${text(p, 'Günlük giriş: 50 jeton eklendi', 'Daily login: 50 coins added')}')
                          ]))),
              const SizedBox(height: 12),
              Text(text(p, 'ÇEVRİMDIŞI OYNANIR', 'PLAYS OFFLINE'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, letterSpacing: 2, color: Colors.white54))
            ])),
          const AdBanner()
        ]));
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _Stat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext c) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Icon(icon, color: const Color(0xffffcc76)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white60))
          ])));
}

class _Menu extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Menu(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext c) => Card(
      child: ListTile(
          minVerticalPadding: 15,
          leading: Icon(icon),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap));
}

class ModeScreen extends ConsumerWidget {
  const ModeScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final a = ref.watch(appProvider), p = a.profile;
    final desc = [
      text(p, 'Sınır yok. Kendi rekorunu kır.',
          'No limits. Beat your own best.'),
      text(p, '60 saniye. Çoklu çizgilerle süre kazan.',
          '60 seconds. Clear multiple lines for more time.'),
      text(p, '5.000 puana en az hamlede ulaş.',
          'Reach 5,000 points in fewer moves.'),
      text(p, '20 bölüm, hedefler ve bomba görevleri.',
          '20 levels, goals and bomb challenges.')
    ];
    return PageShell(
        tr: 'Oyun modu',
        en: 'Game mode',
        child: ListView(
            padding: const EdgeInsets.all(20),
            children: List.generate(
                4,
                (n) => Card(
                    child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: Icon(
                            [
                              Icons.grid_view,
                              Icons.timer_outlined,
                              Icons.bolt,
                              Icons.explore
                            ][n],
                            size: 30),
                        title: Text([
                          'Classic',
                          'Time Attack',
                          'High Score Rush',
                          text(p, 'Macera', 'Adventure')
                        ][n]),
                        subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(desc[n])),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: a.busy
                            ? null
                            : () => n == 3
                                ? open(c, const AdventureScreen())
                                : launch(c, a, Mode.values[n]))))));
  }
}

class AdventureScreen extends ConsumerWidget {
  const AdventureScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final a = ref.watch(appProvider), p = a.profile;
    return PageShell(
        tr: 'Macera haritası',
        en: 'Adventure map',
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(
              text(
                  p, 'Her bölümde yeni bir hedef', 'A new goal in every level'),
              style: Theme.of(c).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(text(p, 'Çizgileri temizle, yıldızları topla.',
              'Clear lines. Collect stars.')),
          const SizedBox(height: 20),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: 20,
              itemBuilder: (c, n) {
                final id = n + 1, locked = id > p.unlocked;
                return Semantics(
                    label: '${text(p, 'Bölüm', 'Level')} $id',
                    button: true,
                    child: Material(
                        color: locked
                            ? const Color(0xff152039)
                            : const Color(0xff284873),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: locked || a.busy
                                ? null
                                : () => launch(c, a, Mode.adventure, level: id),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  locked
                                      ? const Icon(Icons.lock_outline,
                                          color: Colors.white38)
                                      : Text('$id',
                                          style: const TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold)),
                                  Text(
                                      List.generate(
                                          3,
                                          (s) => s < (p.levelStars[id] ?? 0)
                                              ? '★'
                                              : '☆').join(),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xffffca76)))
                                ]))));
              }),
          const SizedBox(height: 22),
          Text(text(
              p,
              '1–5 Temel çizgiler\n6–10 Puan ve hamleler\n11–15 Çizgi ve yerleştirme sınırı\n16–20 Yoğun tahtalar ve bombalar',
              '1–5 Basic line clears\n6–10 Score and moves\n11–15 Lines and placement limits\n16–20 Dense boards and bombs'))
        ]));
  }
}

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final a = ref.watch(appProvider), p = a.profile;
    Widget item(String id, String name, bool isTheme) {
      final owned = p.owned.contains(id), price = productPrices[id]!;
      final selected = (isTheme ? p.theme : p.background) == id;
      return Card(
          child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: isTheme
                  ? CircleAvatar(
                      backgroundColor: BoardStyle.of(id).colors[1],
                      child:
                          const Icon(Icons.palette, color: Color(0xff111e33)))
                  : const Icon(Icons.landscape_outlined),
              title: Text(name),
              subtitle: Text(owned
                  ? text(p, 'Açıldı', 'Unlocked')
                  : '$price ${text(p, 'jeton', 'coins')}'),
              trailing: FilledButton.tonal(
                  onPressed: a.busy || (!owned && p.coins < price)
                      ? null
                      : () async {
                          final ok = await a.selectProduct(id, isTheme);
                          if (ok && id == 'custom') await a.pickPhoto();
                        },
                  child: Text(selected && id != 'custom'
                      ? text(p, 'Seçili', 'Selected')
                      : owned
                          ? (id == 'custom'
                              ? text(p, 'Fotoğraf seç', 'Pick photo')
                              : text(p, 'Seç', 'Select'))
                          : text(p, 'Aç', 'Unlock')))));
    }

    return PageShell(
        tr: 'Mağaza',
        en: 'Shop',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('${p.coins} ${text(p, 'jeton', 'coins')}',
              style: Theme.of(c).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(text(p, 'TEMALAR', 'THEMES'),
              style: const TextStyle(letterSpacing: 2, color: Colors.white60)),
          item('dark', 'Classic Dark', true),
          item('neon', 'Neon Glow', true),
          item('forest', 'Forest', true),
          item('gem', 'Gem & Crystal', true),
          const SizedBox(height: 18),
          Text(text(p, 'ARKA PLANLAR', 'BACKGROUNDS'),
              style: const TextStyle(letterSpacing: 2, color: Colors.white60)),
          item('plain', text(p, 'Sade', 'Plain'), false),
          item('bamboo', text(p, 'Bambu ormanı', 'Bamboo forest'), false),
          item('mountain', text(p, 'Dağ', 'Mountain'), false),
          item('waterfall', text(p, 'Şelale', 'Waterfall'), false),
          item('custom', text(p, 'Kendi fotoğrafın', 'Your photo'), false)
        ]));
  }
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final p = ref.watch(appProvider).profile;
    final names = [
      text(p, 'İlk Adım', 'First Step'),
      text(p, 'Binlik Skor', 'Thousand Points'),
      text(p, 'Hız Ustası', 'Speed Master'),
      text(p, 'Yıkım Uzmanı', 'Demolition Expert'),
      text(p, 'Kişisel Dokunuş', 'Personal Touch'),
      text(p, 'Büyük Usta', 'Grand Master')
    ];
    final desc = [
      text(p, 'Adventure 1’i tamamla', 'Complete Adventure 1'),
      text(p, 'Classic’te 1.000 puan', 'Score 1,000 in Classic'),
      text(p, 'Tek Time Attack turunda 10 çizgi',
          '10 lines in one Time Attack run'),
      text(p, 'Toplam 10 bomba kullan', 'Use 10 bombs in total'),
      text(p, 'Özel arka planı aç ve kullan', 'Unlock and use a custom photo'),
      text(p, '20 bölümde 3 yıldız', '3 stars in all 20 levels')
    ];
    final ids = achievementRewards.keys.toList();
    return PageShell(
        tr: 'Başarılar',
        en: 'Achievements',
        child: ListView(
            padding: const EdgeInsets.all(16),
            children: List.generate(ids.length, (n) {
              final done = p.achievements.contains(ids[n]);
              return Card(
                  child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                          done ? Icons.verified : Icons.military_tech_outlined,
                          color:
                              done ? const Color(0xffffcc76) : Colors.white38),
                      title: Text(names[n]),
                      subtitle: Text(
                          '${desc[n]}\n${achievementRewards[ids[n]]} ${text(p, 'jeton', 'coins')}'),
                      trailing: done ? const Icon(Icons.check) : null));
            })));
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final a = ref.watch(appProvider), p = a.profile;
    return PageShell(
        tr: 'Ayarlar',
        en: 'Settings',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _Volume(
              label: text(p, 'Ana ses seviyesi', 'Master volume'),
              value: p.masterVolume,
              onChanged: (v) => a.mutate((p) => p.masterVolume = v)),
          _Volume(
              label: text(p, 'Müzik seviyesi', 'Music volume'),
              value: p.musicVolume,
              onChanged: (v) => a.mutate((p) => p.musicVolume = v)),
          SwitchListTile(
              title: Text(text(p, 'Ses efektleri', 'Sound effects')),
              value: p.effects,
              onChanged: a.busy ? null : (v) => a.mutate((p) => p.effects = v)),
          SwitchListTile(
              title: Text(text(p, 'Titreşim', 'Haptics')),
              value: p.vibration,
              onChanged:
                  a.busy ? null : (v) => a.mutate((p) => p.vibration = v)),
          SwitchListTile(
              title: Text(text(p, 'Azaltılmış hareket', 'Reduced motion')),
              value: p.reducedMotion,
              onChanged:
                  a.busy ? null : (v) => a.mutate((p) => p.reducedMotion = v)),
          const Divider(),
          ListTile(
              title: Text(text(p, 'Müzik', 'Music')),
              subtitle: DropdownButton<int>(
                  value: p.musicTrack,
                  isExpanded: true,
                  items: [
                    for (final n in [-1, 0, 1, 2])
                      DropdownMenuItem(
                          value: n,
                          child: Text(n == -1
                              ? text(p, 'Karışık', 'Shuffle')
                              : [
                                  'Bamboo Dawn',
                                  'Quiet Mountain',
                                  'Crystal Stream'
                                ][n]))
                  ],
                  onChanged: a.busy
                      ? null
                      : (v) {
                          if (v != null) a.mutate((p) => p.musicTrack = v);
                        })),
          const SizedBox(height: 24),
          Text(
              text(
                  p,
                  'Fotoğraflar ve ilerleme bu cihazda saklanır. Oyun hesabı veya internet bağlantısı gerekmez.',
                  'Photos and progress stay on this device. No account or internet connection required.'),
              style: const TextStyle(color: Colors.white60))
        ]));
  }
}

class _Volume extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _Volume(
      {required this.label, required this.value, required this.onChanged});
  @override
  State<_Volume> createState() => _VolumeState();
}

class _VolumeState extends State<_Volume> {
  double? draft;
  @override
  Widget build(BuildContext c) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(widget.label)),
        Slider(
            value: draft ?? widget.value,
            onChanged: (v) => setState(() => draft = v),
            onChangeEnd: (v) {
              widget.onChanged(v);
              setState(() => draft = null);
            })
      ]);
}
