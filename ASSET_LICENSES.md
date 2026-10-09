# Assets and sources

All bundled game media were created for this project by `tool/make_assets.py`:

| Files | Source | License / reuse |
| --- | --- | --- |
| `assets/audio/music0.wav` | Original procedural pentatonic pluck and flute-inspired synthesis; Bamboo Dawn | CC0-1.0 |
| `assets/audio/music1.wav` | Original procedural synthesis; Quiet Mountain | CC0-1.0 |
| `assets/audio/music2.wav` | Original procedural synthesis; Crystal Stream | CC0-1.0 |
| `assets/audio/place.wav`, `clear.wav`, `bomb.wav` | Original oscillator synthesis | CC0-1.0 |
| `assets/backgrounds/bamboo.png`, `mountain.png`, `waterfall.png` | Original programmatically drawn stylized landscapes | CC0-1.0 |
| UI block geometry and logo | Original Flutter CustomPainter / CSS | Project source license |
| Material icons | Flutter SDK Material icon font | Apache-2.0; distribution supplied by Flutter |

No other game's music, logo or proprietary assets were imported. The 32-second pieces are original instrumental sketches inspired by plucked strings and breathy flute; they are synthesized, not recordings of real guzheng or bamboo flute performers. Artwork is stylized illustration, not stock photography. CC0 text: https://creativecommons.org/publicdomain/zero/1.0/

Dependencies (retrieve their bundled LICENSE files at `flutter pub get`): Flutter BSD-3-Clause; flutter_riverpod MIT; path_provider and image_picker BSD-3-Clause; audioplayers MIT. Flutter `LicenseRegistry` provides package notices after dependencies are resolved. No package notices or locked transitive versions have been fabricated before dependency download.

Technical primary references:
- Flutter install: https://docs.flutter.dev/get-started/install
- Image picker: https://pub.dev/packages/image_picker/versions/1.1.2
- Riverpod: https://pub.dev/packages/flutter_riverpod/versions/2.6.1
- Audio: https://pub.dev/packages/audioplayers/versions/6.1.0
- Android monotonic deep-sleep clock: https://developer.android.com/reference/android/os/SystemClock
- iOS continuous clock: https://developer.apple.com/documentation/kernel/1646199-mach_continuous_time
