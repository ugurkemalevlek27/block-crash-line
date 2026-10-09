import 'dart:convert';
import 'dart:io';
import '../economy/profile.dart';

/// One rename commits rewards, balance, settings and Classic position together.
/// tmp is never treated as committed. bak retains the last known good snapshot.
class Store {
  final Directory directory;
  Store(this.directory);
  File get file => File('${directory.path}/profile.json');
  File get backup => File('${directory.path}/profile.bak');
  Future<Profile> load() async {
    for (final f in [file, backup]) {
      try {
        if (await f.exists())
          return Profile.fromJson(
              jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      } catch (_) {/* Recover snapshot without preventing startup. */}
    }
    return Profile();
  }

  Future<void> save(Profile p) async {
    await directory.create(recursive: true);
    final temp = File('${directory.path}/profile.tmp');
    await temp.writeAsString(jsonEncode(p.toJson()), flush: true);
    if (await file.exists()) {
      // Copy only a parsable profile to the backup.
      var valid = false;
      try {
        Profile.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>);
        valid = true;
      } catch (_) {/* Keep previous valid backup. */}
      if (valid) await file.copy(backup.path);
    }
    await temp.rename(file.path);
  }
}
