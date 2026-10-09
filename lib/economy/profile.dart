import 'dart:math';
import '../engine/game.dart';

const productPrices = <String, int>{
  'dark': 0,
  'neon': 500,
  'forest': 750,
  'gem': 1000,
  'plain': 0,
  'bamboo': 300,
  'mountain': 300,
  'waterfall': 300,
  'custom': 1500
};
const achievementRewards = <String, int>{
  'first': 50,
  'thousand': 100,
  'speed': 150,
  'demolition': 200,
  'personal': 250,
  'master': 1000
};

class Profile {
  int coins = 0, classicBest = 0, timeBest = 0, bombUses = 0;
  int? rushBest;
  Set<String> owned = {'dark', 'plain'}, achievements = {}, rewards = {};
  Map<int, int> levelStars = {}, levelScores = {};
  String theme = 'dark', background = 'plain', photo = '', language = 'tr';
  double masterVolume = .7, musicVolume = .4;
  bool effects = true, vibration = true, reducedMotion = false;
  int musicTrack = 0;
  String day = '';
  int dailyLines = 0;
  Map<String, dynamic>? classic;
  int get unlocked => min(20, levelStars.keys.fold(0, max) + 1);
  void requireLevel(int id) {
    if (id < 1 || id > 20 || id > unlocked) throw StateError('Locked level');
  }

  bool award(String key, int amount) {
    if (!rewards.add(key)) return false;
    coins += amount;
    return true;
  }

  bool achievement(String id) {
    if (!achievements.add(id)) return false;
    award('achievement:$id', achievementRewards[id]!);
    return true;
  }

  void daily(DateTime now) {
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // A backward calendar change never reopens an already claimed day.
    if (day.isEmpty || today.compareTo(day) > 0) {
      day = today;
      dailyLines = 0;
      award('login:$day', 50);
    }
  }

  bool buy(String id) {
    final price = productPrices[id];
    if (price == null || owned.contains(id) || coins < price) return false;
    coins -= price;
    owned.add(id);
    return true;
  }

  void applyMove(Game g, MoveResult move,
      {required bool bomb, required DateTime now}) {
    daily(now);
    coins += move.coins;
    dailyLines += move.lines;
    if (dailyLines >= 20) award('quest:$day', 100);
    if (bomb) bombUses++;
    if (bombUses >= 10) achievement('demolition');
    if (g.mode == Mode.classic) {
      classicBest = max(classicBest, g.score);
      if (g.score >= 1000) achievement('thousand');
      classic = g.outcome == Outcome.playing ? g.toJson() : null;
    }
    if (g.mode == Mode.timeAttack) {
      timeBest = max(timeBest, g.score);
      if (g.lines >= 10) achievement('speed');
    }
    if (g.mode == Mode.rush && g.outcome == Outcome.won) {
      rushBest = min(rushBest ?? g.placements, g.placements);
    }
    if (g.mode == Mode.adventure && g.outcome == Outcome.won) {
      final id = g.level!.id;
      levelStars[id] = max(levelStars[id] ?? 0, g.stars);
      levelScores[id] = max(levelScores[id] ?? 0, g.score);
      award('level:$id:complete', 100);
      if (g.stars == 3) award('level:$id:three', 50);
      if (id == 1) achievement('first');
      if (List.generate(20, (n) => n + 1).every((n) => levelStars[n] == 3))
        achievement('master');
    }
  }

  Map<String, dynamic> toJson() => {
        'schema': 1,
        'coins': coins,
        'classicBest': classicBest,
        'timeBest': timeBest,
        'rushBest': rushBest,
        'bombUses': bombUses,
        'owned': owned.toList(),
        'achievements': achievements.toList(),
        'rewards': rewards.toList(),
        'levelStars': levelStars.map((k, v) => MapEntry('$k', v)),
        'levelScores': levelScores.map((k, v) => MapEntry('$k', v)),
        'theme': theme,
        'background': background,
        'photo': photo,
        'language': language,
        'masterVolume': masterVolume,
        'musicVolume': musicVolume,
        'effects': effects,
        'vibration': vibration,
        'reducedMotion': reducedMotion,
        'musicTrack': musicTrack,
        'day': day,
        'dailyLines': dailyLines,
        'classic': classic
      };
  factory Profile.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 1) throw const FormatException('Unknown profile schema');
    final p = Profile();
    p.coins = j['coins'] as int;
    p.classicBest = j['classicBest'] as int;
    p.timeBest = j['timeBest'] as int;
    p.rushBest = j['rushBest'] as int?;
    p.bombUses = j['bombUses'] as int;
    p.owned = (j['owned'] as List).cast<String>().toSet()
      ..addAll({'dark', 'plain'});
    p.achievements = (j['achievements'] as List).cast<String>().toSet();
    p.rewards = (j['rewards'] as List).cast<String>().toSet();
    p.levelStars = Map<String, dynamic>.from(j['levelStars'])
        .map((k, v) => MapEntry(int.parse(k), v as int));
    p.levelScores = Map<String, dynamic>.from(j['levelScores'])
        .map((k, v) => MapEntry(int.parse(k), v as int));
    p.theme = j['theme'] as String;
    p.background = j['background'] as String;
    p.photo = j['photo'] as String;
    p.language = j['language'] as String;
    if (!['tr', 'en'].contains(p.language)) p.language = 'tr';
    p.masterVolume =
        (j['masterVolume'] as num).toDouble().clamp(0.0, 1.0).toDouble();
    p.musicVolume =
        (j['musicVolume'] as num).toDouble().clamp(0.0, 1.0).toDouble();
    p.effects = j['effects'] as bool;
    p.vibration = j['vibration'] as bool;
    p.reducedMotion = j['reducedMotion'] as bool;
    p.musicTrack = j['musicTrack'] as int;
    p.day = j['day'] as String;
    p.dailyLines = j['dailyLines'] as int;
    if (j['classic'] != null) {
      try {
        final saved = Map<String, dynamic>.from(j['classic']);
        final g = Game.fromJson(saved);
        if (g.mode == Mode.classic && g.outcome == Outcome.playing)
          p.classic = saved;
      } catch (_) {
        p.classic = null;
      }
    }
    if ([p.coins, p.classicBest, p.timeBest, p.bombUses, p.dailyLines]
            .any((v) => v < 0) ||
        p.levelStars.entries.any(
            (e) => e.key < 1 || e.key > 20 || e.value < 1 || e.value > 3) ||
        p.musicTrack < -1 ||
        p.musicTrack > 2) throw const FormatException('Invalid profile');
    if (!p.owned.contains(p.theme) ||
        !['dark', 'neon', 'forest', 'gem'].contains(p.theme)) p.theme = 'dark';
    if (!p.owned.contains(p.background)) p.background = 'plain';
    return p;
  }
  Profile();
}

// Future integrations are deliberately disconnected in MVP.
abstract interface class PlatformAchievementsService {
  Future<void> unlock(String id);
  Future<void> submitScore(Mode mode, int score);
}

class OfflineAchievementsService implements PlatformAchievementsService {
  @override
  Future<void> unlock(String id) async {}
  @override
  Future<void> submitScore(Mode mode, int score) async {}
}
