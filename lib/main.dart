import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controller.dart';
import 'ui/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: BlockCrashApp()));
}

class BlockCrashApp extends ConsumerStatefulWidget {
  const BlockCrashApp({super.key});
  @override
  ConsumerState<BlockCrashApp> createState() => _BlockCrashAppState();
}

class _BlockCrashAppState extends ConsumerState<BlockCrashApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appProvider).lifecycle(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    return MaterialApp(
        title: 'Block Crash Line',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xff0b1428),
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff75bfff),
                brightness: Brightness.dark),
            cardColor: const Color(0xff182641),
            appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent, centerTitle: true),
            filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 54))),
            textTheme: const TextTheme(
                headlineLarge:
                    TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
                titleLarge: TextStyle(fontWeight: FontWeight.w700))),
        home: !app.ready
            ? Scaffold(
                body: Center(
                    child: app.error == null
                        ? const CircularProgressIndicator()
                        : Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(app.error!),
                                  const SizedBox(height: 20),
                                  FilledButton(
                                      onPressed: app.initialize,
                                      child: const Text('Yeniden dene / Retry'))
                                ]))))
            : const HomeScreen());
  }
}
